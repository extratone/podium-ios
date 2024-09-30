//
//  PostModel.swift
//  outsider
//
//  Created by Michael Jach on 11/09/2024.
//

import Foundation

struct PostModel: Codable, Equatable, Identifiable {
  var id: UUID { uuid }
  let uuid: UUID
  let created_at: Date
  let text: String?
  let author: UserModel
  let media: [MediaModel]?
  var likes: [LikeModel]?
  var comments: [CommentModel]?
  var commentsPlain: [PostCommentModelInsert]?
  let is_comment: Bool
}

struct PostModelInsert: Codable {
  let uuid: UUID
  let text: String?
  let author: UUID
  let is_comment: Bool
}
