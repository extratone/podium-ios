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
  
  @Reducer(state: .equatable)
  enum Path {
    case profile(Profile)
    case comments(Comments)
  }
  
  @ObservableState
  struct State: Equatable {
    var currentUser: UserModel
    var query = ""
    var isSearching = false
    var searchResults: [UserModel] = []
    var suggestedProfiles: [UserModel] = []
    
    // Sub states
    var path = StackState<Path.State>()
  }
  
  enum Action {
    case initialize
    case queryChanged(String)
    case isSearchingChanged(Bool)
    case didSearch(Result<[UserModel], Error>)
    case presentProfile(UserModel)
    case fetchSuggestedProfiles
    case didFetchSuggestedProfiles(Result<[UserModel], Error>)
    
    // Sub actions
    case path(StackActionOf<Path>)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .initialize:
        return .run { send in
          await send(.fetchSuggestedProfiles)
        }
        
      case .fetchSuggestedProfiles:
        return .run { send in
          do {
            let results: [UserModel] = try await supabase
              .from("users")
              .select()
              .limit(3)
              .execute()
              .value
            
            await send(.didFetchSuggestedProfiles(.success(results)))
          } catch {
            await send(.didFetchSuggestedProfiles(.failure(error)))
          }
        }
        
      case .didFetchSuggestedProfiles(.success(let profiles)):
        state.suggestedProfiles = profiles
        return .none
        
      case .didFetchSuggestedProfiles(.failure(let error)):
        print(error)
        return .none
        
      case .presentProfile(let user):
        state.isSearching = false
        state.path.append(.profile(Profile.State(
          currentUser: state.currentUser,
          user: user
        )))
        return .none
        
      case .isSearchingChanged(let isSearching):
        state.isSearching = isSearching
        return .none
        
      case .queryChanged(let query):
        state.query = query
        if query.count > 1 {
          return .run { send in
            let searchResults: [UserModel] = try await supabase
              .from("users")
              .select()
              .like("username", pattern: "\(query)%")
              .limit(25)
              .execute()
              .value
            
            await send(.didSearch(.success(searchResults)))
          }
        }
        return .none
        
      case .didSearch(.success(let users)):
        state.searchResults = users
        return .none
        
      case .didSearch(.failure(let error)):
        print(error)
        return .none
        
      case .path(.element(_, action: .profile(.didFollow(.success(let user))))):
        state.currentUser.following?.append(FollowingModel(following: user))
        return .none
        
      case .path(.element(_, action: .profile(.didUnfollow(.success(let user))))):
        state.currentUser.following?.removeAll(where: { $0.following.uuid == user.uuid })
        return .none
        
      case .path(.element(_, action: .profile(.presentComments(let post)))):
        state.path.append(
          .comments(Comments.State(
            currentUser: state.currentUser,
            post: Post.State(
              size: .normal,
              currentUser: state.currentUser,
              post: post
            )))
        )
        return .none
        
      case .path(.element(_, action: .comments(.presentProfile(let profile)))),
          .path(.element(_, action: .profile(.presentProfile(let profile)))):
        state.path.append(.profile(Profile.State(
          currentUser: state.currentUser,
          user: profile
        )))
        return .none
        
      case .path:
        return .none
      }
    }
    .forEach(\.path, action: \.path)
  }
}
