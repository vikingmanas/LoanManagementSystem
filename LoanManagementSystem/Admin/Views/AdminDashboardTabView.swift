import SwiftUI

struct AdminDashboardTabView: View {
    @ObservedObject var viewModel: AdminDashboardViewModel
    @Binding var showingProfile: Bool
    
    @EnvironmentObject private var authManager: AuthManager
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: LMSSpacing.sectionGap) {
                    if let errorMessage = viewModel.errorMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(LMSColors.coral)
                                Text("Failed to Load Dashboard Data")
                                    .font(LMSFont.subheadline.weight(.semibold))
                                    .foregroundStyle(LMSColors.textPrimary)
                            }
                            Text(errorMessage)
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                                .lineLimit(3)
                            
                            Button {
                                Task {
                                    await viewModel.loadDashboardData()
                                }
                            } label: {
                                Text("Retry")
                                    .font(LMSFont.caption.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(LMSColors.brandNavy, in: Capsule())
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: LMSRadius.lg)
                                .stroke(LMSColors.coral.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    headerSection
                    kpiSection
                    communicationCenterSection
                    healthSection
                    auditPreviewSection
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)
                .padding(.vertical, LMSSpacing.md)
            }
            .background(LMSColors.background.ignoresSafeArea())
            .navigationTitle("Admin Portal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingProfile = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [LMSColors.brandNavy, LMSColors.brandNavyLight],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text(authManager.userInitials)
                                .font(LMSFont.caption2.weight(.bold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 34, height: 34)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
            .task {
                if viewModel.kpis.isEmpty {
                    await viewModel.loadDashboardData()
                }
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good morning, \(authManager.userDisplayName.split(separator: " ").first ?? "Admin")")
                    .font(LMSFont.title3)
                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(LMSFont.subheadline)
                    .foregroundStyle(LMSColors.textSecondary)
            }
            Spacer()
        }
    }
    
    private var kpiSection: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.kpis) { kpi in
                NavigationLink {
                    AdminBranchKPIView(kpi: kpi, viewModel: viewModel)
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            Image(systemName: kpi.icon)
                                .font(.title2)
                                .foregroundStyle(kpi.themeColor)
                            Spacer()
                            HStack(spacing: 2) {
                                Image(systemName: kpi.trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                                Text("\(abs(kpi.trend), specifier: "%.1f")%")
                            }
                            .font(.caption.weight(.bold))
                            .foregroundStyle(kpi.trend >= 0 ? LMSColors.emerald : LMSColors.coral)
                        }
                        
                        Spacer(minLength: 0)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(kpi.value)
                                .font(LMSFont.title)
                                .foregroundStyle(LMSColors.textPrimary)
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                            Text(kpi.title)
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, minHeight: 115, alignment: .leading)
                    .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Health")
                .font(LMSFont.headline)
            
            VStack(spacing: 0) {
                healthMetricRow(title: "Server Uptime", value: "\(viewModel.systemHealth.serverUptime)%", icon: "server.rack")
                Divider().padding(.leading, 48)
                healthMetricRow(title: "Active Sessions", value: "\(viewModel.systemHealth.activeSessions)", icon: "person.3")
                Divider().padding(.leading, 48)
                healthMetricRow(title: "Last Backup", value: viewModel.systemHealth.lastBackupTime.formatted(date: .abbreviated, time: .shortened), icon: "externaldrive.badge.checkmark")
            }
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
        }
    }

    private var communicationCenterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Recent Complaints & Feedback")
                        .font(LMSFont.headline)
                    Text("Latest issues raised by branches and managers.")
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer()

                NavigationLink {
                    AdminComplaintsFeedbackManagementView(viewModel: viewModel)
                } label: {
                    HStack(spacing: 4) {
                        Text("View All")
                        Image(systemName: "chevron.right")
                    }
                    .font(LMSFont.subheadline.weight(.semibold))
                    .foregroundStyle(LMSColors.actionBlue)
                }
            }

            VStack(spacing: 12) {
                let recentIssues = viewModel.communicationIssues.sorted { $0.createdDate > $1.createdDate }.prefix(3)
                if recentIssues.isEmpty {
                    ContentUnavailableView(
                        "No Recent Complaints",
                        systemImage: "tray",
                        description: Text("Branch issues and feedback will appear here.")
                    )
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
                } else {
                    ForEach(Array(recentIssues)) { issue in
                        AdminComplaintPreviewCard(issue: issue)
                    }
                }
            }
        }
    }
    
    private func healthMetricRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(LMSColors.actionBlue)
                .frame(width: 24)
            Text(title)
                .font(LMSFont.body)
            Spacer()
            Text(value)
                .font(LMSFont.subheadline.weight(.medium))
                .foregroundStyle(LMSColors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var auditPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Audit Trail")
                    .font(LMSFont.headline)
                Spacer()
                NavigationLink(destination: AdminAuditTrailView()) {
                    Text("View All")
                        .font(LMSFont.subheadline.weight(.semibold))
                        .foregroundStyle(LMSColors.actionBlue)
                }
            }
            
            VStack(spacing: 0) {
                if viewModel.isLoading && viewModel.recentAuditLogs.isEmpty {
                    ProgressView()
                        .padding()
                        .frame(maxWidth: .infinity)
                } else if viewModel.recentAuditLogs.isEmpty {
                    Text("No recent activity.")
                        .font(LMSFont.subheadline)
                        .foregroundStyle(LMSColors.textSecondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(viewModel.recentAuditLogs) { log in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(log.type.color.opacity(0.1))
                                
                                Image(systemName: log.type.icon)
                                    .font(.title3)
                                    .foregroundStyle(log.type.color)
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(log.action)
                                    .font(LMSFont.subheadline.weight(.medium))
                                Text("\(log.userName) • \(log.entityId)")
                                    .font(LMSFont.caption)
                                    .foregroundStyle(LMSColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Text(RelativeDateFormatter.shared.relativeString(from: log.timestamp))
                                .font(LMSFont.caption2)
                                .foregroundStyle(LMSColors.textTertiary)
                        }
                        .padding(.vertical, 12)
                        
                        if log.id != viewModel.recentAuditLogs.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
        }
    }
}

private struct AdminCommunicationSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: LMSRadius.sm))

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(LMSFont.title3)
                    .foregroundStyle(LMSColors.textPrimary)
                Text(title)
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 78)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
    }
}

