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
    var selectedVideo: URL?
    var selectedPhoto: Data?
    var previewImage: Image?
    var queuePlayer: AVQueuePlayer?
    var playerLooper: AVPlayerLooper?
    var camera = CameraManager()
    var isRecording = false
    var isPending = false
    var isCameraSendPresented = false
    var hasMedia: Bool {
      selectedPhoto != nil || selectedVideo != nil
    }
    
    // Sub states
    var cameraSend: CameraSend.State
  }
  
  enum Action {
    case initialize
    case imageSelectionChanged(PhotosPickerItem?)
    case didImageSelect(Data)
    case reset
    case handleCameraPreviews
    case onHandleCameraPreviews(Image?)
    case handleCameraVideo
    case onHandleCameraVideo(URL?, Data)
    case handleCameraPhoto
    case onHandleCameraPhoto(Data?)
    case startPreview
    case pausePreview
    case startRecording
    case stopRecording
    case takePhoto
    case changeZoom(CGFloat)
    case presentCameraSend(Bool)
    
    // Sub actions
    case cameraSend(CameraSend.Action)
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
        
      case .presentCameraSend(let isPresented):
        state.isCameraSendPresented = isPresented
        return .none
        
      case .startPreview:
        state.camera.isPreviewPaused = false
        return .none
        
      case .pausePreview:
        state.camera.isPreviewPaused = true
        return .none
        
      case .handleCameraVideo:
        return .run { [stream = state.camera.movieFileStream] send in
          for await url in stream {
            let asset = AVAsset(url: url)
            let exportSession = asset.createExportSession()
            await exportSession?.export()
            Task { @MainActor in
              if let data = try? Data(contentsOf: exportSession!.outputURL!) {
                send(.onHandleCameraVideo(url, data))
              }
            }
          }
        }
        
      case .onHandleCameraVideo(let url, let data):
        if let url = url {
          let playerItem = AVPlayerItem(url: url)
          state.queuePlayer = AVQueuePlayer(items: [playerItem])
          state.playerLooper = AVPlayerLooper(player: state.queuePlayer!, templateItem: playerItem)
        }
        state.selectedVideo = url
        state.cameraSend.mediaData = data
        state.cameraSend.mediaType = .video
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
        state.selectedPhoto = data
        state.cameraSend.mediaData = data
        state.cameraSend.mediaType = .photo
        return .none
        
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
        return .none
        
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
        state.queuePlayer?.pause()
        state.queuePlayer = nil
        state.selectedVideo = nil
        state.selectedPhoto = nil
        state.imageSelection = nil
        return .run { send in
          await send(.changeZoom(1))
        }
        
      case .imageSelectionChanged(let imageSelection):
        state.imageSelection = imageSelection
        return .run { send in
          let imageData = try await imageSelection!.loadTransferable(type: Data.self)!
          await send(.didImageSelect(imageData))
        }
        
      case .didImageSelect(let data):
        state.selectedPhoto = data
        state.cameraSend.mediaData = data
        state.cameraSend.mediaType = .photo
        return .none
        
      case .cameraSend(.send):
        state.isCameraSendPresented = false
        return .none
        
      case .cameraSend(_):
        return .none
      }
    }
    
    Scope(state: \.cameraSend, action: \.cameraSend) {
      CameraSend()
    }
  }
}
