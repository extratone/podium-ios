//
//  CameraSend.swift
//  outsider
//
//  Created by Michael Jach on 25/09/2024.
//

import SwiftUI
import ComposableArchitecture
import Supabase

@Reducer
struct CameraSend {
  @Dependency(\.supabase) var supabase
  
  @ObservableState
  struct State: Equatable {
    var currentUser: UserModel
    var following: IdentifiedArrayOf<CameraSendRecipient.State>
    var addStory = false
    var mediaData: Data?
    var mediaType: MediaType?
    var isEnabled: Bool {
      !following.filter({ $0.selected }).isEmpty || addStory
    }
    
    init(currentUser: UserModel) {
      self.currentUser = currentUser
      var following: IdentifiedArrayOf<CameraSendRecipient.State> = []
      currentUser.following?.forEach({ followingModel in
        following.append(CameraSendRecipient.State(
          following: followingModel
        ))
      })
      self.following = following
      self.addStory = false
    }
  }
  
  enum Action {
    case onAddStoryChange(Bool)
    case send
    case sendStory(MediaType, URL)
    case didSendStory(Result<StoryModel, Error>)
    case sendMessages([UserModel], MediaType, URL)
    case didSendMessages
    case createChat([UserModel], MediaType, URL)
    case didCreateChat(Result<(ChatModel, MediaType, URL), Error>)
    case sendMessage(UUID, MediaType, URL)
    case didSendMessage(Result<MessageModel, Error>)
    case uploadMedia
    case didUploadMedia(Result<(UUID, URL, MediaType), Error>)
    
    // Sub states
    case following(IdentifiedActionOf<CameraSendRecipient>)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .send:
        return .run { send in
          await send(.uploadMedia)
        }
        
      case .uploadMedia:
        guard let mediaData = state.mediaData else { return .none }
        guard let mediaType = state.mediaType else { return .none }
        let fileExtension = mediaType == .photo ? "jpg" : "mp4"
        return .run { send in
          do {
            let mediaUuid = UUID()
            try await supabase.storage
              .from("media")
              .upload(
                path: "\(mediaUuid)/\(mediaUuid).\(fileExtension)",
                file: mediaData,
                options: FileOptions(upsert: true)
              )
            
            let publicURL = try supabase.storage
              .from("media")
              .getPublicURL(path: "\(mediaUuid)/\(mediaUuid).\(fileExtension)")
            
            await send(.didUploadMedia(.success((mediaUuid, publicURL, mediaType))))
          } catch {
            await send(.didUploadMedia(.failure(error)))
          }
        }
        
      case .didUploadMedia(.success((_, let mediaUrl, let mediaType))):
        let recipients = state
          .following
          .filter({ $0.selected })
          .map({ $0.following.following })
        
        return .merge(
          .run { [addStory = state.addStory] send in
            if addStory {
              await send(.sendStory(mediaType, mediaUrl))
            }
          },
          .run { send in
            if !recipients.isEmpty {
              await send(.sendMessages(recipients, mediaType, mediaUrl))
            }
          }
        )
        
      case .didUploadMedia(.failure(let error)):
        print(error)
        return .none
        
      case .sendStory(let mediaType, let mediaUrl):
        state.addStory = false
        return .run { [currentUser = state.currentUser] send in
          do {
            let storyUuid = UUID()
            
            let story: StoryModel = try await supabase
              .from("stories")
              .insert(StoryModelInsert(
                uuid: storyUuid,
                author_uuid: currentUser.uuid,
                url: mediaUrl,
                type: mediaType
              ))
              .select(
                """
                  uuid,
                  url,
                  type,
                  created_at,
                  author:users(*),
                  stats:stories_stats(*)
                """
              )
              .single()
              .execute()
              .value
            
            await send(.didSendStory(.success(story)))
          } catch {
            await send(.didSendStory(.failure(error)))
          }
        }
        
      case .didSendStory(.success(_)):
        return .none
        
      case .didSendStory(.failure(let error)):
        print(error)
        return .none
        
