import SwiftUI
import UIKit

struct LoanOfficerDashboardView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var viewModel = LoanOfficerDashboardViewModel()
    @StateObject private var notificationViewModel = NotificationViewModel()
    @State private var selectedTab: OfficerWorkspaceTab = .dashboard
    @State private var showingProfile = false

    private var appsRequiringReviewCount: Int {
        viewModel.applications.filter { app in
            app.documents.contains { $0.status != .verified }
        }.count
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                LoanOfficerTodayView(
                    viewModel: viewModel,
                    selectedTab: $selectedTab,
                    notificationViewModel: notificationViewModel,
                    onProfile: { showingProfile = true }
                )
            }
            .tabItem { Label("Dashboard", systemImage: "square.grid.2x2") }
            .tag(OfficerWorkspaceTab.dashboard)

            NavigationStack {
                LoanOfficerReviewQueueView(viewModel: viewModel)
            }
            .tabItem { Label("Review", systemImage: "checklist.checked") }
            .badge(appsRequiringReviewCount > 0 ? appsRequiringReviewCount : 0)
            .tag(OfficerWorkspaceTab.review)

            ChatsFeedTabView(viewModel: viewModel)
                .tabItem { Label("Messages", systemImage: "message") }
                .badge(viewModel.unreadActivityCount > 0 ? viewModel.unreadActivityCount : 0)
                .tag(OfficerWorkspaceTab.messages)

            NavigationStack {
                LoanHistoryTabView(viewModel: viewModel)
            }
            .tabItem { Label("Registry", systemImage: "tray.full") }
            .tag(OfficerWorkspaceTab.registry)
        }
        .tint(LMSColors.brandNavy)
        .task {
            await viewModel.fetchDashboardData()
            // Configure notification VM with current user ID
            if let userId = authManager.currentUser?.uid,
               let uuid = UUID(uuidString: userId) {
                notificationViewModel.configure(userId: uuid)
            }
        }
        .accessibleSheet(isPresented: $showingProfile) {
            LoanOfficerProfileView()
        }
    }
}

enum OfficerWorkspaceTab: Hashable {
    case dashboard
    case review
    case messages
    case registry
}

// MARK: - Dashboard Main View

private struct LoanOfficerTodayView: View {
    @EnvironmentObject var authManager: AuthManager
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @Binding var selectedTab: OfficerWorkspaceTab
    @ObservedObject var notificationViewModel: NotificationViewModel
    var onProfile: () -> Void

    @State private var selectedMetricStatus: OfficerApplicationStatus?
    @State private var selectedApplication: OfficerLoanApplication?
    @State private var showingReportConfirmation = false
    @State private var showingEscalationSheet = false
    @State private var showingPendingAppsList = false
    @State private var showingReadyToSendApps = false
    
    private var pendingApps: [OfficerLoanApplication] {
        viewModel.applications.filter { $0.status == .pending || $0.status == .applied || $0.status == .documentsPending || $0.status == .documentsRejected }
    }

    private var nextApplication: OfficerLoanApplication? {
        viewModel.applications.first { app in
            app.status == .pending || app.status == .underReview || app.status == .documentsPending || app.status == .documentsRejected
        }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: LMSSpacing.xl) {
                
                OfficerActionItemsRow(
                    viewModel: viewModel,
                    selectedTab: $selectedTab,
                    showingEscalationSheet: $showingEscalationSheet,
                    showingPendingAppsList: $showingPendingAppsList,
                    showingReadyToSendApps: $showingReadyToSendApps
                )
                .padding(.top, LMSSpacing.md)

                if let app = nextApplication {
                    OfficerNextActionCard(app: app, selectedApp: $selectedApplication)
                }

                OfficerReviewSnapshotView(
                    viewModel: viewModel,
                    selectedTab: $selectedTab,
                    selectedApplication: $selectedApplication
                )

                OfficerInlineEMICalculatorView()

                OfficerEscalationsSection(
                    viewModel: viewModel,
                    selectedApplication: $selectedApplication
                )

                OfficerAnalyticsSection(viewModel: viewModel)
                
                Spacer()
                    .frame(height: LMSSpacing.xxxl)
            }
        }
        .background(LMSColors.background)
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                NavigationLink {
                    NotificationsListView(viewModel: notificationViewModel, isPushed: true)
                } label: {
                    Image(systemName: notificationViewModel.unreadCount > 0 ? "bell.badge" : "bell")
                }
                .accessibilityLabel("Notifications")

                Button(action: onProfile) {
                    Text(authManager.currentStaffProfile?.initials ?? "AK")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(LMSColors.brandNavy.gradient, in: Circle())
                }
                .accessibilityLabel("Loan officer profile")
            }
        }
        .refreshable {
            await viewModel.fetchDashboardData()
        }
        .navigationDestination(item: $selectedApplication) { app in
            LoanApplicationReviewDetailView(applicationId: app.applicationId, viewModel: viewModel)
        }
        .alert("Report queued", isPresented: $showingReportConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The monthly branch performance report is being prepared.")
        }
        .accessibleSheet(isPresented: $showingEscalationSheet) {
            OfficerEscalationSheet(viewModel: viewModel)
        }
        .navigationDestination(isPresented: $showingPendingAppsList) {
            OfficerPushApplicationListView(
                title: "Pending Applications",
                systemImage: "tray.full.fill",
                description: "No open cases at the moment.",
                applications: pendingApps,
                viewModel: viewModel
            )
        }
        .navigationDestination(isPresented: $showingReadyToSendApps) {
            OfficerPushApplicationListView(
                title: "Send for Approval",
                systemImage: "paperplane.fill",
                description: "No applications ready to send for approval.",
                applications: viewModel.pendingManagerActionApps,
                viewModel: viewModel
            )
        }
    }
}

