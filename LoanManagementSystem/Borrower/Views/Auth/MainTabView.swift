import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var appState: AppStateManager
    @StateObject private var tabRouter = BorrowerTabRouter()
    @StateObject private var dashboardViewModel = DashboardViewModel()

    var body: some View {
        TabView(selection: $tabRouter.selectedTab) {
            DashboardView(viewModel: dashboardViewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(BorrowerTab.dashboard)

            LoanApplicationTabView(viewModel: LoanApplicationViewModel())
                .tabItem {
                    Label("Loans", systemImage: "doc.text.magnifyingglass")
                }
                .tag(BorrowerTab.loans)

            HistoryTabView(viewModel: dashboardViewModel)
                .tabItem {
                    Label("History", systemImage: "clock.fill")
                }
                .tag(BorrowerTab.history)

            NavigationStack {
                ProfileView()
                    .environmentObject(authManager)
                    .environmentObject(appState)
            }
            .tabItem {
                Label("Profile", systemImage: "person.fill")
            }
            .tag(BorrowerTab.profile)
        }
        .tint(LMSColors.brandNavy)
        .toolbarBackground(LMSColors.surfaceElevated, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .environmentObject(tabRouter)
        .task {
            await dashboardViewModel.fetchDashboardData()
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppStateManager())
        .environmentObject(AuthManager())
}

