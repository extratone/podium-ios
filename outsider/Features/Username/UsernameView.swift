//
//  UsernameView.swift
//  outsider
//
//  Created by Michael Jach on 12/09/2024.
//

import SwiftUI
import ComposableArchitecture

struct UsernameView: View {
  @Bindable var store: StoreOf<Username>
  
  var body: some View {
    VStack(alignment: .leading) {
      Text("Claim your username")
        .font(.title)
        .fontWeight(.semibold)
      
      TextField(
        "username",
        text: $store.username.sending(\.onUsernameChanged)
      )
      .textContentType(.username)
      .textInputAutocapitalization(.never)
      .textFieldStyle(PrimaryTextField())
      
      Button {
        store.send(.signUp)
      } label: {
        Text("Sign up")
      }
      .disabled(store.isLoading || store.username.isEmpty)
      .buttonStyle(PrimaryButton(isLoading: store.isLoading))
      
      if let error = store.error {
        Text(error)
          .foregroundStyle(.red)
      }
    }
    .padding()
  }
}

#Preview {
  UsernameView(
    store: Store(initialState: Username.State(  
      uuid: UUID()
    )) {
      Username()
    }
  )
}
