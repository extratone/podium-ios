//
//  PostView.swift
//  outsider
//
//  Created by Michael Jach on 11/09/2024.
//

import SwiftUI
import ComposableArchitecture
import CachedAsyncImage

struct PostView: View {
  @Bindable var store: StoreOf<Post>
  let onShowProfile: () -> Void
  let onShowPost: () -> Void
  
  var body: some View {
    VStack(spacing: 0) {
      Button {
        onShowPost()
      } label: {
        HStack(alignment: .top, spacing: 8) {
          VStack {
            Button {
              onShowProfile()
            } label: {
              CachedAsyncImage(url: store.post.author.avatar_url) { image in
                image
                  .resizable()
                  .scaledToFill()
                  .frame(width: 52, height: 52)
                  .clipShape(Circle())
              } placeholder: {
                Circle()
                  .frame(width: 52, height: 52)
                  .foregroundStyle(.colorBackgroundPrimary)
              }
            }
          }
          
          VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 0) {
              if let displayName = store.post.author.display_name {
                Button {
                  onShowProfile()
                } label: {
                  Text(displayName)
                    .foregroundStyle(.colorTextPrimary)
                    .fontWeight(.semibold)
                    .font(.callout)
                    .padding(.trailing, 4)
                }
              }
              
              Button {
                onShowProfile()
              } label: {
                Text("@\(store.post.author.username)")
                  .foregroundStyle(.colorTextSecondary)
                  .font(.callout)
              }
              
              Spacer()
              
              Text(store.post.created_at.timeAgoDisplay())
                .foregroundStyle(.colorTextSecondary)
                .font(.caption)
            }
            
            VStack(alignment: .leading, spacing: 0) {
              if let text = store.post.text, !text.isEmpty {
                Text(text)
                  .textSelection(.enabled)
                  .font(.callout)
                  .padding(.top, 4)
                  .foregroundStyle(.colorTextPrimary)
                  .multilineTextAlignment(.leading)
              }
              
              if let mediaItems = store.post.media {
                HStack {
                  ForEach(mediaItems) { mediaItem in
                    Button {
                      store.send(.presentMedia(mediaItem))
                    } label: {
                      Rectangle()
                        .frame(height: 180)
                        .overlay(
                          CachedAsyncImage(url: URL(string: mediaItem.url)) { image in
                            image
                              .resizable()
                              .scaledToFill()
                              .frame(height: 180)
                              .clipShape(
                                RoundedRectangle(cornerRadius: 13, style: .continuous)
                              )
                          } placeholder: {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                              .foregroundStyle(.colorBackgroundPrimary)
                          }
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .allowsHitTesting(false)
                    }
                  }
                }
                .padding(.top, 6)
                .sheet(item: $store.scope(state: \.media, action: \.media)) { store in
                  MediaView(store: store)
                }
              }
            }
          }
        }
      }
      
      HStack {
        HStack(spacing: 4) {
          Image("icon-share")
            .resizable()
            .frame(width: 16, height: 16)
            .foregroundColor(.colorTextSecondary)
            .padding(.vertical, 8)
            .padding(.trailing, 16)
        }
        
        Spacer()
        
        HStack(spacing: 4) {
          Image("icon-comments")
            .resizable()
            .frame(width: 16, height: 16)
            .foregroundColor(.colorTextSecondary)
          
          Text("124")
            .font(.caption)
            .foregroundStyle(.colorTextSecondary)
            .fontWeight(.medium)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        
        Spacer()
        
        Button {
          if store.isLiked {
            store.send(.unlike)
          } else {
            store.send(.like)
          }
        } label: {
          HStack(spacing: 4) {
            Image(store.isLiked ? "icon-like-fill" : "icon-like")
              .resizable()
              .frame(width: 16, height: 16)
              .foregroundColor(store.isLiked ? .colorRed : .colorTextSecondary)
            
            Text("\(store.post.likes?.count ?? 0)")
              .font(.caption)
              .foregroundStyle(.colorTextSecondary)
              .fontWeight(.medium)
          }
          .padding(.vertical, 8)
          .padding(.horizontal, 16)
        }
        .sensoryFeedback(.success, trigger: store.post.likes)
        
        Spacer()
        
        Menu {
          Button(action: { }) {
            Label("Copy link", systemImage: "link")
          }
          
          if store.post.author.uuid == store.currentUser.uuid {
            Button(role: .destructive, action: { store.send(.delete) }) {
              Label("Delete", systemImage: "trash")
            }
          } else {
            Button(action: { }) {
              Label("Block author", systemImage: "person.slash")
            }
          }
        } label: {
          Image("icon-dots")
            .resizable()
            .frame(width: 16, height: 16)
            .foregroundColor(.colorTextSecondary)
            .padding(.vertical, 8)
            .padding(.leading, 16)
        }
      }
      .padding(.top, 2)
      .padding(.bottom, 4)
      .padding(.leading, 60)
    }
  }
}

#Preview {
  PostView(
    store: Store(initialState: Post.State(
      currentUser: Mocks.user,
      post: Mocks.post
    )) {
      Post()
    },
    onShowProfile: {},
    onShowPost: {}
  )
}
