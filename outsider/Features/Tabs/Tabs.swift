//
//  Tabs.swift
//  outsider
//
//  Created by Michael Jach on 09/09/2024.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct Tabs {
  @Dependency(\.supabase) var supabase
  
  @ObservableState
  struct State {
    var currentUser: UserModel
    var bannerData = BannerModifier.BannerData(title: "", detail: "", type: .Info)
    var showBanner = false
    var selection: Int?
    
    // Sub states
    var camera: Camera.State
    var home: Home.State
    var explore: Explore.State
    var currentProfile: CurrentProfile.State
  }
  
  enum Action {
    case initialize
    case showBannerChanged(Bool)
    case bannerDataChanged(BannerModifier.BannerData)
    case handleBadSession
    case onSelectionChanged(Int?)
    
    // Sub actions
    case camera(Camera.Action)
    case home(Home.Action)
    case explore(Explore.Action)
    case currentProfile(CurrentProfile.Action)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onSelectionChanged(let selection):
        state.selection = selection
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
        
      case .home(_):
        return .none
        
      case .explore:
        return .none
        
      case .camera(.send):
        state.selection = 1
        state.home.isLoading = true
        return .none
        
      case .camera(.didSend(.success(let story))):
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
