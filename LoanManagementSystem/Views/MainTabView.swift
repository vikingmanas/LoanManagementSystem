import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var appState: AppStateManager
    @StateObject private var tabRouter = BorrowerTabRouter()

    private var notificationBadge: Int { LMSMockNotifications.unreadCount }

    var body: some View {
        TabView(selection: $tabRouter.selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(BorrowerTab.dashboard)

            LoanApplicationTabView(viewModel: LoanApplicationViewModel())
                .tabItem {
                    Label("Loans", systemImage: "doc.text.magnifyingglass")
                }
                .tag(BorrowerTab.loans)

            NotificationsTabView()
                .tabItem {
                    Label("Notifications", systemImage: "bell.fill")
                }
                .tag(BorrowerTab.notifications)
                .badge(notificationBadge)
        }
        .tint(LMSColors.brandNavy)
        .toolbarBackground(LMSColors.surfaceElevated, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .environmentObject(tabRouter)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppStateManager())
        .environmentObject(AuthManager())
}
