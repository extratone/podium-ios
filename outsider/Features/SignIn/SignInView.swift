//
//  SignInView.swift
//  outsider
//
//  Created by Michael Jach on 09/09/2024.
//

import ComposableArchitecture
import SwiftUI

struct SignInView: View {
  @Bindable var store: StoreOf<SignIn>
  
  var body: some View {
    NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
      VStack(alignment: .leading) {
        VStack(alignment: .leading, spacing: 12) {
          Image("icon-logo")
            .resizable()
            .frame(width: 64, height: 64)
            .foregroundStyle(.colorTextPrimary)
          
          Text("Welcome on Podium!")
            .font(.title)
            .fontWeight(.semibold)
          
          Text("Open source network.")
            .font(.title3)
            .fontWeight(.medium)
        }
        .padding(.bottom, 24)
        
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
          store.send(.signIn)
        } label: {
          Text("Sign in")
        }
        .disabled(store.isLoading || store.email.isEmpty || store.password.isEmpty)
        .buttonStyle(PrimaryButton(isLoading: store.isLoading))
        
        NavigationLink(state: SignIn.Path.State.signUp(SignUp.State())) {
          HStack {
            Spacer()
            Text("Create account")
              .fontWeight(.semibold)
            Spacer()
          }
          .padding()
        }
        
        if let error = store.error {
          Text(error)
            .foregroundStyle(.red)
        }
      }
      .padding()
    } destination: { store in
      switch store.case {
      case let .username(store):
        UsernameView(store: store)
        
      case let .signUp(store):
        SignUpView(store: store)
      }
    }
  }
}

#Preview {
  SignInView(
    store: Store(initialState: SignIn.State()) {
      SignIn()
    }
  )
}
