//
//  StoriesView.swift
//  outsider
//
//  Created by Michael Jach on 18/09/2024.
//

import SwiftUI
import ComposableArchitecture

struct StoriesView: View {
  @Bindable var store: StoreOf<Stories>
  
  var body: some View {
    ScrollView(.horizontal) {
      HStack {
        Button {
          if store.stories[store.currentUser.uuid]?.first != nil {
            store.send(.presentSheet(store.currentUser.base))
          } else {
            store.send(.presentCamera)
          }
        } label: {
          ZStack {
            AsyncCachedImage(url: store.currentUser.avatar_url) { image in
              image
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            } placeholder: {
              Circle()
                .frame(width: 48, height: 48)
                .foregroundColor(.colorBackgroundPrimary)
            }
            
            if store.stories[store.currentUser.uuid]?.first != nil {
              Circle()
                .strokeBorder(.colorBackgroundTertiary, lineWidth: 2)
                .frame(width: 56, height: 56)
            } else {
              Circle()
                .strokeBorder(.clear, lineWidth: 2)
                .frame(width: 56, height: 56)
                .overlay {
                  HStack {
                    Spacer()
                    VStack {
                      Spacer()
                      ZStack {
                        Circle()
                          .fill(.colorPrimary)
                          .stroke(.colorBase, lineWidth: 3)
                          .frame(width: 20, height: 20)
                        
                        Image(systemName: "plus")
                          .resizable()
                          .frame(width: 8, height: 8)
                          .foregroundStyle(.colorBase)
                      }
                    }
                  }
                }
            }
          }
        }
        
        ForEach(Array(store.stories.filter({ $0.key != store.currentUser.uuid })), id: \.key) { authorUuid, stories in
          Button {
            store.send(.presentSheet(stories.first?.author))
          } label: {
            ZStack {
              if stories.contains(where: { !($0.stats.contains(where: { $0.viewed_by.uuid == store.currentUser.uuid })) }) {
                Circle()
                  .strokeBorder(.colorPrimary, lineWidth: 2)
                  .frame(width: 56, height: 56)
              } else {
                Circle()
                  .strokeBorder(.colorBackgroundTertiary, lineWidth: 2)
                  .frame(width: 56, height: 56)
              }
              
              AsyncCachedImage(url: stories.first?.author.avatar_url) { image in
                image
                  .resizable()
                  .scaledToFill()
                  .frame(width: 48, height: 48)
                  .clipShape(Circle())
              } placeholder: {
                Circle()
                  .frame(width: 48, height: 48)
                  .foregroundColor(.colorBackgroundPrimary)
              }
            }
          }
        }
      }
      .padding(.horizontal)
      .padding(.bottom, 7)
    }
    .sheet(item: $store.scope(state: \.story, action: \.story)) { store in
      StoryView(store: store)
    }
    .onAppear {
      store.send(.initialize)
    }
  }
}

#Preview {
  StoriesView(
    store: Store(initialState: Stories.State(
      currentUser: Mocks.currentUser
    )) {
      Stories()
    }
  )
}
