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

                OfficerToolsGrid(
                    selectedTab: $selectedTab,
                    showingReportConfirmation: $showingReportConfirmation,
                    showingEscalationSheet: $showingEscalationSheet
                )
                
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
                    Text("AK")
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
                        viewModel.historyFilter = .pending
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

        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("Escalations")
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
                .padding(.horizontal, LMSSpacing.screenHorizontal)

            if needsClarification.isEmpty {
                ContentUnavailableView(
                    "No Escalations",
                    systemImage: "checkmark.circle.fill",
                    description: Text("All submitted cases are awaiting manager action.")
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

// MARK: - Officer Tools Grid

private struct OfficerToolsGrid: View {
    @Binding var selectedTab: OfficerWorkspaceTab
    @Binding var showingReportConfirmation: Bool
    @Binding var showingEscalationSheet: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("Officer Tools")
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
                .padding(.horizontal, LMSSpacing.screenHorizontal)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: LMSSpacing.md), GridItem(.flexible(), spacing: LMSSpacing.md)], spacing: LMSSpacing.md) {
                OfficerToolGridCard(title: "Review Docs", icon: "doc.text.magnifyingglass", tint: LMSColors.actionBlue) { selectedTab = .review }
                OfficerToolGridCard(title: "Messages", icon: "message.badge", tint: LMSColors.coral) { selectedTab = .messages }
                OfficerToolGridCard(title: "Reports", icon: "chart.bar.xaxis", tint: LMSColors.brandNavy) { showingReportConfirmation = true }
                OfficerToolGridCard(title: "Escalate", icon: "arrow.up.forward.circle", tint: LMSColors.amber) { showingEscalationSheet = true }
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)
        }
    }
}

private struct OfficerToolGridCard: View {
    let title: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: LMSSpacing.md) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(tint)
                }

                Text(title)
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(LMSSpacing.lg)
            .background(LMSColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
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
