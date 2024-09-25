//
//  Stats.swift
//  outsider
//
//  Created by Michael Jach on 21/09/2024.
//

import SwiftUI
import ComposableArchitecture

@Reducer
struct Stats {
  @Dependency(\.supabase) var supabase
  
  @ObservableState
  struct State: Equatable {
    var stats: [StoryStatsModel]?
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
