//
//  Comments.swift
//  outsider
//
//  Created by Michael Jach on 16/09/2024.
//

import SwiftUI
import ComposableArchitecture
import Supabase

@Reducer
struct Comments {
  @Dependency(\.supabase) var supabase
  
  @ObservableState
  struct State: Equatable {
    let currentUser: UserModel
    var text = ""
    var tempImage: UIImage?
    
    // Sub states
    var post: Post.State
    var posts: IdentifiedArrayOf<Post.State> = []
  }
  
  enum Action {
    case presentProfile(UserModel)
    case fetchComments
    case didFetchComments(Result<[CommentModel], Error>)
    case onTextChange(String)
    case sendComment
    case didSendComment(Result<(UUID, PostModel), Error>)
    
    // Sub actions
    case post(Post.Action)
    case posts(IdentifiedActionOf<Post>)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .sendComment:
        let text = state.text
        state.text = ""
        return .run { [post = state.post, currentUser = state.currentUser, text = text, tempImage = state.tempImage] send in
          do {
            let commentUuid = UUID()
            let mediaUuid = UUID()
            
            if let tempImage = tempImage {
              try await supabase.storage
                .from("media")
                .upload(
                  path: "\(commentUuid)/\(mediaUuid).png",
                  file: tempImage.jpegData(compressionQuality: 0.8)!,
                  options: FileOptions(upsert: true)
                )
              
              let publicURL = try supabase.storage
                .from("media")
                .getPublicURL(path: "\(commentUuid)/\(mediaUuid).png")
              
              try await supabase
                .from("media")
                .insert(MediaModel(
                  uuid: mediaUuid,
                  url: publicURL.absoluteString,
                  post_uuid: commentUuid
                ))
                .execute()
            }
            
            try await supabase
              .from("posts")
              .insert(PostModelInsert(
                uuid: commentUuid,
                text: text,
                author: currentUser.uuid,
                is_comment: true
              ))
              .execute()
            
            try await supabase
              .from("posts_comments")
              .insert(PostCommentModelInsert(
                post_uuid: post.post.uuid,
                comment_uuid: commentUuid
              ))
              .execute()
            
            if tempImage != nil {
              try await supabase
                .from("posts_media")
                .insert(PostMediaInsert(post_uuid: commentUuid, media_uuid: mediaUuid))
                .execute()
            }
            
            let comment: PostModel = try await supabase
              .from("posts")
              .select(
                """
                  uuid,
                  text,
                  created_at,
                  is_comment,
                  author!inner(*),
                  media(*)
                """
              )
              .eq("uuid", value: commentUuid)
              .single()
              .execute()
              .value
            
            await send(.didSendComment(.success((post.post.uuid, comment))))
          } catch {
            await send(.didSendComment(.failure(error)))
          }
        }
        
      case .didSendComment(.success((_, let comment))):
        state.posts.insert(Post.State(
          size: .small,
          currentUser: state.currentUser,
          post: comment
        ), at: 0)
        return .none
        
      case .didSendComment(.failure(let error)):
        print(error)
        return .none
        
      case .onTextChange(let text):
        state.text = text
        return .none
        
      case .fetchComments:
        return .run { [post = state.post] send in
          do {
            let post: PostModel = try await supabase
              .from("posts")
              .select(
                """
                  uuid,
                  text,
                  created_at,
                  is_comment,
                  comments:posts_comments!posts_comments_post_uuid_fkey(
                    comment:posts!posts_comments_comment_uuid_fkey(*, author:users(*))
                  ),
                  author!inner(*),
                  media(*),
                  likes(*)
                """
              )
              .eq("uuid", value: post.post.uuid)
              .single()
              .execute()
              .value
            
            await send(.didFetchComments(.success(post.comments?.reversed() ?? [])))
          } catch {
            await send(.didFetchComments(.failure(error)))
          }
        }
        
      case .didFetchComments(.success(let comments)):
        var temp: IdentifiedArrayOf<Post.State> = []
        for post in comments {
          temp.append(Post.State(
            size: .small,
            currentUser: state.currentUser,
            post: post.comment
          ))
        }
        state.posts = temp
        return .none
        
      case .didFetchComments(.failure(let error)):
        print(error)
        return .none
        
      case .presentProfile(_):
        return .none
        
      case .post:
        return .none
        
      case .posts:
        return .none
      }
    }
    .forEach(\.posts, action: \.posts) {
      Post()
    }
    
    Scope(state: \.post, action: \.post) {
      Post()
    }
  }
}
