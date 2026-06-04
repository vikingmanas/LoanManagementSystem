import Foundation
import Combine
import SwiftUI

public enum PortalRole: String, CaseIterable, Identifiable {
    case customer = "Customer"
    case loanOfficer = "Loan Officer"
    case bankManager = "Bank Manager"
    case admin = "Admin (Head Manager)"
    
    public var id: String { self.rawValue }
    
    public var icon: String {
        switch self {
        case .customer: return "person.fill"
        case .loanOfficer: return "person.badge.shield.checkmark.fill"
        case .bankManager: return "building.columns.fill"
        case .admin: return "shield.fill"
        }
    }
    
    public var description: String {
        switch self {
        case .customer: return "Apply for and manage your personal loans"
        case .loanOfficer: return "Verify loans, review documents, and support borrowers"
        case .bankManager: return "Approve high-value applications and manage branch statistics"
        case .admin: return "Full system control, configure interest rates, and audit logs"
        }
    }
}

class AppStateManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var selectedRole: PortalRole = .customer
    @Published var showRoleSelection: Bool = false
    @Published var requiresBorrowerOnboarding: Bool = false
    
    
    func login(requiresBorrowerOnboarding: Bool = false) {
        self.requiresBorrowerOnboarding = requiresBorrowerOnboarding
        isAuthenticated = true
    }
    
    func logout() {
        isAuthenticated = false
        selectedRole = .customer
        showRoleSelection = false
        requiresBorrowerOnboarding = false
    }
}
