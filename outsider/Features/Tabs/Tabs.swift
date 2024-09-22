//
//  Tabs.swift
//  outsider
//
//  Created by Michael Jach on 09/09/2024.
//

import SwiftUI
import ComposableArchitecture
import Supabase

@Reducer
struct Tabs {
  enum TabSelection: String {
    case home
    case explore
    case messages
    case currentProfile
  }
  
  @Dependency(\.supabase) var supabase
  
  @ObservableState
  struct State {
    var currentUser: UserModel
    var bannerData = BannerModifier.BannerData(title: "", detail: "", type: .Info)
    var showBanner = false
    var selection: Int?
    var tabSelection: TabSelection = .home
    var channel: RealtimeChannelV2?
    
    // Sub states
    var camera: Camera.State
    var home: Home.State
    var explore: Explore.State
    var currentProfile: CurrentProfile.State
  }
  
  enum Action {
    case initialize
    case subscribe
    case onSubscribe(RealtimeChannelV2)
    case unsubscribe
    case onUnsubscribe
    case showBannerChanged(Bool)
    case bannerDataChanged(BannerModifier.BannerData)
    case handleBadSession
    case onSelectionChanged(Int?)
    case onTabSelectionChanged(TabSelection)
    case onInsertStory(Result<StoryModel, Error>)
    
    // Sub actions
    case camera(Camera.Action)
    case home(Home.Action)
    case explore(Explore.Action)
    case currentProfile(CurrentProfile.Action)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .subscribe:
        return .run { [currentUser = state.currentUser] send in
          let channel = supabase.channel("stories-\(currentUser.uuid.uuidString)")
          
          let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "stories",
            filter: "author_uuid=in.(\(currentUser.following.map({ $0.uuidString }).joined(separator: ", ")))"
          )
          
          await channel.subscribe()
          await send(.onSubscribe(channel))
          
          for await insertAction in insertions {
            do {
              let jsonData = try JSONEncoder().encode(insertAction.record)
              let storyModel = try JSONDecoder().decode(StoryModelInsert.self, from: jsonData)
              
              let story: StoryModel = try await supabase
                .from("stories")
                .select(
                  """
                    uuid,
                    url,
                    type,
                    author:users(*),
                    stats:stories_stats(*)
                  """
                )
                .eq("uuid", value: storyModel.uuid)
                .single()
                .execute()
                .value
              
              await send(.onInsertStory(.success(story)))
            } catch {
              await send(.onInsertStory(.failure(error)))
            }
          }
        }
        
      case .onSubscribe(let channel):
        state.channel = channel
        return .none
        
      case .onUnsubscribe:
        state.channel = nil
        return .none
        
      case .onInsertStory(.success(let story)):
        if state.home.stories.stories[story.author] == nil {
          state.home.stories.stories[story.author] = []
        }
        state.home.stories.stories[story.author]?.append(story)
        return .none
        
      case .onInsertStory(.failure(let error)):
        print(error)
        return .none
        
      case .unsubscribe:
        return .run { [channel = state.channel] send in
          await channel?.unsubscribe()
          await send(.onUnsubscribe)
        }
        
      case .onSelectionChanged(let selection):
        state.selection = selection
        if state.selection == 0 {
          return .run { [camera = state.camera] send in
            await camera.camera.start()
          }
        } else {
          return .run { [camera = state.camera] send in
            camera.camera.stop()
          }
        }
        
      case .onTabSelectionChanged(let tabSelection):
        state.tabSelection = tabSelection
        return .none
        
      case .handleBadSession:
        return .run { send in
          try await supabase.auth.signOut()
        }
        
      case .initialize:
        return .merge(
          .run { send in
            do {
              try await supabase.auth.refreshSession()
            } catch {
              await send(.handleBadSession)
            }
          },
          .run { send in
            await send(.currentProfile(.profile(.fetchProfile)))
          },
          .run { send in
            await send(.unsubscribe)
            await send(.home(.stories(.fetchStories)))
            await send(.subscribe)
          }
        )
        
      case .home(.posts(.element(id: _, action: .didDelete(.success(let uuid))))):
        state.currentProfile.profile.posts.removeAll(where: { $0.post.uuid == uuid })
        return .none
        
