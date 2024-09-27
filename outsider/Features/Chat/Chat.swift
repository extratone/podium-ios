//
//  Chat.swift
//  min
//
//  Created by Michael Jach on 27/06/2024.
//

import ComposableArchitecture
import Foundation
import Supabase

@Reducer
struct Chat {
  @Dependency(\.supabase) var supabase
  
  @ObservableState
  struct State: Equatable, Identifiable {
    var id: UUID { chat.uuid }
    var currentUser: UserModel
    var chat: ChatModel
    var message = ""
    var title: String {
      chat
        .users
        .filter({ $0.uuid != currentUser.uuid })
        .map({ $0.display_name ?? $0.username })
        .joined(separator: ", ")
    }
    var unreadCount: Int {
      chat.messages?.count(where: { message in
        !message.readBy.contains(where: { $0.read_by == currentUser.uuid })
      }) ?? 0
    }
    
    // Sub states
    @Presents var media: Media.State?
  }
  
  enum Action: Sendable {
    case initialize
    case fetchMessages
    case didFetchMessages(Result<[MessageModel], Error>)
    case messageChanged(String)
    case sendMessage
    case didSendMessage(Result<MessageModel, Error>)
    case insertMessage(MessageModel)
    case markAsRead
    case didMarkAsRead(Result<[MessageStatsModelInsert], Error>)
    case presentMedia(MessageModel)
    
    // Sub actions
    case media(PresentationAction<Media.Action>)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .initialize:
        return .run { send in
          await send(.markAsRead)
//          await send(.fetchMessages)
        }
        
      case .presentMedia(let message):
        if let url = message.url {
          state.media = Media.State(media: MediaModel(
            uuid: message.uuid,
            url: url.absoluteString,
            post_uuid: message.uuid
          ))
        }
        return .none
        
      case .markAsRead:
        return .run { [chat = state.chat, currentUser = state.currentUser, messages = state.chat.messages] send in
          do {
            if let stats = messages?
              .filter({ !$0.readBy.contains(where: { $0.uuid == currentUser.uuid }) })
              .map({ message in
                MessageStatsModelInsert(
                  uuid: UUID(),
                  message_uuid: message.uuid,
                  read_by: currentUser.uuid,
                  chat_uuid: chat.uuid
                )
              }) {
              try await supabase
                .from("messages_stats")
                .insert(stats)
                .execute()
              
              await send(.didMarkAsRead(.success(stats)))
            }
          } catch {
            await send(.didMarkAsRead(.failure(error)))
          }
        }
        
      case .didMarkAsRead(.success(let stats)):
        var temp = state.chat.messages
        stats.forEach { stat in
          temp = temp?.map { message in
            if message.uuid == stat.message_uuid {
              var tmp = message
              tmp.readBy.append(MessageStatsModel(
                uuid: stat.uuid,
                message_uuid: stat.message_uuid,
                read_by: stat.read_by,
                chat_uuid: stat.chat_uuid
              ))
              return tmp
            }
            return message
          }
        }
        state.chat.messages = temp
        return .none
        
      case .didMarkAsRead(.failure(let error)):
        print(error)
        return .none
        
      case .insertMessage(let message):
        if state.chat.messages == nil {
          state.chat.messages = []
        }
        state.chat.messages?.append(message)
        return .none
        
      case .messageChanged(let message):
        state.message = message
        return .none
        
      case .sendMessage:
        let text = state.message
        state.message = ""
        return .run { [text = text, chat = state.chat, currentUser = state.currentUser] send in
          do {
            let messageUuid = UUID()
            let messageStatUuid = UUID()
            let message = MessageModel(
              uuid: messageUuid,
              created_at: .now,
              author_uuid: currentUser.uuid,
              chat_uuid: chat.uuid,
              text: text,
              readBy: [MessageStatsModel(
                uuid: messageStatUuid,
                message_uuid: messageUuid,
                read_by: currentUser.uuid,
                chat_uuid: chat.uuid
              )],
              type: .text,
              url: nil
            )
            
            try await supabase
              .from("messages")
              .insert(MessageModelPlain(
                uuid: message.uuid,
                created_at: message.created_at.ISO8601Format(),
                author_uuid: message.author_uuid,
                chat_uuid: message.chat_uuid,
                text: message.text,
                type: message.type,
                url: message.url
              ))
              .execute()
            
            try await supabase
              .from("messages_stats")
              .insert(MessageStatsModelInsert(
                uuid: messageStatUuid,
                message_uuid: messageUuid,
                read_by: currentUser.uuid,
                chat_uuid: chat.uuid
              ))
              .execute()
            
            await send(.didSendMessage(.success(message)))
          } catch {
            await send(.didSendMessage(.failure(error)))
          }
        }
        
      case .didSendMessage(.success(_)):
        return .none
        
      case .didSendMessage(.failure(let error)):
        print(error)
        return .none
        
      case .fetchMessages:
        return .run { [chat = state.chat] send in
          do {
            let messages: [MessageModel] = try await supabase
              .from("messages")
              .select(
                """
                  uuid,
                  text,
                  author_uuid,
                  created_at,
                  type,
                  url,
                  readBy:messages_stats(*),
                  chat_uuid
                """
              )
              .eq("chat_uuid", value: chat.uuid)
              .order("created_at", ascending: false)
              .limit(20)
              .execute()
              .value
            
            await send(.didFetchMessages(.success(messages)))
          } catch {
            await send(.didFetchMessages(.failure(error)))
          }
        }
        
      case .didFetchMessages(.success(let messages)):
        state.chat.messages = messages
        return .run { send in
          await send(.markAsRead)
        }
        
      case .didFetchMessages(.failure(let error)):
        print(error)
        return .none
        
      case .media:
        return .none
      }
    }
    .ifLet(\.$media, action: \.media) {
      Media()
    }
  }
}
