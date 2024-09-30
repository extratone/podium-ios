//
//  Tabs.swift
//  outsider
//
//  Created by Michael Jach on 09/09/2024.
//

import SwiftUI
import ComposableArchitecture
import Supabase
import FirebaseMessaging

@Reducer
struct Tabs {
  enum TabSelection: String {
    case home
    case explore
    case messages
    case currentProfile
  }
  
  @Dependency(\.supabase) var supabase
  
  @ObservableState
  struct State {
    var currentUser: UserModel
    var bannerData = BannerModifier.BannerData(title: "", detail: "", type: .Info)
    var showBanner = false
    var selection: Int?
    var tabSelection: TabSelection = .home
    var channel: RealtimeChannelV2?
    var unreadCount: Int {
      messages.chats.count { chat in
        chat.chat.messages?.contains(where: { message in
          !message.readBy.contains(where: { $0.read_by == currentUser.uuid })
        }) ?? false
      }
    }
    
    // Sub states
    var camera: Camera.State
    var home: Home.State
    var explore: Explore.State
    var messages: Messages.State
    var currentProfile: CurrentProfile.State
  }
  
  enum Action {
    case initialize
    case subscribeStories
    case onSubscribeStories(RealtimeChannelV2)
    case unsubscribeStories
    case onUnsubscribeStories
    case showBannerChanged(Bool)
    case bannerDataChanged(BannerModifier.BannerData)
    case handleBadSession
    case onSelectionChanged(Int?)
    case onTabSelectionChanged(TabSelection)
    case onInsertStory(Result<StoryModel, Error>)
    case registerNotifications
    case synchronizeToken(String)
    case didSynchronizeToken(Result<[String], Error>)
    
    // Sub actions
    case camera(Camera.Action)
    case home(Home.Action)
    case explore(Explore.Action)
    case messages(Messages.Action)
    case currentProfile(CurrentProfile.Action)
  }
  
