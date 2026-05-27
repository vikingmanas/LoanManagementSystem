import SwiftUI


struct ManagerDashboardTabView: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @Binding var selectedTab: ManagerWorkspaceTab
    var onSelectApplicant: (ManagerApplicant) -> Void

    @State private var showBranchOverview = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: LMSSpacing.xl) {

                // Key Performance Indicators
                ActionItemsRow(viewModel: viewModel, selectedTab: $selectedTab)
                    .padding(.top, LMSSpacing.md)

                // Approval Queue
                ManagerApprovalQueueView(
                    viewModel: viewModel,
                    onViewAll: {
                        viewModel.navigateToApplicantsWithPending()
                        selectedTab = .applicants
                    },
                    onSelectApplicant: onSelectApplicant
                )

                // Team Overview
                TeamOverviewSection(viewModel: viewModel)

                // Branch Portfolio Analytics
                VStack(alignment: .leading, spacing: LMSSpacing.md) {
                    Text("Branch Portfolio Analytics")
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                        .padding(.horizontal, LMSSpacing.screenHorizontal)

                    ManagerAnalyticsView(viewModel: viewModel)
                }

                // Reports & Insights
                ManagerReportsView(viewModel: viewModel)

                Spacer()
                    .frame(height: LMSSpacing.xxxl)
            }
        }
        .background(LMSColors.background)
        .refreshable {
            await viewModel.refreshData()
        }
    }
}





// MARK: - Action Items Row (replaces 4-card Branch Command Center)

private struct ActionItemsRow: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @Binding var selectedTab: ManagerWorkspaceTab
    @State private var showDecisionsDueSheet = false

    private var pendingCount: Int { viewModel.pendingApplicants.count }
    private var escalatedCount: Int {
        viewModel.applicants.filter { $0.status == .escalated }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("Action Items")
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
                .padding(.horizontal, LMSSpacing.screenHorizontal)

            HStack(spacing: LMSSpacing.md) {
                ActionItemCard(
                    title: "Decisions Due",
                    value: "\(pendingCount)",
                    icon: "checklist.checked",
                    tint: pendingCount == 0 ? LMSColors.emerald : LMSColors.amber,
                    action: {
                        if pendingCount > 0 {
                            showDecisionsDueSheet = true
                        }
                    }
                )

                ActionItemCard(
                    title: "Escalations",
                    value: "\(escalatedCount)",
                    icon: "arrow.up.forward.circle.fill",
                    tint: escalatedCount == 0 ? LMSColors.emerald : LMSColors.coral,
                    action: nil
                )
            }
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, LMSSpacing.screenHorizontal)
        }
        .sheet(isPresented: $showDecisionsDueSheet) {
            ManagerApplicantListSheet(
                title: "Decisions Due",
                systemImage: "checklist.checked",
                description: "No pending applications require your attention.",
                applicants: viewModel.pendingApplicants,
                viewModel: viewModel
            )
        }
    }
}

private struct ActionItemCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color
    var action: (() -> Void)? = nil

    var body: some View {
        Group {
            if let action = action {
                Button(action: {
                    HapticsManager.triggerImpact(style: .light)
                    action()
                }) {
                    cardContent
                }
                .buttonStyle(.plain)
            } else {
                cardContent
            }
        }
    }

    private var cardContent: some View {
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
}


// MARK: - Team Overview (single place for officer data)

private struct TeamOverviewSection: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @State private var showDetailSheet = false
    @State private var selectedOfficer: ManagerOfficer?

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            HStack {
                Text("Your Team")
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)

                Spacer()

                if !viewModel.officers.isEmpty {
                    Button(action: {
                        HapticsManager.triggerImpact(style: .light)
                        showDetailSheet = true
                    }) {
                        HStack(spacing: 4) {
                            Text("Details")
                                .font(.system(.subheadline, design: .rounded).bold())
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundStyle(LMSColors.actionBlue)
                    }
                }
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)

            if viewModel.officers.isEmpty {
                ContentUnavailableView(
                    "No Loan Officers Tracked",
                    systemImage: "person.2.slash",
                    description: Text("Branch loan officers will appear here after staff assignment or submitted applications.")
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
                    ForEach(viewModel.officers.indices, id: \.self) { index in
                        TeamOfficerRow(officer: viewModel.officers[index])
                        if index < viewModel.officers.count - 1 {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(LMSColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
                .padding(.horizontal, LMSSpacing.screenHorizontal)
            }
        }
        .sheet(isPresented: $showDetailSheet) {
            OfficerPerformanceReportSheet(viewModel: viewModel)
        }
    }
}

private struct TeamOfficerRow: View {
    let officer: ManagerOfficer

    var body: some View {
        HStack(spacing: LMSSpacing.md) {

            ZStack {
                Circle()
                    .fill(LMSColors.brandNavy.opacity(0.10))
                    .frame(width: 44, height: 44)
                Text(officer.initials)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(LMSColors.brandNavy)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(officer.name)
                    .font(.system(.callout, design: .rounded).weight(.semibold))
                    .foregroundStyle(LMSColors.textPrimary)
                Text(officer.role)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(LMSColors.amber)
                        .font(.system(size: 14))
                    Text(String(format: "%.1f", officer.rating))
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                }
            }
        }
        .padding(.vertical, LMSSpacing.md)
        .padding(.horizontal, LMSSpacing.lg)
    }
}


