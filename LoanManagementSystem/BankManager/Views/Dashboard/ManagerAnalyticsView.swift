import SwiftUI

struct ManagerAnalyticsView: View {
    @Bindable var viewModel: ManagerDashboardViewModel
    @State private var showPortfolioLedger = false

    private var approvalStats: (approved: Int, rejected: Int, pending: Int) {
        (
            approved: viewModel.applicants.filter { $0.status == .approved || $0.status == .disbursed }.count,
            rejected: viewModel.applicants.filter { $0.status == .rejected }.count,
            pending: viewModel.pendingApplicants.count
        )
    }

    private var portfolioItems: [LoanPortfolioItem] {
        let loanBook = viewModel.applicants.filter { $0.status == .approved || $0.status == .disbursed }
        let totalAmount = max(loanBook.reduce(0) { $0 + $1.requestedAmount }, 1)

        return ManagerLoanType.allCases.map { loanType in
            let loans = loanBook.filter { $0.loanType == loanType }
            let amount = loans.reduce(0) { $0 + $1.requestedAmount }
            return LoanPortfolioItem(
                loanType: loanType,
                count: loans.count,
                amount: amount,
                share: amount / totalAmount
            )
        }
        .filter { $0.count > 0 }
        .sorted { $0.amount > $1.amount }
    }

    private var highRiskApplicants: [ManagerApplicant] {
        viewModel.applicants.filter { $0.riskLevel == .high || $0.riskLevel == .critical }
    }

    @State private var showDecisionMixSheet = false
    @State private var showNPLRateSheet = false
    @State private var showEscalationsSheet = false
    @State private var showHighRiskSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            AnalyticsCard(action: { showDecisionMixSheet = true }) {
                ChartHeader(
                    title: "Decision Mix",
                    subtitle: "Manager approvals, rejections, and pending clearances"
                )

                ApprovalDonutChart(stats: approvalStats)
            }

            AnalyticsCard(action: { showPortfolioLedger = true }) {
                ChartHeader(
                    title: "Branch Portfolio",
                    subtitle: "Loan book by product type"
                )

                if portfolioItems.isEmpty {
                    ContentUnavailableView(
                        "No Portfolio Data",
                        systemImage: "chart.pie",
                        description: Text("Loan-type distribution will build from real branch applications.")
                    )
                    .frame(minHeight: 190)
                } else {
                    PortfolioDistributionBar(data: portfolioItems)
                        .padding(.top, LMSSpacing.xs)

                    VStack(spacing: LMSSpacing.sm) {
                        ForEach(portfolioItems) { item in
                            PortfolioTypeRow(item: item)
                        }
                    }
                }
            }

