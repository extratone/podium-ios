//
//  Toggle+Extensions.swift
//  outsider
//
//  Created by Michael Jach on 25/09/2024.
//

import SwiftUI

struct PrimaryCheckbox: ToggleStyle {
  func makeBody(configuration: Configuration) -> some View {
    Button(action: {
      configuration.isOn.toggle()
    }, label: {
      HStack {
        Image(systemName: configuration.isOn ? "dot.circle" : "circle")
        
        configuration.label
      }
      .foregroundStyle(.colorTextPrimary)
    })
  }
}
