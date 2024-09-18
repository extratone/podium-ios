//
//  CameraView.swift
//  outsider
//
//  Created by Michael Jach on 18/09/2024.
//

import SwiftUI
import ComposableArchitecture
import PhotosUI

struct CameraView: View {
  @Bindable var store: StoreOf<Camera>
  
  var body: some View {
    ZStack {
      Color.black
        .overlay {
          if let image = store.image {
            Image(uiImage: image)
              .resizable()
              .scaledToFill()
          }
        }
        .ignoresSafeArea()
      
      VStack {
        Spacer()
        
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
          
          Button {
            store.send(.send)
          } label: {
            HStack {
              Text("Send")
            }
          }
        }
        .padding()
      }
    }
  }
}

#Preview {
  CameraView(
    store: Store(initialState: Camera.State(  
      currentUser: Mocks.user
    )) {
      Camera()
    }
  )
}
