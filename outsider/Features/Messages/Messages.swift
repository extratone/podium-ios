//
//  Messages.swift
//  Podium
//
//  Created by Michael Jach on 22/06/2024.
//

import ComposableArchitecture
import Supabase
import Foundation

@Reducer
struct Messages {
  @Dependency(\.supabase) var supabase
  
  @Reducer(state: .equatable)
  enum Path {
    case chat(Chat)
  }
  
  @ObservableState
  struct State {
    var currentUser: CurrentUserModel
    var chatsChannel: RealtimeChannelV2?
    var messagesChannel: RealtimeChannelV2?
    
    // Sab states
    @Presents var newMessage: NewMessage.State?
    var chats: IdentifiedArrayOf<Chat.State> = []
    var path = StackState<Path.State>()
  }
  
  enum Action: Sendable {
    case initialize
    case subscribeChats
    case onSubscribeChats(RealtimeChannelV2)
    case unsubscribeChats
    case subscribeMessages
    case onSubscribeMessages(RealtimeChannelV2)
    case unsubscribeMessages
    case onInsertChat(Result<ChatModel, Error>)
    case onInsertMessage(Result<MessageModel, Error>)
    case fetchChats
    case didFetchChats(Result<[ChatModel], Error>)
    case presentChat(ChatModel)
    case presentNewMessage
    case didSendMessage(Result<MessageModel, Error>)
    case createChat([FollowingModel], String?)
    case sendMessage(chatUuid: UUID, text: String?)
    
    // Sub actions
    case chats(IdentifiedActionOf<Chat>)
    case path(StackActionOf<Path>)
    case newMessage(PresentationAction<NewMessage.Action>)
  }
  
  private enum CancelID {
    case messagesSubscribe
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .initialize:
        return .merge(
          .run { send in
            await send(.fetchChats)
          }
        )
        
      case .createChat(let tokens, let text):
        return .run { send in
          do {
            let chatUuid = UUID()
            
            try await supabase
              .from("chats")
              .insert(ChatModelInsert(
                uuid: chatUuid,
                members: tokens.map({ $0.following.uuid }),
                discovery_string: tokens
                  .map({ $0.following.uuid.uuidString })
                  .sorted()
                  .joined(separator: "_")
              ))
              .execute()
            
            for token in tokens {
              try await supabase
                .from("chats_users")
                .insert(ChatUserModel(
                  chat_uuid: chatUuid,
                  user_uuid: token.following.uuid
                ))
                .execute()
            }
            
            await send(.sendMessage(chatUuid: chatUuid, text: text))
          } catch {
            print(error)
          }
        }
        
      case .sendMessage(let chatUuid, let text):
        return .run { [currentUser = state.currentUser] send in
          do {
            let messageUuid = UUID()
            
            try await supabase
              .from("messages")
              .insert(MessageModelPlain(
                uuid: messageUuid,
                created_at: Date.now.ISO8601Format(),
                author_uuid: currentUser.uuid,
                chat_uuid: chatUuid,
                text: text,
                type: .text,
                url: nil,
                author: currentUser.display_name ?? currentUser.username
              ))
              .execute()
          } catch {
            print(error)
          }
        }
        
      case .newMessage(.presented(.send(let tokens, let message))):
        var members = tokens
        members.append(FollowingModel(following: state.currentUser.base))
        
        return .run { [members = members] send in
          do {
            let chat: ChatModel = try await supabase
              .from("chats")
              .select(
                """
                  *,
                  users(*),
                  discovery_string
                """
              )
              .eq("discovery_string,", value: members
                .map({ $0.following.uuid.uuidString })
                .sorted()
                .joined(separator: "_"))
              .limit(1)
              .single()
              .execute()
              .value
            
            await send(.sendMessage(chatUuid: chat.uuid, text: message))
          } catch {
            if let error = error as? PostgrestError {
              switch error.code {
              case "PGRST116":
                await send(.createChat(members, message))
                break
                
              default:
                await send(.didSendMessage(.failure(error)))
              }
            } else {
              await send(.didSendMessage(.failure(error)))
            }
          }
        }
        
      case .didSendMessage(.success(_)):
        return .none
        
      case .didSendMessage(.failure(let error)):
        print(error)
        return .none
        
      case .newMessage:
        return .none
        
      case .presentNewMessage:
        state.newMessage = NewMessage.State(
          currentUser: state.currentUser
        )
        return .none
        
      case .subscribeChats:
        guard state.chatsChannel?.status != .subscribed else { return .none }
        
        return .run { [currentUser = state.currentUser] send in
          let channel = supabase.channel("chats-\(currentUser.uuid.uuidString)")
          
          let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "chats_users",
            filter: "user_uuid=eq.\(currentUser.uuid)"
          )
          
          await channel.subscribe()
          await send(.onSubscribeChats(channel))
          
