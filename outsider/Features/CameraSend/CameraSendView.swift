//
//  CameraSendView.swift
//  outsider
//
//  Created by Michael Jach on 25/09/2024.
//

import SwiftUI
import ComposableArchitecture

struct CameraSendView: View {
  @Bindable var store: StoreOf<CameraSend>
  
  var body: some View {
    VStack {
      ScrollView {
        VStack(alignment: .leading) {
          HStack {
            Text("Story")
              .foregroundStyle(.colorTextSecondary)
              .fontWeight(.medium)
            
            Spacer()
          }
          
          Toggle(isOn: $store.addStory.sending(\.onAddStoryChange)) {
            HStack {
              AsyncCachedImage(url: store.currentUser.avatar_url) { image in
                image
                  .resizable()
                  .scaledToFill()
                  .frame(width: 36, height: 36)
                  .clipShape(Circle())
              } placeholder: {
                Circle()
                  .frame(width: 36, height: 36)
                  .foregroundStyle(.colorBackgroundPrimary)
              }
              
              VStack(alignment: .leading, spacing: 0) {
                Text("Add to story")
                  .fontWeight(.medium)
              }
              
              Spacer()
            }
          }
          .toggleStyle(PrimaryCheckbox())
          
          HStack {
            Text("Following")
              .foregroundStyle(.colorTextSecondary)
              .fontWeight(.medium)
            
            Spacer()
          }
          
          VStack(alignment: .leading) {
            ForEach(store
              .scope(state: \.following, action: \.following)) { store in
                CameraSendRecipientView(store: store)
              }
          }
        }
        .padding()
      }
      
      HStack {
        Spacer()
        
        Button {
          store.send(.send)
        } label: {
          Text("Send")
        }
        .buttonStyle(SendButton())
        .disabled(!store.isEnabled)
      }
      .padding(.horizontal)
    }
  }
}

#Preview {
  Text("preview")
    .sheet(isPresented: .constant(true), content: {
      CameraSendView(store: Store(initialState: CameraSend.State(
        currentUser: Mocks.currentUser
      )) {
        CameraSend()
      })
    })
}
