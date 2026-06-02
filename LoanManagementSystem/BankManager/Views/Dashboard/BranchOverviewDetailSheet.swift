import SwiftUI

struct BranchOverviewDetailSheet: View {
    let overview: BranchOverview
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: LMSSpacing.xl) {
                    
                    // Header Status
                    VStack(spacing: LMSSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(LMSColors.brandNavy.opacity(0.1))
                                .frame(width: 80, height: 80)
                            Image(systemName: "building.columns.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(LMSColors.brandNavy)
                        }
                        
                        VStack(spacing: 4) {
                            Text("\(overview.name) (\(overview.code))")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(LMSColors.textPrimary)
                            Text(overview.region)
                                .font(.subheadline)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, LMSSpacing.xl)

                    // Audit Status
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Latest Audit Rating")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(LMSColors.textSecondary)
                            Text(overview.auditRating)
                                .font(.headline.weight(.bold))
                                .foregroundStyle(auditColor(overview.auditRating))
                        }
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .font(.title2)
                            .foregroundStyle(auditColor(overview.auditRating))
                    }
                    .padding()
                    .background(LMSColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                    .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
                    .padding(.horizontal, LMSSpacing.screenHorizontal)

                    // Detailed Metrics
                    VStack(alignment: .leading, spacing: LMSSpacing.md) {
                        Text("Performance Breakdown")
                            .font(.system(.footnote, design: .rounded).bold())
                            .foregroundStyle(LMSColors.textSecondary)
                            .padding(.horizontal, LMSSpacing.screenHorizontal)

                        VStack(spacing: 0) {
                            metricRow(title: "Monthly Target", value: CurrencyFormatter.shared.format(overview.monthlyTarget))
                            Divider().padding(.leading, LMSSpacing.lg)
                            metricRow(title: "Total Disbursed", value: CurrencyFormatter.shared.format(overview.totalDisbursed))
                            Divider().padding(.leading, LMSSpacing.lg)
                            metricRow(title: "Estimated Recovered", value: CurrencyFormatter.shared.format(overview.totalRecovered))
                            Divider().padding(.leading, LMSSpacing.lg)
                            metricRow(title: "Non-Performing Loan Rate", value: String(format: "%.2f%%", overview.nplRate))
                            Divider().padding(.leading, LMSSpacing.lg)
                            metricRow(title: "Active Loan Count", value: "\(overview.activeLoanCount)")
                            Divider().padding(.leading, LMSSpacing.lg)
                            metricRow(title: "Staff Count", value: "\(overview.staffCount)")
                        }
                        .background(LMSColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                        .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
                        .padding(.horizontal, LMSSpacing.screenHorizontal)
                    }
                }
                .padding(.bottom, LMSSpacing.xxxl)
            }
            .background(LMSColors.background)
            .navigationTitle("Branch Overview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    private func metricRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(LMSColors.textPrimary)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded).bold())
                .foregroundStyle(LMSColors.textSecondary)
        }
        .padding(.vertical, LMSSpacing.md)
        .padding(.horizontal, LMSSpacing.lg)
    }

    private func auditColor(_ rating: String) -> Color {
        switch rating.lowercased() {
        case "a", "excellent": return LMSColors.emerald
        case "b", "good": return LMSColors.teal
        case "c", "satisfactory": return LMSColors.amber
        default: return LMSColors.coral
        }
    }
}
