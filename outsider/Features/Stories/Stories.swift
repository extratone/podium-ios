//
//  Stories.swift
//  outsider
//
//  Created by Michael Jach on 18/09/2024.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct Stories {
  @Dependency(\.supabase) var supabase
  
  @ObservableState
  struct State: Equatable {
    var currentUser: UserModel
    var stories: Dictionary<UserModel, IdentifiedArrayOf<StoryModel>> = [:]
    
    // Sub states
    @Presents var story: Story.State?
  }
  
  enum Action {
    case initialize
    case fetchStories
    case didFetchStories(Result<Dictionary<UserModel, [StoryModel]>, Error>)
    case presentSheet(UserModel)
    case presentCamera
    
    // Sub actions
    case story(PresentationAction<Story.Action>)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .initialize:
        return .run { send in
          await send(.fetchStories)
        }
        
      case .presentCamera:
        return .none
        
      case .presentSheet(let user):
        state.story = Story.State(
          currentUser: state.currentUser,
          stories: state.stories,
          selectedUser: user
        )
        return .none
        
      case .fetchStories:
        return .run { [currentUser = state.currentUser] send in
          var following = currentUser.following
          following.append(currentUser.uuid)
          
          do {
            let stories: [StoryModel] = try await supabase
              .from("stories")
              .select(
                """
                  uuid,
                  url,
                  type,
                  author:users!inner(*),
                  stats:stories_stats(*)
                """
              )
              .in("author.uuid", values: following)
              .order("created_at", ascending: true)
              .execute()
              .value
            
            let grouped = Dictionary(grouping: stories, by: { $0.author })
            await send(.didFetchStories(.success(grouped)))
          } catch {
            await send(.didFetchStories(.failure(error)))
          }
        }
        
      case .didFetchStories(.success(let stories)):
        state.stories = stories.compactMapValues({ stories in
          return IdentifiedArray(uniqueElements: stories)
        })
        return .none
        
      case .didFetchStories(.failure(let error)):
        print(error)
        return .none
        
      case .story(.presented(.didMarkAsViewed(.success((let stat, let story))))):
        if var tempStories = state.stories[story.author],
           var tempData = tempStories[id: story.uuid] {
          tempData.stats?.append(stat)
          tempStories[id: story.uuid] = tempData
          state.stories[story.author] = tempStories
        }
        return .none
        
      case .story(.presented(.didDelete(.success(let story)))):
        state.stories[story.author]?.removeAll(where: { $0.uuid == story.uuid })
        if let userStories = state.stories[story.author], userStories.isEmpty {
          state.stories.removeValue(forKey: story.author)
        }
        state.story = nil
        return .none
        
      case .story:
        return .none
      }
    }
    .ifLet(\.$story, action: \.story) {
      Story()
    }
  }
}
