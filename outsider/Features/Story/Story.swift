//
//  Story.swift
//  outsider
//
//  Created by Michael Jach on 18/09/2024.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct Story {
  @Dependency(\.supabase) var supabase
  
  @ObservableState
  struct State: Equatable {
    var currentUser: UserModel
    var stories: Dictionary<UserModel, IdentifiedArrayOf<StoryModel>>
    var selectedUser: UserModel
    var selectedStory: StoryModel?
  }
  
  enum Action {
    case initialize
    case next
    case prev
    case markAsViewed
    case didMarkAsViewed(Result<(StoryStatsModel, StoryModel), Error>)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .initialize:
        state.selectedStory = state.stories[state.selectedUser]?.first(where: { !($0.stats?.contains(where: { $0.viewed_by == state.currentUser.uuid }) ?? false) }) ?? state.stories[state.selectedUser]?.first
        return .run { send in
          await send(.markAsViewed)
        }
        
      case .next:
        if let selectedStory = state.selectedStory,
           let index = state.stories[state.selectedUser]?.index(id: selectedStory.uuid),
           state.stories[state.selectedUser]!.count > index + 1 {
          state.selectedStory = state.stories[state.selectedUser]?[index + 1]
          return .run { send in
            await send(.markAsViewed)
          }
        }
        return .none
        
      case .prev:
        if let selectedStory = state.selectedStory,
           let index = state.stories[state.selectedUser]?.index(id: selectedStory.uuid),
           index > 0 {
          state.selectedStory = state.stories[state.selectedUser]?[index - 1]
          return .run { send in
            await send(.markAsViewed)
          }
        }
        return .none
        
      case .markAsViewed:
        return .run { [selectedStory = state.selectedStory, currentUser = state.currentUser] send in
          do {
            guard let selectedStory = selectedStory else { return }
            if !(selectedStory.stats?.contains(where: { $0.viewed_by == currentUser.uuid }) ?? false) {
              let stat = StoryStatsModel(
                uuid: UUID(),
                viewed_by: currentUser.uuid,
                story_uuid: selectedStory.uuid
              )
              try await supabase
                .from("stories_stats")
                .insert(stat)
                .execute()
              
              await send(.didMarkAsViewed(.success((stat, selectedStory))))
            }
          } catch {
            
          }
        }
        
      case .didMarkAsViewed(.success((let stat, let story))):
        if var tempStories = state.stories[story.author],
           var tempData = tempStories[id: story.uuid] {
          tempData.stats?.append(stat)
          tempStories[id: story.uuid] = tempData
          state.stories[story.author] = tempStories
        }
        return .none
        
      case .didMarkAsViewed(.failure(let error)):
        print(error)
        return .none
      }
    }
  }
}
