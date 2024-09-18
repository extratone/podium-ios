//
//  MediaView.swift
//  outsider
//
//  Created by Michael Jach on 12/09/2024.
//

import SwiftUI
import ComposableArchitecture
import CachedAsyncImage

struct MediaView: View {
  var store: StoreOf<Media>
  
  var body: some View {
    VStack {
      Spacer()
      HStack {
        Spacer()
        CachedAsyncImage(url: URL(string: store.media.url)) { image in
          image
            .resizable()
            .scaledToFit()
        } placeholder: {
          ProgressView()
        }
        Spacer()
      }
      Spacer()
    }
    .ignoresSafeArea()
    .background(.black)
  }
}

#Preview {
  MediaView(
    store: Store(initialState: Media.State(
      media: Mocks.media
    )) {
      Media()
    }
  )
}