          for await insertAction in insertions {
            do {
              let jsonData = try JSONEncoder().encode(insertAction.record)
              let chatUser = try JSONDecoder().decode(ChatUserModel.self, from: jsonData)
              
              let chat: ChatModel = try await supabase
                .from("chats")
                .select(
                  """
                    uuid,
                    discovery_string,
                    members,
                    users(*),
                    messages(*)
                  """
                )
                .eq("uuid", value: chatUser.chat_uuid)
                .order("created_at", ascending: false, nullsFirst: false, referencedTable: "messages")
                .limit(1, referencedTable: "messages")
                .single()
                .execute()
                .value
              
              await send(.onInsertChat(.success(chat)))
            } catch {
              await send(.onInsertChat(.failure(error)))
            }
          }
        }
        
      case .onInsertChat(.success(let chat)):
        state.chats.insert(Chat.State(
          currentUser: state.currentUser,
          chat: chat
        ), at: 0)
        return .run { send in
          await send(.unsubscribeMessages)
          await send(.subscribeMessages)
        }
        
      case .onInsertChat(.failure(let error)):
        print(error)
        return .none
        
      case .onSubscribeChats(let channel):
        state.chatsChannel = channel
        return .none
        
      case .unsubscribeChats:
        return .run { [chatsChannel = state.chatsChannel] send in
          await chatsChannel?.unsubscribe()
        }
        
      case .subscribeMessages:
        guard !state.chats.isEmpty else { return .none }
        guard state.messagesChannel?.status != .subscribed else { return .none }
        
        return .run { [chats = state.chats, currentUser = state.currentUser] send in
          let channel = supabase.channel("messages-\(currentUser.uuid.uuidString)")
          
          let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "messages",
            filter: "chat_uuid=in.(\(chats.map({ $0.chat.uuid.uuidString }).joined(separator: ", ")))"
          )
          
          await channel.subscribe()
          await send(.onSubscribeMessages(channel))
          
          for await insertAction in insertions {
            do {
              let jsonData = try JSONEncoder().encode(insertAction.record)
              let messagePlain = try JSONDecoder().decode(MessageModelPlain.self, from: jsonData)
              
              let message: MessageModel = try await supabase
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
                .eq("uuid", value: messagePlain.uuid)
                .single()
                .execute()
                .value
              
              await send(.onInsertMessage(.success(message)))
            } catch {
              await send(.onInsertMessage(.failure(error)))
            }
          }
        }
        
      case .onInsertMessage(.success(let message)):
        state.chats[id: message.chat_uuid]?.chat.messages.append(message)
        
        if let index = state.path.firstIndex(where: { $0.chat?.chat.uuid == message.chat_uuid }) {
          let id = state.path.ids[index]
          return .run { send in
            await send(.path(.element(id: id, action: .chat(.insertMessage(message)))))
          }
        }
        return .none
        
      case .onInsertMessage(.failure(let error)):
        print(error)
        return .none
        
      case .onSubscribeMessages(let channel):
        state.messagesChannel = channel
        return .none
        
      case .unsubscribeMessages:
        return .run { [messagesChannel = state.messagesChannel] send in
          await messagesChannel?.unsubscribe()
        }
        
      case .presentChat(let chat):
        state.path.append(
          .chat(Chat.State(
            currentUser: state.currentUser,
            chat: chat
          )))
        return .none
        
      case .fetchChats:
        return .run { [currentUser = state.currentUser] send in
          await send(.unsubscribeChats)
          await send(.unsubscribeMessages)
          
          do {
            let chats: [ChatModel] = try await supabase
              .from("chats")
              .select(
                """
                  uuid,
                  discovery_string,
                  members,
                  users(*),
                  messages(*, readBy:messages_stats(*))
                """
              )
              .contains("members", value: "{\(currentUser.uuid.uuidString)}")
              .order("created_at", ascending: false, nullsFirst: false, referencedTable: "messages")
              .limit(20, referencedTable: "messages")
              .execute()
              .value
            
            await send(.didFetchChats(.success(chats)))
          } catch {
            await send(.didFetchChats(.failure(error)))
          }
        }
        
      case .didFetchChats(.success(let chats)):
        var temp: IdentifiedArrayOf<Chat.State> = []
        for chat in chats {
          temp.append(Chat.State(
            currentUser: state.currentUser,
            chat: chat
          ))
        }
        state.chats = temp
        return .run { send in
          await send(.subscribeChats)
          await send(.subscribeMessages)
        }
        
      case .didFetchChats(.failure(let error)):
        print(error)
        return .none
      
      case .path(.element(_, action: .chat(.didMarkAsRead(.success(let stats))))),
          .chats(.element(_, action: .didMarkAsRead(.success(let stats)))):
        if let id = stats.first?.chat_uuid,
          var temp = state.chats[id: id]?.chat.messages {
          stats.forEach { stat in
            temp = temp.map { message in
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
          state.chats[id: id]?.chat.messages = temp
        }
        return .none
        
      case .chats(_):
        return .none
        
      case .path(.element(_, action: .chat(.didFetchMessages(.success(let messages))))):
        if let id = messages.first?.chat_uuid {
          state.chats[id: id]?.chat.messages = messages
        }
        return .none
        
      case .path:
        return .none
      }
    }
    .forEach(\.chats, action: \.chats) {
      Chat()
    }
    .forEach(\.path, action: \.path)
    .ifLet(\.$newMessage, action: \.newMessage) {
      NewMessage()
    }
  }
}