            if viewModel.applicants.isEmpty {
                AnalyticsCard {
                    ContentUnavailableView(
                        "No Risk Data",
                        systemImage: "shield.slash",
                        description: Text("Risk metrics will populate once branch applications are submitted.")
                    )
                    .frame(minHeight: 120)
                }
            } else {
                let escalationsCount = viewModel.officerEscalatedApplicants.count
                if viewModel.branchOverview.nplRate > 0 || escalationsCount > 0 || !highRiskApplicants.isEmpty {
                    VStack(spacing: LMSSpacing.sm) {
                        HStack(spacing: LMSSpacing.md) {
                            if viewModel.branchOverview.nplRate > 0 {
                                RiskMetricCard(
                                    title: "NPL Rate",
                                    value: String(format: "%.2f%%", viewModel.branchOverview.nplRate),
                                    icon: "exclamationmark.triangle.fill",
                                    tint: viewModel.branchOverview.nplRate < 1.0 ? LMSColors.emerald : LMSColors.coral,
                                    subtitle: viewModel.branchOverview.nplRate < 1.0 ? "Healthy" : "Needs Attention",
                                    action: { showNPLRateSheet = true }
                                )
                            }
    
                            if escalationsCount > 0 {
                                RiskMetricCard(
                                    title: "Manager Review",
                                    value: "\(escalationsCount)",
                                    icon: "arrow.up.forward.circle.fill",
                                    tint: Color.purple,
                                    subtitle: "Active",
                                    action: { showEscalationsSheet = true }
                                )
                            }
    
                            if !highRiskApplicants.isEmpty {
                                RiskMetricCard(
                                    title: "High Risk",
                                    value: "\(highRiskApplicants.count)",
                                    icon: "shield.lefthalf.filled",
                                    tint: LMSColors.coral,
                                    subtitle: "Flagged",
                                    action: { showHighRiskSheet = true }
                                )
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, LMSSpacing.screenHorizontal)
        .sheet(isPresented: $showPortfolioLedger) {
            BranchPortfolioLedgerSheet(viewModel: viewModel, portfolioItems: portfolioItems)
        }
        .sheet(isPresented: $showDecisionMixSheet) {
            ManagerApplicantListSheet(
                title: "Decision Mix",
                systemImage: "chart.pie.fill",
                description: "No decisions have been made.",
                applicants: viewModel.applicants,
                viewModel: viewModel
            )
        }
        .sheet(isPresented: $showNPLRateSheet) {
            ManagerApplicantListSheet(
                title: "NPL Loans",
                systemImage: "exclamationmark.triangle.fill",
                description: "No non-performing loans found.",
                applicants: viewModel.nonPerformingApplicants,
                viewModel: viewModel
            )
        }
        .sheet(isPresented: $showEscalationsSheet) {
            ManagerApplicantListSheet(
                title: "Manager Review",
                systemImage: "arrow.up.circle.fill",
                description: "No escalated applications.",
                applicants: viewModel.officerEscalatedApplicants,
                viewModel: viewModel
            )
        }
        .sheet(isPresented: $showHighRiskSheet) {
            ManagerApplicantListSheet(
                title: "High-Risk Loans",
                systemImage: "shield.slash.fill",
                description: "No high-risk loans detected.",
                applicants: highRiskApplicants,
                viewModel: viewModel
            )
        }
    }
}

struct LoanPortfolioItem: Identifiable {
    let id = UUID()
    let loanType: ManagerLoanType
    let count: Int
    let amount: Double
    let share: Double
}



private struct RiskMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color
    let subtitle: String
    var action: (() -> Void)? = nil

    var body: some View {
        Button(action: {
            HapticsManager.triggerImpact(style: .light)
            action?()
        }) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(tint)

                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(LMSColors.textPrimary)
                    .monospacedDigit()

                VStack(spacing: 2) {
                    Text(title)
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textSecondary)
                    Text(subtitle)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(tint)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, LMSSpacing.lg)
            .padding(.horizontal, LMSSpacing.sm)
            .background(LMSColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}



private struct AnalyticsCard<Content: View>: View {
    var action: (() -> Void)? = nil
    @ViewBuilder var content: Content

    var body: some View {
        Group {
            if let action = action {
                Button(action: {
                    HapticsManager.triggerImpact(style: .medium)
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
            content
        }
        .padding(LMSSpacing.lg)
        .background(LMSColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
}

private struct ChartHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(.headline, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
            Text(subtitle)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(LMSColors.textSecondary)
        }
    }
}

private struct ApprovalDonutChart: View {
    let stats: (approved: Int, rejected: Int, pending: Int)
    @State private var animated = false

    private var total: Double {
        max(Double(stats.approved + stats.rejected + stats.pending), 1)
    }

    var body: some View {
        HStack(spacing: LMSSpacing.xl) {
            ZStack {
                Circle()
                    .stroke(LMSColors.separatorLight, lineWidth: 11)
                    .frame(width: 96, height: 96)

                Circle()
                    .trim(from: 0, to: animated ? Double(stats.approved) / total : 0)
                    .stroke(LMSColors.emerald, style: StrokeStyle(lineWidth: 11, lineCap: .round))
                    .frame(width: 96, height: 96)
                    .rotationEffect(.degrees(-90))

                Circle()
                    .trim(from: Double(stats.approved) / total, to: animated ? Double(stats.approved + stats.rejected) / total : Double(stats.approved) / total)
                    .stroke(LMSColors.coral, style: StrokeStyle(lineWidth: 11, lineCap: .round))
                    .frame(width: 96, height: 96)
                    .rotationEffect(.degrees(-90))

                Circle()
                    .trim(
                        from: Double(stats.approved + stats.rejected) / total,
                        to: animated ? Double(stats.approved + stats.rejected + stats.pending) / total : Double(stats.approved + stats.rejected) / total
                    )
                    .stroke(LMSColors.amber, style: StrokeStyle(lineWidth: 11, lineCap: .round))
                    .frame(width: 96, height: 96)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(Int(Double(stats.approved) / total * 100))%")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.textPrimary)
                    Text("Approved")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                }
            }

            VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                DonutLegendItem(color: LMSColors.emerald, label: "Approved", value: "\(stats.approved)")
                DonutLegendItem(color: LMSColors.coral, label: "Rejected", value: "\(stats.rejected)")
                DonutLegendItem(color: LMSColors.amber, label: "Pending", value: "\(stats.pending)")
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animated = true
            }
        }
    }
}

private struct DonutLegendItem: View {
    let color: Color
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(color)
                .frame(width: 14, height: 14)
            Text(label)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(LMSColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
                .monospacedDigit()
        }
    }
}

private struct PortfolioDistributionBar: View {
    let data: [LoanPortfolioItem]

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(data) { item in
                    Rectangle()
                        .fill(item.loanType.themeColor)
                        .frame(width: max(geo.size.width * item.share, 8))
                }
            }
        }
        .frame(height: 18)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .accessibilityLabel("Branch portfolio by loan type")
    }
}

