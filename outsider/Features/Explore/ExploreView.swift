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
    NavigationStack {
      List {
        Section {
          HStack {
            Image("icon-search")
              .resizable()
              .scaledToFill()
              .frame(width: 42, height: 42)
              .clipShape(Circle())
            
            VStack(alignment: .leading) {
              Text("Michal Jach")
                .fontWeight(.medium)
                .foregroundStyle(.colorTextPrimary)
              
              Text("@jach")
                .foregroundStyle(.colorTextSecondary)
            }
            
            Spacer()
            
            Button {
              
            } label: {
              Text("Follow")
            }
            .buttonStyle(PrimarySmallButton())
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
    }
  }
}

#Preview {
  ExploreView(
    store: Store(initialState: Explore.State()) {
      Explore()
    }
  )
}
