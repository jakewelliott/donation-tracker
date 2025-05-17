//
//  DonationTrackerApp.swift
//  DonationTracker
//
//  Created by Jake Elliott on 5/16/25.
//

import SwiftUI
import FirebaseCore

@main
struct DonationTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var itemsViewModel = ItemsViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(itemsViewModel)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}
