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
            
            // 1. CUSTOM TOP NAVIGATION BAR (Fixed)
            CustomTopNavigationBar(
                viewModel: viewModel,
                onNotificationPressed: {
                    showNotificationSheet = true
                },
                onProfilePressed: {
                    showProfileSheet = true
                }
            )
            
            // 2. PRIORITY ALERT STRIP (Horizontal Chips)
            if !viewModel.isLoading {
                PriorityAlertStrip(viewModel: viewModel) { alertType in
                    handleAlertDeepLink(alertType)
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Divider()
            
            // 3. NATIVE TABVIEW CONTAINER
            TabView(selection: $viewModel.selectedTab) {
                
                // TAB 1: OVERVIEW WORKSPACE
                ScrollViewReader { proxy in
                    DashboardTabView(
                        viewModel: viewModel,
                        onDocumentSeeAllTapped: {
                            handleAlertDeepLink(.pendingDocuments)
                        },
                        onManagerRespondTapped: { app in
                            HapticsManager.triggerImpact(style: .medium)
                            selectedAppForReview = app
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
                .tabItem {
                    Label("Overview", systemImage: "house.fill")
                }
                .tag(0)
                
                // TAB 2: CHATS & ACTIVITY
                ChatsFeedTabView(viewModel: viewModel)
                    .background(AppTheme.background)
                    .tabItem {
                        Label("Chats & Feed", systemImage: "bubble.left.and.bubble.right.fill")
                    }
                    .tag(1)
                
                // TAB 3: QUICK CONSOLE
                QuickConsoleTabView(viewModel: viewModel) { actionIdentifier in
                    viewModel.performQuickAction(actionIdentifier)
                    selectedAlertMessage = "Routing to module utility: \(actionIdentifier.replacingOccurrences(of: "_", with: " ").capitalized)..."
                    showingAlert = true
                }
                .background(AppTheme.background)
                .tabItem {
                    Label("Quick Console", systemImage: "bolt.fill")
                }
                .tag(2)
                
                // TAB 4: LOAN REGISTRY / HISTORY
                LoanHistoryTabView(viewModel: viewModel)
                    .background(AppTheme.background)
                    .tabItem {
                        Label("Registry", systemImage: "doc.text.magnifyingglass")
                    }
                    .tag(3)
            }
            .tint(AppTheme.actionBlue) // Tint active bottom icons blue
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
                    .foregroundColor(.primary)
                
                Text("Loan Officer · Branch: \(LoanOfficerMockData.branchName)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
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
                            .foregroundColor(.primary)
                            .symbolRenderingMode(.multicolor)
                        
                        if viewModel.unreadActivityCount > 0 {
                            Text("\(viewModel.unreadActivityCount)")
                                .font(.system(size: 8, design: .rounded).bold())
                                .foregroundColor(.white)
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
                            .foregroundColor(.white)
                    }
                }
                .accessibilityLabel("Profile: Arjun Kashyap.")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(Color(.systemBackground))
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
        .background(Color(.systemBackground))
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
                    .foregroundColor(type.color)
                
                Text(title)
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
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
                                .foregroundColor(item.eventType.themeColor)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.borrowerName)
                                    .font(.system(.callout, design: .rounded).bold())
                                Text(item.eventDescription)
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.secondary)
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
