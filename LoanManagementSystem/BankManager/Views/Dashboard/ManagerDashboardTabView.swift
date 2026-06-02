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

                BranchDashboardPromoCard(viewModel: viewModel, showBranchOverview: $showBranchOverview)

                TeamPerformanceRow(viewModel: viewModel)

                Spacer()
                    .frame(height: LMSSpacing.xxxl)
            }
        }
        .background(LMSColors.background)
        .refreshable {
            await viewModel.refreshData()
        }
        .sheet(isPresented: $showBranchOverview) {
            BranchOverviewDetailSheet(overview: viewModel.branchOverview)
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
        viewModel.officerEscalatedApplicants.count
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
                    action: {
                        selectedTab = .branch
                    }
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


// MARK: - Branch quick access (full analytics live on Branch tab)

private struct BranchDashboardPromoCard: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @Binding var showBranchOverview: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("Branch Performance")
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
                .padding(.horizontal, LMSSpacing.screenHorizontal)

            Button {
                HapticsManager.triggerImpact(style: .medium)
                showBranchOverview = true
            } label: {
                VStack(alignment: .leading, spacing: LMSSpacing.md) {
                    HStack(spacing: LMSSpacing.md) {
                        ZStack {
                            RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                                .fill(LMSColors.brandNavy.opacity(0.12))
                                .frame(width: 48, height: 48)
                            Image(systemName: "building.2.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(LMSColors.brandNavy)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.branchOverview.name)
                                .font(.system(.headline, design: .rounded).bold())
                                .foregroundStyle(LMSColors.textPrimary)
                            Text("Charts, officer ratings, and branch reports")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(LMSColors.textSecondary)
                        }

                        Spacer(minLength: 0)

                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(LMSColors.textTertiary)
                    }

                    HStack(spacing: LMSSpacing.sm) {
                        promoMetric(
                            title: "Disbursed",
                            value: viewModel.branchOverview.totalDisbursed.formattedAsCompactINR()
                        )
                        promoMetric(title: "Officers", value: "\(viewModel.officers.count)")
                        promoMetric(title: "Escalations", value: "\(viewModel.officerEscalatedApplicants.count)")
                    }
                }
                .padding(LMSSpacing.lg)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LMSColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, LMSSpacing.screenHorizontal)
        }
    }

    private func promoMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.caption2, design: .rounded).weight(.medium))
                .foregroundStyle(LMSColors.textTertiary)
            Text(value)
                .font(.system(.subheadline, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LMSSpacing.sm)
        .background(LMSColors.background, in: RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous))
    }
}


// MARK: - Team Performance Row

private struct TeamPerformanceRow: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @State private var showPerformanceSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            HStack {
                Text("Team Performance")
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)
                Spacer()
                Button {
                    HapticsManager.triggerImpact(style: .light)
                    showPerformanceSheet = true
                } label: {
                    Text("View All")
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundStyle(LMSColors.actionBlue)
                }
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)

            if viewModel.officers.isEmpty {
                Text("No officers assigned to this branch.")
                    .font(.subheadline)
                    .foregroundStyle(LMSColors.textSecondary)
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: LMSSpacing.md) {
                        ForEach(viewModel.officers) { officer in
                            TeamPerformanceOfficerCard(officer: officer)
                        }
                    }
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                }
            }
        }
        .sheet(isPresented: $showPerformanceSheet) {
            OfficerPerformanceReportSheet(viewModel: viewModel)
        }
    }
}

private struct TeamPerformanceOfficerCard: View {
    let officer: ManagerOfficer
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(LMSColors.brandNavy.opacity(0.1))
                        .frame(width: 40, height: 40)
                    Text(String(officer.name.prefix(1)))
                        .font(.system(.headline, design: .rounded).bold())
                        .foregroundStyle(LMSColors.brandNavy)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(officer.name)
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                    Text("Officer")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                }
            }
            
            HStack {
                Label(String(format: "%.1f", officer.rating), systemImage: "star.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(LMSColors.amber)
                Spacer()
                Text("\(officer.loansProcessedYTD) loans")
                    .font(.caption)
                    .foregroundStyle(LMSColors.textSecondary)
            }
            .padding(.top, 4)
        }
        .padding(LMSSpacing.md)
        .frame(width: 220)
        .background(LMSColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}