// MARK: - Action Items

private struct OfficerActionItemsRow: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @Binding var selectedTab: OfficerWorkspaceTab
    @Binding var showingEscalationSheet: Bool
    @Binding var showingPendingAppsList: Bool
    @Binding var showingReadyToSendApps: Bool
    
    private var pendingAppsCount: Int {
        viewModel.applications.filter { $0.status == .pending || $0.status == .applied || $0.status == .documentsPending || $0.status == .documentsRejected }.count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
            Text("Action Items")
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
                .padding(.horizontal, LMSSpacing.screenHorizontal)

            HStack(spacing: LMSSpacing.md) {
                OfficerActionCard(
                    title: "Pending Applications",
                    value: "\(pendingAppsCount)",
                    icon: "tray.full.fill",
                    tint: pendingAppsCount == 0 ? LMSColors.emerald : LMSColors.actionBlue,
                    action: {
                        HapticsManager.triggerImpact(style: .light)
                        showingPendingAppsList = true
                    }
                )

                OfficerActionCard(
                    title: "Send for Approval",
                    value: "\(viewModel.pendingManagerActionApps.count)",
                    icon: "briefcase.fill",
                    tint: viewModel.pendingManagerActionApps.isEmpty ? LMSColors.emerald : LMSColors.coral,
                    action: {
                        HapticsManager.triggerImpact(style: .light)
                        showingReadyToSendApps = true
                    }
                )
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, LMSSpacing.screenHorizontal)

        }
    }
}

private struct OfficerActionCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous)
                        .fill(tint.opacity(0.12))
                        .frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.textPrimary)
                    Text(title)
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textSecondary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(LMSSpacing.lg)
            .background(LMSColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Next Action Card

private struct OfficerNextActionCard: View {
    let app: OfficerLoanApplication
    @Binding var selectedApp: OfficerLoanApplication?

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
            Text("Next Best Action")
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
                .padding(.horizontal, LMSSpacing.screenHorizontal)

            Button {
                selectedApp = app
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    OfficerAvatar(name: app.borrowerName, tint: app.loanType.themeColor)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.borrowerName)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(LMSColors.textPrimary)
                        Text("\(app.loanType.rawValue) · \(CurrencyFormatter.shared.format(app.requestedAmount))")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(LMSColors.textSecondary)
                        Text(app.status.rawValue)
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(app.status.themeColor)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(LMSColors.textTertiary)
                }
                .padding(LMSSpacing.lg)
                .background(LMSColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, LMSSpacing.screenHorizontal)
        }
    }
}

// MARK: - Review Queue Snapshot

private struct OfficerReviewSnapshotView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @Binding var selectedTab: OfficerWorkspaceTab
    @Binding var selectedApplication: OfficerLoanApplication?

    private var appsWithPendingDocsToday: [OfficerLoanApplication] {
        viewModel.applications.filter { app in
            app.documents.contains { doc in
                doc.status != .verified && Calendar.current.isDateInToday(doc.uploadedDate ?? app.submittedDate)
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
            HStack {
                Text("Today's approval")
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)

                Spacer()

                NavigationLink {
                    OfficerTodayReviewQueueListView(viewModel: viewModel)
                } label: {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(.subheadline, design: .rounded).bold())
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(LMSColors.actionBlue)
                }
                .simultaneousGesture(TapGesture().onEnded {
                    HapticsManager.triggerImpact(style: .light)
                })
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)

            if appsWithPendingDocsToday.isEmpty {
                ContentUnavailableView(
                    "All caught up",
                    systemImage: "checkmark.circle.fill"
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, LMSSpacing.xl)
                .background(LMSColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                        .stroke(LMSColors.separatorLight, lineWidth: 0.5)
                )
                .padding(.horizontal, LMSSpacing.screenHorizontal)
            } else {
                VStack(spacing: LMSSpacing.md) {
                    ForEach(appsWithPendingDocsToday.prefix(2)) { app in
                        let todayPendingDocs = app.documents.filter { doc in
                            doc.status != .verified && Calendar.current.isDateInToday(doc.uploadedDate ?? app.submittedDate)
                        }
                        OfficerApplicationReviewCard(application: app, matchingDocuments: todayPendingDocs, viewModel: viewModel)
                    }
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)
            }
        }
    }
}

