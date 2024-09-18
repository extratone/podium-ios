//
//  Media.swift
//  outsider
//
//  Created by Michael Jach on 12/09/2024.
//

import SwiftUI
import ComposableArchitecture
import Supabase

@Reducer
struct Media {
  @Dependency(\.supabase) var supabase
  
  @ObservableState
  struct State: Equatable {
    let media: MediaModel
  }
  
  enum Action {

  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      
      }
    }
  }
}
