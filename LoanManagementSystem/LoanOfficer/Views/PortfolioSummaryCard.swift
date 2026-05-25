import SwiftUI

struct PortfolioSummaryCard: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onViewAllPressed: () -> Void

    private let targetAmount: Double = 150_000_000.0

    var progressPercentage: Int {
        let value = viewModel.totalPortfolioValue
        let pct = (value / targetAmount) * 100
        return min(Int(pct), 100)
    }

    var body: some View {
        VStack(spacing: 20) {

            HStack {
                Text("My Loan Portfolio")
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundStyle(.white)

                Spacer()

                Button(action: {
                    HapticsManager.triggerImpact(style: .light)
                    onViewAllPressed()
                }) {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(Color(hex: "5CA4FF"))
                }
                .accessibilityLabel("View entire loan portfolio list")
            }


            HStack(spacing: LMSSpacing.lg) {
                portfolioStatColumn(
                    loanCount: viewModel.totalApplications,
                    amount: viewModel.totalPortfolioValue,
                    label: "Total Value"
                )

                portfolioStatColumn(
                    loanCount: viewModel.underProcessCount,
                    amount: viewModel.underProcessValue,
                    label: "Under Process"
                )

                portfolioStatColumn(
                    loanCount: viewModel.closedThisMonthCount,
                    amount: viewModel.closedThisMonthValue,
                    label: "Closed This Mo"
                )
            }


            VStack(spacing: 8) {
                HStack {
                    Text("Monthly Target: ₹ 15 Cr")
                        .font(.system(.caption2, design: .rounded).weight(.medium))
                        .foregroundStyle(.white.opacity(0.75))

                    Spacer()

                    Text("\(progressPercentage)%")
                        .font(.system(.caption2, design: .rounded).bold())
                        .foregroundStyle(.white)
                }


                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(AppTheme.successGreen)
                            .frame(width: geo.size.width * CGFloat(Double(progressPercentage) / 100.0), height: 6)
                    }
                }
                .frame(height: 6)


                HStack {
                    Spacer()

                    HStack(spacing: 4) {
                        if progressPercentage >= 80 {
                            Text("🎯 On Track")
                                .foregroundStyle(AppTheme.successGreen)
                        } else {
                            Text("⚠️ Behind Target")
                                .foregroundStyle(AppTheme.warningAmber)
                        }
                    }
                    .font(.system(.caption2, design: .rounded).bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [Color(hex: "0A2540"), Color(hex: "1A3A5C")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color(hex: "0A2540").opacity(0.15), radius: 10, x: 0, y: 5)
    }

    private func portfolioStatColumn(loanCount: Int, amount: Double, label: String) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text("\(loanCount) Loans")
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(.white)
                .minimumScaleFactor(0.8)
                .lineLimit(1)

            Text(CurrencyFormatter.shared.format(amount))
                .font(.system(.caption2, design: .rounded).weight(.semibold))
                .foregroundStyle(.white.opacity(0.75))
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.white.opacity(0.55))
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(loanCount) loans, total \(CurrencyFormatter.shared.format(amount)).")
    }
}

#Preview {
    PortfolioSummaryCard(viewModel: PreviewSupport.loanOfficerViewModel, onViewAllPressed: {})
        .padding()
}

