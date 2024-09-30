//
//  MessageModel.swift
//  outsider
//
//  Created by Michael Jach on 23/09/2024.
//

import Foundation

struct MessageModel: Equatable, Codable, Identifiable {
  var id: UUID { uuid }
  let uuid: UUID
  let created_at: Date
  let author_uuid: UUID
  let chat_uuid: UUID
  let text: String?
  var readBy: [MessageStatsModel]
  let type: MediaType
  let url: URL?
}

struct MessageModelPlain: Equatable, Codable, Identifiable {
  var id: UUID { uuid }
  let uuid: UUID
  let created_at: String
  let author_uuid: UUID
  let chat_uuid: UUID
  let text: String?
  let type: MediaType
  let url: URL?
  let author: String
}
