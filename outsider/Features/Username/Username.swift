//
//  Username.swift
//  outsider
//
//  Created by Michael Jach on 12/09/2024.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct Username {
  @Dependency(\.supabase) var supabase
  
  @ObservableState
  struct State: Equatable {
    var uuid: UUID
    var isLoading = false
    var username = ""
    var error: String?
  }
  
  enum Action {
    case onUsernameChanged(String)
    case signUp
    case didSignUp(Result<UserModel, Error>)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .onUsernameChanged(let username):
        state.username = username.lowercased()
        return .none
        
      case .signUp:
        return .run { [uuid = state.uuid, username = state.username] send in
          do {
            let user: UserModel = try await supabase
              .from("users")
              .insert(UserModel(
                uuid: uuid,
                username: username,
                display_name: nil,
                avatar_url: nil
              ))
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
              .single()
              .execute()
              .value
            
            await send(.didSignUp(.success(user)))
          } catch let error {
            await send(.didSignUp(.failure(error)))
          }
        }
        
      case .didSignUp(.success(let user)):
        if let encoded = try? JSONEncoder().encode(user) {
          UserDefaults.standard.set(encoded, forKey: StorageKey.user.rawValue)
        }
        return .none
        
      case .didSignUp(.failure(let error)):
        print(error)
        state.error = error.localizedDescription
        return .none
      }
    }
  }
}
