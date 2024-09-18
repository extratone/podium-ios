//
//  Settings.swift
//  outsider
//
//  Created by Michael Jach on 12/09/2024.
//

import SwiftUI
import ComposableArchitecture
import Supabase

@Reducer
struct Settings {
  @Dependency(\.supabase) var supabase
  
  @ObservableState
  struct State: Equatable {
    
  }
  
  enum Action {
    case logout
    case didLogout
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .logout:
        return .run { send in
          do {
            try await supabase.auth.signOut()
            await send(.didLogout)
          } catch {
            print(error)
          }
        }
        
      case .didLogout:
        UserDefaults.standard.removeObject(forKey: StorageKey.user.rawValue)
        return .none
      }
    }
  }
}
