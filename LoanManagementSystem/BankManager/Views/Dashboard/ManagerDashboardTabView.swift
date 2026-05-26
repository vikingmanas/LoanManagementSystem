import SwiftUI


struct ManagerDashboardTabView: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @Binding var selectedTab: ManagerWorkspaceTab
    var onSelectApplicant: (ManagerApplicant) -> Void

    @State private var showBranchOverview = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: LMSSpacing.xl) {

                BranchOverviewCard(overview: viewModel.branchOverview) {
                    showBranchOverview = true
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)
                .padding(.top, LMSSpacing.md)
                .sheet(isPresented: $showBranchOverview) {
                    BranchOverviewDetailSheet(overview: viewModel.branchOverview)
                }

                BranchOperationsSection(viewModel: viewModel, selectedTab: $selectedTab)

                ManagerKPICardsView(viewModel: viewModel, kpis: viewModel.kpis)


                ManagerApprovalQueueView(
                    viewModel: viewModel,
                    onViewAll: {
                        viewModel.navigateToApplicantsWithPending()
                        selectedTab = .applicants
                    },
                    onSelectApplicant: onSelectApplicant
                )


                VStack(alignment: .leading, spacing: LMSSpacing.md) {
                    Text("Branch Portfolio Analytics")
                        .font(.system(.footnote, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textSecondary)
                        .padding(.horizontal, LMSSpacing.screenHorizontal)

                    ManagerAnalyticsView(viewModel: viewModel)
                }


                ManagerRiskPanelView(viewModel: viewModel)


                OfficerPerformanceSection(officers: viewModel.officers)


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


private struct BranchOverviewCard: View {
    let overview: BranchOverview
    var action: () -> Void
    @State private var animatedProgress: Double = 0

    private var targetProgress: Double {
        guard overview.monthlyTarget > 0 else { return 0 }
        return min(1, overview.totalDisbursed / overview.monthlyTarget)
    }

    var body: some View {
        Button(action: {
            HapticsManager.triggerImpact(style: .light)
            action()
        }) {
            VStack(spacing: LMSSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(overview.name)
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(LMSColors.textPrimary)
                        Text("\(overview.code) · \(overview.region)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                    Spacer()
                    LMSStatusPill(text: overview.auditRating, style: .success, icon: "shield.checkmark.fill")
                }

                HStack(spacing: LMSSpacing.sm) {
                    BranchMetricPill(icon: "person.2.fill", value: "\(overview.staffCount)", label: "Staff")
                    BranchMetricPill(icon: "doc.text.fill", value: "\(overview.activeLoanCount)", label: "Active")
                    BranchMetricPill(icon: "indianrupeesign.circle.fill", value: CurrencyFormatter.shared.format(overview.totalDisbursed), label: "Disbursed")
                }

                if overview.monthlyTarget > 0 {
                    VStack(spacing: 4) {
                        HStack {
                            Text("Monthly Target")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(LMSColors.textSecondary)
                            Spacer()
                            Text("\(Int(targetProgress * 100))% of \(CurrencyFormatter.shared.format(overview.monthlyTarget))")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(targetProgress >= 0.8 ? LMSColors.emerald : LMSColors.amber)
                                .monospacedDigit()
                        }

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(LMSColors.brandNavy.opacity(0.10))
                                    .frame(height: 5)
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: targetProgress >= 0.8
                                                ? [LMSColors.emerald, LMSColors.teal]
                                                : [LMSColors.amber, LMSColors.amber.opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * animatedProgress, height: 5)
                            }
                        }
                        .frame(height: 5)
                    }
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.7).delay(0.2)) {
                            animatedProgress = targetProgress
                        }
                    }
                }
            }
            .padding(LMSSpacing.lg)
            .background(LMSColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

private struct BranchMetricPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(LMSColors.brandNavy)
            Text(value)
                .font(.system(.caption2, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(LMSColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LMSSpacing.sm)
        .background(LMSColors.brandNavy.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous))
    }
}

