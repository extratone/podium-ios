//
//  CommentModel.swift
//  outsider
//
//  Created by Michal Jach on 28/09/2024.
//

import Foundation

struct CommentModel: Codable, Equatable, Identifiable {
  var id: UUID { comment.uuid }
  let comment: PostModel
  let created_at: Date
}

struct PostCommentModelInsert: Codable, Equatable {
  let post_uuid: UUID
  let comment_uuid: UUID
}
