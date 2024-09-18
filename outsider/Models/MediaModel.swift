//
//  MediaModel.swift
//  outsider
//
//  Created by Michael Jach on 11/09/2024.
//

import Foundation

struct MediaModel: Codable, Equatable, Identifiable {
  var id: UUID { uuid }
  let uuid: UUID
  let url: String
  let post_uuid: UUID
}

struct PostMediaInsert: Codable {
  let post_uuid: UUID
  let media_uuid: UUID
}
