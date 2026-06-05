
import SwiftUI

@main
struct LoanManagementSystemApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    
    @State private var authManager = AuthManager.shared
    @AppStorage("isDarkMode") private var isDarkMode = false
    
    init() {}
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(authManager)
                .accessibilityOverrides()
                .onAppear { applyDarkModeToAllWindows() }
                .onChange(of: isDarkMode) { applyDarkModeToAllWindows() }
        }
    }
    
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