// MARK: - Inline EMI Calculator

private struct OfficerInlineEMICalculatorView: View {
    @State private var amountText = "2500000"
    @State private var rateText = "8.65"
    @State private var tenureText = "15"

    private var principalAmount: Double {
        parsedValue(amountText)
    }

    private var annualRate: Double {
        parsedValue(rateText)
    }

    private var tenureYears: Double {
        max(parsedValue(tenureText), 0)
    }

    private var totalMonths: Double {
        tenureYears * 12
    }

    private var monthlyEMI: Double {
        guard principalAmount > 0, totalMonths > 0 else { return 0 }

        let monthlyRate = (annualRate / 100) / 12
        if monthlyRate <= 0 {
            return principalAmount / totalMonths
        }

        let compound = pow(1 + monthlyRate, totalMonths)
        let emi = principalAmount * monthlyRate * compound / (compound - 1)
        return emi.isFinite ? emi : 0
    }

    private var totalPayable: Double {
        monthlyEMI * totalMonths
    }

    private var totalInterest: Double {
        max(totalPayable - principalAmount, 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("EMI Calculator")
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
                .padding(.horizontal, LMSSpacing.screenHorizontal)

            VStack(alignment: .leading, spacing: LMSSpacing.lg) {
                HStack(alignment: .top, spacing: LMSSpacing.md) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(LMSColors.brandNavy)
                            .frame(width: 54, height: 54)

                        Image(systemName: "plus.forwardslash.minus")
                            .font(.system(size: 21, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Monthly EMI")
                            .font(.system(.caption, design: .rounded).bold())
                            .foregroundStyle(LMSColors.textSecondary)

                        Text(CurrencyFormatter.shared.format(monthlyEMI))
                            .font(.system(.title2, design: .rounded).bold())
                            .foregroundStyle(LMSColors.textPrimary)
                            .contentTransition(.numericText())
                    }

                    Spacer(minLength: 0)
                }

                HStack(spacing: LMSSpacing.sm) {
                    CalculatorMetricChip(title: "Interest", value: CurrencyFormatter.shared.format(totalInterest))
                    CalculatorMetricChip(title: "Total", value: CurrencyFormatter.shared.format(totalPayable))
                }

                VStack(spacing: LMSSpacing.md) {
                    CalculatorInputRow(
                        title: "Amount",
                        value: $amountText,
                        prefix: "Rs",
                        suffix: nil,
                        keyboard: .numberPad
                    )

                    CalculatorInputRow(
                        title: "Rate",
                        value: $rateText,
                        prefix: nil,
                        suffix: "%",
                        keyboard: .decimalPad
                    )

                    CalculatorInputRow(
                        title: "Time",
                        value: $tenureText,
                        prefix: nil,
                        suffix: "Years",
                        keyboard: .numberPad
                    )
                }
            }
            .padding(LMSSpacing.lg)
            .background(LMSColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                    .stroke(LMSColors.separatorLight, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
            .padding(.horizontal, LMSSpacing.screenHorizontal)
        }
    }

    private func parsedValue(_ text: String) -> Double {
        let sanitized = text.replacingOccurrences(of: ",", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Double(sanitized) ?? 0
    }
}

private struct CalculatorMetricChip: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.caption2, design: .rounded).bold())
                .foregroundStyle(LMSColors.textSecondary)
            Text(value)
                .font(.system(.caption, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LMSSpacing.md)
        .padding(.vertical, LMSSpacing.sm)
        .background(LMSColors.background, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct CalculatorInputRow: View {
    let title: String
    @Binding var value: String
    let prefix: String?
    let suffix: String?
    let keyboard: UIKeyboardType

    var body: some View {
        HStack(spacing: LMSSpacing.md) {
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(LMSColors.textPrimary)
                .frame(width: 58, alignment: .leading)

            HStack(spacing: 8) {
                if let prefix {
                    Text(prefix)
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textSecondary)
                }

                TextField("0", text: $value)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(LMSColors.textPrimary)
                    .keyboardType(keyboard)
                    .multilineTextAlignment(.trailing)

                if let suffix {
                    Text(suffix)
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textSecondary)
                }
            }
            .padding(.horizontal, LMSSpacing.md)
            .frame(height: 44)
            .background(LMSColors.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(LMSColors.separatorLight, lineWidth: 0.5)
            )
        }
    }
}

// MARK: - Escalations Section

private struct OfficerEscalationsSection: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @Binding var selectedApplication: OfficerLoanApplication?

