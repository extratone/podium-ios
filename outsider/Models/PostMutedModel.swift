//
//  PostMutedModel.swift
//  outsider
//
//  Created by Michal Jach on 02/10/2024.
//

import Foundation

struct PostMutedModel: Codable, Hashable, Equatable {
  let post_uuid: UUID
  let user_uuid: UUID
}
