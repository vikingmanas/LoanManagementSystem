import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab = .dashboard
    private var notificationBadge: Int { LMSMockNotifications.unreadCount }

    private enum AppTab: Hashable {
        case dashboard, loans, profile, notifications
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(AppTab.dashboard)

            LoanApplicationTabView()
                .tabItem {
                    Label("Loans", systemImage: "doc.text.magnifyingglass")
                }
                .tag(AppTab.loans)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(AppTab.profile)

            NotificationsTabView()
                .tabItem {
                    Label("Notifications", systemImage: "bell.fill")
                }
                .tag(AppTab.notifications)
                .badge(notificationBadge)
        }
        .tint(LMSColors.brandNavy)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(AppStateManager())
            .environmentObject(AuthManager())
    }
}
