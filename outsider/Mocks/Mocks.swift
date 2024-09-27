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
    avatar_url: nil,
    following: [
      FollowingModel(following: UserModel(
        uuid: UUID(),
        username: "test",
        display_name: "Test User",
        avatar_url: nil
      )),
      FollowingModel(following: UserModel(
        uuid: UUID(),
        username: "test1",
        display_name: nil,
        avatar_url: nil
      ))
    ]
  )
  static let otherUser = UserModel(
    uuid: UUID(),
    username: "username2",
    display_name: "Display Name 2",
    avatar_url: nil,
    following: []
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
    created_at: .now,
    type: .photo,
    stats: nil
  )
  static let chat = ChatModel(
    uuid: UUID(),
    users: [Mocks.user, Mocks.otherUser],
    messages: [photoMessage, message, ownMessage],
    discovery_string: "xxx",
    members: [Mocks.user.uuid]
  )
  static let chat1 = ChatModel(
    uuid: UUID(),
    users: [Mocks.user, Mocks.otherUser],
    messages: [message, ownMessage],
    discovery_string: "xxx1",
    members: [Mocks.user.uuid]
  )
  static let photoMessage = MessageModel(
    uuid: UUID(),
    created_at: .now,
    author_uuid: UUID(),
    chat_uuid: UUID(),
    text: "Hello World",
    readBy: [],
    type: .photo,
    url: URL(string: "https://images.unsplash.com/photo-1566264956500-0549ed17e161?ixlib=rb-1.2.1&q=80&fm=jpg&crop=entropy&cs=tinysrgb&w=1080&fit=max&ixid=eyJhcHBfaWQiOjEyMDd9")!
  )
  static let message = MessageModel(
    uuid: UUID(),
    created_at: .now,
    author_uuid: UUID(),
    chat_uuid: UUID(),
    text: "Hello World",
    readBy: [],
    type: .text,
    url: nil
  )
  static let ownMessage = MessageModel(
    uuid: UUID(),
    created_at: .now,
    author_uuid: user.uuid,
    chat_uuid: UUID(),
    text: "Own message",
    readBy: [],
    type: .text,
    url: nil
  )
}