// MARK: - Officer Performance Report Sheet

struct OfficerPerformanceReportSheet: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @Environment(\.dismiss) var dismiss
    @State private var draftRatings: [UUID: Double] = [:]

    private var summaries: [ManagerOfficerPerformanceSummary] {
        viewModel.officerPerformanceSummaries
    }

    private var totalProcessed: Int {
        viewModel.officers.reduce(0) { $0 + $1.loansProcessedYTD }
    }

    private var avgApprovalRate: Double {
        let rates = viewModel.officers.map(\.approvalRate)
        return rates.isEmpty ? 0 : rates.reduce(0, +) / Double(rates.count)
    }

    private var totalOfficerEscalations: Int {
        viewModel.officerEscalatedApplicants.count
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
                        Section {
                            Text("Review escalations raised by each loan officer, then assign a performance rating for your branch team.")
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(LMSColors.textSecondary)
                        }

                        Section("Branch Summary") {
                            LabeledContent("Officers Tracked", value: "\(viewModel.officers.count)")
                            LabeledContent("Total Loans Processed (YTD)", value: "\(totalProcessed)")
                            LabeledContent("Avg. Approval Rate", value: String(format: "%.1f%%", avgApprovalRate))
                            LabeledContent("Officer Escalations", value: "\(totalOfficerEscalations)")
                        }

                        if !viewModel.unassignedApplicants.isEmpty {
                            Section("Unassigned Loans") {
                                Text("\(viewModel.unassignedApplicants.count) application\(viewModel.unassignedApplicants.count == 1 ? "" : "s") are not linked to a loan officer yet. Reassign them before rating officer performance.")
                                    .font(.footnote)
                                    .foregroundStyle(LMSColors.textSecondary)
                                ForEach(viewModel.unassignedApplicants.prefix(5)) { applicant in
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(applicant.applicationId)
                                            .font(.subheadline.weight(.semibold))
                                        Text("\(applicant.borrowerName) · \(CurrencyFormatter.shared.format(applicant.requestedAmount))")
                                            .font(.caption)
                                            .foregroundStyle(LMSColors.textSecondary)
                                    }
                                }
                            }
                        }

                        Section("Rate Your Team") {
                            ForEach(summaries) { summary in
                                OfficerPerformanceRatingCard(
                                    viewModel: viewModel,
                                    summary: summary,
                                    selectedRating: Binding(
                                        get: {
                                            draftRatings[summary.officer.id]
                                                ?? summary.managerRating
                                                ?? summary.suggestedRating
                                        },
                                        set: { draftRatings[summary.officer.id] = $0 }
                                    ),
                                    onSave: {
                                        let rating = draftRatings[summary.officer.id]
                                            ?? summary.managerRating
                                            ?? summary.suggestedRating
                                        viewModel.setOfficerRating(rating, for: summary.officer.id)
                                    }
                                )
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
                    Button("Done") { dismiss() }
                        .bold()
                }
            }
            .onAppear {
                for summary in summaries {
                    draftRatings[summary.officer.id] = summary.managerRating ?? summary.suggestedRating
                }
            }
        }
    }
}

