//
//  StoryView.swift
//  outsider
//
//  Created by Michael Jach on 18/09/2024.
//

import SwiftUI
import ComposableArchitecture
import AVKit

struct StoryView: View {
  @Bindable var store: StoreOf<Story>
  
  var body: some View {
    ZStack {
      if store.selectedStory?.type == .video {
        GeometryReader { geometry in
          VideoPlayer(player: store.queuePlayer)
            .disabled(true)
            .aspectRatio(contentMode: .fill)
            .ignoresSafeArea()
            .frame(width: geometry.size.width, height: geometry.size.height)
            .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            .clipped()
            .onDisappear {
              store.queuePlayer?.pause()
            }
            .background {
              Color.black
                .ignoresSafeArea()
            }
        }
        .ignoresSafeArea()
      } else {
        Color.black
          .ignoresSafeArea()
          .overlay {
            if let image = store.image {
              Image(uiImage: image)
                .resizable()
                .scaledToFill()
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
          AsyncCachedImage(url: store.selectedUser.avatar_url) { image in
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
          
          if store.selectedStory?.author.uuid == store.currentUser.uuid {
            Menu {
              Button(role: .destructive, action: { store.send(.delete) }) {
                Label("Delete", systemImage: "trash")
              }
            } label: {
              Image("icon-dots")
                .resizable()
                .frame(width: 22, height: 22)
                .foregroundColor(.white)
            }
          }
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
        
        HStack {
          Spacer()
          
          if store.selectedStory?.author.uuid == store.currentUser.uuid {
            Button {
              store.send(.presentStats)
            } label: {
              HStack {
                Image("icon-views")
                  .resizable()
                  .frame(width: 20, height: 20)
                  .foregroundStyle(.white)
                
                Text("\(store.selectedStory?.stats?.count ?? 0) views")
                  .foregroundStyle(.white)
                  .fontWeight(.medium)
                  .font(.subheadline)
              }
            }
          }
        }
        .padding()
      }
      .sheet(item: $store.scope(state: \.stats, action: \.stats)) { store in
        StatsView(store: store)
          .presentationDetents([
            .fraction(0.2),
            .medium,
            .large
          ])
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
