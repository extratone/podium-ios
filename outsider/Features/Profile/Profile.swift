//
//  Profile.swift
//  outsider
//
//  Created by Michael Jach on 16/09/2024.
//

import SwiftUI
import ComposableArchitecture
import PhotosUI
import Supabase

@Reducer
struct Profile {
  @Dependency(\.supabase) var supabase
  
  enum Tabs: String {
    case posts
    case media
    case likes
  }
  
  @ObservableState
  struct State: Equatable {
    var currentUser: CurrentUserModel
    var user: UserModel
    var displayName: String = ""
    var posts: IdentifiedArrayOf<Post.State> = []
    var tempAvatar: UIImage?
    var imageSelection: PhotosPickerItem?
    var selectedTabIndex = Tabs.posts
    var isPending = false
    var isCurrent: Bool {
      return currentUser.uuid == user.uuid
    }
  }
  
  enum Action {
    case initialize
    case imageSelectionChanged(PhotosPickerItem?)
    case upload(UIImage?)
    case didUpload
    case onSelectedTabIndexChanged(Tabs)
    case fetchPosts
    case didFetchPosts(Result<(UserModel, [PostModel]), Error>)
    case presentComments(PostModel)
    case presentProfile(UserModel)
    case onDisplayNameChanged(String)
    case setDisplayName
    case didSetDisplayName(Result<String, Error>)
    case follow(UserModel)
    case didFollow(Result<UserModel, Error>)
    case unfollow(UserModel)
    case didUnfollow(Result<UserModel, Error>)
    
    // Sub actions
    case posts(IdentifiedActionOf<Post>)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .follow(let user):
        state.isPending = true
        return .run { [currentUser = state.currentUser] send in
          do {
            try await supabase
              .from("users_following")
              .upsert(FollowingModelInsert(
                user_uuid: currentUser.uuid,
                following_user_uuid: user.uuid
              ))
              .execute()
            
            await send(.didFollow(.success(user)))
          } catch {
            await send(.didFollow(.failure(error)))
          }
        }
        
      case .didFollow(.success(let user)):
        state.currentUser.following.append(FollowingModel(following: user))
        state.isPending = false
        return .none
        
      case .didFollow(.failure(let error)):
        state.isPending = false
        print(error)
        return .none
        
      case .unfollow(let user):
        state.isPending = true
        return .run { [currentUser = state.currentUser] send in
          do {
            try await supabase
              .from("users_following")
              .delete()
              .eq("user_uuid", value: currentUser.uuid)
              .eq("following_user_uuid", value: user.uuid)
              .execute()
            
            await send(.didUnfollow(.success(user)))
          } catch {
            await send(.didUnfollow(.failure(error)))
          }
        }
        
      case .didUnfollow(.success(let user)):
        state.currentUser.following.removeAll(where: { $0.following.uuid == user.uuid })
        state.isPending = false
        return .none
        
      case .didUnfollow(.failure(let error)):
        state.isPending = false
        print(error)
        return .none
        
      case .setDisplayName:
        let dislayNamePattern = #"^(?=.{1,40}$)[a-zA-Z]+(?:[-' ][a-zA-Z]+)*$"#
        if state.displayName.range(of: dislayNamePattern, options: .regularExpression) == nil {
          state.displayName = state.currentUser.display_name ?? ""
          return .none
        } else {
          return .run { [displayName = state.displayName, currentUser = state.currentUser] send in
            do {
              try await supabase
                .from("users")
                .update(["display_name": displayName])
                .eq("uuid", value: currentUser.uuid)
                .execute()
              
              await send(.didSetDisplayName(.success(displayName)))
            } catch {
              await send(.didSetDisplayName(.failure(error)))
            }
          }
        }
        
      case .didSetDisplayName(.success(let displayName)):
        state.currentUser.display_name = displayName
        return .none
        
      case .didSetDisplayName(.failure(let error)):
        print(error)
        return .none
        
      case .onDisplayNameChanged(let displayName):
        state.displayName = displayName
        return .none
        
      case .presentProfile(_):
        return .none
        
      case .presentComments(_):
        return .none
        
      case .initialize:
        state.displayName = state.user.display_name ?? ""
        return .run { send in
          await send(.fetchPosts)
        }
        
      case .fetchPosts:
        return .run { [currentUser = state.currentUser, user = state.user] send in
          do {
            let user: UserModel = try await supabase
              .from("users")
              .select(
                """
                  uuid,
                  username,
                  display_name,
                  avatar_url,
                  following:users_following!users_following_user_uuid_fkey(
                    following:users!users_following_following_user_uuid_fkey(*)
                  )
                """
              )
              .eq("uuid", value: user.uuid)
              .limit(1)
              .single()
              .execute()
              .value
            
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
              .eq("author.uuid", value: user.uuid)
              .eq("is_comment", value: false)
              .not("uuid", operator: .in, value: "(\(currentUser.mutedPosts.map({ $0.post_uuid.uuidString }).joined(separator: ",")))")
              .order("created_at", ascending: false)
              .limit(20)
              .execute()
              .value
            
            await send(.didFetchPosts(.success((user, posts))))
          } catch {
            await send(.didFetchPosts(.failure(error)))
          }
        }
        
      case .didFetchPosts(.success((let user, let posts))):
        state.user = user
        state.posts.removeAll()
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
        
      case .onSelectedTabIndexChanged(let index):
        state.selectedTabIndex = index
        return .none
        
      case .imageSelectionChanged(let selection):
        state.imageSelection = selection
        return .run { send in
          let image = try await selection!.loadTransferable(type: Data.self)!
          let uiImage = UIImage(data: image)?.resizeImage(targetSize: CGSize(width: 480, height: 480))
          await send(.upload(uiImage))
        }
        
      case .upload(let uiImage):
        state.tempAvatar = uiImage
        return .run { [userUuid = state.currentUser.uuid] send in
          do {
            let resized = uiImage!.pngData()
            let uuid = UUID().uuidString
            try await supabase.storage
              .from("avatars")
              .upload(
                path: "\(userUuid)/\(uuid).png",
                file: resized!,
                options: FileOptions(upsert: true)
              )
            
            let publicURL = try supabase.storage
              .from("avatars")
              .getPublicURL(path: "\(userUuid)/\(uuid).png")
            
            try await supabase
              .from("users")
              .update(["avatar_url": publicURL])
              .eq("uuid", value: userUuid)
              .execute()
            
            await send(.didUpload)
          } catch {
            print(error)
          }
        }
        
      case .didUpload:
        state.imageSelection = nil
        return .none
        
      case .posts(.element(_, action: .didDelete(.success(let uuid)))):
        state.posts.removeAll(where: { $0.post.uuid == uuid })
        return .none
        
      case .posts(.element(_, action: .didMute(.success(let uuid)))):
        state.posts.removeAll(where: { $0.post.uuid == uuid })
        return .none
        
      case .posts(_):
        return .none
      }
    }
    .forEach(\.posts, action: \.posts) {
      Post()
    }
  }
}
