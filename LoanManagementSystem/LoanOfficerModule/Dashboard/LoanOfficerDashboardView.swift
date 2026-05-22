import SwiftUI

struct LoanOfficerDashboardView: View {
    typealias LoanApplication = OfficerLoanApplication
    @StateObject private var viewModel = LoanOfficerDashboardViewModel()
    @State private var scrollTargetID: String? = nil
    
    // Notifications toggle
    @State private var showNotificationSheet = false
    @State private var showingAlert = false
    @State private var selectedAlertMessage: String? = nil
    @State private var selectedAppForReview: LoanApplication? = nil
    @State private var showProfileSheet = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 1. CUSTOM TOP NAVIGATION BAR (Fixed) - Hidden for Tab 3 (Registry) to allow its own native collapsible header
            if viewModel.selectedTab != 3 {
                CustomTopNavigationBar(
                    viewModel: viewModel,
                    onNotificationPressed: {
                        showNotificationSheet = true
                    },
                    onProfilePressed: {
                        showProfileSheet = true
                    }
                )
                
                
                Divider()
            }
            
            // 3. CUSTOM TRANS-TAB CONTAINER WITH FLOATING TAB BAR
            ZStack(alignment: .bottom) {
                // Tab Content Switcher
                ZStack {
                    switch viewModel.selectedTab {
                    case 0:
                        ScrollViewReader { proxy in
                            DashboardTabView(
                                viewModel: viewModel,
                                onDocumentSeeAllTapped: {
                                    handleAlertDeepLink(.pendingDocuments)
                                },
                                onManagerRespondTapped: { app in
                                    HapticsManager.triggerImpact(style: .medium)
                                    selectedAppForReview = app
                                },
                                onQuickActionTapped: { actionIdentifier in
                                    if actionIdentifier == "verify_docs" {
                                        handleAlertDeepLink(.pendingDocuments)
                                    } else if actionIdentifier == "reports" {
                                        HapticsManager.triggerNotification(type: .success)
                                        selectedAlertMessage = "Generating and downloading the Branch Monthly Performance Report..."
                                        showingAlert = true
                                    } else if actionIdentifier == "escalate" {
                                        HapticsManager.triggerNotification(type: .warning)
                                        selectedAlertMessage = "Operational Escalation submitted successfully to Branch Manager."
                                        showingAlert = true
                                    }
                                }
                            )
                            .onChange(of: scrollTargetID) { _, newID in
                                if let newID = newID {
                                    withAnimation(.spring()) {
                                        proxy.scrollTo(newID, anchor: .top)
                                    }
                                    scrollTargetID = nil
                                }
                            }
                        }
                        .background(AppTheme.background)
                        
                    case 1:
                        ChatsFeedTabView(viewModel: viewModel)
                            .background(AppTheme.background)
                            
                    case 2:
                        QuickConsoleTabView(viewModel: viewModel) { actionIdentifier in
                            viewModel.performQuickAction(actionIdentifier)
                            selectedAlertMessage = "Routing to module utility: \(actionIdentifier.replacingOccurrences(of: "_", with: " ").capitalized)..."
                            showingAlert = true
                        }
                        .background(AppTheme.background)
                        
                    case 3:
                        LoanHistoryTabView(viewModel: viewModel)
                            .background(AppTheme.background)
                            
                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom) {
                    Spacer().frame(height: 80) // Prevents active scrolling content from being clipped by tab bar
                }
                
                // Floating iOS translucent tab bar capsule
                CustomFloatingTabBar(selectedTab: $viewModel.selectedTab)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .task {
            // Simulated pull on load
            await viewModel.fetchDashboardData()
        }
        .sheet(isPresented: $showNotificationSheet) {
            NotificationsFeedSheet(viewModel: viewModel)
        }
        .sheet(item: $selectedAppForReview) { app in
            LoanApplicationReviewDetailView(applicationId: app.applicationId, viewModel: viewModel)
        }
        .sheet(isPresented: $showProfileSheet) {
            LoanOfficerProfileView()
        }
        .alert(isPresented: $showingAlert) {
            Alert(
                title: Text("Module Notification"),
                message: Text(selectedAlertMessage ?? ""),
                dismissButton: .default(Text("Continue")) {
                    selectedAlertMessage = nil
                }
            )
        }
    }
    
    // Deep Link router to native bottom tabs
    private func handleAlertDeepLink(_ type: AlertChipType) {
        HapticsManager.triggerImpact(style: .light)
        switch type {
        case .overdueEMI:
            // EMI Alerts -> Switch to Registry (Tab 4), filter by On Hold
            viewModel.historyFilter = .onHold
            viewModel.historySearchQuery = ""
            withAnimation {
                viewModel.selectedTab = 3
            }
            
        case .pendingDocuments:
            // Document Queue -> Switch to Overview (Tab 1), scroll to doc queue
            withAnimation {
                viewModel.selectedTab = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                scrollTargetID = "doc_queue"
            }
            
        case .borrowerQueries:
            // Borrower Queries -> Switch directly to Chats & Feed (Tab 2)
            withAnimation {
                viewModel.selectedTab = 1
            }
            
        case .readyForManager:
            // Ready for Manager -> Switch to Overview (Tab 1), scroll to manager queue
            withAnimation {
                viewModel.selectedTab = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                scrollTargetID = "manager_loans"
            }
        }
    }
}

// MARK: - Navigation Subcomponents

struct CustomTopNavigationBar: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onNotificationPressed: () -> Void
    var onProfilePressed: () -> Void
    