// MARK: - Officer Performance Report Sheet (moved from ManagerReportsView)

struct OfficerPerformanceReportSheet: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @Environment(\.dismiss) var dismiss

    private var totalProcessed: Int {
        viewModel.officers.reduce(0) { $0 + $1.loansProcessedYTD }
    }

    private var avgApprovalRate: Double {
        let rates = viewModel.officers.map(\.approvalRate)
        return rates.isEmpty ? 0 : rates.reduce(0, +) / Double(rates.count)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.officers.isEmpty {
                    ContentUnavailableView(
                        "No Officers Tracked",
                        systemImage: "person.2.slash",
                        description: Text("Officer performance data will appear once staff are assigned to this branch.")
                    )
                } else {
                    List {
                        Section("Branch Summary") {
                            LabeledContent("Officers Tracked", value: "\(viewModel.officers.count)")
                            LabeledContent("Total Loans Processed (YTD)", value: "\(totalProcessed)")
                            LabeledContent("Avg. Approval Rate", value: String(format: "%.1f%%", avgApprovalRate))
                        }

                        Section("Individual Performance") {
                            ForEach(viewModel.officers.sorted(by: { $0.approvalRate > $1.approvalRate })) { officer in
                                VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                                    HStack {
                                        ZStack {
                                            Circle()
                                                .fill(LMSColors.brandNavy.opacity(0.10))
                                                .frame(width: 36, height: 36)
                                            Text(officer.initials)
                                                .font(.system(.caption2, design: .rounded).bold())
                                                .foregroundStyle(LMSColors.brandNavy)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(officer.name)
                                                .font(.system(.callout, design: .rounded).bold())
                                                .foregroundStyle(LMSColors.textPrimary)
                                            Text(officer.role)
                                                .font(.system(.caption2, design: .rounded))
                                                .foregroundStyle(LMSColors.textSecondary)
                                        }

                                        Spacer()

                                        HStack(spacing: 3) {
                                            Image(systemName: "star.fill")
                                                .foregroundStyle(LMSColors.amber)
                                                .font(.system(size: 10))
                                            Text(String(format: "%.1f", officer.rating))
                                                .font(.system(.caption, design: .rounded).bold())
                                                .foregroundStyle(LMSColors.textPrimary)
                                        }
                                    }

                                    HStack(spacing: LMSSpacing.lg) {
                                        PerformanceMetric(label: "Processed", value: "\(officer.loansProcessedYTD)")
                                        PerformanceMetric(label: "Approval", value: String(format: "%.1f%%", officer.approvalRate))
                                        PerformanceMetric(label: "Capacity", value: "\(officer.activeCases)/\(officer.maxCapacity)")
                                    }

                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(officer.capacityColor.opacity(0.15))
                                                .frame(height: 5)
                                            Capsule()
                                                .fill(officer.capacityColor)
                                                .frame(width: geo.size.width * officer.capacityPercentage, height: 5)
                                        }
                                    }
                                    .frame(height: 5)
                                }
                                .padding(.vertical, LMSSpacing.xs)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Officer Performance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private struct PerformanceMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.caption, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(LMSColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}


#Preview {
    @Previewable @State var selectedTab: ManagerWorkspaceTab = .dashboard

    ManagerDashboardTabView(
        viewModel: PreviewSupport.managerViewModel,
        selectedTab: $selectedTab,
        onSelectApplicant: { _ in }
    )
    .previewManagerEnvironment()
}
