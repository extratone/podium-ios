//
//  TabsView.swift
//  outsider
//
//  Created by Michael Jach on 09/09/2024.
//

import ComposableArchitecture
import SwiftUI

struct TabsView: View {
  @Bindable var store: StoreOf<Tabs>
  @Environment(\.scenePhase) var scenePhase
  
  var body: some View {
    ZStack {
      GeometryReader { geometry in
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 0) {
            CameraView(store: store.scope(state: \.camera, action: \.camera))
              .frame(
                width: geometry.size.width
              )
              .id(0)
            
            TabView(selection: $store.tabSelection.sending(\.onTabSelectionChanged)) {
              Group {
                HomeView(store: store.scope(state: \.home, action: \.home))
                  .toolbarBackground(Color.colorBase, for: .tabBar)
                  .tabItem {
                    Image("icon-home")
                  }
                  .tag(Tabs.TabSelection.home)
                
                ExploreView(store: store.scope(state: \.explore, action: \.explore))
                  .toolbarBackground(Color.colorBase, for: .tabBar)
                  .tabItem {
                    Image("icon-search")
                  }
                  .tag(Tabs.TabSelection.explore)
                
                MessagesView(store: store.scope(state: \.messages, action: \.messages))
                  .toolbarBackground(Color.colorBase, for: .tabBar)
                  .tabItem {
                    Image("icon-messages")
                  }
                  .badge(store.unreadCount)
                  .tag(Tabs.TabSelection.messages)
                
                CurrentProfileView(store: store.scope(state: \.currentProfile, action: \.currentProfile))
                  .toolbarBackground(Color.colorBase, for: .tabBar)
                  .tabItem {
                    Image("icon-profile")
                  }
                  .tag(Tabs.TabSelection.currentProfile)
              }
            }
            .frame(
              width: geometry.size.width
            )
            .id(1)
          }
          .scrollTargetLayout()
        }
        .scrollDisabled(store.tabSelection != Tabs.TabSelection.home || !store.home.path.isEmpty || store.home.send.focusedField != nil)
        .scrollPosition(id: $store.selection.sending(\.onSelectionChanged))
        .defaultScrollAnchor(.trailing)
        .scrollTargetBehavior(.paging)
        .animation(.easeInOut, value: store.selection)
        .toolbarBackground(Color.colorBase, for: .tabBar)
        .onAppear {
          store.send(.initialize)
        }
      }
    }
    .onChange(of: scenePhase, { _, newValue in
      if newValue == .active {
        store.send(.messages(.subscribeMessages))
        store.send(.messages(.subscribeChats))
      } else if newValue == .background {
//        store.send(.messages(.unsubscribeMessages))
//        store.send(.messages(.unsubscribeChats))
      }
    })
    .banner(
      data: $store.bannerData.sending(\.bannerDataChanged),
      show: $store.showBanner.sending(\.showBannerChanged)
    )
  }
}

#Preview {
  TabsView(
    store: Store(initialState: Tabs.State(
      currentUser: Mocks.user,
      camera: Camera.State(
        currentUser: Mocks.user,
        cameraSend: CameraSend.State(
          currentUser: Mocks.user
        )
      ),
      home: Home.State(
        currentUser: Mocks.user,
        send: Send.State(
          currentUser: Mocks.user
        ),
        stories: Stories.State(
          currentUser: Mocks.user
        )
      ),
      explore: Explore.State(
        currentUser: Mocks.user
      ),
      messages: Messages.State(
        currentUser: Mocks.user
      ),
      currentProfile: CurrentProfile.State(
        profile: Profile.State(
          currentUser: Mocks.user,
          user: Mocks.user
        )
      )
    )) {
      Tabs()
    }
  )
}