    var body: some View {
        let needsClarification = viewModel.sentToManagerApps.filter { $0.managerStatus == .needsClarification }

        if !needsClarification.isEmpty {
            VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                Text("Escalations")
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)
                    .padding(.horizontal, LMSSpacing.screenHorizontal)

                VStack(spacing: 0) {
                    ForEach(Array(needsClarification.enumerated()), id: \.element.id) { index, app in
                        Button {
                            selectedApplication = app
                        } label: {
                            OfficerApplicationCompactRow(app: app, accessory: "Respond")
                        }
                        .buttonStyle(.plain)

                        if index < needsClarification.count - 1 {
                            Divider().padding(.leading, 72)
                        }
                    }
                }
                .background(LMSColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                .padding(.horizontal, LMSSpacing.screenHorizontal)
            }
        }
    }
}

// MARK: - Analytics Section

private struct OfficerAnalyticsSection: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @State private var showPipelineDetails = false

    private var stats: (pending: Int, underReview: Int, sentToManager: Int, completed: Int) {
        let pending = viewModel.applications.filter { $0.status == .pending || $0.status == .applied || $0.status == .documentsPending || $0.status == .documentsRejected }.count
        let underReview = viewModel.applications.filter { $0.status == .underReview }.count
        let sent = viewModel.pendingManagerActionApps.count
        let completed = viewModel.applications.filter { $0.status == .approved || $0.status == .disbursed || $0.status == .rejected }.count
        return (pending, underReview, sent, completed)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
            Text("Assigned applications")
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
                .padding(.horizontal, LMSSpacing.screenHorizontal)
            
            Button(action: {
                HapticsManager.triggerImpact(style: .medium)
                showPipelineDetails = true
            }) {
                VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                    OfficerPipelineBars(stats: stats)
                }
                .padding(.horizontal, LMSSpacing.lg)
                .padding(.vertical, LMSSpacing.xl)
                .background(LMSColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, LMSSpacing.screenHorizontal)
        }
        .accessibleSheet(isPresented: $showPipelineDetails) {
            LoanOfficerPipelineDetailsSheet(viewModel: viewModel)
        }
    }
}

private struct OfficerPipelineBars: View {
    let stats: (pending: Int, underReview: Int, sentToManager: Int, completed: Int)
    @State private var animated = false

    private var totalCount: Int {
        stats.pending + stats.underReview + stats.sentToManager + stats.completed
    }

    private var chartTotal: Double {
        max(Double(totalCount), 1)
    }

    private var rows: [(label: String, count: Int, color: Color, icon: String)] {
        [
            ("Docs Needed", stats.pending, LMSColors.amber, "doc.text.fill"),
            ("Under Review", stats.underReview, LMSColors.actionBlue, "magnifyingglass"),
            ("With Manager", stats.sentToManager, Color.purple, "briefcase.fill"),
            ("Closed", stats.completed, LMSColors.emerald, "checkmark.seal.fill")
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(totalCount)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.textPrimary)
                    Text("Total cases")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(LMSColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(LMSColors.textTertiary)
                    .padding(.top, 6)
            }

            VStack(spacing: 12) {
                ForEach(rows, id: \.label) { row in
                    PipelineBarRow(
                        label: row.label,
                        count: row.count,
                        total: chartTotal,
                        color: row.color,
                        icon: row.icon,
                        animated: animated
                    )
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.65).delay(0.15)) {
                animated = true
            }
        }
    }
}

private struct PipelineBarRow: View {
    let label: String
    let count: Int
    let total: Double
    let color: Color
    let icon: String
    let animated: Bool

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(max(Double(count) / total, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 18)

                Text(label)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(LMSColors.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text("\(count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(LMSColors.textPrimary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LMSColors.separatorLight)

                    Capsule()
                        .fill(color)
                        .frame(width: animated ? max(proxy.size.width * progress, count == 0 ? 0 : 8) : 0)
                }
            }
            .frame(height: 8)
        }
    }
}


// MARK: - Today's approval List

