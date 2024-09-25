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
  @Dependency(\.dismiss) var dismiss
  
  @ObservableState
  struct State: Equatable {
    var currentUser: UserModel
    var stories: Dictionary<UUID, IdentifiedArrayOf<StoryModel>>
    var selectedUser: UserModel
    var selectedStory: StoryModel?
//    var selectedStats: [StoryStatsModel]?
    var image: UIImage?
    var queuePlayer: AVQueuePlayer?
    var playerLooper: AVPlayerLooper?
    var isPending = false
    
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
    case didFetchProfileStats(Result<[StoryStatsModel], Error>)
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
//        state.selectedStats = []
        state.stats?.stats = []
        if state.currentUser.uuid != state.selectedUser.uuid {
          return .none
        }
        return .merge(
          .cancel(id: CancelID.fetchStats),
          .run { [selectedStory = state.selectedStory] send in
            guard let selectedStory = selectedStory else { return }
            do {
              let stats: [StoryStatsModel] = try await supabase
                .from("stories_stats")
                .select(
                  """
                    uuid,
                    story_uuid,
                    author_uuid,
                    viewed_by:users(*)
                  """
                )
                .eq("story_uuid", value: selectedStory.uuid)
                .execute()
                .value
              
              await send(.didFetchProfileStats(.success(stats)))
            } catch {
              await send(.didFetchProfileStats(.failure(error)))
            }
          }
            .cancellable(id: CancelID.fetchStats)
        )
        
      case .didFetchProfileStats(.success(let stats)):
        state.selectedStory?.stats = stats
//        state.selectedStats = stats
        state.stats?.stats = stats
        return .none
        
      case .didFetchProfileStats(.failure(let error)):
        print(error)
        return .none
        
      case .presentStats:
        state.stats = Stats.State(stats: state.selectedStory?.stats)
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
        state.isPending = true
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
        state.isPending = false
        state.stories[story.author.uuid]?.removeAll(where: { $0.uuid == story.uuid })
        return .none
        
      case .didDelete(.failure(let error)):
        state.isPending = false
        print(error)
        return .none
        
      case .initialize:
        state.selectedStory = state.stories[state.selectedUser.uuid]?.first(where: { !($0.stats?.contains(where: { $0.viewed_by.uuid == state.currentUser.uuid }) ?? false) }) ?? state.stories[state.selectedUser.uuid]?.first
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
           let index = state.stories[state.selectedUser.uuid]?.index(id: selectedStory.uuid),
           state.stories[state.selectedUser.uuid]!.count > index + 1 {
          state.selectedStory = state.stories[state.selectedUser.uuid]?[index + 1]
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
           let index = state.stories[state.selectedUser.uuid]?.index(id: selectedStory.uuid),
           index > 0 {
          state.selectedStory = state.stories[state.selectedUser.uuid]?[index - 1]
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
            if !(selectedStory.stats?.contains(where: { $0.viewed_by.uuid == currentUser.uuid }) ?? false) {
              let statInsert = StoryStatsModelInsert(
                uuid: UUID(),
                viewed_by: currentUser.uuid,
                story_uuid: selectedStory.uuid,
                author_uuid: selectedStory.author.uuid
              )
              let stat = StoryStatsModel(
                uuid: statInsert.uuid,
                viewed_by: currentUser,
                story_uuid: statInsert.story_uuid,
                author_uuid: statInsert.author_uuid
              )
              
              try await supabase
                .from("stories_stats")
                .insert(statInsert)
                .execute()
              
              await send(.didMarkAsViewed(.success((stat, selectedStory))))
            }
          } catch {
            print(error)
          }
        }
        
      case .didMarkAsViewed(.success((let stat, let story))):
        if var tempStories = state.stories[story.author.uuid],
           var tempData = tempStories[id: story.uuid] {
          tempData.stats?.append(stat)
          tempStories[id: story.uuid] = tempData
          state.stories[story.author.uuid] = tempStories
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
