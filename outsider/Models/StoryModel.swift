//
//  StoryModel.swift
//  outsider
//
//  Created by Michael Jach on 18/09/2024.
//

import Foundation

enum MediaType: String, Codable {
  case photo
  case video
  case text
}

struct StoryModel: Codable, Equatable, Identifiable, Hashable {
  var id: UUID { uuid }
  let uuid: UUID
  let author: UserModel
  let url: URL
  let created_at: Date
  let type: MediaType
  var stats: [StoryStatsModel]
}

struct StoryModelInsert: Codable {
  let uuid: UUID
  let author_uuid: UUID
  let url: URL
  let type: MediaType
}
