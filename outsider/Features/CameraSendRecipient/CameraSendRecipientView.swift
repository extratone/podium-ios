//
//  CameraSendRecipientView.swift
//  outsider
//
//  Created by Michael Jach on 25/09/2024.
//

import SwiftUI
import ComposableArchitecture

struct CameraSendRecipientView: View {
  @Bindable var store: StoreOf<CameraSendRecipient>
  
  var body: some View {
    Toggle(isOn: $store.selected.sending(\.onSelectedChange)) {
      HStack {
        AsyncCachedImage(url: store.following.following.avatar_url) { image in
          image
            .resizable()
            .scaledToFill()
            .frame(width: 36, height: 36)
            .clipShape(Circle())
        } placeholder: {
          Circle()
            .frame(width: 36, height: 36)
            .foregroundStyle(.colorBackgroundPrimary)
        }
        
        VStack(alignment: .leading, spacing: 0) {
          if let displayName = store.following.following.display_name {
            Text(displayName)
              .fontWeight(.medium)
          }
          Text("@\(store.following.following.username)")
            .foregroundStyle(.colorTextSecondary)
            .fontWeight(.medium)
        }
        
        Spacer()
      }
    }
    .toggleStyle(PrimaryCheckbox())
  }
}

#Preview {
  CameraSendRecipientView(store: Store(initialState: CameraSendRecipient.State(
    following: FollowingModel(following: Mocks.user)
  )) {
    CameraSendRecipient()
  })
}
