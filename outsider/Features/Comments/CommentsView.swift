//
//  CommentsView.swift
//  outsider
//
//  Created by Michael Jach on 16/09/2024.
//

import SwiftUI
import ComposableArchitecture

struct CommentsView: View {
  @Bindable var store: StoreOf<Comments>
  
  var body: some View {
    VStack {
      ScrollView(showsIndicators: false) {
        VStack(alignment: .leading, spacing: 0) {
          PostView(
            store: store.scope(state: \.post, action: \.post),
            onShowProfile: {
              store.send(.presentProfile(store.post.post.author))
            },
            onShowPost: {}
          )
          .padding(.horizontal, 10)
          .padding(.top, 10)
          
          Divider()
            .padding(.bottom, 10)
          
          ForEach(store.scope(state: \.posts, action: \.posts)) { postStore in
            PostView(
              store: postStore,
              onShowProfile: {
                store.send(.presentProfile(postStore.post.author))
              },
              onShowPost: {
//                store.send(.presentComments(postStore.post))
              }
            )
            .padding(.horizontal, 10)
            
            Divider()
              .padding(.bottom, 10)
          }
        }
      }
      
      TextField("Comment...", text: $store.text.sending(\.onTextChange))
        .textFieldStyle(PrimaryTextField())
        .padding()
        .onSubmit {
          store.send(.sendComment)
        }
    }
    .navigationTitle("Post")
    .navigationBarTitleDisplayMode(.inline)
    .onAppear {
      store.send(.fetchComments)
    }
  }
}

#Preview {
  CommentsView(
    store: Store(initialState: Comments.State(
      currentUser: Mocks.currentUser,
      post: Post.State(
        size: .normal,
        currentUser: Mocks.currentUser,
        post: Mocks.post
      ),
      posts: [
        Post.State(
          size: .small,
          currentUser: Mocks.currentUser,
          post: Mocks.comment.comment
        ),
        Post.State(
          size: .small,
          currentUser: Mocks.currentUser,
          post: Mocks.comment1.comment
        )
      ]
    )) {
      Comments()
    }
  )
}