private struct PortfolioTypeRow: View {
    let item: LoanPortfolioItem

    var body: some View {
        HStack(spacing: LMSSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous)
                    .fill(item.loanType.themeColor.opacity(0.14))
                    .frame(width: 36, height: 36)
                Image(systemName: item.loanType.symbol)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(item.loanType.themeColor)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.loanType.rawValue)
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)
                Text("\(item.count) application\(item.count == 1 ? "" : "s")")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(CurrencyFormatter.shared.format(item.amount))
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)
                Text("\(Int(item.share * 100))%")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(item.loanType.themeColor)
            }
        }
        .padding(LMSSpacing.sm)
        .background(item.loanType.themeColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
    }
}

struct BranchPortfolioLedgerSheet: View {
    @Bindable var viewModel: ManagerDashboardViewModel
    let portfolioItems: [LoanPortfolioItem]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if portfolioItems.isEmpty {
                    ContentUnavailableView(
                        "No Loans",
                        systemImage: "list.clipboard",
                        description: Text("Active and disbursed loans will appear here.")
                    )
                } else {
                    List {
                        ForEach(portfolioItems) { item in
                            Section {
                                let sectorLoans = viewModel.applicants.filter {
                                    $0.loanType == item.loanType && ($0.status == .approved || $0.status == .disbursed)
                                }
                                ForEach(sectorLoans) { loan in
                                    HStack(spacing: LMSSpacing.md) {
                                        ZStack {
                                            Circle()
                                                .fill(loan.status.themeColor.opacity(0.12))
                                                .frame(width: 36, height: 36)
                                            Text(loan.borrowerInitials)
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(loan.status.themeColor)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(loan.borrowerName)
                                                .font(.system(.callout, design: .rounded).bold())
                                                .foregroundStyle(LMSColors.textPrimary)
                                            Text("Officer: \(loan.assignedOfficer)")
                                                .font(.system(.caption, design: .rounded))
                                                .foregroundStyle(LMSColors.textSecondary)
                                        }

                                        Spacer()

                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(CurrencyFormatter.shared.format(loan.requestedAmount))
                                                .font(.system(.subheadline, design: .rounded).bold())
                                                .foregroundStyle(LMSColors.textPrimary)
                                            Text(loan.status.displayName)
                                                .font(.system(.caption2, design: .rounded).weight(.semibold))
                                                .foregroundStyle(loan.status.themeColor)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            } header: {
                                HStack {
                                    Image(systemName: item.loanType.symbol)
                                    Text(item.loanType.rawValue)
                                    Spacer()
                                    Text(CurrencyFormatter.shared.format(item.amount))
                                }
                                .font(.system(.subheadline, design: .rounded).bold())
                                .foregroundStyle(item.loanType.themeColor)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Branch Portfolio Ledger")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .bold()
                }
            }
        }
    }
}

