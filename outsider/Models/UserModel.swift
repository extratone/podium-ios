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
