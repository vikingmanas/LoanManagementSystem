import SwiftUI

struct PortfolioMetricsSheet: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Header card breakdown
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Portfolio Distribution")
                            .font(.system(.title3, design: .rounded).bold())
                            .foregroundColor(.primary)
                        
                        Text("Overall status distribution of your assigned borrower loan applications.")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    // 2x2 KPI Grid View
                    KPIGridView(viewModel: viewModel) { selectedStatus in
                        // Trigger haptics, set filter, route to Tab 4 (Registry) and dismiss sheet
                        HapticsManager.triggerImpact(style: .medium)
                        viewModel.historyFilter = selectedStatus
                        viewModel.selectedTab = 3 // Route to Tab 4 (Registry)
                        dismiss()
                    }
                    .padding(.horizontal, 16)
                    
                    // Extra descriptive details to feel premium
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Active Action Guidelines")
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundColor(.primary)
                        
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(AppTheme.warningAmber)
                            Text("Pending Review items require KYC verification and document checks before forwarding to the manager.")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundColor(AppTheme.successGreen)
                            Text("Approved items are cleared and sent to management for final disbursement approval.")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(16)
                    .background(AppTheme.neutralSurface)
                    .cornerRadius(16)
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
