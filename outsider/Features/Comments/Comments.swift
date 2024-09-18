//
//  Comments.swift
//  outsider
//
//  Created by Michael Jach on 16/09/2024.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct Comments {
  
  @ObservableState
  struct State: Equatable {
    // Sub states
    var post: Post.State
  }
  
  enum Action {
    case presentProfile(UserModel)
    
    // Sub actions
    case post(Post.Action)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {  
      case .presentProfile(_):
        return .none
        
      case .post:
        return .none
      }
    }
    
    Scope(state: \.post, action: \.post) {
      Post()
    }
  }
}
