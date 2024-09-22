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
    var video: Video?
    var queuePlayer: AVQueuePlayer?
    var playerLooper: AVPlayerLooper?
    var camera = CameraManager()
    var movieFileUrl: URL?
    var previewImage: Image?
    var photoToken: Data?
    var isRecording = false
    var isPending = false
    var hasMedia: Bool {
      image != nil || queuePlayer != nil || photoToken != nil
    }
  }
  
  enum Action {
    case initialize
    case imageSelectionChanged(PhotosPickerItem?)
    case didImageSelect(UIImage?)
    case send(Source)
    case didSend(Result<StoryModel, Error>)
    case reset
    case handleCameraPreviews
    case onHandleCameraPreviews(Image?)
    case handleCameraVideo
    case onHandleCameraVideo(URL?)
    case handleCameraPhoto
    case onHandleCameraPhoto(Data?)
    case startPreview
    case pausePreview
    case startRecording
    case stopRecording
    case takePhoto
    case changeZoom(CGFloat)
  }
  
  enum Source {
    case cameraRollPhoto
    case photo
    case video
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .initialize:
        return .run { send in
          await send(.handleCameraPreviews)
          await send(.handleCameraVideo)
          await send(.handleCameraPhoto)
        }
        
      case .startPreview:
        state.camera.isPreviewPaused = false
        return .none
        
      case .pausePreview:
        state.camera.isPreviewPaused = true
        return .none
        
      case .handleCameraVideo:
        return .run { [stream = state.camera.movieFileStream] send in
          for await url in stream {
            Task { @MainActor in
              send(.onHandleCameraVideo(url))
            }
          }
        }
        
      case .onHandleCameraVideo(let url):
        if let url = url {
          let playerItem = AVPlayerItem(url: url)
          state.queuePlayer = AVQueuePlayer(items: [playerItem])
          state.playerLooper = AVPlayerLooper(player: state.queuePlayer!, templateItem: playerItem)
        }
        state.movieFileUrl = url
        return .none
        
      case .handleCameraPhoto:
        return .run { [camera = state.camera] send in
          let unpackedPhotoStream = camera.photoStream
            .compactMap { $0.fileDataRepresentation() }
          
          for await photoData in unpackedPhotoStream {
            Task { @MainActor in
              send(.onHandleCameraPhoto(photoData))
            }
          }
        }
        
      case .onHandleCameraPhoto(let data):
        state.photoToken = data
        return .run { send in
          
        }
        
      case .handleCameraPreviews:
        return .run { [previewStream = state.camera.previewStream] send in
          let imageStream = previewStream.map { $0.image }
          
          for await image in imageStream {
            Task { @MainActor in
              send(.onHandleCameraPreviews(image))
            }
          }
        }
        
      case .onHandleCameraPreviews(let image):
        state.previewImage = image
        return .none
        
      case .takePhoto:
        state.camera.takePhoto()
        return .none
        
      case .startRecording:
        state.camera.startRecordingVideo()
        state.isRecording = true
        return .none
        
      case .stopRecording:
        state.camera.stopRecordingVideo()
        state.isRecording = false
        return .run { send in
          
        }
        
      case .changeZoom(let zoom):
        let factor = zoom < 1 ? 1 : zoom
        return .run { [camera = state.camera] send in
          do {
            try camera.deviceInput?.device.lockForConfiguration()
            camera.deviceInput?.device.videoZoomFactor = factor
            camera.deviceInput?.device.unlockForConfiguration()
          }
          catch {
            print(error.localizedDescription)
          }
        }
        
      case .reset:
        state.image = nil
        state.queuePlayer?.pause()
        state.queuePlayer = nil
        state.video = nil
        state.imageSelection = nil
        state.movieFileUrl = nil
        state.photoToken = nil
        return .run { send in
          await send(.changeZoom(1))
        }
        
      case .send(let source):
        state.isPending = true
        switch source {
        case .photo:
          return .run { [photo = state.photoToken, currentUser = state.currentUser] send in
            guard let photo = photo else { return }
            do {
              let storyUuid = UUID()
              try await supabase.storage
                .from("stories")
                .upload(
                  path: "\(storyUuid)/\(storyUuid).jpg",
                  file: photo,
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
          
        case .video:
          return .run { [video = state.movieFileUrl, currentUser = state.currentUser] send in
            guard let videoUrl = video else { return }
            do {
              let storyUuid = UUID()
              let asset = AVAsset(url: videoUrl)
              let exportSession = asset.createExportSession(uuid: storyUuid.uuidString)
              await exportSession?.export()
              let data = try? Data(contentsOf: exportSession!.outputURL!)
              
              try await supabase.storage
                .from("stories")
                .upload(
                  path: "\(storyUuid)/\(storyUuid).mp4",
                  file: data!,
                  options: FileOptions(upsert: true)
                )
              
              let publicURL = try supabase.storage
                .from("stories")
                .getPublicURL(path: "\(storyUuid)/\(storyUuid).mp4")
              
              let story: StoryModel = try await supabase
                .from("stories")
                .insert(StoryModelInsert(
                  uuid: storyUuid,
                  author_uuid: currentUser.uuid,
                  url: publicURL,
                  type: .video
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
          
        case .cameraRollPhoto:
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
        }
        
      case .didSend(.success(_)):
        state.isPending = false
        return .run { send in
          await send(.reset)
        }
        
      case .didSend(.failure(let error)):
        state.isPending = false
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
