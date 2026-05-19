import Foundation
import Combine

class AppStateManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    
    // Mock user details could be stored here later
    
    func login() {
        isAuthenticated = true
    }
    
    func logout() {
        isAuthenticated = false
    }
}
