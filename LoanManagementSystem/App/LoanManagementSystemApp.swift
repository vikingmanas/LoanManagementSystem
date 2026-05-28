//
//  LoanManagementSystemApp.swift
//  LoanManagementSystem
//
//  Created by apple on 14/05/26.
//

import SwiftUI

@main
struct LoanManagementSystemApp: App {
    
    /// Shared authentication manager injected into the environment.
    @StateObject private var authManager = AuthManager.shared
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    init() {}
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .preferredColorScheme(isDarkMode ? .dark : .light)
        }
    }
}
