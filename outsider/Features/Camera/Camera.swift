//
//  Camera.swift
//  outsider
//
//  Created by Michael Jach on 18/09/2024.
//

import SwiftUI
import ComposableArchitecture
import PhotosUI
import Supabase

@Reducer
struct Camera {
  @Dependency(\.supabase) var supabase
  
  @ObservableState
  struct State: Equatable {
    var currentUser: UserModel
    var imageSelection: PhotosPickerItem?
    var image: UIImage?
  }
  
  enum Action {
    case imageSelectionChanged(PhotosPickerItem?)
    case didImageSelect(UIImage?)
    case send
    case didSend(Result<StoryModel, Error>)
    case reset
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .reset:
        state.image = nil
        state.imageSelection = nil
        return .none
        
      case .send:
        let image = state.image
        state.imageSelection = nil
        state.image = nil
        return .run { [currentUser = state.currentUser] send in
          do {
            let storyUuid = UUID()
            
            try await supabase.storage
              .from("stories")
              .upload(
                path: "\(storyUuid)/\(storyUuid).jpg",
                file: image!.jpegData(compressionQuality: 0.8)!,
                options: FileOptions(upsert: true)
              )
            
            let publicURL = try supabase.storage
              .from("stories")
              .getPublicURL(path: "\(storyUuid)/\(storyUuid).jpg")
            
            let story: StoryModel = try await supabase
              .from("stories")
              .insert(StoryModelInsert(
                uuid: storyUuid,
                author_uuid: currentUser.uuid,
                url: publicURL,
                type: .photo
              ))
              .select(
                """
                  uuid,
                  url,
                  type,
                  author:users(*),
                  stats:stories_stats(*)
                """
              )
              .single()
              .execute()
              .value
            
            await send(.didSend(.success(story)))
          } catch {
            await send(.didSend(.failure(error)))
          }
        }
        
      case .didSend(.success(let story)):
        return .none
        
      case .didSend(.failure(let error)):
        print(error)
        return .none
        
      case .imageSelectionChanged(let imageSelection):
        state.imageSelection = imageSelection
        return .run { send in
          let image = try await imageSelection!.loadTransferable(type: Data.self)!
          let uiImage = UIImage(data: image)?.resizeImage(targetSize: CGSize(width: 1600, height: 1600))
          await send(.didImageSelect(uiImage))
        }
        
      case .didImageSelect(let image):
        state.image = image
        return .none
      }
    }
  }
}
