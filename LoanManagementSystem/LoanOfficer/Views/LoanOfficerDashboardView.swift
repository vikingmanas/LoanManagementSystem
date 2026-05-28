import SwiftUI
import UIKit

struct LoanOfficerDashboardView: View {
    @StateObject private var viewModel = LoanOfficerDashboardViewModel()
    @State private var selectedTab: OfficerWorkspaceTab = .dashboard
    @State private var showingNotifications = false
    @State private var showingProfile = false

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                LoanOfficerTodayView(
                    viewModel: viewModel,
                    selectedTab: $selectedTab,
                    onNotifications: { showingNotifications = true },
                    onProfile: { showingProfile = true }
                )
            }
            .tabItem { Label("Dashboard", systemImage: "square.grid.2x2") }
            .tag(OfficerWorkspaceTab.dashboard)

            NavigationStack {
                LoanOfficerReviewQueueView(viewModel: viewModel)
            }
            .tabItem { Label("Review", systemImage: "checklist.checked") }
            .badge(viewModel.pendingDocumentCount > 0 ? viewModel.pendingDocumentCount : 0)
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
        }
        .sheet(isPresented: $showingNotifications) {
            NotificationsFeedSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showingProfile) {
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
    var onNotifications: () -> Void
    var onProfile: () -> Void

    @State private var selectedMetricStatus: OfficerApplicationStatus?
    @State private var selectedApplication: OfficerLoanApplication?
    @State private var showingReportConfirmation = false
    @State private var showingEscalationSheet = false

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
                    showingEscalationSheet: $showingEscalationSheet
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
                Button(action: onNotifications) {
                    Image(systemName: viewModel.unreadActivityCount > 0 ? "bell.badge" : "bell")
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
        .sheet(item: $selectedApplication) { app in
            LoanApplicationReviewDetailView(applicationId: app.applicationId, viewModel: viewModel)
        }
        .alert("Report queued", isPresented: $showingReportConfirmation) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("The monthly branch performance report is being prepared.")
        }
        .sheet(isPresented: $showingEscalationSheet) {
            OfficerEscalationSheet()
        }
    }
}

// MARK: - Action Items

