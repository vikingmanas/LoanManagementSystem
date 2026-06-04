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
    
    init() {}
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .accessibilityOverrides() // Trigger Xcode re-index
                .onAppear { applyDarkModeToAllWindows() }
                .onChange(of: isDarkMode) { _ in applyDarkModeToAllWindows() }
        }
    }
    
    /// Applies the dark mode override to EVERY connected UIWindow,
    /// including sheet / fullScreenCover presentation windows.
    /// This ensures toggling Dark Mode in Accessibility settings
    /// takes effect immediately, even on already-open sheets.
    private func applyDarkModeToAllWindows() {
        let style: UIUserInterfaceStyle = isDarkMode ? .dark : .light
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = style
            }
        }
    }
}
