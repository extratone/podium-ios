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
      } header: {
        Text("Profile")
      }
      
      Section {
        NavigationLink("Privacy policy", destination: Text("Privacy"))
        NavigationLink("Terms of service", destination: Text("Terms of service"))
      } header: {
        Text("Podium")
      } footer: {
        Text("Version 0.1b01")
      }
    }
    .navigationTitle("Settings")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack {
    SettingsView(
      store: Store(initialState: Settings.State()) {
        Settings()
      }
    )
  }
}