      case .home(.send(.didSend(.success(let post)))):
        state.currentProfile.profile.posts.insert(Post.State(currentUser: state.currentUser, post: post), at: 0)
        return .none
        
      case .home(.send(.didSend(.failure(let error)))):
        state.bannerData = BannerModifier.BannerData(
          title: "Error",
          detail: error.localizedDescription,
          type: .Error
        )
        state.showBanner = true
        return .none
        
      case .home(.posts(.element(_, action: .didLike(.success(let like))))),
          .currentProfile(.profile(.posts(.element(_, action: .didLike(.success(let like)))))):
        if state.home.posts[id: like.post_uuid]?.post.likes == nil {
          state.home.posts[id: like.post_uuid]?.post.likes = []
          state.currentProfile.profile.posts[id: like.post_uuid]?.post.likes = []
        }
        state.home.posts[id: like.post_uuid]?.post.likes?.append(like)
        state.currentProfile.profile.posts[id: like.post_uuid]?.post.likes?.append(like)
        return .none
        
      case .home(.posts(.element(let id, action: .didUnlike(_)))),
          .currentProfile(.profile(.posts(.element(let id, action: .didUnlike(_))))):
        if var temp = state.home.posts[id: id] {
          temp.post.likes?.removeAll(where: { $0.liked_by == state.currentUser.uuid })
          state.home.posts[id: id] = temp
          state.currentProfile.profile.posts[id: id] = temp
        }
        return .none
        
      case .home(.stories(.presentCamera)):
        state.selection = 0
        return .none
        
      case .home(.path(.element(_, .profile(.didFollow(.success(let uuid)))))):
        state.currentUser.following.append(uuid)
        state.home.currentUser.following.append(uuid)
        state.home.stories.currentUser.following.append(uuid)
        state.currentProfile.profile.currentUser.following.append(uuid)
        if let encoded = try? JSONEncoder().encode(state.currentUser) {
          UserDefaults.standard.set(encoded, forKey: StorageKey.user.rawValue)
        }
        return .run { send in
          await send(.unsubscribe)
          await send(.home(.fetchPosts))
          await send(.home(.stories(.fetchStories)))
          await send(.subscribe)
        }
        
      case .home(.path(.element(_, .profile(.didUnfollow(.success(let uuid)))))):
        state.currentUser.following.removeAll(where: { $0 == uuid })
        state.home.currentUser.following.removeAll(where: { $0 == uuid })
        state.home.stories.currentUser.following.removeAll(where: { $0 == uuid })
        state.currentProfile.profile.currentUser.following.removeAll(where: { $0 == uuid })
        if let encoded = try? JSONEncoder().encode(state.currentUser) {
          UserDefaults.standard.set(encoded, forKey: StorageKey.user.rawValue)
        }
        return .run { send in
          await send(.unsubscribe)
          await send(.home(.fetchPosts))
          await send(.home(.stories(.fetchStories)))
          await send(.subscribe)
        }
        
      case .home(_):
        return .none
        
      case .explore:
        return .none
        
      case .camera(.send):
        state.selection = 1
        state.home.isLoading = true
        return .none
        
      case .camera(.didSend(.success(_))):
        state.home.isLoading = false
        return .run { send in
          await send(.home(.stories(.fetchStories)))
        }
        
      case .camera:
        return .none
        
      case .currentProfile(.profile(.didUpload)):
        return .run { send in
          await send(.currentProfile(.profile(.fetchProfile)))
        }
        
      case .currentProfile(.profile(.didFetchProfile(.success((let user, _))))):
        state.home.stories.currentUser = user
        return .none
        
      case .currentProfile(_):
        return .none
        
      case .showBannerChanged(let showBanner):
        state.showBanner = showBanner
        return .none
        
      case .bannerDataChanged(let bannerData):
        state.bannerData = bannerData
        return .none
      }
    }
    
    Scope(state: \.camera, action: \.camera) {
      Camera()
    }
    
    Scope(state: \.home, action: \.home) {
      Home()
    }
    
    Scope(state: \.explore, action: \.explore) {
      Explore()
    }
    
    Scope(state: \.currentProfile, action: \.currentProfile) {
      CurrentProfile()
    }
  }
}
