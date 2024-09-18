//
//  Mocks.swift
//  outsider
//
//  Created by Michael Jach on 11/09/2024.
//

import Foundation

class Mocks {
  static let user = UserModel(
    uuid: UUID(),
    username: "username",
    display_name: "Display Name",
    avatar_url: nil
  )
  static let media = MediaModel(
    uuid: UUID(),
    url: "https://images.unsplash.com/photo-1566264956500-0549ed17e161?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max&ixid=eyJhcHBfaWQiOjEyMDd9",
    post_uuid: UUID()
  )
  static let post = PostModel(
    uuid: UUID(),
    created_at: Date.distantPast,
    text: """
    Hello World!
    Powiedz jak leci?
    """,
    author: user,
    media: [
      media, media
    ],
    likes: []
  )
  static let story = StoryModel(
    uuid: UUID(),
    author: user,
    url: URL(string: "https://images.unsplash.com/photo-1566264956500-0549ed17e161?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max&ixid=eyJhcHBfaWQiOjEyMDd9")!,
    type: .photo,
    stats: nil
  )
}
