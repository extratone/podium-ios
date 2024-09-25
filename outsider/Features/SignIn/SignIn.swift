//
//  SignIn.swift
//  outsider
//
//  Created by Michael Jach on 09/09/2024.
//

import SwiftUI
import ComposableArchitecture
import Supabase

@Reducer
struct SignIn {
  @Dependency(\.supabase) var supabase
  
  @Reducer(state: .equatable)
  enum Path {
    case username(Username)
    case signUp(SignUp)
  }
  
  @ObservableState
  struct State: Equatable {
    var isLoading = false
    var error: String?
    var email: String = ""
    var password: String = ""
    
    // Sub states
    var path = StackState<Path.State>()
  }
  
  enum Action {
    case signIn
    case didSignIn(Result<UUID, Error>)
    case fetchUser(UUID)
    case didFetchUser(Result<UserModel, Error>)
    case onEmailChanged(email: String)
    case onPasswordChanged(password: String)
    case presentUsername(UUID)
    
    // Sub states
    case path(StackActionOf<Path>)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .signIn:
        state.isLoading = true
        state.error = nil
        return .run { [email = state.email, password = state.password] send in
          do {
            let session = try await supabase.auth.signIn(
              email: email,
              password: password
            )
            
            await send(.didSignIn(.success(session.user.id)))
          } catch let error {
            await send(.didSignIn(.failure(error)))
          }
        }
        
      case .didSignIn(.success(let uuid)):
        return .run { send in
          await send(.fetchUser(uuid))
        }
        
      case .didSignIn(.failure(let error)):
        state.isLoading = false
        state.error = error.localizedDescription
        return .none
        
      case .fetchUser(let uuid):
        return .run { send in
          do {
            let user: UserModel = try await supabase
              .from("users")
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
              .eq("uuid", value: uuid)
              .limit(1)
              .single()
              .execute()
              .value
            
            await send(.didFetchUser(.success(user)))
          } catch {
            if let error = error as? PostgrestError {
              switch error.code {
              case "PGRST116":
                await send(.presentUsername(uuid))
                break
                
              default:
                await send(.didFetchUser(.failure(error)))
              }
            } else {
              await send(.didFetchUser(.failure(error)))
            }
          }
        }
        
      case .didFetchUser(.success(let user)):
        state.isLoading = false
        if let encoded = try? JSONEncoder().encode(user) {
          UserDefaults.standard.set(encoded, forKey: StorageKey.user.rawValue)
        }
        return .none
        
      case .didFetchUser(.failure(let error)):
        print(error)
        return .none
        
      case .presentUsername(let uuid):
        state.path.append(.username(Username.State(uuid: uuid)))
        return .none
        
      case .onEmailChanged(let email):
        state.email = email
        return .none
        
      case .onPasswordChanged(let password):
        state.password = password
        return .none
        
      case .path(.element(_, action: .signUp(.didSignUp(.success(let uuid))))):
        state.path.append(.username(Username.State(uuid: uuid)))
        return .none
        
      case .path(_):
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}
