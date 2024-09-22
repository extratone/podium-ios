//
//  ProfileView.swift
//  outsider
//
//  Created by Michael Jach on 09/09/2024.
//

import SwiftUI
import ComposableArchitecture
import PhotosUI

struct CurrentProfileView: View {
  @Bindable var store: StoreOf<CurrentProfile>
  
  init(store: StoreOf<CurrentProfile>) {
    self.store = store
    UINavigationBar.appearance().largeTitleTextAttributes = [
      .font : UIFont(name: "ClashDisplayVariable-Bold_Medium", size: 34)!
    ]
  }
  
  var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      ProfileView(store: store.scope(state: \.profile, action: \.profile))
        .toolbar {
          ToolbarItem(placement: .topBarTrailing) {
            NavigationLink(state: CurrentProfile.Path.State.settings(Settings.State())) {
              Image("icon-settings")
                .foregroundColor(.colorTextPrimary)
            }
          }
        }
    } destination: { store in
      switch store.case {
      case let .settings(store):
        SettingsView(store: store)
        
      case let .profile(store):
        ProfileView(store: store)
        
      case let .comments(store):
        CommentsView(store: store)
      }
    }
  }
}

#Preview {
  CurrentProfileView(
    store: Store(initialState: CurrentProfile.State(
      profile: Profile.State(
        currentUser: Mocks.user,
        user: Mocks.user
      )
    )) {
      CurrentProfile()
    }
  )
}
