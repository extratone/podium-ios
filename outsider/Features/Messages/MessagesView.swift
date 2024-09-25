//
//  MessagesView.swift
//  Podium
//
//  Created by Michael Jach on 22/06/2024.
//

import SwiftUI
import ComposableArchitecture

struct MessagesView: View {
  @Bindable var store: StoreOf<Messages>
  
  init(store: StoreOf<Messages>) {
    self.store = store
    UINavigationBar.appearance().largeTitleTextAttributes = [
      .font : UIFont(name: "ClashDisplayVariable-Bold_Medium", size: 34)!
    ]
  }
  
  var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      List {
        ForEach(store
          .scope(state: \.chats, action: \.chats)
          .sorted(by: { prev, next in
            return prev.chat.messages?.last?.created_at ?? .now > next.chat.messages?.last?.created_at ?? .now
          })
        ) { chatStore in
          Button {
            store.send(.presentChat(chatStore.chat))
          } label: {
            HStack {
              HStack(spacing: -32) {
                ForEach(chatStore.chat.users.filter({ $0.uuid != store.currentUser.uuid }).prefix(3)) { user in
                  AsyncImage(url: user.avatar_url) { image in
                    image
                      .resizable()
                      .scaledToFill()
                      .frame(width: 54, height: 54)
                      .clipShape(Circle())
                  } placeholder: {
                    Circle()
                      .frame(width: 54, height: 54)
                      .foregroundStyle(.colorBackgroundPrimary)
                  }
                }
              }
              
              VStack(alignment: .leading) {
                Text(chatStore.chat.users.filter({ $0.uuid != store.currentUser.uuid }).map({ $0.display_name ?? $0.username }).joined(separator: ", "))
                  .fontWeight(.semibold)
                
                Text(chatStore.chat.messages?.last?.text ?? "")
                  .fontWeight(.medium)
                  .font(.subheadline)
                  .foregroundStyle(.colorTextSecondary)
                  .lineLimit(1)
              }
            }
          }
          .listRowSeparator(.hidden)
        }
      }
      .listSectionSeparator(.hidden)
      .listStyle(.plain)
      .navigationTitle("Messages")
      .sheet(
        item: $store.scope(state: \.newMessage, action: \.newMessage)
      ) { store in
        NewMessageView(store: store)
      }
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            store.send(.presentNewMessage)
          } label: {
            Image(systemName:"plus")
              .resizable()
          }
        }
      }
    } destination: { store in
      switch store.case {
      case let .chat(store):
        ChatView(store: store)
      }
    }
  }
}

#Preview {
  MessagesView(store: Store(initialState: Messages.State(
    currentUser: Mocks.user,
    chats: [
      Chat.State(
        currentUser: Mocks.user,
        chat: Mocks.chat
      )
    ]
  )) {
    Messages()
  })
}