      case .createChat(let members, let mediaType, let mediaUrl):
        return .run { send in
          do {
            let chatUuid = UUID()
            try await supabase
              .from("chats")
              .insert(ChatModelInsert(
                uuid: chatUuid,
                members: members.map({ $0.uuid }),
                discovery_string: members
                  .map({ $0.uuid.uuidString })
                  .sorted()
                  .joined(separator: "_")
              ))
              .execute()
            
            try await supabase
              .from("chats_users")
              .insert(ChatUserModel(
                chat_uuid: chatUuid,
                user_uuid: members[0].uuid
              ))
              .execute()
            
            try await supabase
              .from("chats_users")
              .insert(ChatUserModel(
                chat_uuid: chatUuid,
                user_uuid: members[1].uuid
              ))
              .execute()
            
            let model = ChatModel(
              uuid: chatUuid,
              users: members,
              discovery_string: members
                .map({ $0.uuid.uuidString })
                .sorted()
                .joined(separator: "_"),
              members: members.map({ $0.uuid })
            )
            
            await send(.didCreateChat(.success((model, mediaType, mediaUrl))))
          } catch {
            await send(.didCreateChat(.failure(error)))
          }
        }
        
      case .didCreateChat(.success((let chat, let mediaType, let mediaUrl))):
        return .run { send in
          await send(.sendMessage(chat.uuid, mediaType, mediaUrl))
        }
        
      case .didCreateChat(.failure(let error)):
        print(error)
        return .none
        
      case .sendMessage(let chatUuid, let mediaType, let mediaUrl):
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
                text: nil,
                type: mediaType,
                url: mediaUrl
              ))
              .execute()
            
            let statUuid = UUID()
            try await supabase
              .from("messages_stats")
              .insert(MessageStatsModelInsert(
                uuid: statUuid,
                message_uuid: messageUuid,
                read_by: currentUser.uuid,
                chat_uuid: chatUuid
              ))
              .execute()
            
            let model = MessageModel(
              uuid: messageUuid,
              created_at: .now,
              author_uuid: currentUser.uuid,
              chat_uuid: chatUuid,
              text: nil,
              readBy: [MessageStatsModel(
                uuid: statUuid,
                message_uuid: messageUuid,
                read_by: currentUser.uuid,
                chat_uuid: chatUuid
              )],
              type: mediaType,
              url: mediaUrl
            )
            
            await send(.didSendMessage(.success(model)))
          } catch {
            await send(.didSendMessage(.failure(error)))
          }
        }
        
      case .didSendMessage(.success(_)):
        return .none
        
      case .didSendMessage(.failure(let error)):
        print(error)
        return .none
        
      case .sendMessages(let recipients, let mediaType, let mediaUrl):
        return .run { [currentUser = state.currentUser] send in
          do {
            // Check if Chat exists for each recipient
            try await withThrowingTaskGroup(of: (UUID, Bool).self) { group in
              for recipient in recipients {
                let members = [recipient, currentUser]
                
                group.addTask {
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
                        .map({ $0.uuid.uuidString })
                        .sorted()
                        .joined(separator: "_"))
                      .limit(1)
                      .single()
                      .execute()
                      .value
                    
                    await send(.sendMessage(chat.uuid, mediaType, mediaUrl))
                  } catch {
                    if let error = error as? PostgrestError {
                      switch error.code {
                      case "PGRST116":
                        await send(.createChat(members, mediaType, mediaUrl))
                        break
                        
                      default:
                        break
                      }
                    } else {
                      print(error)
                    }
                  }

                  return (UUID(), true)
                }
              }
              
              var chats = [UUID: Bool]()
              
              for try await (uuid, bl) in group {
                chats[uuid] = bl
              }
              
              return chats
            }
            
            await send(.didSendMessages)
          } catch {
            print(error)
          }
        }
        
      case .didSendMessages:
        state.following = IdentifiedArray(uniqueElements: state.following.map({ followingState in
          var temp = followingState
          temp.selected = false
          return temp
        }))
        return .none
        
      case .onAddStoryChange(let selected):
        state.addStory = selected
        return .none
        
      case .following(_):
        return .none
      }
    }
    .forEach(\.following, action: \.following) {
      CameraSendRecipient()
    }
  }
}
