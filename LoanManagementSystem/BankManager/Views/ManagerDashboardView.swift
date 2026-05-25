import SwiftUI


struct ManagerDashboardView: View {
    @StateObject private var viewModel = ManagerDashboardViewModel()


    @State private var showProfileSheet = false
    @State private var showSettingsSheet = false
    @State private var showNotificationSheet = false
    @State private var showSearchSheet = false
    @State private var selectedApplicant: ManagerApplicant? = nil

    var body: some View {
        VStack(spacing: 0) {

            ManagerTopToolbar(
                viewModel: viewModel,
                onNotificationPressed: { showNotificationSheet = true },
                onSettingsPressed: { showSettingsSheet = true },
                onProfilePressed: { showProfileSheet = true },
                onSearchPressed: { showSearchSheet = true }
            )

            Divider()


            ZStack(alignment: .bottom) {
                ZStack {
                    switch viewModel.selectedTab {
                    case 0:
                        ManagerDashboardTabView(
                            viewModel: viewModel,
                            onSelectApplicant: { applicant in
                                selectedApplicant = applicant
                            }
                        )
                        .transition(.opacity)

                    case 1:
                        ManagerApplicantsTabView(
                            viewModel: viewModel,
                            onSelectApplicant: { applicant in
                                selectedApplicant = applicant
                            }
                        )
                        .transition(.opacity)

                    case 2:
                        ManagerCommunicationTabView(viewModel: viewModel)
                            .transition(.opacity)

                    default:
                        EmptyView()
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .safeAreaInset(edge: .bottom) {
                    Spacer().frame(height: 80)
                }


                ManagerFloatingTabBar(
                    selectedTab: $viewModel.selectedTab,
                    unreadChatCount: viewModel.unreadChatCount
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            }
            .edgesIgnoringSafeArea(.bottom)
        }
        .task {
            await viewModel.fetchDashboardData()
        }


        .sheet(isPresented: $showProfileSheet) {
            ManagerProfileView()
        }
        .sheet(isPresented: $showSettingsSheet) {
            ManagerSettingsView()
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
            ManagerApplicantDetailView(applicant: applicant, viewModel: viewModel)
        }
    }
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
                    TextField("Search applicants, officers…", text: $query)
                        .font(.system(.body, design: .rounded))
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
                    Spacer()
                    VStack(spacing: LMSSpacing.md) {
                        Image(systemName: "text.magnifyingglass")
                            .font(.system(size: 44))
                            .foregroundStyle(LMSColors.textTertiary)
                        Text("Search by name, application ID, or officer.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                    Spacer()
                } else if results.isEmpty {
                    Spacer()
                    VStack(spacing: LMSSpacing.md) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 44))
                            .foregroundStyle(LMSColors.textTertiary)
                        Text("No results for \"\(query)\"")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                    Spacer()
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
                                        .font(.system(.caption, design: .rounded).bold())
                                        .foregroundStyle(applicant.status.themeColor)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(applicant.borrowerName)
                                        .font(.system(.callout, design: .rounded).bold())
                                        .foregroundStyle(LMSColors.textPrimary)
                                    Text("\(applicant.applicationId) · \(applicant.loanType.rawValue)")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(LMSColors.textSecondary)
                                }

                                Spacer()

                                Text(applicant.status.displayName)
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .foregroundStyle(applicant.status.themeColor)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(applicant.status.themeColor.opacity(0.10))
                                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
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
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ManagerDashboardView()
        .previewManagerEnvironment()
}

