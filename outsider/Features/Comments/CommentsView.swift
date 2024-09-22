//
//  CommentsView.swift
//  outsider
//
//  Created by Michael Jach on 16/09/2024.
//

import SwiftUI
import ComposableArchitecture

struct CommentsView: View {
  var store: StoreOf<Comments>
  
  var body: some View {
    VStack {
      ScrollView(showsIndicators: false) {
        VStack(alignment: .leading) {
          PostView(
            store: store.scope(state: \.post, action: \.post),
            onShowProfile: {
              store.send(.presentProfile(store.post.post.author))
            },
            onShowPost: {}
          )
          
          Divider()
            .padding(.bottom, 12)
          
          Text("Comments")
            .fontWeight(.medium)
            .font(.subheadline)
        }
        .padding()
      }
      
      TextField("Comment...", text: .constant(""))
        .textFieldStyle(PrimaryTextField())
        .padding()
    }
    .navigationTitle("Post")
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  CommentsView(
    store: Store(initialState: Comments.State(
      post: Post.State(
        currentUser: Mocks.user,
        post: Mocks.post
      )
    )) {
      Comments()
    }
  )
}