private struct OfficerTodayReviewQueueListView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel

    private var todayApplications: [(application: OfficerLoanApplication, matchingDocuments: [LoanDocument])] {
        viewModel.applications.compactMap { application in
            let todayDocs = application.documents.filter { doc in
                doc.status != .verified && Calendar.current.isDateInToday(doc.uploadedDate ?? application.submittedDate)
            }
            return todayDocs.isEmpty ? nil : (application, todayDocs)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: LMSSpacing.md) {
                if todayApplications.isEmpty {
                    ContentUnavailableView(
                        "All caught up",
                        systemImage: "checkmark.circle.fill"
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(todayApplications, id: \.application.id) { pair in
                        OfficerApplicationReviewCard(
                            application: pair.application,
                            matchingDocuments: pair.matchingDocuments,
                            viewModel: viewModel
                        )
                    }
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                }
            }
            .padding(.vertical, LMSSpacing.md)
        }
        .background(LMSColors.background)
        .navigationTitle("Today's approval")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Review Queue Tab

private struct LoanOfficerReviewQueueView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @State private var query = ""
    @State private var selectedStatus: OfficerDocumentStatus?

    private var filteredApplications: [(application: OfficerLoanApplication, matchingDocuments: [LoanDocument])] {
        viewModel.applications.compactMap { application in
            let docs = application.documents.filter { doc in
                let matchesQuery = query.isEmpty 
                    || application.borrowerName.localizedCaseInsensitiveContains(query) 
                    || application.applicationId.localizedCaseInsensitiveContains(query) 
                    || doc.docType.rawValue.localizedCaseInsensitiveContains(query)
                
                let matchesStatus = selectedStatus == nil || doc.status == selectedStatus
                return matchesQuery && matchesStatus
            }
            return docs.isEmpty ? nil : (application, docs)
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: LMSSpacing.md) {
                if filteredApplications.isEmpty {
                    ContentUnavailableView("No documents", systemImage: "doc.text.magnifyingglass", description: Text("Try a different search or status."))
                        .padding(.top, 40)
                } else {
                    ForEach(filteredApplications, id: \.application.id) { pair in
                        OfficerApplicationReviewCard(
                            application: pair.application,
                            matchingDocuments: pair.matchingDocuments,
                            viewModel: viewModel
                        )
                    }
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                }
            }
            .padding(.vertical, LMSSpacing.md)
        }
        .background(LMSColors.background)
        .navigationTitle("Review")
        .searchable(text: $query, prompt: "Borrower, document, application")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Filter by Status", selection: $selectedStatus) {
                        Text("All").tag(Optional<OfficerDocumentStatus>.none)
                        Text("New").tag(Optional(OfficerDocumentStatus.uploaded))
                        Text("Re-upload").tag(Optional(OfficerDocumentStatus.reUploaded))
                        Text("Missing").tag(Optional(OfficerDocumentStatus.pending))
                    }
                } label: {
                    Label("Filter", systemImage: selectedStatus == nil ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                }
            }
        }
        .refreshable { await viewModel.fetchDashboardData() }
    }
}

// MARK: - Escalation Sheet

private struct OfficerEscalationSheet: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    @State private var priority = "Normal"
    @State private var selectedApplicationId: String = ""
    @State private var errorMessage: String?

    private var escalatableApplications: [OfficerLoanApplication] {
        viewModel.escalatableApplications
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Application") {
                    if escalatableApplications.isEmpty {
                        Text("No active applications available to escalate.")
                            .foregroundStyle(LMSColors.textSecondary)
                    } else {
                        Picker("Select Loan", selection: $selectedApplicationId) {
                            Text("Choose application").tag("")
                            ForEach(escalatableApplications) { app in
                                Text("\(app.applicationId) · \(app.borrowerName)").tag(app.applicationId)
                            }
                        }
                    }
                }

                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        Text("Normal").tag("Normal")
                        Text("High").tag("High")
                        Text("Critical").tag("Critical")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Reason") {
                    TextField("Describe why this case needs manager review", text: $reason, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    Text("The branch manager will see this escalation under Officer Performance with your name and the loan details.")
                        .font(.footnote)
                        .foregroundStyle(LMSColors.textSecondary)
                }
            }
            .navigationTitle("Escalate Case")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") { submitEscalation() }
                        .disabled(!canSubmit)
                }
            }
            .alert("Escalation Failed", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .onAppear {
                if selectedApplicationId.isEmpty {
                    selectedApplicationId = escalatableApplications.first?.applicationId ?? ""
                }
            }
        }
    }

    private var canSubmit: Bool {
        !selectedApplicationId.isEmpty
            && !reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !escalatableApplications.isEmpty
    }

    private func submitEscalation() {
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        let composedReason = "[\(priority)] \(trimmedReason)"
        guard viewModel.escalateApplication(applicationId: selectedApplicationId, reason: composedReason) else {
            errorMessage = "Could not escalate this application. It may already be closed or escalated."
            return
        }
        HapticsManager.triggerNotification(type: .success)
        dismiss()
    }
}

