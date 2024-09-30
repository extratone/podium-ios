//
//  outsiderApp.swift
//  outsider
//
//  Created by Michael Jach on 09/09/2024.
//

import SwiftUI
import ComposableArchitecture
import FirebaseCore
import FirebaseMessaging

@main
struct outsiderApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
  
  let store = Store(initialState: Main.State()) {
    Main()
  }
  
  var body: some Scene {
    WindowGroup {
      MainView(store: store)
      .onAppear {
        delegate.store = store
      }
    }
  }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  var store: Store<Main.State, Main.Action>?
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    UNUserNotificationCenter.current().delegate = self
    Messaging.messaging().delegate = self
    application.registerForRemoteNotifications()
    return true
  }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
  
}

extension AppDelegate: MessagingDelegate {
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    Messaging.messaging().apnsToken = deviceToken
  }
  
  func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
    guard let fcmToken = fcmToken else { return }
    store?.send(.setToken(fcmToken))
    store?.send(.tabs(.synchronizeToken(fcmToken)))
  }
}
