import SwiftUI

struct PortfolioMetricsSheet: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {


                    VStack(alignment: .leading, spacing: 6) {
                        Text("Portfolio Distribution")
                            .font(.system(.title3, design: .rounded).bold())
                            .foregroundStyle(LMSColors.textPrimary)

                        Text("Overall status distribution of your assigned borrower loan applications.")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)


                    KPIGridView(viewModel: viewModel) { selectedStatus in

                        HapticsManager.triggerImpact(style: .medium)
                        viewModel.historyFilter = selectedStatus
                        viewModel.selectedTab = 3
                        dismiss()
                    }
                    .padding(.horizontal, 16)


                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Action Guidelines")
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundStyle(LMSColors.textPrimary)

                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(AppTheme.warningAmber)
                            Text("Pending Review items require KYC verification and document checks before forwarding to the manager.")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(LMSColors.textSecondary)
                        }

                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(AppTheme.successGreen)
                            Text("Approved items are cleared and sent to management for final disbursement approval.")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                    }
                    .padding(16)
                    .background(AppTheme.neutralSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("Portfolio Performance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    PortfolioMetricsSheet(viewModel: PreviewSupport.loanOfficerViewModel)
}