// MARK: - Document Row

struct OfficerDocumentRow: View {
    let item: DocumentQueueItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.docType.symbol)
                .font(.system(.headline, design: .rounded).weight(.semibold))
                .foregroundStyle(item.docType.iconColor)
                .frame(width: 44, height: 44)
                .background(item.docType.iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.borrowerName)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(LMSColors.textPrimary)
                    .lineLimit(1)
                Text("\(item.docType.rawValue) · \(item.applicationId)")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }

            Spacer(minLength: 4)

            Text(item.status.rawValue)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(item.status.themeColor)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(item.status.themeColor.opacity(0.12), in: Capsule())
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.vertical, 10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.borrowerName), \(item.docType.rawValue), \(item.status.rawValue)")
    }
}

// MARK: - Application Compact Row

struct OfficerApplicationCompactRow: View {
    let app: OfficerLoanApplication
    var accessory: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            OfficerAvatar(name: app.borrowerName, tint: app.loanType.themeColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(app.borrowerName)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(LMSColors.textPrimary)
                Text("\(app.loanType.rawValue) · \(app.applicationId)")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
            }
            Spacer()
            if let accessory {
                Text(accessory)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(LMSColors.actionBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(LMSColors.actionBlue.opacity(0.12), in: Capsule())
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(LMSColors.textTertiary)
            }
        }
        .padding(LMSSpacing.lg)
    }
}

// MARK: - Avatar

struct OfficerAvatar: View {
    let name: String
    var tint: Color = .blue

    private var initials: String {
        name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined().uppercased()
    }

    var body: some View {
        Text(initials)
            .font(.system(.subheadline, design: .rounded).weight(.bold))
            .foregroundStyle(tint)
            .frame(width: 44, height: 44)
            .background(tint.opacity(0.12), in: Circle())
    }
}

// MARK: - Notifications Sheet

struct NotificationsFeedSheet: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if viewModel.activityFeed.isEmpty {
                    ContentUnavailableView("No Notifications", systemImage: "bell.slash", description: Text("All priority work is clear."))
                } else {
                    ForEach(viewModel.activityFeed) { item in
                        HStack(alignment: .top, spacing: 14) {
                            if !item.isRead {
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 10, height: 10)
                                    .padding(.top, 12)
                            } else {
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 10, height: 10)
                                    .padding(.top, 12)
                            }
                            
                            Image(systemName: item.eventType.symbol)
                                .font(.title3)
                                .foregroundStyle(item.eventType.themeColor)
                                .frame(width: 36, height: 36)
                                .background(item.eventType.themeColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                                
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(item.borrowerName)
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Text(RelativeDateFormatter.shared.relativeString(from: item.timestamp))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Text(item.eventDescription)
                                    .font(.subheadline)
                                    .foregroundStyle(!item.isRead ? .primary : .secondary)
                                    .lineLimit(3)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.vertical, 6)
                        .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 8, trailing: 16))
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
private struct LoanOfficerPipelineDetailsSheet: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @Environment(\.dismiss) var dismiss

    private var pendingApps: [OfficerLoanApplication] {
        viewModel.applications.filter { $0.status == .pending || $0.status == .applied || $0.status == .documentsPending || $0.status == .documentsRejected }
    }
    
    private var underReviewApps: [OfficerLoanApplication] {
        viewModel.applications.filter { $0.status == .underReview }
    }
    
    private var sentToManagerApps: [OfficerLoanApplication] {
        viewModel.pendingManagerActionApps
    }
    
    private var completedApps: [OfficerLoanApplication] {
        viewModel.applications.filter { $0.status == .approved || $0.status == .disbursed || $0.status == .rejected }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.applications.isEmpty {
                    ContentUnavailableView(
                        "No Cases",
                        systemImage: "folder.badge.minus",
                        description: Text("No applications have been assigned to you yet.")
                    )
                } else {
                    List {
                        PipelineSection(title: "Docs Needed", applications: pendingApps, icon: "doc.text.fill", tint: LMSColors.amber)
                        PipelineSection(title: "Under Review", applications: underReviewApps, icon: "magnifyingglass", tint: LMSColors.actionBlue)
                        PipelineSection(title: "With Manager", applications: sentToManagerApps, icon: "briefcase.fill", tint: Color.purple)
                        PipelineSection(title: "Closed", applications: completedApps, icon: "checkmark.seal.fill", tint: LMSColors.emerald)
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Pipeline Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .font(.system(.body, design: .rounded).bold())
                }
            }
        }
    }
}

private struct PipelineSection: View {
    let title: String
    let applications: [OfficerLoanApplication]
    let icon: String
    let tint: Color

