import SwiftUI
import Charts

struct LoanOfficerDetailedAnalyticsSheet: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @Environment(\.dismiss) var dismiss


    private var statusData: [(status: String, count: Int, color: Color)] {
        let applications = viewModel.applications

        let approved = applications.filter { $0.status == .approved || $0.status == .disbursed }.count
        let rejected = applications.filter { $0.status == .rejected || $0.status == .documentsRejected }.count
        let underReview = applications.filter { $0.status == .underReview || $0.status == .sentToManager || $0.status == .finalApprovalPending || $0.status == .verificationCompleted }.count
        let pending = applications.filter { $0.status == .pending || $0.status == .applied || $0.status == .documentsPending }.count

        return [
            ("Approved", approved, AppTheme.successGreen),
            ("Under Review", underReview, AppTheme.actionBlue),
            ("Pending", pending, AppTheme.warningAmber),
            ("Rejected", rejected, AppTheme.criticalRed)
        ].filter { $0.1 > 0 }
    }

    private var loanTypeData: [(type: String, count: Int, color: Color)] {
        let types = OfficerLoanType.allCases
        var data: [(String, Int, Color)] = []
        for type in types {
            let count = viewModel.applications.filter { $0.loanType == type }.count
            if count > 0 {
                data.append((type.rawValue, count, type.themeColor))
            }
        }
        return data
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {


                    HStack(spacing: 16) {
                        metricCard(title: "Total Loans", value: "\(viewModel.totalApplications)", icon: "doc.on.doc.fill", color: AppTheme.brandNavy)
                        metricCard(title: "Total Value", value: CurrencyFormatter.shared.format(viewModel.totalPortfolioValue), icon: "indianrupeesign.circle.fill", color: AppTheme.actionBlue)
                    }
                    .padding(.horizontal)


                    VStack(alignment: .leading, spacing: 16) {
                        Text("Application Status Breakdown")
                            .font(.system(.title3, design: .rounded).bold())
                            .padding(.horizontal)

                        Chart {
                            ForEach(statusData, id: \.status) { item in
                                SectorMark(
                                    angle: .value("Count", item.count),
                                    innerRadius: .ratio(0.6),
                                    angularInset: 1.5
                                )
                                .foregroundStyle(item.color)
                                .annotation(position: .overlay) {
                                    Text("\(item.count)")
                                        .font(.system(.caption, design: .rounded).bold())
                                        .foregroundStyle(.white)
                                }
                            }
                        }
                        .frame(height: 220)


                        HStack {
                            ForEach(statusData, id: \.status) { item in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(item.color)
                                        .frame(width: 8, height: 8)
                                    Text(item.status)
                                        .font(.system(size: 10, design: .rounded))
                                        .foregroundStyle(LMSColors.textSecondary)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)


                    VStack(alignment: .leading, spacing: 16) {
                        Text("Loan Types Distribution")
                            .font(.system(.title3, design: .rounded).bold())
                            .padding(.horizontal)

                        Chart {
                            ForEach(loanTypeData, id: \.type) { item in
                                BarMark(
                                    x: .value("Count", item.count),
                                    y: .value("Type", item.type)
                                )
                                .foregroundStyle(item.color.gradient)
                                .cornerRadius(6)
                                .annotation(position: .trailing) {
                                    Text("\(item.count)")
                                        .font(.system(.caption, design: .rounded).bold())
                                        .foregroundStyle(LMSColors.textSecondary)
                                }
                            }
                        }
                        .frame(height: 200)
                        .chartXAxis(.hidden)
                        .padding(.trailing, 16)
                    }
                    .padding(.vertical)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                }
                .padding(.vertical)
            }
            .background(AppTheme.background)
            .navigationTitle("Detailed Analytics")
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

    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(title)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}


