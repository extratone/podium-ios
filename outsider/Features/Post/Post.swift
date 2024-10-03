//
//  Post.swift
//  outsider
//
//  Created by Michael Jach on 11/09/2024.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct Post {
  @Dependency(\.supabase) var supabase
  
  @ObservableState
  struct State: Equatable, Identifiable {
    var id: UUID { post.uuid }
    var size: Size
    let currentUser: CurrentUserModel
    var post: PostModel
    var isPending = false
    var isLiked: Bool {
      return post.likes.contains(where: { $0.liked_by == currentUser.uuid })
    }
    
    // Sub states
    @Presents var media: Media.State?
  }
  
  enum Action {
    case delete
    case didDelete(Result<UUID, Error>)
    case presentMedia(MediaModel)
    case like
    case didLike(Result<LikeModel, Error>)
    case unlike
    case didUnlike(PostModel)
    case mute
    case didMute(Result<UUID, Error>)
    case report
    case didReport(Result<UUID, Error>)
    
    // Sub actions
    case media(PresentationAction<Media.Action>)
  }
  
  enum Size {
    case small
    case normal
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .report:
        return .run { [post = state.post, currentUser = state.currentUser] send in
          do {
            try await supabase
              .from("posts_reports")
              .insert(PostMutedModel(
                post_uuid: post.uuid,
                user_uuid: currentUser.uuid
              ))
              .execute()
            
            await send(.didReport(.success(post.uuid)))
          } catch {
            await send(.didReport(.failure(error)))
          }
        }
        
      case .didReport(.success(let postUuid)):
        return .none
        
      case .didReport(.failure(let error)):
        print(error)
        return .none
        
      case .mute:
        return .run { [post = state.post, currentUser = state.currentUser] send in
          do {
            try await supabase
              .from("posts_muted")
              .insert(PostMutedModel(
                post_uuid: post.uuid,
                user_uuid: currentUser.uuid
              ))
              .execute()
            
            await send(.didMute(.success(post.uuid)))
          } catch {
            await send(.didMute(.failure(error)))
          }
        }
        
      case .didMute(.success(let postUuid)):
        return .none
        
      case .didMute(.failure(let error)):
        print(error)
        return .none
        
      case .presentMedia(let media):
        state.media = Media.State(media: media)
        return .none
        
      case .media:
        return .none
        
      case .like:
        let like = LikeModel(uuid: UUID(), post_uuid: state.post.uuid, liked_by: state.currentUser.uuid)
        return .merge(
          .run { send in
            do {
              try await supabase
                .from("likes")
                .insert(like)
                .execute()
            } catch {
              await send(.didLike(.failure(error)))
            }
          },
          .run { send in
            await send(.didLike(.success(like)))
          }
        )
        
      case .didLike(.success(let like)):
        state.post.likes.append(like)
        return .none
        
      case .didLike(.failure(let error)):
        print(error)
        return .none
        
      case .unlike:
        return .merge(
          .run { [post = state.post] send in
            do {
              try await supabase
                .from("likes")
                .delete()
                .eq("post_uuid", value: post.uuid)
                .execute()
            } catch {
              print(error)
            }
          },
          .run { [post = state.post] send in
            await send(.didUnlike(post))
          }
        )
        
      case .didUnlike(let post):
        state.post.likes.removeAll(where: { $0.post_uuid == post.uuid })
        return .none
        
      case .delete:
        state.isPending = true
        return .run { [post = state.post] send in
          do {
            try await supabase
              .from("posts_media")
              .delete()
              .eq("post_uuid", value: post.uuid)
              .execute()
            
            try await supabase
              .from("posts_comments")
              .delete()
              .eq("comment_uuid", value: post.uuid)
              .execute()
            
            try await supabase
              .from("likes")
              .delete()
              .eq("post_uuid", value: post.uuid)
              .execute()
            
            try await supabase
              .from("posts")
              .delete()
              .eq("uuid", value: post.uuid)
              .execute()
            
            try await supabase
              .from("media")
              .delete()
              .eq("post_uuid", value: post.uuid)
              .execute()
            
            _ = try await supabase.storage
              .from("media")
              .remove(paths: ["\(post.uuid.uuidString)"])
            
            await send(.didDelete(.success(post.uuid)))
          } catch {
            await send(.didDelete(.failure(error)))
          }
        }
        
      case .didDelete(.success(_)):
        state.isPending = false
        return .none
        
      case .didDelete(.failure(let error)):
        state.isPending = false
        print(error)
        return .none
      }
    }
    .ifLet(\.$media, action: \.media) {
      Media()
    }
  }
}