    var body: some View {
        if !applications.isEmpty {
            Section {
                ForEach(applications) { app in
                    HStack(spacing: LMSSpacing.md) {
                        OfficerAvatar(name: app.borrowerName, tint: app.loanType.themeColor)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.borrowerName)
                                .font(.system(.callout, design: .rounded).bold())
                                .foregroundStyle(LMSColors.textPrimary)
                            Text("\(app.loanType.rawValue) · \(app.applicationId)")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(LMSColors.textSecondary)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(CurrencyFormatter.shared.format(app.requestedAmount))
                                .font(.system(.subheadline, design: .rounded).bold())
                                .foregroundStyle(LMSColors.textPrimary)
                            
                            Text(app.status.displayName)
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(app.status.themeColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(app.status.themeColor.opacity(0.12), in: Capsule())
                        }
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                HStack {
                    Image(systemName: icon)
                    Text(title)
                    Spacer()
                    Text("\(applications.count)")
                }
                .font(.system(.subheadline, design: .rounded).bold())
                .foregroundStyle(tint)
            }
        }
    }
}

private struct OfficerApplicationListSheet: View {
    let title: String
    let systemImage: String
    let description: String
    let applications: [OfficerLoanApplication]
    
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @State private var selectedApplication: OfficerLoanApplication?
    
    var body: some View {
        NavigationStack {
            Group {
                if applications.isEmpty {
                    ContentUnavailableView(
                        title,
                        systemImage: systemImage,
                        description: Text(description)
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: LMSSpacing.sm) {
                            ForEach(applications) { application in
                                Button(action: {
                                    HapticsManager.triggerImpact(style: .medium)
                                    selectedApplication = application
                                }) {
                                    OfficerApplicationCompactRow(app: application, accessory: "View")
                                }
                                .buttonStyle(LMSPressableStyle())
                            }
                        }
                        .padding(LMSSpacing.screenHorizontal)
                        .padding(.vertical, LMSSpacing.md)
                    }
                    .background(LMSColors.background)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .navigationDestination(item: $selectedApplication) { application in
                LoanApplicationReviewDetailView(applicationId: application.applicationId, viewModel: viewModel)
            }
        }
    }
}

private struct OfficerPushApplicationListView: View {
    let title: String
    let systemImage: String
    let description: String
    let applications: [OfficerLoanApplication]
    
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @State private var selectedApplication: OfficerLoanApplication?
    
