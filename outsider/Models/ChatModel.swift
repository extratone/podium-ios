//
//  ChatModel.swift
//  outsider
//
//  Created by Michael Jach on 23/09/2024.
//

import Foundation

struct ChatModel: Equatable, Codable, Identifiable {
  var id: UUID { uuid }
  let uuid: UUID
  let users: [UserModel]
  var messages: [MessageModel]
  let discovery_string: String
  let members: [UUID]
}

struct ChatModelInsert: Equatable, Codable {
  let uuid: UUID
  let members: [UUID]
  let discovery_string: String
}

struct ChatMessageModel: Codable {
  let chat_uuid: UUID
  let message_uuid: UUID
}

struct ChatUserModel: Codable {
  let chat_uuid: UUID
  let user_uuid: UUID
}
