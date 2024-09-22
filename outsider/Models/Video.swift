//
//  Video.swift
//  outsider
//
//  Created by Michael Jach on 21/09/2024.
//

import Foundation
import SwiftUI

struct Video: Transferable, Equatable {
  let url: URL
  
  static var transferRepresentation: some TransferRepresentation {
    FileRepresentation(contentType: .movie) { movie in
      SentTransferredFile(movie.url)
    } importing: { received in
      let copy = URL.documentsDirectory.appending(path: "movie.mp4")
      
      if FileManager.default.fileExists(atPath: copy.path()) {
        try FileManager.default.removeItem(at: copy)
      }
      
      try FileManager.default.copyItem(at: received.file, to: copy)
      return Self.init(url: copy)
    }
  }
}
