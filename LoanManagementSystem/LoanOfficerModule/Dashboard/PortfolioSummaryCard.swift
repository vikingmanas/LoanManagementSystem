import SwiftUI

struct PortfolioSummaryCard: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onViewAllPressed: () -> Void
    
    private let targetAmount: Double = 150_000_000.0 // ₹ 15 Cr target
    
    var progressPercentage: Int {
        let value = viewModel.totalPortfolioValue
        let pct = (value / targetAmount) * 100
        return min(Int(pct), 100)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Header Row
            HStack {
                Text("My Loan Portfolio")
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundColor(.white)
                
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
                    .foregroundColor(Color(hex: "5CA4FF"))
                }
                .accessibilityLabel("View entire loan portfolio list")
            }
            
            // Main Stats Row
            HStack(spacing: 0) {
                // Col 1: Total Value
                VStack(alignment: .center, spacing: 4) {
                    Text(CurrencyFormatter.shared.format(viewModel.totalPortfolioValue))
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    Text("\(viewModel.totalApplications) Loans")
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundColor(.white.opacity(0.7))
                    Text("Total Value")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Total portfolio value: \(CurrencyFormatter.shared.format(viewModel.totalPortfolioValue)) across \(viewModel.totalApplications) loans.")
                
                // Vertical Divider
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 1, height: 44)
                
                // Col 2: Under Process
                VStack(alignment: .center, spacing: 4) {
                    Text(CurrencyFormatter.shared.format(viewModel.underProcessValue))
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    Text("\(viewModel.underProcessCount) Loans")
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundColor(.white.opacity(0.7))
                    Text("Under Process")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Under process value: \(CurrencyFormatter.shared.format(viewModel.underProcessValue)) in \(viewModel.underProcessCount) loans.")
                
                // Vertical Divider
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 1, height: 44)
                
                // Col 3: Closed This Month
                VStack(alignment: .center, spacing: 4) {
                    Text(CurrencyFormatter.shared.format(viewModel.closedThisMonthValue))
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)
                    Text("\(viewModel.closedThisMonthCount) Loans")
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundColor(.white.opacity(0.7))
                    Text("Closed This Mo")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Closed this month value: \(CurrencyFormatter.shared.format(viewModel.closedThisMonthValue)) with \(viewModel.closedThisMonthCount) loans.")
            }
            
            // Progress Bar Section
            VStack(spacing: 8) {
                HStack {
                    Text("Monthly Target: ₹ 15 Cr")
                        .font(.system(.caption2, design: .rounded).weight(.medium))
                        .foregroundColor(.white.opacity(0.75))
                    
                    Spacer()
                    
                    Text("\(progressPercentage)%")
                        .font(.system(.caption2, design: .rounded).bold())
                        .foregroundColor(.white)
                }
                
                // ZStack Custom Bar
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
                
                // Target Status Pill
                HStack {
                    Spacer()
                    
                    HStack(spacing: 4) {
                        if progressPercentage >= 80 {
                            Text("🎯 On Track")
                                .foregroundColor(AppTheme.successGreen)
                        } else {
                            Text("⚠️ Behind Target")
                                .foregroundColor(AppTheme.warningAmber)
                        }
                    }
                    .font(.system(.caption2, design: .rounded).bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.12))
                    .cornerRadius(8)
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
        .cornerRadius(16)
        .shadow(color: Color(hex: "0A2540").opacity(0.15), radius: 10, x: 0, y: 5)
    }
}
