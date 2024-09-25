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
  }
  
  enum Action: Sendable {
    case initialize
    case fetchMessages
    case didFetchMessages(Result<[MessageModel], Error>)
    case messageChanged(String)
    case sendMessage
    case didSendMessage(Result<MessageModel, Error>)
    case insertMessage(MessageModel)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .initialize:
        return .run { send in
          await send(.fetchMessages)
        }
        
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
            let message = MessageModel(
              uuid: UUID(),
              created_at: .now,
              author_uuid: currentUser.uuid,
              chat_uuid: chat.uuid,
              text: text
            )
            
            try await supabase
              .from("messages")
              .insert(message)
              .execute()
            
            try await supabase
              .from("chats_messages")
              .insert(ChatMessageModel(
                chat_uuid: chat.uuid,
                message_uuid: message.uuid
              ))
              .execute()
            
            await send(.didSendMessage(.success(message)))
          } catch {
            await send(.didSendMessage(.failure(error)))
          }
        }
        
      case .didSendMessage(.success(let message)):
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
                  chat_uuid
                """
              )
              .eq("chat_uuid", value: chat.uuid)
              .execute()
              .value
            
            await send(.didFetchMessages(.success(messages)))
          } catch {
            await send(.didFetchMessages(.failure(error)))
          }
        }
        
      case .didFetchMessages(.success(let messages)):
        state.chat.messages = messages
        return .none
        
      case .didFetchMessages(.failure(let error)):
        print(error)
        return .none
      }
    }
  }
}
