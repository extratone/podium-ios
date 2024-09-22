//
//  CurrentProfile.swift
//  outsider
//
//  Created by Michael Jach on 09/09/2024.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct CurrentProfile {
  @Reducer(state: .equatable)
  enum Path {
    case settings(Settings)
    case comments(Comments)
    case profile(Profile)
  }
  
  @ObservableState
  struct State: Equatable {
    // Sub states
    var path = StackState<Path.State>()
    var profile: Profile.State
  }
  
  enum Action {
    // Sub actions
    case path(StackActionOf<Path>)
    case profile(Profile.Action)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .path(.element(_, action: .profile(.presentComments(let post)))),
          .profile(.presentComments(let post)):
        state.path.append(
          .comments(Comments.State(
            post: Post.State(
              currentUser: state.profile.currentUser,
              post: post
            )))
        )
        return .none
        
      case .path(.element(_, action: .comments(.presentProfile(let profile)))),
          .path(.element(_, action: .profile(.presentProfile(let profile)))),
          .profile(.presentProfile(let profile)):
        state.path.append(.profile(Profile.State(
          currentUser: state.profile.currentUser,
          user: profile
        )))
        return .none
        
      case .path:
        return .none
        
      case .profile(.didFetchProfile(.success((let user, _)))):
        state.profile.currentUser = user
        if let encoded = try? JSONEncoder().encode(user) {
          UserDefaults.standard.set(encoded, forKey: StorageKey.user.rawValue)
        }
        return .none
        
      case .profile:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
    
    Scope(state: \.profile, action: \.profile) {
      Profile()
    }
  }
}
