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
            if message.author_uuid == store.currentUser.uuid {
              HStack(alignment: .bottom) {
                Spacer()
                
                if let text = message.text {
                  Text(text)
                    .fontWeight(.medium)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(.colorBackgroundPrimary)
                    .clipShape(Capsule())
                }
                
                AsyncCachedImage(url: store.currentUser.avatar_url) { image in
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
              .padding(.horizontal)
            } else {
              HStack(alignment: .bottom) {
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
                
                if let text = message.text {
                  Text(text)
                    .foregroundStyle(.white)
                    .fontWeight(.medium)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(.colorMessage)
                    .clipShape(Capsule())
                }
                
                Spacer()
              }
              .padding(.horizontal)
            }
          }
        }
        .padding(.vertical)
      }
      .scrollDismissesKeyboard(.interactively)
      .defaultScrollAnchor(.bottom)
      
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