private struct AdminComplaintPreviewCard: View {
    let issue: AdminCommunicationIssue

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: issue.category.icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(LMSColors.brandNavy)
                .frame(width: 38, height: 38)
                .background(LMSColors.brandNavy.opacity(0.10), in: RoundedRectangle(cornerRadius: LMSRadius.sm))

            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .top, spacing: 8) {
                    Text(issue.title)
                        .font(LMSFont.subheadline.weight(.semibold))
                        .foregroundStyle(LMSColors.textPrimary)
                        .lineLimit(2)
                    Spacer(minLength: 0)
                    Circle()
                        .fill(issue.priority.color)
                        .frame(width: 9, height: 9)
                        .padding(.top, 5)
                }

                Text(issue.branchName)
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(issue.category.rawValue)
                        .font(LMSFont.caption2.weight(.semibold))
                        .foregroundStyle(LMSColors.textSecondary)
                    Spacer()
                    Text(RelativeDateFormatter.shared.relativeString(from: issue.createdDate))
                        .font(LMSFont.caption2.weight(.semibold))
                        .foregroundStyle(LMSColors.textTertiary)
                }
            }
        }
        .padding(12)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
    }
}

private struct AdminComplaintsFeedbackManagementView: View {
    @ObservedObject var viewModel: AdminDashboardViewModel
    @State private var searchText = ""
    @State private var selectedTab: AdminIssueStatus?
    @State private var selectedCategory: AdminIssueCategory?
    @State private var selectedPriority: AdminIssuePriority?
    @State private var showingBroadcastComposer = false
    @State private var showingFilters = false

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    private var filteredIssues: [AdminCommunicationIssue] {
        viewModel.communicationIssues
            .filter { issue in
                let matchesTab: Bool
                switch selectedTab {
                case nil: matchesTab = true
                case .open: matchesTab = issue.status == .open
                case .inProgress: matchesTab = issue.status == .inProgress || issue.status == .waitingForResponse
                case .waitingForResponse: matchesTab = issue.status == .waitingForResponse
                case .resolved: matchesTab = issue.status == .resolved
                case .archived: matchesTab = issue.status == .archived
                }

                let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
                let matchesSearch = query.isEmpty
                    || issue.issueId.localizedCaseInsensitiveContains(query)
                    || issue.title.localizedCaseInsensitiveContains(query)
                    || issue.branchName.localizedCaseInsensitiveContains(query)
                    || issue.raisedBy.localizedCaseInsensitiveContains(query)
                    || issue.category.rawValue.localizedCaseInsensitiveContains(query)

                return matchesTab
                    && matchesSearch
                    && (selectedCategory == nil || issue.category == selectedCategory)
                    && (selectedPriority == nil || issue.priority == selectedPriority)
            }
            .sorted { $0.createdDate > $1.createdDate }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                managementSummaryGrid
                statusTabs

                if showingFilters {
                    managementFilters
                }

                if filteredIssues.isEmpty {
                    ContentUnavailableView(
                        "No Complaints Found",
                        systemImage: "magnifyingglass",
                        description: Text("Try another search, tab, or filter.")
                    )
                    .padding(.vertical, 24)
                    .frame(maxWidth: .infinity)
                    .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
                } else {
                    VStack(spacing: 12) {
                        ForEach(filteredIssues) { issue in
                            NavigationLink {
                                AdminIssueDetailScreen(issue: issue, viewModel: viewModel)
                            } label: {
                                AdminCommunicationIssueCard(issue: issue)
                            }
                            .buttonStyle(LMSPressableStyle())
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(LMSColors.background.ignoresSafeArea())
        .navigationTitle("Complaints & Feedback")
        .searchable(text: $searchText, prompt: "Search issue, branch, raised by")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showingFilters.toggle()
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                .accessibilityLabel("Filter complaints")

                Button {
                    showingBroadcastComposer = true
                } label: {
                    Image(systemName: "megaphone.fill")
                }
                .accessibilityLabel("Create broadcast")
            }
        }
        .sheet(isPresented: $showingBroadcastComposer) {
            AdminBroadcastComposerSheet(viewModel: viewModel)
        }
    }

    private var managementSummaryGrid: some View {
        let summary = viewModel.communicationSummary
        return LazyVGrid(columns: columns, spacing: 12) {
            AdminCommunicationSummaryCard(title: "Open Issues", value: "\(summary.open)", icon: "exclamationmark.bubble.fill", tint: LMSColors.coral)
            AdminCommunicationSummaryCard(title: "Under Review", value: "\(summary.underReview)", icon: "clock.badge.checkmark.fill", tint: LMSColors.actionBlue)
            AdminCommunicationSummaryCard(title: "Resolved", value: "\(summary.resolved)", icon: "checkmark.seal.fill", tint: LMSColors.emerald)
            AdminCommunicationSummaryCard(title: "Broadcast Messages", value: "\(summary.broadcasts)", icon: "megaphone.fill", tint: LMSColors.amber)
        }
    }

    private var statusTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                managementChip("All", isSelected: selectedTab == nil) {
                    selectedTab = nil
                }
                managementChip("Open", isSelected: selectedTab == .open) {
                    selectedTab = .open
                }
                managementChip("In Progress", isSelected: selectedTab == .inProgress) {
                    selectedTab = .inProgress
                }
                managementChip("Resolved", isSelected: selectedTab == .resolved) {
                    selectedTab = .resolved
                }
                managementChip("Archived", isSelected: selectedTab == .archived) {
                    selectedTab = .archived
                }
            }
        }
    }

    private var managementFilters: some View {
        VStack(spacing: 8) {
            filterRow(title: "Category", selection: $selectedCategory, values: AdminIssueCategory.allCases)
            filterRow(title: "Priority", selection: $selectedPriority, values: AdminIssuePriority.allCases)
        }
        .padding(12)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
    }

    private func filterRow<T: Identifiable & Hashable & RawRepresentable>(
        title: String,
        selection: Binding<T?>,
        values: [T]
    ) -> some View where T.RawValue == String {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Text(title)
                    .font(LMSFont.caption.weight(.bold))
                    .foregroundStyle(LMSColors.textSecondary)
                managementChip("All", isSelected: selection.wrappedValue == nil) {
                    selection.wrappedValue = nil
                }
                ForEach(values) { value in
                    managementChip(value.rawValue, isSelected: selection.wrappedValue == value) {
                        selection.wrappedValue = value
                    }
                }
            }
        }
    }

    private func managementChip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(LMSFont.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : LMSColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(isSelected ? LMSColors.brandNavy : LMSColors.surface, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct AdminCommunicationIssueCard: View {
    let issue: AdminCommunicationIssue

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(issue.title)
                        .font(LMSFont.headline)
                        .foregroundStyle(LMSColors.textPrimary)
                        .lineLimit(2)
                    Text(issue.branchName)
                        .font(LMSFont.subheadline)
                        .foregroundStyle(LMSColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer()

                AdminCommunicationPill(text: priorityText(for: issue.priority), tint: issue.priority.color)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text("Issue ID: \(issue.issueId)")
                    .font(LMSFont.caption.weight(.semibold))
                    .foregroundStyle(LMSColors.textSecondary)
                Text("Raised By: \(issue.raisedBy)")
                    .font(LMSFont.caption.weight(.semibold))
                    .foregroundStyle(LMSColors.textSecondary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(issue.category.rawValue)
                    .font(LMSFont.caption.weight(.bold))
                    .foregroundStyle(LMSColors.brandNavy)
                Text(issue.issue)
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textPrimary)
                    .lineLimit(2)
            }

            HStack {
                Text("Updated \(RelativeDateFormatter.shared.relativeString(from: issue.replies.last?.timestamp ?? issue.createdDate))")
                    .font(LMSFont.caption2.weight(.semibold))
                    .foregroundStyle(LMSColors.textTertiary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LMSColors.textTertiary)
            }
        }
        .padding(14)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
    }

    private func priorityText(for priority: AdminIssuePriority) -> String {
        switch priority {
        case .low: return "Low Priority"
        case .medium: return "Medium Priority"
        case .high: return "High Priority"
        case .critical: return "Critical"
        }
    }
}

