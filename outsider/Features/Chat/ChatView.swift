//
//  ChatView.swift
//  min
//
//  Created by Michael Jach on 27/06/2024.
//

import SwiftUI
import ComposableArchitecture

struct ChatView: View {
  @Bindable var store: StoreOf<Chat>
  
  var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(spacing: 4) {
          ForEach(store.chat.messages ?? []) { message in
            HStack(alignment: .bottom) {
              if message.author_uuid == store.currentUser.uuid {
                Spacer()
              } else {
                AsyncCachedImage(url: store.chat.users.first(where: { $0.uuid == message.author_uuid })?.avatar_url) { image in
                  image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                } placeholder: {
                  Circle()
                    .frame(width: 32, height: 32)
                    .foregroundStyle(.colorBackgroundPrimary)
                }
              }
              
              VStack(alignment: .leading) {
                if let url = message.url {
                  Button {
                    store.send(.presentMedia(message))
                  } label: {
                    AsyncCachedImage(url: url) { image in
                      image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .background {
                          RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(.colorBackgroundPrimary)
                                .stroke(.colorBackgroundPrimary, lineWidth: 3)
                        }
                    } placeholder: {
                      RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .frame(width: 200, height: 120)
                        .foregroundStyle(.colorBackgroundPrimary)
                    }
                  }
                }
                
                if let text = message.text {
                  Text(text)
                    .foregroundStyle(message.author_uuid == store.currentUser.uuid ? .white : .colorTextPrimary)
                    .fontWeight(.medium)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(message.author_uuid == store.currentUser.uuid ? .colorMessage : .colorBackgroundPrimary)
                    .clipShape(Capsule())
                }
              }
              
              if message.author_uuid != store.currentUser.uuid {
                Spacer()
              }
            }
            .padding(.horizontal)
          }
        }
        .padding(.vertical)
      }
      .scrollDismissesKeyboard(.interactively)
      .defaultScrollAnchor(.bottom)
      .sheet(item: $store.scope(state: \.media, action: \.media)) { store in
        MediaView(store: store)
      }
      
      HStack {
        TextField("Message...", text: $store.message.sending(\.messageChanged))
          .textFieldStyle(PrimaryTextField())
        
        Button {
          store.send(.sendMessage)
        } label: {
          Image("icon-send")
            .resizable()
            .foregroundStyle(.colorBase)
            .frame(width: 16, height: 16)
            .padding(8)
            .background(.colorPrimary)
            .clipShape(Circle())
        }
        .disabled(store.message.isEmpty)
        .opacity(store.message.isEmpty ? 0.6 : 1)
      }
      .padding()
    }
    .adaptsToKeyboard()
    .navigationTitle("Chat")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      store.send(.initialize)
    }
  }
}

#Preview {
  NavigationStack {
    ChatView(store: Store(initialState: Chat.State(
      currentUser: Mocks.user,
      chat: Mocks.chat
    )) {
      Chat()
    })
  }
}
