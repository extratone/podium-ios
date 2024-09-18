//
//  Date+Extensions.swift
//  outsider
//
//  Created by Michael Jach on 11/09/2024.
//

import Foundation

extension Date {
  func timeAgoDisplay() -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .abbreviated
    return formatter.localizedString(for: self, relativeTo: Date())
  }
}
