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
  
  var body: some View {
    ZStack {
      TabView {
        Group {
          GeometryReader { geometry in
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 0) {
                CameraView(store: store.scope(state: \.camera, action: \.camera))
                  .toolbarBackground(Color.colorBase, for: .tabBar)
                  .frame(
                    width: geometry.size.width
                  )
                  .id(0)
                
                HomeView(store: store.scope(state: \.home, action: \.home))
                  .toolbarBackground(Color.colorBase, for: .tabBar)
                  .frame(
                    width: geometry.size.width
                  )
                  .id(1)
              }
              .scrollTargetLayout()
            }
            .scrollPosition(id: $store.selection.sending(\.onSelectionChanged))
            .defaultScrollAnchor(.trailing)
            .scrollTargetBehavior(.paging)
            .animation(.easeInOut, value: store.selection)
          }
          .tabItem {
            Image("icon-home")
          }
          
          ExploreView(store: store.scope(state: \.explore, action: \.explore))
            .toolbarBackground(Color.colorBase, for: .tabBar)
            .tabItem {
              Image("icon-search")
            }
          
          Text("Messages")
            .toolbarBackground(Color.colorBase, for: .tabBar)
            .tabItem {
              Image("icon-messages")
            }
          
          CurrentProfileView(store: store.scope(state: \.currentProfile, action: \.currentProfile))
            .toolbarBackground(Color.colorBase, for: .tabBar)
            .tabItem {
              Image("icon-profile")
            }
        }
      }
    }
    .onAppear {
      store.send(.initialize)
    }
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
        currentUser: Mocks.user
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
      explore: Explore.State(),
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
