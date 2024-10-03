//
//  NewMessage.swift
//  min
//
//  Created by Michael Jach on 17/07/2024.
//

import ComposableArchitecture

@Reducer
struct NewMessage {
  @Dependency(\.supabase) var supabase
  @Dependency(\.dismiss) var dismiss
  
  @ObservableState
  struct State {
    var currentUser: CurrentUserModel
    var query = ""
    var text = ""
    var isSearching = true
    var currentTokens = [FollowingModel]()
    var tokens: [FollowingModel] { currentUser.following }
    var suggested: [FollowingModel] {
      Array(currentUser.following
        .filter({ user in
          return !currentTokens.contains(where: { $0.following.uuid == user.following.uuid })
        })
          .prefix(20))
    }
    var searchResults: [FollowingModel] {
      if query.isEmpty {
        return []
      }
      let trimmedSearchText = query.trimmingCharacters(in: .whitespaces)
      return tokens
        .filter({ token in
          return !currentTokens.contains(where: { $0.following.uuid == token.following.uuid })
        })
        .filter({ $0.following.username.contains(trimmedSearchText) })
    }
  }
  
  enum Action: Sendable {
    case textChanged(String)
    case queryChanged(String)
    case currentTokensChanged([FollowingModel])
    case addToken(FollowingModel)
    case dismiss
    case send([FollowingModel], String)
    case isSearchingChanged(Bool)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .isSearchingChanged(let isSearching):
        state.isSearching = isSearching
        return .none
        
      case .send:
        return .run { _ in await self.dismiss() }
        
      case .dismiss:
        return .run { _ in await self.dismiss() }
        
      case .addToken(let user):
        state.query = ""
        state.currentTokens.append(user)
        return .none
        
      case .textChanged(let text):
        state.text = text
        return .none
        
      case .queryChanged(let query):
        state.query = query
        return .none
        
      case .currentTokensChanged(let tokens):
        state.currentTokens = tokens
        return .none
      }
    }
  }
}