    var body: some View {
        HStack(alignment: .center) {
            // Left Profile Summary
            VStack(alignment: .leading, spacing: 2) {
                Text("Good Morning, \(LoanOfficerMockData.officerName) 👋")
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)
                
                Text("Loan Officer · Branch: \(LoanOfficerMockData.branchName)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
            }
            
            Spacer()
            
            // Right Control Stack
            HStack(spacing: 12) {
                // Notifications icon
                Button(action: {
                    HapticsManager.triggerImpact(style: .light)
                    onNotificationPressed()
                }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(LMSColors.textPrimary)
                            .symbolRenderingMode(.multicolor)
                        
                        if viewModel.unreadActivityCount > 0 {
                            Text("\(viewModel.unreadActivityCount)")
                                .font(.system(size: 8, design: .rounded).bold())
                                .foregroundStyle(.white)
                                .frame(width: 12, height: 12)
                                .background(AppTheme.criticalRed)
                                .clipShape(Circle())
                                .offset(x: 4, y: -4)
                        }
                    }
                }
                .accessibilityLabel("System notifications. \(viewModel.unreadActivityCount) unread alerts.")
                
                // Avatar badge Button to open Profile Sheet
                Button(action: {
                    HapticsManager.triggerImpact(style: .medium)
                    onProfilePressed()
                }) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.brandNavy)
                            .frame(width: 32, height: 32)
                        
                        Text("AK")
                            .font(.system(.caption, design: .rounded).bold())
                            .foregroundStyle(.white)
                    }
                }
                .accessibilityLabel("Profile: Arjun Kashyap.")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(LMSColors.surface)
    }
}

// MARK: - Priority Alerts Bar
enum AlertChipType: CaseIterable {
    case overdueEMI
    case pendingDocuments
    case borrowerQueries
    case readyForManager
    
    var symbol: String {
        switch self {
        case .overdueEMI: return "exclamationmark.triangle.fill"
        case .pendingDocuments: return "clock.badge.exclamationmark"
        case .borrowerQueries: return "person.crop.circle.badge.questionmark"
        case .readyForManager: return "checkmark.seal.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .overdueEMI: return AppTheme.criticalRed
        case .pendingDocuments: return AppTheme.warningAmber
        case .borrowerQueries: return AppTheme.actionBlue
        case .readyForManager: return AppTheme.successGreen
        }
    }
    
