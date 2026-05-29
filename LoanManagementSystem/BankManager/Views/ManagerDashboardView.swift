import SwiftUI

struct ManagerDashboardView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var viewModel = ManagerDashboardViewModel()

    @State private var selectedTab: ManagerWorkspaceTab = .dashboard
    @State private var showProfileSheet = false
    @State private var showNotificationSheet = false
    @State private var showSearchSheet = false
    @State private var selectedApplicant: ManagerApplicant?

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ManagerDashboardTabView(
                    viewModel: viewModel,
                    selectedTab: $selectedTab,
                    onSelectApplicant: { selectedApplicant = $0 }
                )
                .navigationTitle("\(viewModel.branchOverview.name)")
                .navigationBarTitleDisplayMode(.large)
                .toolbar { dashboardToolbar }
            }
            .tabItem { Label("Dashboard", systemImage: "square.grid.2x2") }
            .tag(ManagerWorkspaceTab.dashboard)

            NavigationStack {
                ManagerApplicantsTabView(
                    viewModel: viewModel,
                    onSelectApplicant: { selectedApplicant = $0 }
                )
                .navigationTitle("Applicants")
                .toolbar { applicantsToolbar }
            }
            .tabItem { Label("Applicants", systemImage: "person.2") }
            .badge(viewModel.pendingApplicants.count > 0 ? viewModel.pendingApplicants.count : 0)
            .tag(ManagerWorkspaceTab.applicants)

            NavigationStack {
                ManagerCommunicationTabView(viewModel: viewModel)
                    .navigationTitle("Messages")
                    .toolbar { messagesToolbar }
            }
            .tabItem { Label("Messages", systemImage: "message") }
            .badge(viewModel.unreadChatCount > 0 ? viewModel.unreadChatCount : 0)
            .tag(ManagerWorkspaceTab.messages)
        }
        .tint(LMSColors.brandNavy)
        .task {
            await viewModel.fetchDashboardData(authManager: authManager)
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToApplicantsTab"))) { _ in
            selectedTab = .applicants
        }
        .onChange(of: selectedTab) { _, tab in
            viewModel.selectedTab = tab.rawValue
        }
        .onChange(of: viewModel.selectedTab) { _, rawValue in
            guard let tab = ManagerWorkspaceTab(rawValue: rawValue), tab != selectedTab else { return }
            selectedTab = tab
        }
        .sheet(isPresented: $showProfileSheet) {
            ManagerProfileView(viewModel: viewModel)
        }
        .sheet(isPresented: $showNotificationSheet) {
            ManagerNotificationsView(viewModel: viewModel)
        }
        .sheet(isPresented: $showSearchSheet) {
            ManagerSearchSheet(viewModel: viewModel) { applicant in
                showSearchSheet = false
                selectedApplicant = applicant
            }
        }
        .sheet(item: $selectedApplicant) { applicant in
            ManagerApplicantDetailView(applicantId: applicant.id, viewModel: viewModel)
        }
    }

    @ToolbarContentBuilder
    private var dashboardToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: LMSSpacing.sm) {
                notificationButton
                profileButton
            }
        }
    }

    @ToolbarContentBuilder
    private var applicantsToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            notificationButton
        }
    }

    @ToolbarContentBuilder
    private var messagesToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            notificationButton
        }
    }

    private var searchButton: some View {
        Button(action: { showSearchSheet = true }) {
            Image(systemName: "magnifyingglass")
        }
        .accessibilityLabel("Search applicants")
    }

    private var notificationButton: some View {
        Button(action: { showNotificationSheet = true }) {
            Image(systemName: viewModel.unreadNotificationCount > 0 ? "bell.badge" : "bell")
        }
        .accessibilityLabel("Notifications")
    }

    private var profileButton: some View {
        Button(action: { showProfileSheet = true }) {
            Text(viewModel.managerProfile.initials)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(LMSColors.brandNavy.gradient, in: Circle())
        }
        .accessibilityLabel("Manager profile")
    }
}

enum ManagerWorkspaceTab: Int, Hashable {
    case dashboard = 0
    case applicants = 1
    case messages = 2
}

private struct ManagerSearchSheet: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    var onSelectApplicant: (ManagerApplicant) -> Void
    @Environment(\.dismiss) var dismiss
    @State private var query = ""

    private var results: [ManagerApplicant] {
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return [] }
        return viewModel.applicants.filter {
            $0.borrowerName.localizedCaseInsensitiveContains(q) ||
            $0.applicationId.localizedCaseInsensitiveContains(q) ||
            $0.assignedOfficer.localizedCaseInsensitiveContains(q)
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(LMSColors.textSecondary)
                    TextField("Search applicants, officers...", text: $query)
                        .font(.body)
                        .textFieldStyle(.plain)
                    if !query.isEmpty {
                        Button(action: { query = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(LMSColors.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, LMSSpacing.lg)
                .padding(.vertical, LMSSpacing.md)
                .background(LMSColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
                .padding(.horizontal, LMSSpacing.screenHorizontal)
                .padding(.top, LMSSpacing.md)

                if query.isEmpty {
                    ContentUnavailableView(
                        "Search Applications",
                        systemImage: "text.magnifyingglass",
                        description: Text("Search by borrower name, application ID, or loan officer.")
                    )
                } else if results.isEmpty {
                    ContentUnavailableView.search(text: query)
                } else {
                    List(results) { applicant in
                        Button(action: {
                            HapticsManager.triggerImpact(style: .medium)
                            onSelectApplicant(applicant)
                        }) {
                            HStack(spacing: LMSSpacing.md) {
                                ZStack {
                                    Circle()
                                        .fill(applicant.status.themeColor.opacity(0.12))
                                        .frame(width: 36, height: 36)
                                    Text(applicant.borrowerInitials)
                                        .font(.caption.weight(.bold))
                                        .foregroundStyle(applicant.status.themeColor)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(applicant.borrowerName)
                                        .font(.callout.weight(.semibold))
                                        .foregroundStyle(LMSColors.textPrimary)
                                    Text("\(applicant.applicationId) · \(applicant.loanType.rawValue)")
                                        .font(.caption)
                                        .foregroundStyle(LMSColors.textSecondary)
                                }

                                Spacer()

                                Text(applicant.status.displayName)
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(applicant.status.themeColor)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .background(LMSColors.background)
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ManagerDashboardView()
        .previewManagerEnvironment()
}
