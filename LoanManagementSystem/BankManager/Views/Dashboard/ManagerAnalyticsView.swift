import SwiftUI

// MARK: - Manager Analytics View
struct ManagerAnalyticsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.xl) {

            // MARK: 1 — Monthly Disbursement Chart
            VStack(alignment: .leading, spacing: LMSSpacing.md) {
                HStack {
                    Text("Monthly Disbursements")
                        .font(.system(.footnote, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                    Spacer()
                    Text("₹ in Lakhs")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(LMSColors.textTertiary)
                }

                MonthlyBarChart(data: ManagerMockData.monthlyDisbursements)
            }
            .padding(LMSSpacing.lg)
            .background(LMSColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)

            // MARK: 2 — Approval vs Rejection Donut
            VStack(alignment: .leading, spacing: LMSSpacing.md) {
                Text("Approval vs Rejection")
                    .font(.system(.footnote, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)

                ApprovalDonutChart(stats: ManagerMockData.approvalStats)
            }
            .padding(LMSSpacing.lg)
            .background(LMSColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)

            // MARK: 3 — Portfolio Distribution
            VStack(alignment: .leading, spacing: LMSSpacing.md) {
                Text("Portfolio Distribution")
                    .font(.system(.footnote, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)

                PortfolioDistributionBar(data: ManagerMockData.loanDistribution)

                HStack(spacing: LMSSpacing.lg) {
                    ForEach(ManagerMockData.loanDistribution, id: \.0) { item in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(item.2)
                                .frame(width: 6, height: 6)
                            Text("\(item.0) \(Int(item.1))%")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                    }
                }
            }
            .padding(LMSSpacing.lg)
            .background(LMSColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        }
        .padding(.horizontal, LMSSpacing.screenHorizontal)
    }
}

// MARK: - Monthly Bar Chart
private struct MonthlyBarChart: View {
    let data: [(String, Double)]
    @State private var animated = false

    private var maxValue: Double {
        data.map(\.1).max() ?? 1
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            ForEach(data, id: \.0) { item in
                VStack(spacing: 6) {
                    Text("\(Int(item.1))")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)

                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [LMSColors.brandNavy, LMSColors.actionBlue],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .frame(height: animated ? CGFloat(item.1 / maxValue) * 100 : 0)

                    Text(item.0)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 140)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7).delay(0.15)) {
                animated = true
            }
        }
    }
}

// MARK: - Approval Donut Chart
private struct ApprovalDonutChart: View {
    let stats: (approved: Int, rejected: Int, pending: Int)
    @State private var animated = false

    private var total: Double {
        Double(stats.approved + stats.rejected + stats.pending)
    }

    var body: some View {
        HStack(spacing: LMSSpacing.xl) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(LMSColors.separatorLight, lineWidth: 10)
                    .frame(width: 90, height: 90)

                // Approved
                Circle()
                    .trim(from: 0, to: animated ? Double(stats.approved) / total : 0)
                    .stroke(LMSColors.emerald, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))

                // Rejected
                Circle()
                    .trim(from: Double(stats.approved) / total, to: animated ? Double(stats.approved + stats.rejected) / total : Double(stats.approved) / total)
                    .stroke(LMSColors.coral, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))

                // Center text
                VStack(spacing: 1) {
                    Text("\(Int(Double(stats.approved) / total * 100))%")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
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
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(LMSColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
                .monospacedDigit()
        }
    }
}

// MARK: - Portfolio Distribution Bar
private struct PortfolioDistributionBar: View {
    let data: [(String, Double, Color)]

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(data, id: \.0) { item in
                    Rectangle()
                        .fill(item.2)
                        .frame(width: geo.size.width * (item.1 / 100.0))
                }
            }
            .frame(height: 10)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
        .frame(height: 10)
    }
}

#Preview {
    ScrollView {
        ManagerAnalyticsView()
    }
    .previewManagerEnvironment()
}
