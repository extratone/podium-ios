//
//  MessageStatsModel.swift
//  outsider
//
//  Created by Michael Jach on 25/09/2024.
//

import Foundation

struct MessageStatsModel: Codable, Equatable {
  let uuid: UUID
  let message_uuid: UUID
  let read_by: UUID
  let chat_uuid: UUID
}

struct MessageStatsModelInsert: Codable {
  let uuid: UUID
  let message_uuid: UUID
  let read_by: UUID
  let chat_uuid: UUID
}
