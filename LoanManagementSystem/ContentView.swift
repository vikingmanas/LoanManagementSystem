import SwiftUI

struct ContentView: View {
    @StateObject private var appState = AppStateManager()
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashScreenView()
                    .transition(.opacity)
            } else {
                Group {
                    if appState.isAuthenticated {
                        MainTabView()
                    } else {
                        SignInView()
                    }
                }
                .environmentObject(appState)
                .transition(.opacity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