private struct BranchOperationsSection: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @Binding var selectedTab: ManagerWorkspaceTab
    @State private var showPerformanceSheet = false
    @State private var showCustomerFilesSheet = false
    @State private var showDecisionsDueSheet = false
    @State private var showClearedLoansSheet = false

    private var customerCount: Int { viewModel.applicants.count }
    private var officerCount: Int { viewModel.officers.count }
    private var pendingCount: Int { viewModel.pendingApplicants.count }
    private var approvedCount: Int {
        viewModel.applicants.filter { $0.status == .approved || $0.status == .disbursed }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("Branch Command Center")
                .font(.system(.footnote, design: .rounded).bold())
                .foregroundStyle(LMSColors.textSecondary)
                .padding(.horizontal, LMSSpacing.screenHorizontal)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: LMSSpacing.md),
                GridItem(.flexible(), spacing: LMSSpacing.md)
            ], spacing: LMSSpacing.md) {
                BranchOperationCard(
                    title: "Customer Files",
                    value: "\(customerCount)",
                    subtitle: "Profiles in manager scope",
                    icon: "person.text.rectangle",
                    tint: LMSColors.actionBlue,
                    action: { showCustomerFilesSheet = true }
                )

                BranchOperationCard(
                    title: "Loan Officers",
                    value: "\(officerCount)",
                    subtitle: "Tracked branch staff",
                    icon: "person.2.fill",
                    tint: LMSColors.teal,
                    action: { showPerformanceSheet = true }
                )

                BranchOperationCard(
                    title: "Decisions Due",
                    value: "\(pendingCount)",
                    subtitle: "Awaiting approve/reject",
                    icon: "checklist.checked",
                    tint: pendingCount == 0 ? LMSColors.emerald : LMSColors.amber,
                    action: { showDecisionsDueSheet = true }
                )

                BranchOperationCard(
                    title: "Cleared Loans",
                    value: "\(approvedCount)",
                    subtitle: "Approved or disbursed",
                    icon: "checkmark.seal.fill",
                    tint: LMSColors.emerald,
                    action: { showClearedLoansSheet = true }
                )
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)
        }
        .sheet(isPresented: $showPerformanceSheet) {
            OfficerPerformanceReportSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showCustomerFilesSheet) {
            ManagerApplicantListSheet(
                title: "Customer Files",
                systemImage: "person.3.fill",
                description: "No customer files found in your branch.",
                applicants: viewModel.applicants,
                viewModel: viewModel
            )
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
        .sheet(isPresented: $showClearedLoansSheet) {
            ManagerApplicantListSheet(
                title: "Cleared Loans",
                systemImage: "checkmark.seal.fill",
                description: "No cleared loans yet.",
                applicants: viewModel.applicants.filter { $0.status == .approved || $0.status == .disbursed },
                viewModel: viewModel
            )
        }
    }
}

private struct BranchOperationCard: View {
    let title: String
    let value: String
    let subtitle: String
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
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous)
                        .fill(tint.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(tint)
                }
                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(LMSColors.textPrimary)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                    Text(subtitle)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LMSSpacing.lg)
        .background(LMSColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

private struct OfficerPerformanceSection: View {
    let officers: [ManagerOfficer]

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("Officer Performance")
                .font(.system(.footnote, design: .rounded).bold())
                .foregroundStyle(LMSColors.textSecondary)
                .padding(.horizontal, LMSSpacing.screenHorizontal)

            if officers.isEmpty {
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
                    ForEach(officers.indices, id: \.self) { index in
                        OfficerPerformanceRow(officer: officers[index])
                        if index < officers.count - 1 {
                            Divider()
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(LMSColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                        .stroke(LMSColors.separatorLight, lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
                .padding(.horizontal, LMSSpacing.screenHorizontal)
            }
        }
    }
}

private struct OfficerPerformanceRow: View {
    let officer: ManagerOfficer

    var body: some View {
        HStack(spacing: LMSSpacing.md) {

            ZStack {
                Circle()
                    .fill(LMSColors.brandNavy.opacity(0.10))
                    .frame(width: 40, height: 40)
                Text(officer.initials)
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(LMSColors.brandNavy)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(officer.name)
                    .font(.system(.callout, design: .rounded).weight(.semibold))
                    .foregroundStyle(LMSColors.textPrimary)
                Text(officer.role)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(LMSColors.amber)
                        .font(.system(size: 10))
                    Text(String(format: "%.1f", officer.rating))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.textPrimary)
                }

                HStack(spacing: 6) {
                    Text("\(officer.activeCases)/\(officer.maxCapacity)")
                        .font(.system(.caption2, design: .rounded).weight(.medium))
                        .foregroundStyle(LMSColors.textSecondary)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(officer.capacityColor.opacity(0.20))
                                .frame(height: 4)
                            Capsule()
                                .fill(officer.capacityColor)
                                .frame(width: geo.size.width * officer.capacityPercentage, height: 4)
                        }
                    }
                    .frame(width: 32, height: 4)
                }
            }
        }
        .padding(.vertical, LMSSpacing.md)
        .padding(.horizontal, LMSSpacing.lg)
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
