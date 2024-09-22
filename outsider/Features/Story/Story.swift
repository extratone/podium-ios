//
//  Story.swift
//  outsider
//
//  Created by Michael Jach on 18/09/2024.
//

import SwiftUI
import ComposableArchitecture
import AVKit

@Reducer
struct Story {
  @Dependency(\.supabase) var supabase
  
  @ObservableState
  struct State: Equatable {
    var currentUser: UserModel
    var stories: Dictionary<UserModel, IdentifiedArrayOf<StoryModel>>
    var selectedUser: UserModel
    var selectedStory: StoryModel?
    var selectedStats: [UserModel]?
    var image: UIImage?
    var queuePlayer: AVQueuePlayer?
    var playerLooper: AVPlayerLooper?
    
    // Sub states
    @Presents var stats: Stats.State?
  }
  
  enum Action {
    case initialize
    case next
    case prev
    case markAsViewed
    case didMarkAsViewed(Result<(StoryStatsModel, StoryModel), Error>)
    case delete
    case didDelete(Result<StoryModel, Error>)
    case downloadImage
    case didDownloadImage(Result<UIImage?, Error>)
    case didLoadVideo(Result<URL, Error>)
    case fetchProfileStats
    case didFetchProfileStats(Result<[UserModel], Error>)
    case presentStats
    
    // Sub actions
    case stats(PresentationAction<Stats.Action>)
  }
  
  private enum CancelID {
    case imageDownload
    case fetchStats
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .fetchProfileStats:
        state.selectedStats = []
        state.stats?.profiles = []
        if state.currentUser.uuid != state.selectedUser.uuid {
          return .none
        }
        return .merge(
          .cancel(id: CancelID.fetchStats),
          .run { [selectedStory = state.selectedStory] send in
            guard let stats = selectedStory?.stats else { return }
            do {
              let profiles: [UserModel] = try await supabase
                .from("users")
                .select()
                .in("uuid", values: stats.map({ $0.viewed_by }))
                .execute()
                .value
              
              await send(.didFetchProfileStats(.success(profiles)))
            } catch {
              await send(.didFetchProfileStats(.failure(error)))
            }
          }
            .cancellable(id: CancelID.fetchStats)
        )
        
      case .didFetchProfileStats(.success(let profiles)):
        state.selectedStats = profiles
        state.stats?.profiles = profiles
        return .none
        
      case .didFetchProfileStats(.failure(let error)):
        print(error)
        return .none
        
      case .presentStats:
        state.stats = Stats.State(profiles: state.selectedStats)
        return .none
        
      case .stats:
        return .none
        
      case .downloadImage:
        state.image = nil
        return .merge(
          .cancel(id: CancelID.imageDownload),
          .run { [selectedStory = state.selectedStory] send in
            guard let selectedStory = selectedStory else { return }
            if selectedStory.type == .photo {
              do {
                let imageData = try Data(contentsOf: selectedStory.url)
                let loadedImage = UIImage(data: imageData)
                await send(.didDownloadImage(.success(loadedImage)))
              } catch {
                await send(.didDownloadImage(.failure(error)))
              }
            } else {
              await send(.didLoadVideo(.success(selectedStory.url)))
            }
          }
            .cancellable(id: CancelID.imageDownload)
        )
        
      case .didDownloadImage(.success(let uiImage)):
        state.image = uiImage
        return .run { send in
          await send(.markAsViewed)
        }
        
      case .didDownloadImage(.failure(let error)):
        print(error)
        return .none
        
      case .didLoadVideo(.success(let url)):
        let playerItem = AVPlayerItem(url: url)
        state.queuePlayer = state.queuePlayer ?? AVQueuePlayer(items: [])
        state.playerLooper = AVPlayerLooper(player: state.queuePlayer!, templateItem: playerItem)
        state.queuePlayer?.removeAllItems()
        state.queuePlayer?.insert(playerItem, after: nil)
        state.queuePlayer?.play()
        return .run { send in
          await send(.markAsViewed)
        }
        
      case .didLoadVideo(.failure(let error)):
        print(error)
        return .none
        
      case .delete:
        guard let selectedStory = state.selectedStory else { return .none }
        return .run { [story = selectedStory] send in
          do {
            try await supabase
              .from("stories_stats")
              .delete()
              .eq("story_uuid", value: story.uuid)
              .execute()
            
            try await supabase
              .from("stories")
              .delete()
              .eq("uuid", value: story.uuid)
              .execute()
            
            _ = try await supabase.storage
              .from("stories")
              .remove(paths: ["\(story.uuid.uuidString)"])
            
            await send(.didDelete(.success(story)))
          } catch {
            await send(.didDelete(.failure(error)))
          }
        }
        
      case .didDelete(.success(let story)):
        state.stories[story.author]?.removeAll(where: { $0.uuid == story.uuid })
        return .none
        
      case .didDelete(.failure(let error)):
        print(error)
        return .none
        
      case .initialize:
        state.selectedStory = state.stories[state.selectedUser]?.first(where: { !($0.stats?.contains(where: { $0.viewed_by == state.currentUser.uuid }) ?? false) }) ?? state.stories[state.selectedUser]?.first
        return .merge(
          .run { send in
            await send(.downloadImage)
          },
          .run { send in
            await send(.fetchProfileStats)
          }
        )
        
      case .next:
        if let selectedStory = state.selectedStory,
           let index = state.stories[state.selectedUser]?.index(id: selectedStory.uuid),
           state.stories[state.selectedUser]!.count > index + 1 {
          state.selectedStory = state.stories[state.selectedUser]?[index + 1]
          return .merge(
            .run { send in
              await send(.downloadImage)
            },
            .run { send in
              await send(.fetchProfileStats)
            }
          )
        }
        return .none
        
      case .prev:
        if let selectedStory = state.selectedStory,
           let index = state.stories[state.selectedUser]?.index(id: selectedStory.uuid),
           index > 0 {
          state.selectedStory = state.stories[state.selectedUser]?[index - 1]
          return .merge(
            .run { send in
              await send(.downloadImage)
            },
            .run { send in
              await send(.fetchProfileStats)
            }
          )
        }
        return .none
        
      case .markAsViewed:
        if state.selectedUser.uuid == state.currentUser.uuid {
          return .none
        }
        return .run { [selectedStory = state.selectedStory, currentUser = state.currentUser] send in
          do {
            guard let selectedStory = selectedStory else { return }
            if !(selectedStory.stats?.contains(where: { $0.viewed_by == currentUser.uuid }) ?? false) {
              let stat = StoryStatsModel(
                uuid: UUID(),
                viewed_by: currentUser.uuid,
                story_uuid: selectedStory.uuid,
                author_uuid: selectedStory.author.uuid
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
    .ifLet(\.$stats, action: \.stats) {
      Stats()
    }
  }
}
