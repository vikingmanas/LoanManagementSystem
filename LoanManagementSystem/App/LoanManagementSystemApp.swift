






import SwiftUI

@main
struct LoanManagementSystemApp: App {


    @StateObject private var authManager = AuthManager()


    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}

