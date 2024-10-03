//
//  UserModel.swift
//  outsider
//
//  Created by Michael Jach on 09/09/2024.
//

import Foundation

struct UserModel: Codable, Equatable, Hashable, Identifiable {
  var id: UUID { uuid }
  let uuid: UUID
  let username: String
  var display_name: String?
  let avatar_url: URL?
  var following: [FollowingModel]?
}

struct CurrentUserModel: Codable, Equatable, Hashable, Identifiable {
  var id: UUID { uuid }
  let uuid: UUID
  let username: String
  var display_name: String?
  var fcm_tokens: [String]
  let avatar_url: URL?
  var following: [FollowingModel] = []
  var mutedPosts: [PostMutedModel] = []
  
  var base: UserModel {
    UserModel(
      uuid: uuid,
      username: username,
      display_name: display_name,
      avatar_url: avatar_url,
      following: following
    )
  }
}

struct CurrentUserModelInsert: Codable, Equatable, Hashable, Identifiable {
  var id: UUID { uuid }
  let uuid: UUID
  let username: String
  var display_name: String?
  var fcm_tokens: [String]
  let avatar_url: URL?
}