private struct AdminCommunicationFact: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(LMSFont.caption2.weight(.bold))
                .foregroundStyle(LMSColors.textTertiary)
                .textCase(.uppercase)
            Text(value)
                .font(LMSFont.caption.weight(.semibold))
                .foregroundStyle(LMSColors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(8)
        .background(LMSColors.surfaceTertiary, in: RoundedRectangle(cornerRadius: LMSRadius.sm))
    }
}

private struct AdminCommunicationPill: View {
    let text: String
    let tint: Color

    var body: some View {
        Text(text)
            .font(LMSFont.caption2.weight(.bold))
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(tint.opacity(0.12), in: Capsule())
            .lineLimit(1)
    }
}

private struct AdminCommunicationActionStyle: ButtonStyle {
    let tint: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(LMSFont.caption.weight(.bold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.vertical, 9)
            .padding(.horizontal, 8)
            .background(tint.opacity(configuration.isPressed ? 0.18 : 0.10), in: RoundedRectangle(cornerRadius: LMSRadius.sm))
    }
}

private struct AdminIssueDetailScreen: View {
    let issue: AdminCommunicationIssue
    @ObservedObject var viewModel: AdminDashboardViewModel
    @State private var replyText = ""
    @State private var selectedDepartment = "Product Team"

    private var currentIssue: AdminCommunicationIssue {
        viewModel.communicationIssues.first(where: { $0.id == issue.id }) ?? issue
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                issueHeader
                branchSection
                attachmentSection
                timelineSection
                conversationSection
                replySection
                resolutionNotesSection
                actionSection
            }
            .padding(16)
        }
        .background(LMSColors.background.ignoresSafeArea())
        .navigationTitle("Complaint Detail")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var issueHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Issue Information")
                .font(LMSFont.headline)
            Text(currentIssue.title)
                .font(LMSFont.title3)
            Text(currentIssue.issue)
                .font(LMSFont.subheadline)
                .foregroundStyle(LMSColors.textPrimary)

            HStack {
                AdminCommunicationPill(text: currentIssue.category.rawValue, tint: LMSColors.brandNavy)
                AdminCommunicationPill(text: currentIssue.priority.rawValue, tint: currentIssue.priority.color)
                AdminCommunicationPill(text: currentIssue.status.rawValue, tint: currentIssue.status.color)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
    }

    private var branchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Branch Information")
                .font(LMSFont.headline)
            AdminCommunicationFact(label: "Branch Name", value: currentIssue.branchName)
            AdminCommunicationFact(label: "Raised By", value: currentIssue.raisedBy)
            AdminCommunicationFact(label: "Category", value: currentIssue.category.rawValue)
        }
        .padding(14)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
    }

    private var attachmentSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Supporting Documents")
                .font(LMSFont.headline)

            if currentIssue.supportingDocuments.isEmpty {
                Text("No attachments provided.")
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)
            } else {
                ForEach(currentIssue.supportingDocuments, id: \.self) { document in
                    Label(document, systemImage: "paperclip")
                        .font(LMSFont.caption.weight(.semibold))
                        .foregroundStyle(LMSColors.textPrimary)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
    }

    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Audit Trail")
                .font(LMSFont.headline)
            AdminCommunicationFact(label: "Created By", value: currentIssue.createdBy)
            AdminCommunicationFact(label: "Assigned To", value: currentIssue.assignedTo ?? "Unassigned")
            AdminCommunicationFact(label: "Response Date", value: currentIssue.responseDate?.formatted(date: .abbreviated, time: .shortened) ?? "Pending")
            AdminCommunicationFact(label: "Resolved Date", value: currentIssue.resolvedDate?.formatted(date: .abbreviated, time: .shortened) ?? "Pending")
            AdminCommunicationFact(label: "Last Updated By", value: currentIssue.lastUpdatedBy)
        }
        .padding(14)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
    }

    private var conversationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Conversation Thread")
                .font(LMSFont.headline)
            ForEach(currentIssue.replies) { reply in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(reply.author)
                            .font(LMSFont.caption.weight(.bold))
                        Spacer()
                        Text(RelativeDateFormatter.shared.relativeString(from: reply.timestamp))
                            .font(LMSFont.caption2)
                            .foregroundStyle(LMSColors.textTertiary)
                    }
                    Text(reply.message)
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textPrimary)
                }
                .padding(10)
                .background(LMSColors.surfaceTertiary, in: RoundedRectangle(cornerRadius: LMSRadius.sm))
            }
        }
        .padding(14)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
    }

    private var replySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Admin Response Panel")
                .font(LMSFont.headline)
            TextField("Write a response to the branch...", text: $replyText, axis: .vertical)
                .lineLimit(3...5)
                .padding(10)
                .background(LMSColors.surfaceTertiary, in: RoundedRectangle(cornerRadius: LMSRadius.sm))
            Button("Send Reply") {
                viewModel.reply(to: currentIssue, message: replyText)
                replyText = ""
            }
            .disabled(replyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .buttonStyle(AdminCommunicationActionStyle(tint: LMSColors.actionBlue))
        }
        .padding(14)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
    }

    private var resolutionNotesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Resolution Notes")
                .font(LMSFont.headline)
            Text(currentIssue.resolvedDate == nil ? "Resolution pending. Assign a department, reply to the branch, or escalate for faster closure." : "Resolved on \(currentIssue.resolvedDate?.formatted(date: .abbreviated, time: .shortened) ?? "").")
                .font(LMSFont.caption)
                .foregroundStyle(LMSColors.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
    }

    private var actionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Admin Actions")
                .font(LMSFont.headline)

            Picker("Department", selection: $selectedDepartment) {
                Text("Product Team").tag("Product Team")
                Text("IT Operations").tag("IT Operations")
                Text("HR Staffing").tag("HR Staffing")
                Text("Training Team").tag("Training Team")
                Text("Compliance").tag("Compliance")
            }
            .pickerStyle(.menu)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                Button("Assign") { viewModel.assignIssue(currentIssue, to: selectedDepartment) }
                    .buttonStyle(AdminCommunicationActionStyle(tint: LMSColors.brandNavy))
                Button("Mark Resolved") { viewModel.markIssueResolved(currentIssue) }
                    .buttonStyle(AdminCommunicationActionStyle(tint: LMSColors.emerald))
                Button("Escalate") { viewModel.escalateIssue(currentIssue) }
                    .buttonStyle(AdminCommunicationActionStyle(tint: LMSColors.coral))
                Button("Archive") { viewModel.archiveIssue(currentIssue) }
                    .buttonStyle(AdminCommunicationActionStyle(tint: LMSColors.textSecondary))
            }

            Button {
                viewModel.createBroadcast(from: currentIssue)
            } label: {
                Label("Create Broadcast From Issue", systemImage: "megaphone.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(AdminCommunicationActionStyle(tint: LMSColors.amber))
        }
        .padding(14)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
    }
}

private struct AdminBroadcastComposerSheet: View {
    @ObservedObject var viewModel: AdminDashboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var subject = "Vehicle Loan Rate Revision"
    @State private var message = "Effective from 01 June 2026, vehicle loan rates have been revised for eligible customers."
    @State private var recipients: AdminBroadcastRecipient = .allBranchManagers
    @State private var type: AdminAnnouncementType = .interestRateChange

    var body: some View {
        NavigationStack {
            Form {
                Section("Broadcast To") {
                    Picker("Recipients", selection: $recipients) {
                        ForEach(AdminBroadcastRecipient.allCases) { recipient in
                            Text(recipient.rawValue).tag(recipient)
                        }
                    }
                    Picker("Announcement Type", selection: $type) {
                        ForEach(AdminAnnouncementType.allCases) { item in
                            Text(item.rawValue).tag(item)
                        }
                    }
                }

                Section("Message") {
                    TextField("Subject", text: $subject)
                    TextField("Message", text: $message, axis: .vertical)
                        .lineLimit(4...7)
                }
            }
            .navigationTitle("Broadcast Center")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        viewModel.createBroadcast(subject: subject, message: message, recipients: recipients, type: type)
                        dismiss()
                    }
                    .disabled(subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
