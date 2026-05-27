import SwiftUI


struct ManagerApprovalQueueView: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    var onViewAll: () -> Void
    var onSelectApplicant: (ManagerApplicant) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {

            HStack {
                Text("Approval Queue")
                    .font(.system(.footnote, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textSecondary)

                Spacer()

                if !viewModel.pendingApplicants.isEmpty {
                    Button(action: {
                        HapticsManager.triggerImpact(style: .light)
                        onViewAll()
                    }) {
                        HStack(spacing: 4) {
                            Text("View All")
                                .font(.system(.footnote, design: .rounded).bold())
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(LMSColors.actionBlue)
                    }
                }
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)

            if viewModel.pendingApplicants.isEmpty {

                VStack(spacing: LMSSpacing.lg) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(LMSColors.emerald)

                    Text("No Pending Clearances")
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)

                    Text("All branch loan applications have been reviewed.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, LMSSpacing.xxxl)
                .background(LMSColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                .padding(.horizontal, LMSSpacing.screenHorizontal)
            } else {
                VStack(spacing: LMSSpacing.sm) {
                    ForEach(Array(viewModel.pendingApplicants.prefix(3))) { applicant in
                        Button(action: {
                            HapticsManager.triggerImpact(style: .medium)
                            onSelectApplicant(applicant)
                        }) {
                            ApprovalQueueCard(applicant: applicant)
                        }
                        .buttonStyle(LMSPressableStyle())
                    }
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)
            }
        }
    }
}


private struct ApprovalQueueCard: View {
    let applicant: ManagerApplicant

    var body: some View {
        HStack(spacing: LMSSpacing.md) {

            ZStack {
                RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                    .fill(applicant.status.themeColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: applicant.status.icon)
                    .foregroundStyle(applicant.status.themeColor)
                    .font(.system(size: 18, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(applicant.borrowerName)
                        .font(.system(.callout, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)

                    Spacer()

                    Text(CurrencyFormatter.shared.format(applicant.requestedAmount))
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundStyle(LMSColors.brandNavy)
                }

                HStack {
                    Text("\(applicant.loanType.rawValue) · CIBIL: \(applicant.cibilScore)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)

                    Spacer()


                    HStack(spacing: 3) {
                        Circle()
                            .fill(applicant.riskLevel.themeColor)
                            .frame(width: 5, height: 5)
                        Text(applicant.riskLevel.rawValue)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(applicant.riskLevel.themeColor)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(applicant.riskLevel.themeColor.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }

                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(LMSColors.textTertiary)
                    Text(applicant.assignedOfficer)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundStyle(LMSColors.textTertiary)

                    Spacer()

                    Text(applicant.status.displayName)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(applicant.status.themeColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(applicant.status.themeColor.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
        }
        .padding(LMSSpacing.md)
        .background(LMSColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    ManagerApprovalQueueView(
        viewModel: PreviewSupport.managerViewModel,
        onViewAll: {},
        onSelectApplicant: { _ in }
    )
    .padding()
    .previewManagerEnvironment()
}

