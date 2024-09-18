//
//  StoriesView.swift
//  outsider
//
//  Created by Michael Jach on 18/09/2024.
//

import SwiftUI
import ComposableArchitecture
import CachedAsyncImage

struct StoriesView: View {
  @Bindable var store: StoreOf<Stories>
  
  var body: some View {
    ScrollView(.horizontal) {
      HStack {
        Button {
          if store.stories.first(where: { $0.key.uuid == store.currentUser.uuid }) != nil {
            store.send(.presentSheet(store.currentUser))
          } else {
            store.send(.presentCamera)
          }
        } label: {
          ZStack {
            CachedAsyncImage(url: store.currentUser.avatar_url) { image in
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
            
            if store.stories.first(where: { $0.key.uuid == store.currentUser.uuid }) != nil {
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
        
        ForEach(Array(store.stories.filter({ $0.key.uuid != store.currentUser.uuid })), id: \.key) { author, stories in
          Button {
            store.send(.presentSheet(author))
          } label: {
            ZStack {
              if stories.contains(where: { !($0.stats?.contains(where: { $0.viewed_by == store.currentUser.uuid }) ?? true) }) {
                Circle()
                  .strokeBorder(.colorPrimary, lineWidth: 2)
                  .frame(width: 56, height: 56)
              } else {
                Circle()
                  .strokeBorder(.colorBackgroundTertiary, lineWidth: 2)
                  .frame(width: 56, height: 56)
              }
              
              CachedAsyncImage(url: author.avatar_url) { image in
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
      currentUser: Mocks.user
    )) {
      Stories()
    }
  )
}
