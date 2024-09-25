//
//  NewMessageView.swift
//  min
//
//  Created by Michael Jach on 17/07/2024.
//

import SwiftUI
import ComposableArchitecture

struct NewMessageView: View {
  @Bindable var store: StoreOf<NewMessage>

  var body: some View {
    NavigationStack {
      VStack {
        List {
          Section {
            ForEach(store.searchResults.isEmpty ? store.suggested : store.searchResults, id: \.self) { result in
              VStack(spacing: 0) {
                Button {
                  store.send(.addToken(result))
                } label: {
                  HStack {
                    AsyncCachedImage(url: result.following.avatar_url) { image in
                      image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 48, height: 48)
                        .clipShape(Circle())
                    } placeholder: {
                      Circle()
                        .frame(width: 48, height: 48)
                        .foregroundStyle(.colorBackgroundPrimary)
                    }
                    
                    VStack(alignment: .leading) {
                      if let displayName = result.following.display_name {
                        Text(displayName)
                          .fontWeight(.medium)
                      }
                      Text("@\(result.following.username)")
                        .foregroundStyle(.colorTextSecondary)
                        .fontWeight(.medium)
                    }
                  }
                }
              }
            }
            .listRowSeparator(.hidden)
          } header: {
            if store.searchResults.isEmpty && !store.suggested.isEmpty {
              Text("Suggested")
            }
          }
        }
        .listStyle(.plain)
        .searchable(
          text: $store.query.sending(\.queryChanged),
          tokens: $store.currentTokens.sending(\.currentTokensChanged),
          isPresented: $store.isSearching.sending(\.isSearchingChanged),
          placement: .navigationBarDrawer(displayMode: .always),
          prompt: Text("Search friends...")) { token in
            Text(token.following.username)
          }
          .textInputAutocapitalization(.never)
        
        Spacer()
        
        HStack(alignment: .center) {
          TextField("Message...", text: $store.text.sending(\.textChanged))
            .textFieldStyle(PrimaryTextField())
          
          Button {
            store.send(.send(store.currentTokens, store.text))
          } label: {
            Image("icon-send")
              .resizable()
              .frame(width: 24, height: 24)
              .padding(12)
              .foregroundColor(.colorBase)
              .background(.colorPrimary)
              .clipShape(Circle())
          }
          .disabled(store.text.isEmpty || store.currentTokens.isEmpty)
          .opacity((!store.text.isEmpty && !store.currentTokens.isEmpty) ? 1 : 0.5)
        }
        .padding(.horizontal)
        .padding(.bottom)
      }
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button {
            store.send(.dismiss)
          } label: {
            Image("icon-close")
              .resizable()
          }
        }
      }
    }
  }
}

#Preview {
  Text("preview")
    .sheet(isPresented: .constant(true), content: {
      NewMessageView(store: Store(initialState: NewMessage.State(
        currentUser: Mocks.user
      )) {
        NewMessage()
      })
    })
}
