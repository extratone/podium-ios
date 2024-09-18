//
//  View+Extensions.swift
//  outsider
//
//  Created by Michael Jach on 11/09/2024.
//

import SwiftUI

extension View {
  func endTextEditing() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                    to: nil, from: nil, for: nil)
  }
}
