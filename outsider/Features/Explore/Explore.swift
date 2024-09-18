//
//  Explore.swift
//  outsider
//
//  Created by Michael Jach on 12/09/2024.
//

import SwiftUI
import ComposableArchitecture
import Supabase

@Reducer
struct Explore {
  @Dependency(\.supabase) var supabase
  
  @ObservableState
  struct State: Equatable {
    var query = ""
    var isSearching = false
  }
  
  enum Action {
    case queryChanged(String)
    case isSearchingChanged(Bool)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .isSearchingChanged(let isSearching):
        state.isSearching = isSearching
        return .none
        
      case .queryChanged(let query):
        state.query = query
        if query.count > 1 {
          return .run { send in
            
          }
        }
        return .none
      }
    }
  }
}
