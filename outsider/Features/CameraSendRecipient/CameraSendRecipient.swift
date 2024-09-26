//
//  CameraSendRecipient.swift
//  outsider
//
//  Created by Michael Jach on 25/09/2024.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct CameraSendRecipient {
  @Dependency(\.supabase) var supabase
  
  @ObservableState
  struct State: Equatable, Identifiable {
    var id: UUID { following.following.uuid }
    var following: FollowingModel
    var selected = false
  }
  
  enum Action {
    case onSelectedChange(Bool)
  }
    
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onSelectedChange(let isSelected):
        state.selected = isSelected
        return .none
      }
    }
  }
}
