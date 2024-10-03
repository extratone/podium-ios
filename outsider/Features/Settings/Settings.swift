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
    let currentUserUuid: UUID
  }
  
  enum Action {
    case logout
    case didLogout
    case deleteAccount
    case didDeleteAccount
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .deleteAccount:
        return .run { [currentUserUuid = state.currentUserUuid] send in
          do {
            try await supabase
              .from("users_following")
              .delete()
              .eq("user_uuid", value: currentUserUuid)
              .execute()
            
            try await supabase
              .from("users")
              .delete()
              .eq("uuid", value: currentUserUuid)
              .execute()
            
//            try await supabase.auth.admin.deleteUser(id: currentUserUuid.uuidString)
            
            await send(.didDeleteAccount)
          } catch {
            print(error)
          }
        }
        
      case .didDeleteAccount:
        return .run { send in
          await send(.didLogout)
        }
        
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
