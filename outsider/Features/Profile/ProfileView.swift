//
//  ProfileView.swift
//  outsider
//
//  Created by Michael Jach on 16/09/2024.
//

import SwiftUI
import ComposableArchitecture
import PhotosUI

struct ProfileView: View {
  @Bindable var store: StoreOf<Profile>
  
  init(store: StoreOf<Profile>) {
    self.store = store
    UINavigationBar.appearance().largeTitleTextAttributes = [
      .font : UIFont(name: "ClashDisplayVariable-Bold_Medium", size: 34)!
    ]
  }
  
  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(spacing: 16) {
        VStack(alignment: .leading, spacing: 16) {
          HStack {
            if store.isCurrent {
              PhotosPicker(
                selection: $store.imageSelection.sending(\.imageSelectionChanged)
              ) {
                if let tempAvatar = store.tempAvatar {
                  Image(uiImage: tempAvatar)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 72, height: 72)
                    .clipShape(Circle())
                } else {
                  AsyncCachedImage(url: store.user.avatar_url) { image in
                    image
                      .resizable()
                      .scaledToFill()
                      .frame(width: 72, height: 72)
                      .clipShape(Circle())
                  } placeholder: {
                    Circle()
                      .frame(width: 72, height: 72)
                      .foregroundColor(.colorBackgroundPrimary)
                  }
                }
              }
            } else {
              AsyncCachedImage(url: store.user.avatar_url) { image in
                image
                  .resizable()
                  .scaledToFill()
                  .frame(width: 72, height: 72)
                  .clipShape(Circle())
              } placeholder: {
                Circle()
                  .frame(width: 72, height: 72)
                  .foregroundColor(.colorBackgroundPrimary)
              }
            }
            
            VStack(alignment: .leading, spacing: 0) {
              if store.isCurrent {
                TextField(
                  "Display name",
                  text: $store.displayName.sending(\.onDisplayNameChanged)
                )
                .submitLabel(.done)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundStyle(.colorTextPrimary)
                .onSubmit {
                  store.send(.setDisplayName)
                }
              } else {
                if !store.displayName.isEmpty {
                  Text(store.displayName)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundStyle(.colorTextPrimary)
                }
              }
              
              Text("@\(store.user.username)")
                .foregroundStyle(.colorTextSecondary)
                .fontWeight(.medium)
            }
            
            Spacer()
          }
          
          Text("This is my bio...")
            .foregroundStyle(.colorTextPrimary)
            .fontWeight(.medium)
          
          HStack(spacing: 12) {
            Text("**\(store.user.following?.count ?? 0)** following")
          }
          
          if !store.isCurrent {
            Button {
              if let following = store.currentUser.following, following.contains(where: { $0.following.uuid == store.user.uuid }) {
                store.send(.unfollow(store.user))
              } else {
                store.send(.follow(store.user))
              }
            } label: {
              HStack {
                Spacer()
                if let following = store.currentUser.following, following.contains(where: { $0.following.uuid == store.user.uuid }) {
                  Text("Unfollow")
                } else {
                  Text("Follow")
                }
                Spacer()
              }
            }
            .buttonStyle(PrimarySmallButton())
            .disabled(store.isPending)
          }
        }
        .padding(.horizontal)
        
        Divider()
        
        Picker("Tabs", selection: $store.selectedTabIndex.sending(\.onSelectedTabIndexChanged)) {
          Text("Posts")
            .tag(Profile.Tabs.posts)
          Text("Media")
            .tag(Profile.Tabs.media)
          Text("Likes")
            .tag(Profile.Tabs.likes)
        }
        .pickerStyle(SegmentedPickerStyle())
        .padding(.horizontal)
        
        switch store.selectedTabIndex {
        case .posts:
          VStack(spacing: 0) {
            ForEach(store.scope(state: \.posts, action: \.posts)) { postStore in
              PostView(
                store: postStore,
                onShowProfile: {
                  store.send(.presentProfile(postStore.post.author))
                },
                onShowPost: {
                  store.send(.presentComments(postStore.post))
                }
              )
              .padding(.horizontal, 10)
              Divider()
                .padding(.bottom, 10)
            }
          }
          .animation(.spring(), value: store.posts)
        case .media:
          Text("No media")
        case .likes:
          Text("No likes")
        }
      }
      .padding(.vertical, 12)
    }
    .navigationTitle("Profile")
    .onAppear {
      store.send(.initialize)
    }
  }
}

#Preview {
  ProfileView(
    store: Store(initialState: Profile.State(
      currentUser: Mocks.user,
      user: Mocks.user,
      posts: [Post.State(
        currentUser: Mocks.user,
        post: Mocks.post
      )]
    )) {
      Profile()
    }
  )
}
