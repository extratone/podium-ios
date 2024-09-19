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
        if store.image != nil {
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
          }
          .padding()
        }
        
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
          
          if store.image == nil {
            Button {
              
            } label: {
              Circle()
                .frame(width: 82, height: 82)
                .foregroundStyle(.white)
            }
          } else {
            HStack {
              Button {
                store.send(.send)
              } label: {
                HStack(spacing: 0) {
                  Text("Add story")
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                  
                  Image("icon-send")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.black)
                }
                .padding(.vertical, 8)
                .padding(.leading, 16)
                .padding(.trailing, 8)
                .background(.white)
                .clipShape(Capsule())
              }
            }
          }
          
          Spacer()
          
          VStack {
            
          }
          .frame(width: 24, height: 24)
          .padding(16)
        }
        .padding(48)
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
