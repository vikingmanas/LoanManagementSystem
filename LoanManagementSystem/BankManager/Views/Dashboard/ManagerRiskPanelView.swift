import SwiftUI


struct ManagerRiskPanelView: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel

    private var highRiskApplicants: [ManagerApplicant] {
        viewModel.applicants.filter { $0.riskLevel == .high || $0.riskLevel == .critical }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("Risk Monitoring")
                .font(.system(.footnote, design: .rounded).bold())
                .foregroundStyle(LMSColors.textSecondary)
                .padding(.horizontal, LMSSpacing.screenHorizontal)

            VStack(spacing: LMSSpacing.md) {

                HStack(spacing: LMSSpacing.md) {
                    RiskGaugeCard(
                        title: "NPL Rate",
                        value: String(format: "%.2f%%", viewModel.branchOverview.nplRate),
                        progress: viewModel.branchOverview.nplRate / 5.0,
                        tint: viewModel.branchOverview.nplRate < 1.0 ? LMSColors.emerald : LMSColors.coral,
                        subtitle: viewModel.branchOverview.nplRate < 1.0 ? "Excellent" : "Needs Attention"
                    )

                    RiskGaugeCard(
                        title: "Escalations",
                        value: "\(viewModel.applicants.filter { $0.status == .escalated }.count)",
                        progress: Double(viewModel.applicants.filter { $0.status == .escalated }.count) / 10.0,
                        tint: Color.purple,
                        subtitle: "Active"
                    )
                }


                if !highRiskApplicants.isEmpty {
                    VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(LMSColors.coral)
                                .font(.system(size: 12, weight: .bold))

                            Text("HIGH-RISK LOANS")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundStyle(LMSColors.coral)
                        }

                        ForEach(highRiskApplicants) { applicant in
                            HStack(spacing: LMSSpacing.sm) {
                                Circle()
                                    .fill(applicant.riskLevel.themeColor)
                                    .frame(width: 8, height: 8)

                                Text(applicant.borrowerName)
                                    .font(.system(.caption, design: .rounded).bold())
                                    .foregroundStyle(LMSColors.textPrimary)

                                Spacer()

                                Text(applicant.applicationId)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundStyle(LMSColors.textTertiary)

                                Text(CurrencyFormatter.shared.format(applicant.requestedAmount))
                                    .font(.system(.caption2, design: .rounded).bold())
                                    .foregroundStyle(LMSColors.textSecondary)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .padding(LMSSpacing.md)
                    .background(LMSColors.coral.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                            .stroke(LMSColors.coral.opacity(0.15), lineWidth: 0.5)
                    )
                }
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)
        }
    }
}


private struct RiskGaugeCard: View {
    let title: String
    let value: String
    let progress: Double
    let tint: Color
    let subtitle: String
    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(LMSColors.textSecondary)

            HStack(spacing: LMSSpacing.sm) {

                ZStack {
                    Circle()
                        .stroke(tint.opacity(0.15), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: animatedProgress)
                        .stroke(tint, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 1) {
                    Text(value)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.textPrimary)
                        .monospacedDigit()
                    Text(subtitle)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundStyle(tint)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LMSSpacing.md)
        .background(LMSColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
        .onAppear {
            withAnimation(.easeOut(duration: 0.7).delay(0.15)) {
                animatedProgress = min(progress, 1.0)
            }
        }
    }
}

#Preview {
    ManagerRiskPanelView(viewModel: PreviewSupport.managerViewModel)
        .previewManagerEnvironment()
}

