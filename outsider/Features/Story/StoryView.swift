//
//  StoryView.swift
//  outsider
//
//  Created by Michael Jach on 18/09/2024.
//

import SwiftUI
import ComposableArchitecture
import CachedAsyncImage

struct StoryView: View {
  var store: StoreOf<Story>
  
  var body: some View {
    ZStack {
      if let selectedStory = store.selectedStory {
        Color.black
          .ignoresSafeArea()
          .overlay {
            CachedAsyncImage(url: selectedStory.url) { image in
              image
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
            } placeholder: {
              Color.black
                .ignoresSafeArea()
            }
          }
      }
      
      VStack(spacing: 0) {
        HStack {
          ForEach(store.stories[store.selectedUser] ?? []) { story in
            RoundedRectangle(cornerRadius: 8, style: .circular)
              .frame(height: 3)
              .foregroundStyle(.white)
              .opacity(store.selectedStory?.uuid == story.uuid ? 0.8 : 0.4)
          }
        }
        .padding(.horizontal)
        .padding(.top)
        
        HStack {
          CachedAsyncImage(url: store.selectedUser.avatar_url) { image in
            image
              .resizable()
              .scaledToFill()
              .frame(width: 42, height: 42)
              .clipShape(Circle())
          } placeholder: {
            Circle()
              .frame(width: 42, height: 42)
              .foregroundColor(.colorBackgroundPrimary)
          }
          
          VStack(alignment: .leading, spacing: 0) {
            if let displayName = store.selectedUser.display_name {
              Text(displayName)
                .foregroundStyle(.white)
                .fontWeight(.medium)
            }
            
            Text("@\(store.selectedUser.username)")
              .foregroundStyle(.white)
              .fontWeight(.medium)
              .foregroundStyle(.colorTextSecondary)
              .font(.subheadline)
          }
          
          Spacer()
        }
        .padding()
        
        HStack(spacing: 0) {
          Button {
            store.send(.prev)
          } label: {
            Color.clear
          }
          
          Button {
            store.send(.next)
          } label: {
            Color.clear
          }
        }
        
        Spacer()
      }
      .onAppear {
        store.send(.initialize)
      }
    }
  }
}

#Preview {
  StoryView(
    store: Store(initialState: Story.State(
      currentUser: Mocks.user,
      stories: [Mocks.user: [Mocks.story]],
      selectedUser: Mocks.user
    )) {
      Story()
    }
  )
}
