//
//  HomeView.swift
//  outsider
//
//  Created by Michael Jach on 09/09/2024.
//

import SwiftUI
import ComposableArchitecture

struct HomeView: View {
  @Bindable var store: StoreOf<Home>
  
  var body: some View {
    ZStack {
      NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
        VStack(spacing: 0) {
          StoriesView(store: store.scope(state: \.stories, action: \.stories))
          
          ZStack {
            LinearGradient(colors: store.isLoading ? [.clear, .yellow, .blue, .clear] : [.clear, .blue, .yellow, .clear], startPoint: store.isLoading ? .topLeading : .leading, endPoint: store.isLoading ? .bottomTrailing : .topTrailing)
              .frame(height: 3)
              .animation(.easeIn.repeatForever().speed(0.5), value: store.isLoading)
          }
          .opacity(store.isLoading ? 1 : 0)
          .animation(.easeIn.speed(1), value: store.isLoading)
          
          Divider()
          
          ZStack {
            ScrollView(showsIndicators: false) {
              VStack(spacing: 0) {
                ForEach(store.scope(state: \.posts, action: \.posts)) { postStore in
                  PostView(
                    store: postStore,
                    onShowProfile: {
                      store.send(.presentProfile(postStore.post.author))
                    },
                    onShowPost: {
                      store.send(.presentComments(postStore.post))
                    }
                  )
                  .padding(.horizontal, 10)
                  Divider()
                    .padding(.bottom, 10)
                }
              }
              .padding(.top, 10)
              .padding(.bottom, 72)
            }
            .scrollDismissesKeyboard(.interactively)
            
            VStack {
              Spacer()
              SendView(store: store.scope(state: \.send, action: \.send))
            }
            .adaptsToKeyboard()
          }
        }
        .toolbar {
          ToolbarItem(placement: .topBarLeading) {
            Text("Podium")
              .font(.custom("ClashDisplayVariable-Bold_Medium", size: 24))
              .fontWeight(.medium)
          }
        }
      } destination: { store in
        switch store.case {
        case let .comments(commentsStore):
          CommentsView(store: commentsStore)
        case let .profile(store):
          ProfileView(store: store)
        }
      }
    }
    .onAppear {
      store.send(.fetchPosts)
    }
  }
}

#Preview {
  TabView {
    HomeView(
      store: Store(initialState: Home.State(
        currentUser: Mocks.user,
        send: Send.State(
          currentUser: Mocks.user
        ),
        stories: Stories.State(
          currentUser: Mocks.user
        )
      )) {
        Home()
      }
    )
    .toolbarBackground(Color.colorBase, for: .tabBar)
    .tabItem { Image("icon-home") }
    
    Text("s")
      .tabItem { Image("icon-search") }
    
    Text("s")
      .tabItem { Image("icon-messages") }
    
    Text("s")
      .tabItem { Image("icon-profile") }
  }
}