    func title(count: Int) -> String {
        switch self {
        case .overdueEMI: return "\(count) Overdue EMI Alerts"
        case .pendingDocuments: return "\(count) Documents Pending"
        case .borrowerQueries: return "\(count) Borrower Queries"
        case .readyForManager: return "\(count) Ready for Manager"
        }
    }
}

struct PriorityAlertStrip: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onChipPressed: (AlertChipType) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // Only render chips that have counts > 0
                
                // 🔴 Overdue EMI
                let emiCount = 4
                AlertChip(type: .overdueEMI, count: emiCount, title: "4 Overdue EMI Alerts") {
                    onChipPressed(.overdueEMI)
                }
                
                // 🟡 Pending Documents
                let docsCount = viewModel.pendingDocumentCount
                if docsCount > 0 {
                    AlertChip(type: .pendingDocuments, count: docsCount, title: "\(docsCount) Documents Pending") {
                        onChipPressed(.pendingDocuments)
                    }
                }
                
                // 🔵 Borrower Queries
                let queriesCount = viewModel.activityFeed.filter { $0.eventType == .queryRaised && !$0.isRead }.count
                if queriesCount > 0 {
                    AlertChip(type: .borrowerQueries, count: queriesCount, title: "\(queriesCount) Borrower Queries") {
                        onChipPressed(.borrowerQueries)
                    }
                }
                
                // 🟢 Ready for Manager
                let managerReadyCount = 2
                AlertChip(type: .readyForManager, count: managerReadyCount, title: "2 Ready for Manager") {
                    onChipPressed(.readyForManager)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(LMSColors.surface)
    }
}

struct AlertChip: View {
    let type: AlertChipType
    let count: Int
    let title: String
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: type.symbol)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(type.color)
                
                Text(title)
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(type.color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint("Deep links to the corresponding section below.")
    }
}

// MARK: - Sheet Subviews

struct NotificationsFeedSheet: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.activityFeed.isEmpty {
                    ContentUnavailableView("No Alerts", systemImage: "bell.slash", description: Text("All is quiet here!"))
                } else {
                    ForEach(viewModel.activityFeed) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: item.eventType.symbol)
                                .foregroundStyle(item.eventType.themeColor)
                                .font(LMSFont.title3)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.borrowerName)
                                    .font(.system(.callout, design: .rounded).bold())
                                Text(item.eventDescription)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(LMSColors.textSecondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Priority Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Premium Custom Floating iOS Tab Bar
struct CustomFloatingTabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            TabBarButton(iconName: "house", activeIconName: "house.fill", title: "Overview", isSelected: selectedTab == 0) {
                selectedTab = 0
            }
            Spacer()
            TabBarButton(iconName: "bubble.left", activeIconName: "bubble.left.fill", title: "Chats", isSelected: selectedTab == 1) {
                selectedTab = 1
            }
            Spacer()
            TabBarButton(iconName: "bolt", activeIconName: "bolt.fill", title: "Console", isSelected: selectedTab == 2) {
                selectedTab = 2
            }
            Spacer()
            TabBarButton(iconName: "doc.text.magnifyingglass", activeIconName: "doc.text.magnifyingglass", title: "Registry", isSelected: selectedTab == 3) {
                selectedTab = 3
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .background(
            VisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 5)
        )
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }
}

struct TabBarButton: View {
    let iconName: String
    let activeIconName: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticsManager.triggerImpact(style: .light)
            action()
        }) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? activeIconName : iconName)
                    .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? AppTheme.actionBlue : .secondary)
                    .frame(height: 24)
                
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .semibold, design: .rounded))
                    .foregroundColor(isSelected ? AppTheme.actionBlue : .secondary)
            }
            .frame(width: 60)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView()
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
}


