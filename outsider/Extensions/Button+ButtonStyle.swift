//
//  Button+ButtonStyle.swift
//  outsider
//
//  Created by Michael Jach on 09/09/2024.
//

import SwiftUI

struct PrimaryButton: ButtonStyle {
  @Environment(\.isEnabled) var isEnabled
  var isLoading: Bool?
  
  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 8) {
      Spacer()
      
      if let isLoading = isLoading, isLoading {
        ProgressView()
          .tint(.colorTextReverse)
      }
      
      configuration.label
        .foregroundStyle(.colorTextReverse)
        .fontWeight(.semibold)
        .opacity(isEnabled ? 1 : 0.4)
      
      Spacer()
    }
    .padding()
    .background(.colorPrimary)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .scaleEffect(configuration.isPressed ? 0.95 : 1)
  }
}

struct PrimarySmallButton: ButtonStyle {
  @Environment(\.isEnabled) var isEnabled
  var isLoading: Bool?
  
  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 8) {
      if let isLoading = isLoading, isLoading {
        ProgressView()
          .tint(.colorTextReverse)
      }
      
      configuration.label
        .foregroundStyle(.colorTextReverse)
        .fontWeight(.semibold)
        .opacity(isEnabled ? 1 : 0.4)
    }
    .padding(.vertical, 6)
    .padding(.horizontal, 16)
    .background(.colorPrimary)
    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    .scaleEffect(configuration.isPressed ? 0.95 : 1)
  }
}

struct LinkButton: ButtonStyle {
  @Environment(\.isEnabled) var isEnabled
  
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .padding()
      .foregroundStyle(isEnabled ? .colorPrimary : .colorTextSecondary)
      .opacity(configuration.isPressed ? 0.4 : 1)
      .fontWeight(.semibold)
  }
}

struct SendButton: ButtonStyle {
  @Environment(\.isEnabled) var isEnabled
  
  func makeBody(configuration: Configuration) -> some View {
    HStack(spacing: 0) {
      configuration.label
        .fontWeight(.semibold)
        .foregroundStyle(.black)
      
      Image("icon-send")
        .resizable()
        .frame(width: 20, height: 20)
        .foregroundStyle(.black)
    }
    .padding(.vertical, 12)
    .padding(.leading, 22)
    .padding(.trailing, 14)
    .background(.yellow)
    .clipShape(Capsule())
    .opacity(isEnabled ? 1 : 0.5)
  }
}

#Preview {
  VStack {
    Button {
      
    } label: {
      Text("Submit")
    }
    .buttonStyle(PrimaryButton())
    
    Button {
      
    } label: {
      Text("Submit")
    }
    .disabled(true)
    .buttonStyle(PrimaryButton())
    
    Button {
      
    } label: {
      Text("Submit")
    }
    .buttonStyle(PrimaryButton(isLoading: true))
    
    Button {
      
    } label: {
      Text("Create account")
    }
    .buttonStyle(LinkButton())
    
    Button {
      
    } label: {
      Text("Create account disabled")
    }
    .disabled(true)
    .buttonStyle(LinkButton())
    
    Button {
      
    } label: {
      Text("Follow")
    }
    .buttonStyle(PrimarySmallButton())
    
    Button {
      
    } label: {
      Text("Send")
    }
    .buttonStyle(SendButton())
    
    Button {
      
    } label: {
      Text("Send")
    }
    .disabled(true)
    .buttonStyle(SendButton())
  }
  .padding()
}
