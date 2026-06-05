import SwiftUI

struct AdminDashboardView: View {
    @State private var viewModel = AdminDashboardViewModel()
    @State private var staffViewModel = AdminStaffViewModel()
    @State private var selectedTab: AdminTab = .dashboard

    var body: some View {
        TabView(selection: $selectedTab) {
            AdminDashboardTabView(viewModel: viewModel)
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
    }
}
