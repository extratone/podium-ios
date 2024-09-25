//
//  FollowingModel.swift
//  outsider
//
//  Created by Michael Jach on 24/09/2024.
//

import Foundation

struct FollowingModel: Codable, Equatable, Hashable, Identifiable {
  var id: UUID { following.uuid }
  let following: UserModel
}

struct FollowingModelInsert: Codable {
  let user_uuid: UUID
  let following_user_uuid: UUID
}
