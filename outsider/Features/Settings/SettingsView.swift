//
//  SettingsView.swift
//  outsider
//
//  Created by Michael Jach on 12/09/2024.
//

import SwiftUI
import ComposableArchitecture

struct SettingsView: View {
  var store: StoreOf<Settings>
  
  var body: some View {
    List {
      Section {
        Button {
          store.send(.logout)
        } label: {
          Text("Log out")
            .foregroundStyle(.red)
        }
        
        Button {
          store.send(.deleteAccount)
        } label: {
          Text("Delete account")
            .foregroundStyle(.red)
        }
      } header: {
        Text("Profile")
      }
      
      Section {
        Text("[Privacy policy](https://jach.me/privacy.html)")
          .accentColor(.colorTextPrimary)
        Text("[End-user license agreement](https://jach.me/eula.html)")
          .accentColor(.colorTextPrimary)
      } header: {
        Text("Podium")
      } footer: {
        if let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion"), let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") {
          Text("Version \(version).\(build)")
        }
      }
    }
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack {
    SettingsView(
      store: Store(initialState: Settings.State(
        currentUserUuid: Mocks.user.uuid
      )) {
        Settings()
      }
    )
  }
}
