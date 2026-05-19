//
//  LoanManagementSystemApp.swift
//  LoanManagementSystem
//
//  Created by apple on 14/05/26.
//

import SwiftUI
import FirebaseCore

@main
struct LoanManagementSystemApp: App {
    
    /// Shared authentication manager injected into the environment.
    @StateObject private var authManager = AuthManager()
    
    init() {
        // Configure Firebase SDK on app launch.
        // This reads GoogleService-Info.plist automatically.
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
