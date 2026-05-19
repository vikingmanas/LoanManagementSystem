//
//  ContentView.swift
//  LoanManagementSystem
//
//  Created by apple on 14/05/26.
//

import SwiftUI

// MARK: - ContentView (Auth Router)
/// Root view that switches between authentication and dashboard flows
/// based on the current Firebase auth state.
struct ContentView: View {
    @EnvironmentObject private var authManager: AuthManager
    
    var body: some View {
        Group {
            if !authManager.isAuthStateResolved {
                // MARK: - Splash / Loading State
                // Shown briefly while Firebase resolves the persisted auth session.
                splashView
                    .transition(.opacity)
            } else if authManager.isAuthenticated {
                // MARK: - Authenticated → Dashboard
                DashboardView()
                    .environmentObject(authManager)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            } else {
                // MARK: - Not Authenticated → Login
                LoginView()
                    .environmentObject(authManager)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.85), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.4), value: authManager.isAuthStateResolved)
    }
    
    // MARK: - Splash View
    /// A minimal branded splash screen shown during auth state resolution.
    private var splashView: some View {
        ZStack {
            LinearGradient(
                colors: [Color.brandNavy, Color(hex: "#2E3B84")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
                
                Text("Loan Manager")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white.opacity(0.8))
                    .scaleEffect(1.1)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
