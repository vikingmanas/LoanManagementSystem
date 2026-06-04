import SwiftUI

struct AdminDashboardView: View {
    @StateObject private var viewModel = AdminDashboardViewModel()
    @StateObject private var staffViewModel = AdminStaffViewModel()
    @State private var selectedTab: AdminTab = .dashboard
    @State private var showingProfile = false

    var body: some View {
        TabView(selection: $selectedTab) {
            AdminDashboardTabView(viewModel: viewModel, showingProfile: $showingProfile)
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }
                .tag(AdminTab.dashboard)

            AdminUsersTabView(viewModel: staffViewModel)
                .tabItem {
                    Label("Staff", systemImage: "person.2")
                }
                .tag(AdminTab.staff)

            AdminLoanRulesTabView()
                .tabItem {
                    Label("Loan Rules", systemImage: "gearshape.2")
                }
                .tag(AdminTab.loanRules)
                
            AdminTemplatesTabView()
                .tabItem {
                    Label("Templates", systemImage: "text.bubble")
                }
                .tag(AdminTab.templates)
        }
        .accessibleSheet(isPresented: $showingProfile) {
            AdminProfileSheet()
        }
    }
}
