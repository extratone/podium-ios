//
//  CIImage+Extensions.swift
//  min
//
//  Created by Michael Jach on 10/07/2024.
//

import SwiftUI

extension CIImage {
  var image: Image? {
    let ciContext = CIContext()
    guard let cgImage = ciContext.createCGImage(self, from: self.extent) else { return nil }
    return Image(decorative: cgImage, scale: 1, orientation: .up)
  }
}
