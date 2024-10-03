//
//  Home.swift
//  outsider
//
//  Created by Michael Jach on 09/09/2024.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct Home {
  @Dependency(\.supabase) var supabase
  
  @Reducer(state: .equatable)
  enum Path {
    case comments(Comments)
    case profile(Profile)
  }
  
  @ObservableState
  struct State: Equatable {
    var isLoading = false
    var currentUser: CurrentUserModel
    var posts: IdentifiedArrayOf<Post.State> = []
    
    // Sub states
    var send: Send.State
    var path = StackState<Path.State>()
    var stories: Stories.State
  }
  
  enum Action {
    case fetchPosts
    case didFetchPosts(Result<[PostModel], Error>)
    case setIsLoading(Bool)
    case presentComments(PostModel)
    case presentProfile(UserModel)
    
    // Sub actions
    case send(Send.Action)
    case posts(IdentifiedActionOf<Post>)
    case path(StackActionOf<Path>)
    case stories(Stories.Action)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .presentComments(let post),
          .path(.element(_, action: .profile(.presentComments(let post)))):
        state.path.append(
          .comments(Comments.State(
            currentUser: state.currentUser,
            post: Post.State(
              size: .normal,
              currentUser: state.currentUser,
              post: post
            )))
        )
        return .none
        
      case .presentProfile(let profile),
          .path(.element(_, action: .comments(.presentProfile(let profile)))),
          .path(.element(_, action: .profile(.presentProfile(let profile)))):
        state.path.append(.profile(Profile.State(
          currentUser: state.currentUser,
          user: profile
        )))
        return .none
        
      case .setIsLoading(let isLoading):
        state.isLoading = isLoading
        return .none
        
      case .posts(.element(id: _, action: .didDelete(.success(let uuid)))):
        state.posts.removeAll(where: { $0.post.uuid == uuid })
        return .none
        
      case .posts(.element(id: _, action: .didMute(.success(let uuid)))):
        state.posts.removeAll(where: { $0.post.uuid == uuid })
        return .none
        
      case .path(.element(_, action: .comments(.post(.didLike(.success(let like)))))):
        state.posts[id: like.post_uuid]?.post.likes.append(like)
        return .none
        
      case .path(.element(_, action: .comments(.post(.didUnlike(let post))))):
        state.posts[id: post.uuid]?.post.likes.removeAll(where: { $0.post_uuid == post.uuid })
        return .none
        
      case .posts:
        return .none
        
      case .fetchPosts:
        return .run { [currentUser = state.currentUser] send in
          do {
            let posts: [PostModel] = try await supabase
              .from("posts")
              .select(
                """
                  uuid,
                  text,
                  created_at,
                  is_comment,
                  commentsCount:posts_comments!posts_comments_post_uuid_fkey(
                    count
                  ),
                  author!inner(*),
                  media(*),
                  likes(*)
                """
              )
              .eq("is_comment", value: false)
              .not("uuid", operator: .in, value: "(\(currentUser.mutedPosts.map({ $0.post_uuid.uuidString }).joined(separator: ",")))")
              .order("created_at", ascending: false)
              .limit(20)
              .execute()
              .value
            
            await send(.didFetchPosts(.success(posts)))
          } catch {
            await send(.didFetchPosts(.failure(error)))
          }
        }
        
      case .didFetchPosts(.success(let posts)):
        var temp: IdentifiedArrayOf<Post.State> = []
        for post in posts {
          temp.append(Post.State(
            size: .normal,
            currentUser: state.currentUser,
            post: post
          ))
        }
        state.posts = temp
        return .none
        
      case .didFetchPosts(.failure(let error)):
        print(error)
        return .none
        
      case .send(.didSend(.success(let post))):
        state.isLoading = false
        state.posts.insert(Post.State(
          size: .normal,
          currentUser: state.currentUser,
          post: post
        ), at: 0)
        return .none
        
      case .send(.didSend(.failure)):
        state.isLoading = false
        return .none
        
      case .send(.send):
        state.isLoading = true
        return .none
        
      case .send:
        return .none
        
      case .stories:
        return .none
        
      case .path:
        return .none
      }
    }
    .forEach(\.posts, action: \.posts) {
      Post()
    }
    .forEach(\.path, action: \.path)
    
    Scope(state: \.send, action: \.send) {
      Send()
    }
    
    Scope(state: \.stories, action: \.stories) {
      Stories()
    }
  }
}
