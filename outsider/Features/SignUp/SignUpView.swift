//
//  SignUpView.swift
//  outsider
//
//  Created by Michael Jach on 09/09/2024.
//

import SwiftUI
import ComposableArchitecture

struct SignUpView: View {
  @Bindable var store: StoreOf<SignUp>
  
  var body: some View {
    VStack(alignment: .leading) {
      Text("Sign up")
        .font(.title)
        .fontWeight(.semibold)
      
      TextField(
        "Email",
        text: $store.email.sending(\.onEmailChanged)
      )
      .textContentType(.emailAddress)
      .keyboardType(.emailAddress)
      .textInputAutocapitalization(.never)
      .textFieldStyle(PrimaryTextField())
      
      SecureField(
        "Password",
        text: $store.password.sending(\.onPasswordChanged)
      )
      .textContentType(.password)
      .textInputAutocapitalization(.never)
      .textFieldStyle(PrimaryTextField())
      
      Button {
        store.send(.signUp)
      } label: {
        Text("Sign up")
      }
      .disabled(store.isLoading || store.email.isEmpty || store.password.isEmpty)
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
  SignUpView(
    store: Store(initialState: SignUp.State()) {
      SignUp()
    }
  )
}