private struct OfficerPerformanceRatingCard: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    let summary: ManagerOfficerPerformanceSummary
    @Binding var selectedRating: Double
    let onSave: () -> Void

    private var assignedLoans: [ManagerApplicant] {
        viewModel.applicants(for: summary.officer)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            HStack(alignment: .top, spacing: LMSSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(LMSColors.brandNavy.opacity(0.10))
                        .frame(width: 40, height: 40)
                    Text(summary.officer.initials)
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundStyle(LMSColors.brandNavy)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.officer.name)
                        .font(.system(.callout, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                    Text(summary.officer.role)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                }

                Spacer()

                if summary.officerEscalationCount > 0 {
                    Label("\(summary.officerEscalationCount)", systemImage: "arrow.up.forward.circle.fill")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(LMSColors.coral)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(LMSColors.coral.opacity(0.12), in: Capsule())
                }
            }

            HStack(spacing: LMSSpacing.lg) {
                PerformanceMetric(label: "Assigned", value: "\(assignedLoans.count)")
                PerformanceMetric(label: "Approval", value: String(format: "%.1f%%", summary.officer.approvalRate))
                PerformanceMetric(label: "Escalated", value: "\(summary.officerEscalationCount)")
            }

            if assignedLoans.isEmpty {
                Text("No loans are currently assigned to this officer.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
            } else {
                VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                    Text("Assigned Loans")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(LMSColors.textSecondary)

                    ForEach(assignedLoans.prefix(4)) { loan in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(loan.applicationId)
                                    .font(.system(.caption, design: .rounded).weight(.bold))
                                    .foregroundStyle(LMSColors.brandNavy)
                                Text(loan.borrowerName)
                                    .font(.system(.caption2, design: .rounded))
                                Text("\(loan.loanType.rawValue) · \(CurrencyFormatter.shared.format(loan.requestedAmount))")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(LMSColors.textSecondary)
                            }
                            Spacer()
                            Text(loan.status.displayName)
                                .font(.system(.caption2, design: .rounded).weight(.semibold))
                                .foregroundStyle(loan.status.themeColor)
                        }
                        .padding(LMSSpacing.sm)
                        .background(LMSColors.surfaceElevated, in: RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous))
                    }

                    if assignedLoans.count > 4 {
                        Text("+ \(assignedLoans.count - 4) more assigned loan\(assignedLoans.count - 4 == 1 ? "" : "s")")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(LMSColors.textTertiary)
                    }
                }
            }

            if summary.escalations.isEmpty {
                Text("No officer escalations on record.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
            } else {
                VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                    Text("Escalated Loans")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(LMSColors.textSecondary)

                    ForEach(summary.escalations) { escalation in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(escalation.applicationId)
                                    .font(.system(.caption, design: .rounded).weight(.bold))
                                    .foregroundStyle(LMSColors.brandNavy)
                                Spacer()
                                Text(escalation.escalatedAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(LMSColors.textTertiary)
                            }
                            Text(escalation.borrowerName)
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                            Text("\(escalation.loanType.rawValue) · \(CurrencyFormatter.shared.format(escalation.requestedAmount)) · \(escalation.riskLevel.rawValue) risk")
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(LMSColors.textSecondary)
                            Text(escalation.reason)
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(LMSColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(LMSSpacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(LMSColors.surfaceElevated, in: RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous))
                    }
                }
            }

            VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                HStack {
                    Text("Performance Rating")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(LMSColors.textSecondary)
                    Spacer()
                    Text(String(format: "%.1f / 5", selectedRating))
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                }

                Text("Suggested: \(String(format: "%.1f", summary.suggestedRating)) from assigned loans, escalations, and approval rate")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(LMSColors.textTertiary)

                OfficerStarRatingPicker(rating: $selectedRating)

                Button(action: onSave) {
                    Text(summary.officer.managerRating == nil ? "Save Rating" : "Update Rating")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(LMSColors.brandNavy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(LMSColors.brandNavy.opacity(0.10), in: RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, LMSSpacing.xs)
    }
}

private struct OfficerStarRatingPicker: View {
    @Binding var rating: Double

    var body: some View {
        HStack(spacing: 10) {
            ForEach(1...5, id: \.self) { star in
                Button {
                    HapticsManager.triggerImpact(style: .light)
                    rating = Double(star)
                } label: {
                    Image(systemName: Double(star) <= rating ? "star.fill" : "star")
                        .font(.system(size: 24))
                        .foregroundStyle(LMSColors.amber)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(star) star")
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
