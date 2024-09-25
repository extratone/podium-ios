//
//  CameraView.swift
//  outsider
//
//  Created by Michael Jach on 18/09/2024.
//

import SwiftUI
import ComposableArchitecture
import PhotosUI
import AVKit

struct CameraView: View {
  @Bindable var store: StoreOf<Camera>
  @State private var shutterTapped = false
  
  var body: some View {
    ZStack {
      if let image = store.image {
        Color.black
          .overlay {
            Image(uiImage: image)
              .resizable()
              .scaledToFill()
          }
          .ignoresSafeArea()
      } else if store.queuePlayer != nil {
        GeometryReader { geometry in
          VideoPlayer(player: store.queuePlayer)
            .disabled(true)
            .ignoresSafeArea()
            .frame(width: geometry.size.height * 16 / 9, height: geometry.size.height)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .onAppear {
              store.queuePlayer?.play()
            }
            .onDisappear {
              store.queuePlayer?.pause()
            }
        }
        .ignoresSafeArea()
      } else if let photoToken = store.photoToken,
                let uiImage = UIImage(data: photoToken) {
        GeometryReader { geometry in
          Image(uiImage: uiImage)
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea()
      } else {
        GeometryReader { geometry in
          if let image = store.previewImage {
            image
              .resizable()
              .scaledToFill()
              .frame(width: geometry.size.width, height: geometry.size.height)
              .ignoresSafeArea()
          }
        }
        .ignoresSafeArea()
        .onAppear {
          store.send(.startPreview)
        }
        .onDisappear {
          store.send(.pausePreview)
        }
      }
      
      VStack {
        if store.hasMedia {
          HStack {
            Spacer()
            
            Button {
              store.send(.reset)
            } label: {
              Image("icon-close")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundStyle(.white)
            }
            .disabled(store.isPending)
          }
          .padding()
        } else if store.isRecording {
          HStack {
            Image(systemName: "record.circle")
              .foregroundColor(.red)
              .frame(width: 16, height: 16)
              .symbolEffect(.pulse, isActive: store.isRecording)
            
            Text("Recording")
              .foregroundStyle(.white)
              .fontWeight(.medium)
          }
        }
        
        Spacer()
        
        if store.hasMedia {
          HStack {
            HStack(spacing: 24) {
              Button {
                
              } label: {
                Image(systemName: "textbox")
                  .resizable()
                  .frame(width: 32, height: 22)
                  .foregroundStyle(.white)
              }
              
              Button {
                
              } label: {
                Image(systemName: "photo")
                  .resizable()
                  .frame(width: 28, height: 22)
                  .foregroundStyle(.white)
              }
            }
            
            Spacer()
            
            Button {
              if store.image != nil {
                store.send(.send(.cameraRollPhoto))
              } else if store.queuePlayer != nil {
                store.send(.send(.video))
              } else if store.photoToken != nil {
                store.send(.send(.photo))
              }
            } label: {
              HStack(spacing: 0) {
                Text("Add story")
                  .fontWeight(.semibold)
                  .foregroundStyle(.black)
                
                Image("icon-send")
                  .resizable()
                  .frame(width: 20, height: 20)
                  .foregroundStyle(.black)
              }
              .padding(.vertical, 8)
              .padding(.leading, 16)
              .padding(.trailing, 8)
              .background(.yellow)
              .clipShape(Capsule())
            }
            .disabled(store.isPending)
            .opacity(store.isPending ? 0.6 : 1)
          }
          .padding(24)
        } else {
          HStack {
            PhotosPicker(
              selection: $store.imageSelection.sending(\.imageSelectionChanged)
            ) {
              Image("icon-photo")
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundStyle(.white)
            }
            .padding(16)
            
            Spacer()
            
            Image(systemName: "circle")
              .symbolEffect(.pulse, isActive: store.isRecording)
              .foregroundStyle(store.isRecording ? Color.red : Color.white)
              .font(.system(size: 90))
              .opacity(shutterTapped ? 0.5 : 1)
              .onTapGesture {
                shutterTapped = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { shutterTapped = false }
                store.send(.takePhoto)
              }
              .gesture(
                LongPressGesture(minimumDuration: 0.3)
                  .onEnded { _ in
                    store.send(.startRecording)
                  }
                  .sequenced(before: DragGesture(minimumDistance: 0).onChanged({ dragValue in
                    if store.isRecording {
                      let factor = 1 + (abs(dragValue.translation.height) / 100)
                      store.send(.changeZoom(factor))
                    }
                  }))
                  .onEnded { _ in
                    store.send(.stopRecording)
                    
                  }
              )
            
            Spacer()
            
            Color.clear
              .frame(width: 24, height: 24)
              .padding(16)
          }
          .padding(48)
        }
      }
    }
    .background(.black)
    .onAppear {
      store.send(.initialize)
    }
  }
}

#Preview {
  CameraView(
    store: Store(initialState: Camera.State(
      currentUser: Mocks.user,
      photoToken: UIImage(systemName: "apple.logo")?.withTintColor(.red).pngData()
    )) {
      Camera()
    }
  )
}
