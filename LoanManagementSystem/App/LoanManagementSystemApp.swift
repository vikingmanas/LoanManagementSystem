//
//  LoanManagementSystemApp.swift
//  LoanManagementSystem
//
//  Created by apple on 14/05/26.
//

import SwiftUI

@main
struct LoanManagementSystemApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    /// Shared authentication manager injected into the environment.
    @StateObject private var authManager = AuthManager.shared
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    // Accessibility Overrides
    @AppStorage("forceHighContrast") private var forceHighContrast = false
    @AppStorage("forceBoldText") private var forceBoldText = false
    @AppStorage("reduceMotion") private var reduceMotion = false
    
    init() {}
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .preferredColorScheme(isDarkMode ? .dark : .light)
                .environment(\.legibilityWeight, forceBoldText ? .bold : .regular)
                .transaction { transaction in
                    if reduceMotion {
                        transaction.animation = nil
                    }
                }
        }
    }
}