  var body: some Reducer<State, Action> {
    Reduce { state, action in
      switch action {
      case .synchronizeToken(let token):
        if !state.currentUser.fcm_tokens.contains(token) {
          state.currentUser.fcm_tokens.append(token)
        }
        return .run { [currentUser = state.currentUser] send in
          do {
            try await supabase
              .from("users")
              .update(["fcm_tokens": currentUser.fcm_tokens])
              .eq("uuid", value: currentUser.uuid)
              .execute()
            
            await send(.didSynchronizeToken(.success(currentUser.fcm_tokens)))
          } catch {
            await send(.didSynchronizeToken(.failure(error)))
          }
        }
        
      case .didSynchronizeToken(.success(let tokens)):
        state.currentUser.fcm_tokens = tokens
        if let encoded = try? JSONEncoder().encode(state.currentUser) {
          UserDefaults.standard.set(encoded, forKey: StorageKey.user.rawValue)
        }
        return .none
        
      case .didSynchronizeToken(.failure(let error)):
        print(error)
        return .none
        
      case .subscribeStories:
        guard let following = state.currentUser.following else { return .none }
        return .run { [following = following, currentUser = state.currentUser] send in
          let channel = supabase.channel("stories-\(currentUser.uuid.uuidString)")
          
          let insertions = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "stories",
            filter: "author_uuid=in.(\(following.map({ $0.following.uuid.uuidString }).joined(separator: ", ")))"
          )
          
          await channel.subscribe()
          await send(.onSubscribeStories(channel))
          
          for await insertAction in insertions {
            do {
              let jsonData = try JSONEncoder().encode(insertAction.record)
              let storyModel = try JSONDecoder().decode(StoryModelInsert.self, from: jsonData)
              
              let story: StoryModel = try await supabase
                .from("stories")
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
                .eq("uuid", value: storyModel.uuid)
                .single()
                .execute()
                .value
              
              await send(.onInsertStory(.success(story)))
            } catch {
              await send(.onInsertStory(.failure(error)))
            }
          }
        }
        
      case .onSubscribeStories(let channel):
        state.channel = channel
        return .none
        
      case .onUnsubscribeStories:
        state.channel = nil
        return .none
        
      case .onInsertStory(.success(let story)):
        if state.home.stories.stories[story.author.uuid] == nil {
          state.home.stories.stories[story.author.uuid] = []
        }
        state.home.stories.stories[story.author.uuid]?.append(story)
        return .none
        
      case .onInsertStory(.failure(let error)):
        print(error)
        return .none
        
      case .unsubscribeStories:
        return .run { [channel = state.channel] send in
          await channel?.unsubscribe()
          await send(.onUnsubscribeStories)
        }
        
      case .onSelectionChanged(let selection):
        state.selection = selection
        if state.selection == 0 {
          return .run { [camera = state.camera] send in
            await camera.camera.start()
          }
        } else {
          return .run { [camera = state.camera] send in
            camera.camera.stop()
          }
        }
        
      case .onTabSelectionChanged(let tabSelection):
        state.tabSelection = tabSelection
        return .none
        
      case .handleBadSession:
        return .run { send in
          try await supabase.auth.signOut()
        }
        
      case .registerNotifications:
        return .run { send in
          await withCheckedContinuation { continuation in
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            UNUserNotificationCenter.current().requestAuthorization(
              options: authOptions,
              completionHandler: { _, _ in
                continuation.resume()
              }
            )
          }
          
//          Messaging.messaging().token { token, error in
//            if let error = error {
//              print("Error fetching FCM registration token: \(error)")
//            } else if let token = token {
//              print("FCM registration token: \(token)")
//            }
//          }
        }
        
      case .initialize:
        return .merge(
          //          .run { send in
          //            do {
          //              try await supabase.auth.refreshSession()
          //            } catch {
          //              await send(.handleBadSession)
          //            }
          //          },

          .run { send in
            await send(.registerNotifications)
          },
          .run { send in
            await send(.currentProfile(.profile(.fetchProfile)))
          },
          .run { send in
            await send(.messages(.fetchChats))
          },
          .run { send in
            await send(.home(.stories(.fetchStories)))
            await send(.subscribeStories)
          }
        )
        
      case .home(.posts(.element(id: _, action: .didDelete(.success(let uuid))))):
        state.currentProfile.profile.posts.removeAll(where: { $0.post.uuid == uuid })
        return .none
        
      case .home(.send(.didSend(.success(let post)))):
        state.currentProfile.profile.posts.insert(Post.State(
          size: .normal,
          currentUser: state.currentUser,
          post: post
        ), at: 0)
        return .none
        
      case .home(.send(.didSend(.failure(let error)))),
          .home(.stories(.story(.presented(.didDelete(.failure(let error)))))),
          .messages(.chats(.element(id: _, action: .didSendMessage(.failure(let error))))),
          .messages(.path(.element(_, .chat(.didSendMessage(.failure(let error)))))),
          .home(.posts(.element(id: _, action: .didDelete(.failure(let error))))):
        state.home.isLoading = false
        state.bannerData = BannerModifier.BannerData(
          title: "Error",
          detail: error.localizedDescription,
          type: .Error
        )
        state.showBanner = true
        return .none
        
      case .home(.posts(.element(_, action: .didLike(.success(let like))))),
          .currentProfile(.profile(.posts(.element(_, action: .didLike(.success(let like)))))):
        if state.home.posts[id: like.post_uuid]?.post.likes == nil {
          state.home.posts[id: like.post_uuid]?.post.likes = []
          state.currentProfile.profile.posts[id: like.post_uuid]?.post.likes = []
        }
        state.home.posts[id: like.post_uuid]?.post.likes?.append(like)
        state.currentProfile.profile.posts[id: like.post_uuid]?.post.likes?.append(like)
        return .none
        
      case .home(.posts(.element(let id, action: .didUnlike(_)))),
          .currentProfile(.profile(.posts(.element(let id, action: .didUnlike(_))))):
        if var temp = state.home.posts[id: id] {
          temp.post.likes?.removeAll(where: { $0.liked_by == state.currentUser.uuid })
          state.home.posts[id: id] = temp
          state.currentProfile.profile.posts[id: id] = temp
        }
        return .none
        
      case .home(.stories(.presentCamera)):
        state.selection = 0
        return .none
        
      case .home(.path(.element(_, .profile(.didFollow(.success(let user)))))),
          .explore(.path(.element(_, action: .profile(.didFollow(.success(let user)))))):
        let following = FollowingModel(following: user)
        state.currentUser.following?.append(following)
        state.home.currentUser.following?.append(following)
        state.home.stories.currentUser.following?.append(following)
        state.currentProfile.profile.currentUser.following?.append(following)
        state.messages.currentUser.following?.append(following)
        state.camera.cameraSend.currentUser.following?.append(following)
        state.camera.cameraSend.following.append(CameraSendRecipient.State(following: following))
        if let encoded = try? JSONEncoder().encode(state.currentUser) {
          UserDefaults.standard.set(encoded, forKey: StorageKey.user.rawValue)
        }
        return .run { send in
          await send(.unsubscribeStories)
          await send(.home(.fetchPosts))
          await send(.home(.stories(.fetchStories)))
          await send(.subscribeStories)
        }
        
      case .home(.path(.element(_, .profile(.didUnfollow(.success(let user)))))),
          .explore(.path(.element(_, action: .profile(.didUnfollow(.success(let user)))))):
        state.currentUser.following?.removeAll(where: { $0.following.uuid == user.uuid })
        state.home.currentUser.following?.removeAll(where: { $0.following.uuid == user.uuid })
        state.home.stories.currentUser.following?.removeAll(where: { $0.following.uuid == user.uuid })
        state.currentProfile.profile.currentUser.following?.removeAll(where: { $0.following.uuid == user.uuid })
        state.messages.currentUser.following?.removeAll(where: { $0.following.uuid == user.uuid })
        state.camera.cameraSend.currentUser.following?.removeAll(where: { $0.following.uuid == user.uuid })
        state.camera.cameraSend.following.removeAll(where: { $0.following.following.uuid == user.uuid })
        if let encoded = try? JSONEncoder().encode(state.currentUser) {
          UserDefaults.standard.set(encoded, forKey: StorageKey.user.rawValue)
        }
        return .run { send in
          await send(.unsubscribeStories)
          await send(.home(.fetchPosts))
          await send(.home(.stories(.fetchStories)))
          await send(.subscribeStories)
        }
        
      case .home(_):
        return .none
        
      case .explore:
        return .none
        
      case .camera(.cameraSend(.send)):
        state.selection = 1
        state.home.isLoading = true
        return .none
        
      case .camera(.cameraSend(.didSendStory(.success(_)))):
        state.home.isLoading = false
        return .run { send in
          await send(.home(.stories(.fetchStories)))
        }
        
      case .camera(.cameraSend(.didSendMessages)):
        state.home.isLoading = false
        return .none
        
      case .camera(.cameraSend(.didSendMessage(.success(let message)))):
        state.messages.chats[id: message.chat_uuid]?.chat.messages?.append(message)
        return .none
        
      case .camera(.cameraSend(.didCreateChat(.success((let chat, _, _))))):
        state.messages.chats.insert(Chat.State(
          currentUser: state.currentUser,
          chat: chat
        ), at: 0)
        return .run { send in
          await send(.messages(.unsubscribeMessages))
          await send(.messages(.subscribeMessages))
        }
        
      case .camera(_):
        return .none
        
      case .currentProfile(.profile(.didUpload)):
        return .run { send in
          await send(.currentProfile(.profile(.fetchProfile)))
        }
        
      case .currentProfile(.profile(.didFetchProfile(.success((let user, _))))):
        state.home.stories.currentUser = user
        return .none
        
      case .currentProfile(_):
        return .none
        
      case .showBannerChanged(let showBanner):
        state.showBanner = showBanner
        return .none
        
      case .bannerDataChanged(let bannerData):
        state.bannerData = bannerData
        return .none
        
      case .messages:
        return .none
      }
    }
    
    Scope(state: \.camera, action: \.camera) {
      Camera()
    }
    
    Scope(state: \.home, action: \.home) {
      Home()
    }
    
    Scope(state: \.explore, action: \.explore) {
      Explore()
    }
    
    Scope(state: \.messages, action: \.messages) {
      Messages()
    }
    
    Scope(state: \.currentProfile, action: \.currentProfile) {
      CurrentProfile()
    }
  }
}
