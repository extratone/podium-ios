//
//  LikeModel.swift
//  outsider
//
//  Created by Michael Jach on 15/09/2024.
//

import Foundation

struct LikeModel: Codable, Equatable {
  let uuid: UUID
  let post_uuid: UUID
  let liked_by: UUID
}
