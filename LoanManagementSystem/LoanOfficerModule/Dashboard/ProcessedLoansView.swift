import SwiftUI

struct ProcessedLoansView: View {
    typealias LoanApplication = OfficerLoanApplication
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onRespondTapped: (LoanApplication) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Row
            HStack {
                HStack(spacing: 8) {
                    Text("Sent to Manager")
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundColor(.primary)
                    
                    Text("This Week")
                        .font(.system(.caption2, design: .rounded).bold())
                        .foregroundColor(AppTheme.actionBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.actionBlue.opacity(0.12))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(.horizontal, 16)
            
            // Processed List Card
            VStack(spacing: 0) {
                let items = viewModel.sentToManagerApps
                if items.isEmpty {
                    ContentUnavailableView(
                        "No Applications Sent",
                        systemImage: "paperplane.fill",
                        description: Text("Forward verified loans to the manager for disbursement approval.")
                    )
                    .frame(height: 140)
                } else {
                    ForEach(items) { app in
                        ProcessedLoanRow(app: app) {
                            onRespondTapped(app)
                        }
                        
                        if app.id != items.last?.id {
                            Divider()
                                .padding(.leading, 64)
                        }
                    }
                }
            }
            .background(AppTheme.neutralSurface)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 3)
        }
    }
}

struct ProcessedLoanRow: View {
    typealias LoanApplication = OfficerLoanApplication
    let app: LoanApplication
    var onRespond: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Left: Loan Type icon circle
            ZStack {
                Circle()
                    .fill(app.loanType.themeColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                
                Image(systemName: app.loanType.symbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(app.loanType.themeColor)
            }
            
            // Center Details
            VStack(alignment: .leading, spacing: 3) {
                Text("\(app.borrowerName) · \(app.loanType.rawValue)")
                    .font(.system(.callout, design: .rounded).bold())
                    .foregroundColor(.primary)
                
                Text("\(app.applicationId) · \(CurrencyFormatter.shared.format(app.requestedAmount))")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                
                if let sentDate = app.sentToManagerDate {
                    Text("Sent on \(RelativeDateFormatter.shared.absoluteString(from: sentDate))")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(Color(.placeholderText))
                }
            }
            
            Spacer()
            
            // Right: Manager Status Badge
            if let status = app.managerStatus {
                VStack(alignment: .trailing, spacing: 6) {
                    Text(status.rawValue)
                        .font(.system(.caption2, design: .rounded).bold())
                        .foregroundColor(status == .underReview ? AppTheme.warningAmber : .white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(status == .underReview ? AppTheme.warningAmber.opacity(0.15) : status.themeColor)
                        .cornerRadius(8)
                    
                    if status == .needsClarification {
                        Button(action: {
                            HapticsManager.triggerImpact(style: .medium)
                            onRespond()
                        }) {
                            Text("Respond")
                                .font(.system(.caption2, design: .rounded).bold())
                                .foregroundColor(AppTheme.criticalRed)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(AppTheme.criticalRed.opacity(0.12))
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Respond to manager query for \(app.borrowerName)")
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(app.borrowerName), \(app.loanType.rawValue) for \(CurrencyFormatter.shared.format(app.requestedAmount)). Manager status is \(app.managerStatus?.rawValue ?? "unknown").")
    }
}
