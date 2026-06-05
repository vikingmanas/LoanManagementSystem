import SwiftUI

struct AdminApplicationDetailSheet: View {
    let app: DBLoanApplication
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: LMSSpacing.sectionGap) {
                    headerSection
                    
                    loanSection
                    
                    borrowerSection
                    
                    timelineSection
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)
                .padding(.vertical, LMSSpacing.lg)
            }
            .lmsScreenBackground()
            .navigationTitle("Application Detail")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .font(LMSFont.button)
                    .foregroundStyle(LMSColors.brandNavy)
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            Text(app.formData.fullName.components(separatedBy: " ").compactMap { $0.first }.map { String($0) }.joined().uppercased())
                .font(LMSFont.title)
                .foregroundStyle(.white)
                .frame(width: 68, height: 68)
                .background(LMSColors.brandNavy, in: Circle())
            
            Text(app.formData.fullName)
                .font(LMSFont.title3)
                .bold()
                .foregroundStyle(LMSColors.textPrimary)
            
            Text("APP-\(app.applicationId.uuidString.prefix(8).uppercased())")
                .font(LMSFont.caption)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(LMSColors.brandNavy)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(LMSColors.brandNavy.opacity(0.08), in: Capsule())
            
            LMSStatusPill(
                text: displayStatus(app.status),
                style: statusStyle(app.status),
                icon: statusIcon(app.status)
            )
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LMSSpacing.md)
    }
    
    private var loanSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Loan Information")
                .font(LMSFont.headline)
                .foregroundStyle(LMSColors.textPrimary)
            
            VStack(spacing: 0) {
                detailRow(title: "Amount Requested", value: formatCurrency(app.amountRequested), highlight: true)
                Divider().padding(.leading, 16)
                detailRow(title: "Tenure", value: "\(app.tenureMonths) Months")
                Divider().padding(.leading, 16)
                detailRow(title: "Purpose", value: app.purpose.capitalized)
                Divider().padding(.leading, 16)
                detailRow(title: "Repayment preference", value: app.formData.repaymentPreference)
            }
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
        }
    }
    
    private var borrowerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Borrower Profile")
                .font(LMSFont.headline)
                .foregroundStyle(LMSColors.textPrimary)
            
            VStack(spacing: 0) {
                detailRow(title: "Email Address", value: app.formData.emailAddress)
                Divider().padding(.leading, 16)
                detailRow(title: "Mobile Number", value: app.formData.mobileNumber)
                Divider().padding(.leading, 16)
                detailRow(title: "Address", value: app.formData.address)
                Divider().padding(.leading, 16)
                detailRow(title: "Employment Type", value: app.formData.employmentType)
                Divider().padding(.leading, 16)
                detailRow(title: "Employer Name", value: app.formData.employerName.isEmpty ? "N/A" : app.formData.employerName)
                Divider().padding(.leading, 16)
                detailRow(title: "Monthly Income", value: formatCurrency(Double(app.formData.monthlyIncome) ?? 0))
                Divider().padding(.leading, 16)
                
                HStack(spacing: 12) {
                    Text("CIBIL Score")
                        .font(LMSFont.body)
                        .foregroundStyle(LMSColors.textPrimary)
                    Spacer()
                    let score = app.formData.creditScoreValue
                    Text("\(score)")
                        .font(LMSFont.subheadline)
                        .bold()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(cibilColor(score), in: RoundedRectangle(cornerRadius: 6))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
        }
    }
    
    private var timelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Application Lifecycle Timeline")
                .font(LMSFont.headline)
                .foregroundStyle(LMSColors.textPrimary)
            
            if app.stageHistory.isEmpty {
                Text("No stage history recorded.")
                    .font(LMSFont.subheadline)
                    .foregroundStyle(LMSColors.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(0..<app.stageHistory.count, id: \.self) { idx in
                        let entry = app.stageHistory[idx]
                        let isLast = idx == app.stageHistory.count - 1
                        
                        HStack(alignment: .top, spacing: 12) {

                            VStack(spacing: 0) {
                                Circle()
                                    .fill(isLast ? LMSColors.emerald : LMSColors.brandNavy)
                                    .frame(width: 12, height: 12)
                                    .padding(.top, 4)
                                
                                if !isLast {
                                    Rectangle()
                                        .fill(LMSColors.separatorLight)
                                        .frame(width: 2)
                                        .frame(minHeight: 40)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.stage.rawValue)
                                    .font(LMSFont.subheadline.weight(.semibold))
                                    .foregroundStyle(LMSColors.textPrimary)
                                
                                Text(entry.timestamp.formatted(date: .numeric, time: .shortened))
                                    .font(LMSFont.caption2)
                                    .foregroundStyle(LMSColors.textTertiary)
                                
                                if !entry.note.isEmpty {
                                    Text(entry.note)
                                        .font(LMSFont.caption)
                                        .foregroundStyle(LMSColors.textSecondary)
                                        .padding(8)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .background(LMSColors.background, in: RoundedRectangle(cornerRadius: 6))
                                        .padding(.top, 2)
                                }
                            }
                            .padding(.bottom, isLast ? 0 : 16)
                        }
                    }
                }
                .padding(16)
                .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
            }
        }
    }
    
    private func detailRow(title: String, value: String, highlight: Bool = false) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(title)
                .font(LMSFont.body)
                .foregroundStyle(LMSColors.textSecondary)
            Spacer()
            Text(value)
                .font(LMSFont.body)
                .fontWeight(highlight ? .bold : .regular)
                .foregroundStyle(highlight ? LMSColors.brandNavy : LMSColors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "₹\(Int(value))"
    }
    
    private func cibilColor(_ score: Int) -> Color {
        if score >= 750 {
            return LMSColors.emerald
        } else if score >= CentralLoanRepository.shared.globalRules.minCibilScore {
            return LMSColors.amber
        } else {
            return LMSColors.coral
        }
    }
}
