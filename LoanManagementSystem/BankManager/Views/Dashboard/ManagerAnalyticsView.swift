import SwiftUI

struct ManagerAnalyticsView: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @State private var showPortfolioLedger = false

    private var monthlyDisbursements: [(String, Double)] {
        let calendar = Calendar.current
        let months = (0..<6).compactMap { offset in
            calendar.date(byAdding: .month, value: -offset, to: Date())
        }.reversed()

        return months.map { date in
            let amount = viewModel.applicants
                .filter { applicant in
                    (applicant.status == .approved || applicant.status == .disbursed) &&
                    calendar.isDate(applicant.submissionDate, equalTo: date, toGranularity: .month)
                }
                .reduce(0) { $0 + $1.requestedAmount / 100_000 }

            return (date.formatted(.dateTime.month(.abbreviated)), amount)
        }
    }

    private var approvalStats: (approved: Int, rejected: Int, pending: Int) {
        (
            approved: viewModel.applicants.filter { $0.status == .approved || $0.status == .disbursed }.count,
            rejected: viewModel.applicants.filter { $0.status == .rejected }.count,
            pending: viewModel.pendingApplicants.count
        )
    }

    private var portfolioItems: [LoanPortfolioItem] {
        let totalAmount = max(viewModel.applicants.reduce(0) { $0 + $1.requestedAmount }, 1)

        return ManagerLoanType.allCases.map { loanType in
            let loans = viewModel.applicants.filter { $0.loanType == loanType }
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

    @State private var showDisbursementsSheet = false
    @State private var showDecisionMixSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            AnalyticsCard(action: { showDisbursementsSheet = true }) {
                HStack {
                    ChartHeader(
                        title: "Monthly Disbursements",
                        subtitle: "Approved and disbursed value"
                    )
                    Spacer()
                    Text("₹ in Lakhs")
                        .font(LMSFont.caption2)
                        .foregroundStyle(LMSColors.textTertiary)
                }

                MonthlyBarChart(data: monthlyDisbursements)
            }

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
        }
        .padding(.horizontal, LMSSpacing.screenHorizontal)
        .sheet(isPresented: $showPortfolioLedger) {
            BranchPortfolioLedgerSheet(viewModel: viewModel, portfolioItems: portfolioItems)
        }
        .sheet(isPresented: $showDisbursementsSheet) {
            ManagerApplicantListSheet(
                title: "Monthly Disbursements",
                systemImage: "chart.bar.fill",
                description: "No disbursed loans in this period.",
                applicants: viewModel.applicants.filter { $0.status == .disbursed || $0.status == .approved },
                viewModel: viewModel
            )
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
    }
}

struct LoanPortfolioItem: Identifiable {
    let id = UUID()
    let loanType: ManagerLoanType
    let count: Int
    let amount: Double
    let share: Double
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
                .font(LMSFont.footnote.weight(.bold))
                .foregroundStyle(LMSColors.textPrimary)
            Text(subtitle)
                .font(LMSFont.caption2)
                .foregroundStyle(LMSColors.textSecondary)
        }
    }
}

private struct MonthlyBarChart: View {
    let data: [(String, Double)]
    @State private var animated = false

    private var maxValue: Double {
        max(data.map(\.1).max() ?? 0, 1)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ForEach(Array(data.enumerated()), id: \.offset) { index, item in
                VStack(spacing: 6) {
                    Text("\(Int(item.1))")
                        .font(LMSFont.caption2.weight(.bold))
                        .foregroundStyle(LMSColors.textSecondary)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(monthTint(index).gradient)
                        .frame(height: animated ? max(CGFloat(item.1 / maxValue) * 108, item.1 > 0 ? 8 : 2) : 0)

                    Text(item.0)
                        .font(LMSFont.caption2.weight(.semibold))
                        .foregroundStyle(LMSColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 148)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7).delay(0.15)) {
                animated = true
            }
        }
    }

    private func monthTint(_ index: Int) -> Color {
        let colors: [Color] = [
            LMSColors.brandNavy,
            LMSColors.teal,
            LMSColors.emerald,
            LMSColors.amber,
            LMSColors.actionBlue,
            Color.purple
        ]
        return colors[index % colors.count]
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

                VStack(spacing: 1) {
                    Text("\(Int(Double(stats.approved) / total * 100))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.textPrimary)
                    Text("Approved")
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
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
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(label)
                .font(LMSFont.caption)
                .foregroundStyle(LMSColors.textSecondary)
            Spacer()
            Text(value)
                .font(LMSFont.caption.weight(.bold))
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
                    .font(LMSFont.caption.weight(.bold))
                    .foregroundStyle(LMSColors.textPrimary)
                Text("\(item.count) application\(item.count == 1 ? "" : "s")")
                    .font(LMSFont.caption2)
                    .foregroundStyle(LMSColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(CurrencyFormatter.shared.format(item.amount))
                    .font(LMSFont.caption.weight(.bold))
                    .foregroundStyle(LMSColors.textPrimary)
                Text("\(Int(item.share * 100))%")
                    .font(LMSFont.caption2.weight(.semibold))
                    .foregroundStyle(item.loanType.themeColor)
            }
        }
        .padding(LMSSpacing.sm)
        .background(item.loanType.themeColor.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
    }
}

struct BranchPortfolioLedgerSheet: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    let portfolioItems: [LoanPortfolioItem]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.applicants.isEmpty {
                    ContentUnavailableView(
                        "No Loans",
                        systemImage: "list.clipboard",
                        description: Text("Active and disbursed loans will appear here.")
                    )
                } else {
                    List {
                        ForEach(portfolioItems) { item in
                            Section {
                                let sectorLoans = viewModel.applicants.filter { $0.loanType == item.loanType }
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
                    Button("Close") { dismiss() }
                        .font(.system(.body, design: .rounded).bold())
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        ManagerAnalyticsView(viewModel: PreviewSupport.managerViewModel)
    }
    .previewManagerEnvironment()
}
