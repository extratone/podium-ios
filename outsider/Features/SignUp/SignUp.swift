//
//  SignUp.swift
//  outsider
//
//  Created by Michael Jach on 09/09/2024.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct SignUp {
  @Dependency(\.supabase) var supabase
  
  @ObservableState
  struct State: Equatable {
    var isLoading = false
    var error: String?
    var email: String = ""
    var password: String = ""
  }
  
  enum Action {
    case signUp
    case didSignUp(Result<UUID, Error>)
    case onEmailChanged(email: String)
    case onPasswordChanged(password: String)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .signUp:
        state.isLoading = true
        state.error = nil
        return .run { [email = state.email, password = state.password] send in
          do {
            let authResponse = try await supabase.auth.signUp(
              email: email,
              password: password
            )
            await send(.didSignUp(.success(authResponse.user.id)))
          } catch let error {
            await send(.didSignUp(.failure(error)))
          }
        }
        
      case .onEmailChanged(let email):
        state.email = email
        return .none
        
      case .onPasswordChanged(let password):
        state.password = password
        return .none
        
      case .didSignUp(.success(_)):
        state.isLoading = false
        return .none
        
      case .didSignUp(.failure(let error)):
        state.isLoading = false
        state.error = error.localizedDescription
        return .none
      }
    }
  }
}
