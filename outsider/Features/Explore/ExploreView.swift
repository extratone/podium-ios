//
//  ExploreView.swift
//  outsider
//
//  Created by Michael Jach on 12/09/2024.
//

import SwiftUI
import ComposableArchitecture

struct ExploreView: View {
  @Bindable var store: StoreOf<Explore>
  
  init(store: StoreOf<Explore>) {
    self.store = store
    UINavigationBar.appearance().largeTitleTextAttributes = [
      .font : UIFont(name: "ClashDisplayVariable-Bold_Medium", size: 34)!
    ]
  }
  
  var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      List {
        Group {
          if store.isSearching {
            ForEach(store.searchResults, id: \.self) { result in
              Button {
                store.send(.presentProfile(result))
              } label: {
                HStack {
                  AsyncCachedImage(url: result.avatar_url) { image in
                    image
                      .resizable()
                      .scaledToFill()
                      .frame(width: 42, height: 42)
                      .clipShape(Circle())
                  } placeholder: {
                    Circle()
                      .frame(width: 42, height: 42)
                      .foregroundColor(.colorBackgroundPrimary)
                  }
                  
                  VStack(alignment: .leading) {
                    if let displayName = result.display_name {
                      Text(displayName)
                        .fontWeight(.medium)
                        .foregroundStyle(.colorTextPrimary)
                    }
                    
                    Text("@\(result.username)")
                      .foregroundStyle(.colorTextSecondary)
                  }
                  
                  Spacer()
                }
              }
            }
          } else {
            Section {
              ForEach(store.suggestedProfiles, id: \.self) { profile in
                VStack(spacing: 0) {
                  Button {
                    store.send(.presentProfile(profile))
                  } label: {
                    HStack {
                      AsyncCachedImage(url: profile.avatar_url) { image in
                        image
                          .resizable()
                          .scaledToFill()
                          .frame(width: 42, height: 42)
                          .clipShape(Circle())
                      } placeholder: {
                        Circle()
                          .frame(width: 42, height: 42)
                          .foregroundColor(.colorBackgroundPrimary)
                      }
                      
                      VStack(alignment: .leading, spacing: 0) {
                        if let displayName = profile.display_name {
                          Text(displayName)
                            .fontWeight(.medium)
                            .foregroundStyle(.colorTextPrimary)
                        }
                        
                        Text("@\(profile.username)")
                          .foregroundStyle(.colorTextSecondary)
                      }
                      
                      Spacer()
                    }
                  }
                }
              }
            } header: {
              Text("Profiles")
            }
            .listRowSeparator(.hidden)
            
            Section {
              NavigationLink(destination: Text("d")) {
                Text("#worldcup")
                  .fontWeight(.medium)
                  .foregroundStyle(.colorTextPrimary)
              }
              NavigationLink(destination: Text("d")) {
                Text("#test")
                  .fontWeight(.medium)
                  .foregroundStyle(.colorTextPrimary)
              }
              NavigationLink(destination: Text("d")) {
                Text("#yoga")
                  .fontWeight(.medium)
                  .foregroundStyle(.colorTextPrimary)
              }
            } header: {
              Text("Tags")
            }
            .listRowSeparator(.hidden)
            
            Section {
              
            } header: {
              Text("Popular")
            }
          }
        }
        .listRowSeparator(.hidden)
      }
      .listStyle(.plain)
      .searchable(
        text: $store.query.sending(\.queryChanged),
        isPresented: $store.isSearching.sending(\.isSearchingChanged),
        placement: .navigationBarDrawer(displayMode: .always)
      )
      .textInputAutocapitalization(.never)
      .navigationTitle("Explore")
    } destination: { store in
      switch store.case {
      case let .profile(store):
        ProfileView(store: store)
        
      case let .comments(store):
        CommentsView(store: store)
      }
    }
    .onAppear {
      store.send(.initialize)
    }
  }
}

#Preview {
  ExploreView(
    store: Store(initialState: Explore.State(
      currentUser: Mocks.user
    )) {
      Explore()
    }
  )
}
