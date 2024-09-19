//
//  SendView.swift
//  outsider
//
//  Created by Michael Jach on 11/09/2024.
//

import SwiftUI
import ComposableArchitecture
import PhotosUI

struct SendView: View {
  @Bindable var store: StoreOf<Send>
  @FocusState var focusedField: Send.State.Field?
  
  var body: some View {
    HStack(alignment: .bottom, spacing: 4) {
      PhotosPicker(
        selection: $store.imageSelection.sending(\.imageSelectionChanged)
      ) {
        Image("icon-photo")
          .resizable()
          .frame(width: 24, height: 24)
          .foregroundStyle(.white)
      }
      .disabled(store.isPending)
      .padding(16)
      
      VStack {
        TextField(
          "What's on your mind...",
          text: $store.prompt.sending(\.onPromptChanged),
          prompt: Text("What's on your mind...")
            .foregroundStyle(.colorTextSecondary),
          axis: .vertical
        )
        .focused($focusedField, equals: .send)
        .disabled(store.isPending)
        .foregroundStyle(.white)
        .onChange(of: store.isPending) { oldValue, newValue in
          endTextEditing()
        }
        
        if let tempImage = store.tempImage {
          ZStack {
            Image(uiImage: tempImage)
              .resizable()
              .scaledToFill()
              .frame(height: 120)
              .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
              .allowsHitTesting(false)
            
            HStack {
              Spacer()
              VStack {
                Button {
                  store.send(.clearImages)
                } label: {
                  Image(systemName: "xmark")
                    .foregroundColor(.white)
                    .padding(12)
                }
                Spacer()
              }
            }
          }
          .frame(height: 120)
        }
      }
      .bind($store.focusedField.sending(\.setFocusedField), to: $focusedField)
      .padding(.vertical, 16)
      
      
      Button {
        store.send(.send)
      } label: {
        Image("icon-send")
          .resizable()
          .foregroundStyle(.colorBase.opacity(store.isFormDisabled ? 0.4 : 1))
          .padding(4)
          .frame(width: 24, height: 24)
          .background(.colorPrimary)
          .clipShape(Circle())
      }
      .disabled(store.isFormDisabled)
      .padding(16)
    }
    .background(
      RoundedRectangle(cornerRadius: 17, style: .continuous)
        .foregroundColor(.colorBackgroundSecondary)
    )
    .padding()
    .animation(.easeInOut, value: store.prompt)
    .animation(.easeInOut, value: store.tempImage)
  }
}

#Preview {
  SendView(
    store: Store(initialState: Send.State(
      currentUser: Mocks.user
    )) {
      Send()
    }
  )
}
