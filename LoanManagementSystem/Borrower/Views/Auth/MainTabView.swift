import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var appState: AppStateManager
    @StateObject private var tabRouter = BorrowerTabRouter()
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @StateObject private var loanApplicationViewModel = LoanApplicationViewModel()

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.94)
        appearance.shadowColor = UIColor.separator.withAlphaComponent(0.18)

        let selected = UIColor(LMSColors.brandNavy)
        let normal = UIColor.secondaryLabel
        [appearance.stackedLayoutAppearance, appearance.inlineLayoutAppearance, appearance.compactInlineLayoutAppearance].forEach { item in
            item.normal.iconColor = normal
            item.normal.titleTextAttributes = [.foregroundColor: normal]
            item.selected.iconColor = selected
            item.selected.titleTextAttributes = [.foregroundColor: selected, .font: UIFont.systemFont(ofSize: 11, weight: .semibold)]
        }

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().isTranslucent = true
    }

    var body: some View {
        TabView(selection: $tabRouter.selectedTab) {
            DashboardView(viewModel: dashboardViewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(BorrowerTab.dashboard)
            
            BorrowerApplicationsTabView(viewModel: loanApplicationViewModel)
                .tabItem {
                    Label("Applications", systemImage: "tray.full.fill")
                }
                .tag(BorrowerTab.applications)

            LoanApplicationTabView(viewModel: loanApplicationViewModel)
                .tabItem {
                    Label("Loans", systemImage: "doc.text.magnifyingglass")
                }
                .tag(BorrowerTab.loans)

            

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
