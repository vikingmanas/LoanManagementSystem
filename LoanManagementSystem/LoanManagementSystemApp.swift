//
//  LoanManagementSystemApp.swift
//  LoanManagementSystem
//
//  Created by apple on 14/05/26.
//

import SwiftUI
import FirebaseCore

/// Firebase App Delegate — ensures Firebase is configured before any view or
/// @StateObject initialization occurs.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct LoanManagementSystemApp: App {
    
    /// Register the AppDelegate so Firebase configures before @StateObject init.
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    /// Shared authentication manager injected into the environment.
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}

