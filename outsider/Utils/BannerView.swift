//
//  BannerView.swift
//  min
//
//  Created by Michael Jach on 11/07/2024.
//

import SwiftUI

struct BannerModifier: ViewModifier {
  
  struct BannerData {
    var title: String
    var detail: String
    var type: BannerType
  }
  
  enum BannerType {
    case Info
    case Warning
    case Success
    case Error
    
    var tintColor: Color {
      switch self {
      case .Info:
        return Color.black
      case .Success:
        return Color.green
      case .Warning:
        return Color.yellow
      case .Error:
        return Color.red
      }
    }
  }
  
  // Members for the Banner
  @Binding var data: BannerData
  @Binding var show: Bool
  
  func body(content: Content) -> some View {
    ZStack {
      content
      if show {
        VStack {
          HStack {
            VStack(alignment: .leading, spacing: 2) {
              Text(data.title)
                .font(.subheadline)
                .bold()
              Text(data.detail)
                .font(.subheadline)
                .fontWeight(.medium)
            }
            Spacer()
          }
          .foregroundColor(Color.white)
          .padding(12)
          .background(data.type.tintColor)
          .cornerRadius(12)
          Spacer()
        }
        .padding()
        .animation(.easeIn(duration: 0.5))
        .transition(.asymmetric(
          insertion: .move(edge: .top),
          removal: .move(edge: .top)
        ))
        .onTapGesture {
          withAnimation {
            self.show = false
          }
        }
        .onAppear(perform: {
          DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation {
              self.show = false
            }
          }
        })
      }
    }
  }
  
}

extension View {
  func banner(data: Binding<BannerModifier.BannerData>, show: Binding<Bool>) -> some View {
    self.modifier(BannerModifier(data: data, show: show))
  }
}

struct Banner_Previews: PreviewProvider {
  static var previews: some View {
    VStack {
      Text("Hello")
    }
    .banner(
      data: .constant(BannerModifier.BannerData(
        title: "Error",
        detail: "Incorrect credentials.",
        type: .Error
      )),
      show: .constant(true)
    )
  }
}
