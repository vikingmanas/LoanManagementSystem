import SwiftUI

struct ApplicantCard: View {
    let applicant: LoanApplicantModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header: Name + Badge
            HStack(alignment: .top) {
                HStack(spacing: 12) {
                    // Avatar Placeholder
                    ZStack {
                        Circle()
                            .fill(LMSColors.brandNavy.opacity(0.12))
                            .frame(width: 44, height: 44)
                        
                        Text(String(applicant.applicantName.prefix(1)))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(LMSColors.brandNavy)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(applicant.loanId)
                            .font(LMSFont.caption.weight(.semibold))
                            .foregroundStyle(LMSColors.textSecondary)
                        
                        Text(applicant.applicantName)
                            .font(LMSFont.subheadline.weight(.semibold))
                            .foregroundStyle(LMSColors.textPrimary)
                    }
                }
                
                Spacer()
                
                // Status Badge
                Text(applicant.status.rawValue.uppercased())
                    .font(LMSFont.caption2.weight(.bold))
                    .foregroundStyle(applicant.status.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(applicant.status.color.opacity(0.12), in: Capsule())
            }
            
            // Financials Row
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Requested")
                        .font(LMSFont.caption2)
                        .foregroundStyle(LMSColors.textTertiary)
                    Text(formatCurrency(applicant.requestedAmount))
                        .font(LMSFont.subheadline.weight(.bold))
                        .foregroundStyle(LMSColors.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("CIBIL Score")
                        .font(LMSFont.caption2)
                        .foregroundStyle(LMSColors.textTertiary)
                    Text("\(applicant.cibilScore)")
                        .font(LMSFont.subheadline.weight(.bold))
                        .foregroundStyle(scoreColor(applicant.cibilScore))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Loan Type")
                        .font(LMSFont.caption2)
                        .foregroundStyle(LMSColors.textTertiary)
                    Text(applicant.loanType.rawValue)
                        .font(LMSFont.subheadline.weight(.medium))
                        .foregroundStyle(LMSColors.textSecondary)
                }
            }
            
            Divider().background(LMSColors.separatorLight)
            
            // Footer: Recommendation & Date
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                    Text(applicant.recommendation.rawValue)
                        .font(LMSFont.caption.weight(.medium))
                }
                .foregroundStyle(applicant.recommendation.color)
                
                Spacer()
                
                Text(applicant.applicationDate, style: .relative)
                    .font(LMSFont.caption2)
                    .foregroundStyle(LMSColors.textTertiary)
            }
        }
        .padding(16)
        .lmsCard(radius: LMSRadius.lg)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₹\(Int(amount))"
    }
    
    private func scoreColor(_ score: Int) -> Color {
        if score >= 750 { return LMSColors.emerald }
        if score >= 650 { return LMSColors.amber }
        return LMSColors.coral
    }
}

#Preview {
    ZStack {
        LMSColors.background.ignoresSafeArea()
        ApplicantCard(applicant: LoanReviewViewModel().applicants[0])
            .padding()
    }
    .preferredColorScheme(.dark)
}