    var body: some View {
        Group {
            if applications.isEmpty {
                ContentUnavailableView(
                    title,
                    systemImage: systemImage,
                    description: Text(description)
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: LMSSpacing.sm) {
                        ForEach(applications) { application in
                            Button(action: {
                                HapticsManager.triggerImpact(style: .medium)
                                selectedApplication = application
                            }) {
                                OfficerApplicationCompactRow(app: application, accessory: "View")
                            }
                            .buttonStyle(LMSPressableStyle())
                        }
                    }
                    .padding(LMSSpacing.screenHorizontal)
                    .padding(.vertical, LMSSpacing.md)
                }
                .background(LMSColors.background)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedApplication) { application in
            LoanApplicationReviewDetailView(applicationId: application.applicationId, viewModel: viewModel)
        }
    }
}

// MARK: - Grouped Application Review Card

struct OfficerApplicationReviewCard: View {
    let application: OfficerLoanApplication
    let matchingDocuments: [LoanDocument]
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header: Borrower Avatar, Name, Loan details, status
            NavigationLink {
                LoanApplicationReviewDetailView(applicationId: application.applicationId, viewModel: viewModel)
            } label: {
                HStack(spacing: 12) {
                    OfficerAvatar(name: application.borrowerName, tint: application.loanType.themeColor)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(application.borrowerName)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(LMSColors.textPrimary)
                        
                        Text("\(application.loanType.rawValue) · \(CurrencyFormatter.shared.format(application.requestedAmount))")
                            .font(.system(.caption, design: .rounded).weight(.medium))
                            .foregroundStyle(LMSColors.textSecondary)
                        
                        Text("App ID: \(application.applicationId)")
                            .font(.system(.caption2, design: .rounded).monospaced())
                            .foregroundStyle(LMSColors.textTertiary)
                    }
                    
                    Spacer()
                    
                    // Document progress indicator
                    VStack(alignment: .trailing, spacing: 4) {
                        let total = application.documents.count
                        let verified = application.documents.filter { $0.status == .verified }.count
                        Text("\(verified)/\(total) Verified")
                            .font(.system(.caption2, design: .rounded).bold())
                            .foregroundStyle(verified == total ? LMSColors.emerald : LMSColors.actionBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background((verified == total ? LMSColors.emerald : LMSColors.actionBlue).opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
            .buttonStyle(.plain)
            
            Divider()
                .padding(.vertical, 4)
            
            // Nested documents list
            VStack(spacing: 8) {
                ForEach(matchingDocuments) { doc in
                    NavigationLink {
                        LoanApplicationReviewDetailView(
                            applicationId: application.applicationId,
                            initialDocumentId: doc.id,
                            viewModel: viewModel
                        )
                    } label: {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(doc.docType.iconColor.opacity(0.12))
                                    .frame(width: 32, height: 32)
                                Image(systemName: doc.docType.symbol)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(doc.docType.iconColor)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(doc.docType.rawValue)
                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                                    .foregroundStyle(LMSColors.textPrimary)
                                
                                if let reason = doc.rejectionReason {
                                    Text(reason)
                                        .font(.system(size: 10))
                                        .foregroundStyle(LMSColors.coral)
                                } else {
                                    Text(doc.status.rawValue)
                                        .font(.system(size: 10))
                                        .foregroundStyle(LMSColors.textSecondary)
                                }
                            }
                            
                            Spacer()
                            
                            // Status tag
                            Text(doc.status.rawValue)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(doc.status == .pending ? LMSColors.amber : .white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(doc.status == .pending ? LMSColors.amber.opacity(0.15) : doc.status.themeColor)
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(LMSColors.textTertiary)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(LMSColors.surfaceElevated.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .background(LMSColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
    

}

// MARK: - Calculator Sheet

struct OfficerCalculatorSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var principalAmount: Double = 2500000.0
    @State private var interestRate: Double = 8.65
    @State private var tenureYears: Double = 15.0

    private var calculatedEMI: Double {
        let monthlyRate = (interestRate / 100.0) / 12.0
        let totalMonths = tenureYears * 12.0
        guard monthlyRate > 0 else { return principalAmount / totalMonths }
        let emi = principalAmount * (monthlyRate * pow(1.0 + monthlyRate, totalMonths)) / (pow(1.0 + monthlyRate, totalMonths) - 1.0)
        return emi.isNaN ? 0.0 : emi
    }

    private var totalInterest: Double {
        (calculatedEMI * tenureYears * 12.0) - principalAmount
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: LMSSpacing.xl) {
                    // Output metrics
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Monthly EMI")
                                .font(.system(.caption, design: .rounded).bold())
                                .foregroundStyle(LMSColors.textSecondary)
                            Text(CurrencyFormatter.shared.format(calculatedEMI))
                                .font(.system(.title, design: .rounded).bold())
                                .foregroundStyle(LMSColors.actionBlue)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Total Interest Payable")
                                .font(.system(.caption, design: .rounded).bold())
                                .foregroundStyle(LMSColors.textSecondary)
                            Text(CurrencyFormatter.shared.format(totalInterest))
                                .font(.system(.body, design: .rounded).bold())
                                .foregroundStyle(LMSColors.textPrimary)
                        }
                    }
                    .padding(LMSSpacing.lg)
                    .background(LMSColors.actionBlue.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))

                    // Sliders
                    VStack(spacing: LMSSpacing.lg) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Principal Loan Amount")
                                    .font(.system(.caption, design: .rounded).weight(.bold))
                                Spacer()
                                Text(CurrencyFormatter.shared.format(principalAmount))
                                    .font(.system(.caption, design: .rounded).bold())
                                    .foregroundStyle(LMSColors.actionBlue)
                            }
                            Slider(value: $principalAmount, in: 500000...10000000, step: 100000)
                                .tint(LMSColors.actionBlue)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Interest Rate (p.a.)")
                                    .font(.system(.caption, design: .rounded).weight(.bold))
                                Spacer()
                                Text(String(format: "%.2f %%", interestRate))
                                    .font(.system(.caption, design: .rounded).bold())
                                    .foregroundStyle(LMSColors.actionBlue)
                            }
                            Slider(value: $interestRate, in: 5.0...15.0, step: 0.05)
                                .tint(LMSColors.actionBlue)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Tenure Duration")
                                    .font(.system(.caption, design: .rounded).weight(.bold))
                                Spacer()
                                Text("\(Int(tenureYears)) Years")
                                    .font(.system(.caption, design: .rounded).bold())
                                    .foregroundStyle(LMSColors.actionBlue)
                            }
                            Slider(value: $tenureYears, in: 1...30, step: 1)
                                .tint(LMSColors.actionBlue)
                        }
                    }
                    .padding(LMSSpacing.lg)
                    .background(LMSColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)
                .padding(.top, LMSSpacing.md)
            }
            .background(LMSColors.background)
            .navigationTitle("Quick Financial Calculator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(.body, design: .rounded).bold())
                }
            }
        }
    }
}
