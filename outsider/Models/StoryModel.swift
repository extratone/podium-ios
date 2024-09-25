//
//  StoryModel.swift
//  outsider
//
//  Created by Michael Jach on 18/09/2024.
//

import Foundation

enum StoryType: String, Codable {
  case photo
  case video
}

struct StoryModel: Codable, Equatable, Identifiable, Hashable {
  var id: UUID { uuid }
  let uuid: UUID
  let author: UserModel
  let url: URL
  let created_at: Date
  let type: StoryType
  var stats: [StoryStatsModel]?
}

struct StoryModelInsert: Codable {
  let uuid: UUID
  let author_uuid: UUID
  let url: URL
  let type: StoryType
}
