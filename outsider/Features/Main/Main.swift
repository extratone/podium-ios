//
//  Main.swift
//  outsider
//
//  Created by Michael Jach on 09/09/2024.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct Main {
  @ObservableState
  struct State {
    var token: String?
    
    // Sub states
    var signIn: SignIn.State?
    var tabs: Tabs.State?
  }
  
  enum Action {
    case initialize
    case setToken(String)
    
    // Nested
    case signIn(SignIn.Action)
    case tabs(Tabs.Action)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .setToken(let token):
        state.token = token
        state.tabs?.currentUser.fcm_tokens.append(token)
        return .none
        
      case .initialize:
        if let data = UserDefaults.standard.data(forKey: StorageKey.user.rawValue),
           var decoded = try? JSONDecoder().decode(UserModel.self, from: data) {
          if let token = state.token, !decoded.fcm_tokens.contains(token) {
            decoded.fcm_tokens.append(token)
          }
          state.tabs = Tabs.State(
            currentUser: decoded,
            camera: Camera.State(
              currentUser: decoded,
              cameraSend: CameraSend.State(
                currentUser: decoded
              )
            ),
            home: Home.State(
              currentUser: decoded,
              send: Send.State(currentUser: decoded),
              stories: Stories.State(currentUser: decoded)
            ),
            explore: Explore.State(
              currentUser: decoded
            ),
            messages: Messages.State(
              currentUser: decoded
            ),
            currentProfile: CurrentProfile.State(
              profile: Profile.State(
                currentUser: decoded,
                user: decoded
              )
            )
          )
        } else {
          state.signIn = SignIn.State()
        }
        return .none
        
      case .signIn(.didFetchUser(.success(let u))),
          .signIn(.path(.element(_, action: .username(.didSignUp(.success(let u)))))):
        var user = u
        if let token = state.token, !user.fcm_tokens.contains(token) {
          user.fcm_tokens.append(token)
        }
        state.tabs = Tabs.State(
          currentUser: user,
          camera: Camera.State(
            currentUser: user,
            cameraSend: CameraSend.State(
              currentUser: user
            )
          ),
          home: Home.State(
            currentUser: user,
            send: Send.State(currentUser: user),
            stories: Stories.State(currentUser: user)
          ),
          explore: Explore.State(
            currentUser: user
          ),
          messages: Messages.State(
            currentUser: user
          ),
          currentProfile: CurrentProfile.State(
            profile: Profile.State(
              currentUser: user,
              user: user
            )
          )
        )
        state.signIn = nil
        return .run { [token = state.token] send in
          guard let token = token else { return }
          await send(.tabs(.synchronizeToken(token)))
        }
        
      case .signIn(_):
        return .none
        
      case .tabs(.handleBadSession):
        state.signIn = SignIn.State()
        state.tabs = nil
        return .none
        
      case .tabs(.currentProfile(.path(.element(_, action: .settings(.didLogout))))):
        state.signIn = SignIn.State()
        state.tabs = nil
        return .none
        
      case .tabs(_):
        return .none
      }
    }
    .ifLet(\.signIn, action: \.signIn) {
      SignIn()
    }
    .ifLet(\.tabs, action: \.tabs) {
      Tabs()
    }
  }
}
