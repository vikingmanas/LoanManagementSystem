import SwiftUI

struct ContentView: View {
    @State private var selectedRole: RoleType = .loanOfficer
    
    enum RoleType {
        case borrower
        case loanOfficer
    }
    
    var body: some View {
        ZStack {
            if selectedRole == .borrower {
                // Launch Borrower Dashboard
                NavigationStack {
                    DashboardView()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchRoleToOfficer"))) { _ in
                    selectedRole = .loanOfficer
                }
            } else {
                // Launch Loan Officer Dashboard
                NavigationStack {
                    LoanOfficerDashboardView()
                }
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchRoleToBorrower"))) { _ in
                    selectedRole = .borrower
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedRole)
    }
}

#Preview {
    ContentView()
}
