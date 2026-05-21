import SwiftUI

// MARK: - ContentView (Auth Router)
/// Root view that switches between authentication and dashboard flows
/// based on the current Firebase auth state.
struct ContentView: View {
    
    // Firebase/Auth Manager
    @EnvironmentObject private var authManager: AuthManager
    
    // App State Manager
    @StateObject private var appState = AppStateManager()
    
    // Splash control
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            
            // MARK: - Splash Screen
            if showSplash || !authManager.isAuthStateResolved {
                
                splashView
                    .transition(.opacity)
                
            } else {
                
                Group {
                    
                    // MARK: - Authenticated Flow
                    if authManager.isAuthenticated || appState.isAuthenticated {
                        
                        MainTabView()
                            .environmentObject(authManager)
                            .environmentObject(appState)
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                        
                    } else {
                        
                        // MARK: - Authentication Flow
                        SignInView()
                            .environmentObject(authManager)
                            .environmentObject(appState)
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }
                }
            }
        }
        .animation(
            .spring(response: 0.5, dampingFraction: 0.85),
            value: authManager.isAuthenticated
        )
        .animation(
            .easeInOut(duration: 0.4),
            value: authManager.isAuthStateResolved
        )
        .onAppear {
            
            // MARK: - Splash Delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
    
    // MARK: - Splash View
    private var splashView: some View {
        ZStack {
            
            LinearGradient(
                colors: [
                    Color.brandNavy,
                    Color(hex: "#2E3B84")
                ],
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
