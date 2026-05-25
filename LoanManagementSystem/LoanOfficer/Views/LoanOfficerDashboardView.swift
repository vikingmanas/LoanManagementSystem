import SwiftUI
import UIKit

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: effect)
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
}

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
        ScrollView {
            LazyVStack(spacing: LMSSpacing.lg) {
                workloadStrip
                nextBestActionCard
                reviewSnapshot
                escalationsSection
                toolsGrid
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)
            .padding(.bottom, LMSSpacing.xxl)
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

    // MARK: - Workload KPI Strip

    private var workloadStrip: some View {
        HStack(spacing: LMSSpacing.md) {
            OfficerMetricPill(title: "Pending", value: "\(viewModel.pendingCount)", icon: "clock", tint: .orange) {
                HapticsManager.triggerImpact(style: .light)
                routeRegistry(.pending)
            }
            OfficerMetricPill(title: "Docs", value: "\(viewModel.pendingDocumentCount)", icon: "doc.badge.clock", tint: .blue) {
                HapticsManager.triggerImpact(style: .light)
                selectedTab = .review
            }
            OfficerMetricPill(title: "Ready", value: "\(viewModel.sentToManagerApps.count)", icon: "paperplane", tint: .green) {
                HapticsManager.triggerImpact(style: .light)
                selectedTab = .registry
            }
        }
    }

    // MARK: - Next Best Action

    private var nextBestActionCard: some View {
        NativeGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Next best action", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(.primary)

                if let app = nextApplication {
                    HStack(alignment: .center, spacing: 12) {
                        OfficerAvatar(name: app.borrowerName, tint: app.loanType.themeColor)

                        VStack(alignment: .leading, spacing: 4) {
                            Text(app.borrowerName)
                                .font(.body.weight(.semibold))
                            Text("\(app.loanType.rawValue) · \(CurrencyFormatter.shared.format(app.requestedAmount))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(app.status.rawValue)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(app.status.themeColor)
                        }

                        Spacer()

                        Button {
                            selectedApplication = app
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Open application")
                    }
                } else {
                    ContentUnavailableView("No urgent case", systemImage: "checkmark.seal", description: Text("All priority work is clear."))
                        .frame(minHeight: 100)
                }
            }
        }
    }

    // MARK: - Review Snapshot

    private var reviewSnapshot: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            SectionTitle("Review queue", subtitle: "Newest uploads and re-uploads")

            NativeGlassCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.documentQueueList.prefix(4).enumerated()), id: \.element.id) { index, item in
                        NavigationLink {
                            DocumentReviewDetailView(item: item, viewModel: viewModel)
                        } label: {
                            OfficerDocumentRow(item: item)
                                .padding(.horizontal, LMSSpacing.lg)
                        }
                        .buttonStyle(.plain)

                        if index < min(viewModel.documentQueueList.count, 4) - 1 {
                            Divider().padding(.leading, 76)
                        }
                    }

                    Divider()

                    Button {
                        selectedTab = .review
                    } label: {
                        HStack {
                            Text("Open full review queue")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(LMSColors.actionBlue)
                        .padding(LMSSpacing.lg)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Escalations (formerly Manager Follow-Up)

    private var escalationsSection: some View {
        let needsClarification = viewModel.sentToManagerApps.filter { $0.managerStatus == .needsClarification }

        return VStack(alignment: .leading, spacing: LMSSpacing.md) {
            SectionTitle("Escalations", subtitle: "Manager clarifications & approval status")

            NativeGlassCard(padding: 0) {
                if needsClarification.isEmpty {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("No escalations pending")
                                .font(.subheadline.weight(.semibold))
                            Text("All submitted cases are awaiting manager action.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(LMSSpacing.lg)
                } else {
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
            }
        }
    }

    // MARK: - Tools Grid

    private var toolsGrid: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            SectionTitle("Officer tools", subtitle: "Quick utilities")

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: LMSSpacing.md) {
                OfficerToolCard(title: "Review docs", icon: "doc.text.magnifyingglass", tint: .blue) { selectedTab = .review }
                OfficerToolCard(title: "Messages", icon: "message.badge", tint: .teal) { selectedTab = .messages }
                OfficerToolCard(title: "Reports", icon: "chart.bar.xaxis", tint: .purple) { showingReportConfirmation = true }
                OfficerToolCard(title: "Escalate", icon: "arrow.up.forward.circle", tint: .red) { showingEscalationSheet = true }
            }
        }
    }

    private func routeRegistry(_ status: OfficerApplicationStatus?) {
        viewModel.historyFilter = status
        selectedTab = .registry
    }
}

// MARK: - Review Queue

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

// MARK: - Glass Card

private struct NativeGlassCard<Content: View>: View {
    var padding: CGFloat = 16
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .nativeOfficerGlass(cornerRadius: LMSRadius.card)
    }
}

// MARK: - Section Title

private struct SectionTitle: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.headline)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Metric Pill

private struct OfficerMetricPill: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(tint)
                Text(value)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(.primary)
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(LMSSpacing.lg)
            .nativeOfficerGlass(cornerRadius: LMSRadius.xl, interactive: true)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tool Card

private struct OfficerToolCard: View {
    let title: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.12), in: Circle())
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer()
            }
            .padding(LMSSpacing.lg)
            .nativeOfficerGlass(cornerRadius: LMSRadius.xl, interactive: true)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Document Row

struct OfficerDocumentRow: View {
    let item: DocumentQueueItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.docType.symbol)
                .font(.headline.weight(.semibold))
                .foregroundStyle(item.docType.iconColor)
                .frame(width: 44, height: 44)
                .background(item.docType.iconColor.opacity(0.12), in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.borrowerName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                Text("\(item.docType.rawValue) · \(item.applicationId)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
            }

            Spacer(minLength: 4)

            Text(item.status.rawValue)
                .font(.caption.weight(.semibold))
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
                    .font(.body.weight(.semibold))
                Text("\(app.loanType.rawValue) · \(app.applicationId)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let accessory {
                Text(accessory)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(LMSColors.actionBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(LMSColors.actionBlue.opacity(0.12), in: Capsule())
            } else {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
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
            .font(.subheadline.weight(.bold))
            .foregroundStyle(tint)
            .frame(width: 44, height: 44)
            .background(tint.opacity(0.12), in: Circle())
    }
}

// MARK: - Glass Effect

extension View {
    @ViewBuilder
    func nativeOfficerGlass(cornerRadius: CGFloat = LMSRadius.xl, interactive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(interactive ? .regular.interactive() : .regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            self
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
                )
        }
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
