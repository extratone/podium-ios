//
//  UserModel.swift
//  outsider
//
//  Created by Michael Jach on 09/09/2024.
//

import Foundation

struct UserModel: Codable, Equatable, Hashable {
  let uuid: UUID
  let username: String
  let display_name: String?
  let avatar_url: URL?
  var following: [UUID]
}
