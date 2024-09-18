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
      case .path:
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
