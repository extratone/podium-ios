//
//  outsiderApp.swift
//  outsider
//
//  Created by Michael Jach on 09/09/2024.
//

import SwiftUI
import ComposableArchitecture

@main
struct outsiderApp: App {
  var body: some Scene {
    WindowGroup {
      MainView(
        store: Store(initialState: Main.State()) {
          Main()
        }
      )
    }
  }
}
