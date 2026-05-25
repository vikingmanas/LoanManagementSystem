 import SwiftUI

struct LoanOfficerDashboardView: View {
    typealias LoanApplication = OfficerLoanApplication
    @StateObject private var viewModel = LoanOfficerDashboardViewModel()
    @State private var scrollTargetID: String? = nil


    @State private var showNotificationSheet = false
    @State private var showingAlert = false
    @State private var selectedAlertMessage: String? = nil
    @State private var selectedAppForReview: LoanApplication? = nil
    @State private var showProfileSheet = false

    var body: some View {
        VStack(spacing: 0) {


            if viewModel.selectedTab != 3 && viewModel.selectedTab != 1 {
                CustomTopNavigationBar(
                    viewModel: viewModel,
                    onNotificationPressed: {
                        showNotificationSheet = true
                    },
                    onProfilePressed: {
                        showProfileSheet = true
                    }
                )
            }


            TabView(selection: $viewModel.selectedTab) {
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
                            handleOverviewQuickAction(actionIdentifier)
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
                    Label("Overview", systemImage: "house")
                }
                .tag(0)

                ChatsFeedTabView(viewModel: viewModel)
                    .background(AppTheme.background)
                    .tabItem {
                        Label("Chats", systemImage: "bubble.left")
                    }
                    .tag(1)

                QuickConsoleTabView(viewModel: viewModel) { actionIdentifier in
                    handleOverviewQuickAction(actionIdentifier)
                }
                .background(AppTheme.background)
                .tabItem {
                    Label("Console", systemImage: "bolt")
                }
                .tag(2)

                LoanHistoryTabView(viewModel: viewModel)
                    .background(AppTheme.background)
                    .tabItem {
                        Label("Registry", systemImage: "doc.text.magnifyingglass")
                    }
                    .tag(3)
            }
        }
        .task {

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

    private func handleOverviewQuickAction(_ actionIdentifier: String) {
        switch actionIdentifier {
        case "verify_docs", "verify_documents":
            handleAlertDeepLink(.pendingDocuments)
        case "reports", "branch_reports":
            HapticsManager.triggerNotification(type: .success)
            selectedAlertMessage = "Generating and downloading the Branch Monthly Performance Report..."
            showingAlert = true
        case "escalate", "escalate_case":
            HapticsManager.triggerNotification(type: .warning)
            selectedAlertMessage = "Operational Escalation submitted successfully to Branch Manager."
            showingAlert = true
        default:
            viewModel.performQuickAction(actionIdentifier)
            selectedAlertMessage = "Routing to module utility: \(actionIdentifier.replacingOccurrences(of: "_", with: " ").capitalized)..."
            showingAlert = true
        }
    }


    private func handleAlertDeepLink(_ type: AlertChipType) {
        HapticsManager.triggerImpact(style: .light)
        switch type {
        case .overdueEMI:

            viewModel.historyFilter = .onHold
            viewModel.historySearchQuery = ""
            withAnimation {
                viewModel.selectedTab = 3
            }

        case .pendingDocuments:

            withAnimation {
                viewModel.selectedTab = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                scrollTargetID = "doc_queue"
            }

        case .borrowerQueries:

            withAnimation {
                viewModel.selectedTab = 1
            }

        case .readyForManager:

            withAnimation {
                viewModel.selectedTab = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                scrollTargetID = "manager_loans"
            }
        }
    }
}



struct CustomTopNavigationBar: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onNotificationPressed: () -> Void
    var onProfilePressed: () -> Void

    var body: some View {
        HStack(alignment: .center) {

            VStack(alignment: .leading, spacing: 2) {
                Text("Good Morning, \(LoanOfficerMockData.officerName) 👋")
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)

                Text("Loan Officer · Branch: \(LoanOfficerMockData.branchName)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
            }

            Spacer()


            HStack(spacing: 12) {

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
        .padding(.bottom, 8)
        .background(AppTheme.background)
    }
}


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



                let emiCount = 4
                AlertChip(type: .overdueEMI, count: emiCount, title: "4 Overdue EMI Alerts") {
                    onChipPressed(.overdueEMI)
                }


                let docsCount = viewModel.pendingDocumentCount
                if docsCount > 0 {
                    AlertChip(type: .pendingDocuments, count: docsCount, title: "\(docsCount) Documents Pending") {
                        onChipPressed(.pendingDocuments)
                    }
                }


                let queriesCount = viewModel.activityFeed.filter { $0.eventType == .queryRaised && !$0.isRead }.count
                if queriesCount > 0 {
                    AlertChip(type: .borrowerQueries, count: queriesCount, title: "\(queriesCount) Borrower Queries") {
                        onChipPressed(.borrowerQueries)
                    }
                }


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


#Preview {
    LoanOfficerDashboardView()
        .previewLoanOfficerEnvironment()
}