private struct OfficerActionItemsRow: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @Binding var selectedTab: OfficerWorkspaceTab
    @Binding var showingEscalationSheet: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("Action Items")
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
                .padding(.horizontal, LMSSpacing.screenHorizontal)

            HStack(spacing: LMSSpacing.md) {
                OfficerActionCard(
                    title: "Pending Docs",
                    value: "\(viewModel.pendingDocumentCount)",
                    icon: "doc.badge.clock",
                    tint: viewModel.pendingDocumentCount == 0 ? LMSColors.emerald : LMSColors.actionBlue,
                    action: {
                        HapticsManager.triggerImpact(style: .light)
                        selectedTab = .review
                    }
                )

                OfficerActionCard(
                    title: "Ready to Send",
                    value: "\(viewModel.sentToManagerApps.count)",
                    icon: "paperplane.fill",
                    tint: viewModel.sentToManagerApps.isEmpty ? LMSColors.emerald : LMSColors.coral,
                    action: {
                        HapticsManager.triggerImpact(style: .light)
                        viewModel.historyFilter = .newCases
                        selectedTab = .registry
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
            VStack(alignment: .leading, spacing: LMSSpacing.md) {
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
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
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

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            HStack {
                Text("Review Queue")
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)

                Spacer()

                Button(action: {
                    HapticsManager.triggerImpact(style: .light)
                    selectedTab = .review
                }) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(.subheadline, design: .rounded).bold())
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(LMSColors.actionBlue)
                }
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)

            if viewModel.documentQueueList.isEmpty {
                ContentUnavailableView(
                    "Queue Clear",
                    systemImage: "checkmark.circle.fill",
                    description: Text("No documents currently require your review.")
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
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.documentQueueList.prefix(4).enumerated()), id: \.element.id) { index, item in
                        NavigationLink {
                            DocumentReviewDetailView(item: item, viewModel: viewModel)
                        } label: {
                            OfficerDocumentRow(item: item)
                                .padding(.horizontal, LMSSpacing.lg)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)

                        if index < min(viewModel.documentQueueList.count, 4) - 1 {
                            Divider()
                                .padding(.leading, 72)
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

// MARK: - Escalations Section

private struct OfficerEscalationsSection: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @Binding var selectedApplication: OfficerLoanApplication?

    var body: some View {
        let needsClarification = viewModel.sentToManagerApps.filter { $0.managerStatus == .needsClarification }

        if !needsClarification.isEmpty {
            VStack(alignment: .leading, spacing: LMSSpacing.md) {
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
        let sent = viewModel.applications.filter { $0.status == .verificationCompleted || $0.status == .sentToManager || $0.status == .finalApprovalPending }.count
        let completed = viewModel.applications.filter { $0.status == .approved || $0.status == .disbursed || $0.status == .rejected }.count
        return (pending, underReview, sent, completed)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("Case Pipeline")
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
                .padding(.horizontal, LMSSpacing.screenHorizontal)
            
            Button(action: {
                HapticsManager.triggerImpact(style: .medium)
                showPipelineDetails = true
            }) {
                VStack(alignment: .leading, spacing: LMSSpacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Current Caseload")
                            .font(.system(.headline, design: .rounded).bold())
                            .foregroundStyle(LMSColors.textPrimary)
                        Text("Breakdown of all applications assigned to you")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                    
                    OfficerPipelineChart(stats: stats)
                }
                .padding(LMSSpacing.lg)
                .background(LMSColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, LMSSpacing.screenHorizontal)
        }
        .sheet(isPresented: $showPipelineDetails) {
            LoanOfficerPipelineDetailsSheet(viewModel: viewModel)
        }
    }
}

private struct OfficerPipelineChart: View {
    let stats: (pending: Int, underReview: Int, sentToManager: Int, completed: Int)
    @State private var animated = false

    private var total: Double {
        max(Double(stats.pending + stats.underReview + stats.sentToManager + stats.completed), 1)
    }

    var body: some View {
        HStack(spacing: LMSSpacing.xl) {
            ZStack {
                Circle()
                    .stroke(LMSColors.separatorLight, lineWidth: 11)
                    .frame(width: 96, height: 96)

                Circle()
                    .trim(from: 0, to: animated ? Double(stats.pending) / total : 0)
                    .stroke(LMSColors.amber, style: StrokeStyle(lineWidth: 11, lineCap: .round))
                    .frame(width: 96, height: 96)
                    .rotationEffect(.degrees(-90))

                Circle()
                    .trim(from: Double(stats.pending) / total, to: animated ? Double(stats.pending + stats.underReview) / total : Double(stats.pending) / total)
                    .stroke(LMSColors.actionBlue, style: StrokeStyle(lineWidth: 11, lineCap: .round))
                    .frame(width: 96, height: 96)
                    .rotationEffect(.degrees(-90))
                    
                Circle()
                    .trim(from: Double(stats.pending + stats.underReview) / total, to: animated ? Double(stats.pending + stats.underReview + stats.sentToManager) / total : Double(stats.pending + stats.underReview) / total)
                    .stroke(Color.purple, style: StrokeStyle(lineWidth: 11, lineCap: .round))
                    .frame(width: 96, height: 96)
                    .rotationEffect(.degrees(-90))

                Circle()
                    .trim(
                        from: Double(stats.pending + stats.underReview + stats.sentToManager) / total,
                        to: animated ? 1.0 : Double(stats.pending + stats.underReview + stats.sentToManager) / total
                    )
                    .stroke(LMSColors.emerald, style: StrokeStyle(lineWidth: 11, lineCap: .round))
                    .frame(width: 96, height: 96)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(Int(total))")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.textPrimary)
                    Text("Total")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                ChartLegendRow(color: LMSColors.amber, label: "Pending Docs", count: stats.pending)
                ChartLegendRow(color: LMSColors.actionBlue, label: "In Review", count: stats.underReview)
                ChartLegendRow(color: Color.purple, label: "Manager Auth", count: stats.sentToManager)
                ChartLegendRow(color: LMSColors.emerald, label: "Completed", count: stats.completed)
            }
            
            Spacer(minLength: 0)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(LMSColors.textTertiary)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animated = true
            }
        }
    }
}

private struct ChartLegendRow: View {
    let color: Color
    let label: String
    let count: Int
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(LMSColors.textSecondary)
                .lineLimit(1)
            Spacer()
            Text("\(count)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(LMSColors.textPrimary)
        }
    }
}


// MARK: - Review Queue Tab

private struct LoanOfficerReviewQueueView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @State private var query = ""
    @State private var selectedStatus: OfficerDocumentStatus?

    private var filteredItems: [DocumentQueueItem] {
        viewModel.documentQueueList.filter { item in
            let matchesQuery = query.isEmpty || item.borrowerName.localizedCaseInsensitiveContains(query) || item.applicationId.localizedCaseInsensitiveContains(query) || item.docType.rawValue.localizedCaseInsensitiveContains(query)
            let matchesStatus = selectedStatus == nil || item.status == selectedStatus
            return matchesQuery && matchesStatus
        }
    }

    var body: some View {
        List {
            Section {
                Picker("Status", selection: $selectedStatus) {
                    Text("All").tag(Optional<OfficerDocumentStatus>.none)
                    Text("New").tag(Optional(OfficerDocumentStatus.uploaded))
                    Text("Re-upload").tag(Optional(OfficerDocumentStatus.reUploaded))
                    Text("Missing").tag(Optional(OfficerDocumentStatus.pending))
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)

            Section {
                if filteredItems.isEmpty {
                    ContentUnavailableView("No documents", systemImage: "doc.text.magnifyingglass", description: Text("Try a different search or status."))
                } else {
                    ForEach(filteredItems) { item in
                        NavigationLink {
                            DocumentReviewDetailView(item: item, viewModel: viewModel)
                        } label: {
                            OfficerDocumentRow(item: item)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            if item.status == .uploaded || item.status == .reUploaded {
                                Button {
                                    viewModel.updateDocumentStatus(applicationId: item.applicationId, docId: item.id, newStatus: .verified)
                                } label: {
                                    Label("Verify", systemImage: "checkmark.shield")
                                }
                                .tint(.green)
                            }
                        }
                    }
                }
            } header: {
                Text("Documents")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Review")
        .searchable(text: $query, prompt: "Borrower, document, application")
        .refreshable { await viewModel.fetchDashboardData() }
    }
}

// MARK: - Escalation Sheet

private struct OfficerEscalationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var reason = ""
    @State private var priority = "Normal"

    var body: some View {
        NavigationStack {
            Form {
                Section("Priority") {
                    Picker("Priority", selection: $priority) {
                        Text("Normal").tag("Normal")
                        Text("High").tag("High")
                        Text("Critical").tag("Critical")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Reason") {
                    TextField("Describe the blocker", text: $reason, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Escalate Case")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") { dismiss() }
                        .disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
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
        viewModel.applications.filter { $0.status == .verificationCompleted || $0.status == .sentToManager || $0.status == .finalApprovalPending }
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
                        PipelineSection(title: "Pending Action", applications: pendingApps, icon: "clock.fill", tint: LMSColors.amber)
                        PipelineSection(title: "In Review", applications: underReviewApps, icon: "magnifyingglass", tint: LMSColors.actionBlue)
                        PipelineSection(title: "Submitted", applications: sentToManagerApps, icon: "paperplane.fill", tint: Color.purple)
                        PipelineSection(title: "Completed", applications: completedApps, icon: "checkmark.seal.fill", tint: LMSColors.emerald)
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
            .sheet(item: $selectedApplication) { application in
                LoanApplicationReviewDetailView(applicationId: application.applicationId, viewModel: viewModel)
            }
        }
    }
}
