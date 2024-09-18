//
//  MainView.swift
//  outsider
//
//  Created by Michael Jach on 09/09/2024.
//

import SwiftUI
import ComposableArchitecture

struct MainView: View {
  var store: StoreOf<Main>
  
  var body: some View {
    Group {
      if let store = store.scope(state: \.tabs, action: \.tabs) {
        TabsView(store: store)
      }
      
      if let store = store.scope(state: \.signIn, action: \.signIn) {
        SignInView(store: store)
      }
    }
    .onAppear {
      store.send(.initialize)
    }
  }
}

#Preview {
  MainView(
    store: Store(initialState: Main.State()) {
      Main()
    }
  )
}
