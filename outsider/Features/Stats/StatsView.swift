//
//  StatsView.swift
//  outsider
//
//  Created by Michael Jach on 21/09/2024.
//

import SwiftUI
import ComposableArchitecture

struct StatsView: View {
  var store: StoreOf<Stats>
  
  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("\(store.profiles?.count ?? 0) views")
          .font(.subheadline)
          .fontWeight(.medium)
        Spacer()
      }
      .padding()
      
      Divider()
      
      ScrollView {
        VStack(alignment: .leading) {
          if let profiles = store.profiles {
            ForEach(profiles) { profile in
              HStack {
                AsyncCachedImage(url: profile.avatar_url) { image in
                  image
                    .resizable()
                    .scaledToFill()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                } placeholder: {
                  Circle()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.colorBackgroundPrimary)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                  if let displayName = profile.display_name {
                    Text(displayName)
                      .fontWeight(.medium)
                  }
                  
                  Text("@\(profile.username)")
                    .fontWeight(.medium)
                    .foregroundStyle(.colorTextSecondary)
                    .font(.subheadline)
                }
                
                Spacer()
              }
            }
          }
        }
        .padding()
      }
    }
  }
}

#Preview {
  StatsView(
    store: Store(initialState: Stats.State(
      
    )) {
      Stats()
    }
  )
}
