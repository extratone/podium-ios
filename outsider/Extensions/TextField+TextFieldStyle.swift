//
//  TextField+TextFieldStyle.swift
//  outsider
//
//  Created by Michael Jach on 09/09/2024.
//

import SwiftUI

struct PrimaryTextField: TextFieldStyle {
  func _body(configuration: TextField<Self._Label>) -> some View {
    configuration
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .foregroundColor(.colorBackgroundPrimary)
      )
  }
}

#Preview {
  VStack {
    TextField("Placeholder", text: .constant(""))
      .textFieldStyle(PrimaryTextField())
    
    TextField("Placeholder", text: .constant("Value set"))
      .textFieldStyle(PrimaryTextField())
  }
}
