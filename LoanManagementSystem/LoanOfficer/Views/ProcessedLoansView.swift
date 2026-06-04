import SwiftUI

struct ProcessedLoansView: View {
    typealias LoanApplication = OfficerLoanApplication
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onRespondTapped: (LoanApplication) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                HStack(spacing: 8) {
                    Text("Manager Desk")
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)

                    Text("This Week")
                        .font(.system(.caption2, design: .rounded).bold())
                        .foregroundStyle(LMSColors.actionBlue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(LMSColors.actionBlue.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Spacer()
            }
            .padding(.horizontal, 16)


            VStack(spacing: 0) {
                let items = viewModel.pendingManagerActionApps
                if items.isEmpty {
                    ContentUnavailableView(
                        "No Manager Desk Items",
                        systemImage: "briefcase.fill",
                        description: Text("No applications are waiting for manager action.")
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
            .background(LMSColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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

            ZStack {
                Circle()
                    .fill(app.loanType.themeColor.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: app.loanType.symbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(app.loanType.themeColor)
            }


            VStack(alignment: .leading, spacing: 3) {
                Text("\(app.borrowerName) · \(app.loanType.rawValue)")
                    .font(.system(.callout, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)

                Text("\(app.applicationId) · \(CurrencyFormatter.shared.format(app.requestedAmount))")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)

                if let sentDate = app.sentToManagerDate {
                    Text("Sent on \(RelativeDateFormatter.shared.absoluteString(from: sentDate))")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(Color(.placeholderText))
                }
            }

            Spacer()


            if let status = app.managerStatus {
                VStack(alignment: .trailing, spacing: 6) {
                    Text(status.rawValue)
                        .font(.system(.caption2, design: .rounded).bold())
                        .foregroundStyle(status == .underReview ? LMSColors.amber : .white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(status == .underReview ? LMSColors.amber.opacity(0.15) : status.themeColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    if status == .needsClarification {
                        Button(action: {
                            HapticsManager.triggerImpact(style: .medium)
                            onRespond()
                        }) {
                            Text("Respond")
                                .font(.system(.caption2, design: .rounded).bold())
                                .foregroundStyle(LMSColors.coral)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(LMSColors.coral.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Respond to manager query for \(app.borrowerName)")
                    }

                    if status == .sentBack {
                        Button(action: {
                            HapticsManager.triggerImpact(style: .medium)
                            onRespond()
                        }) {
                            Text("Re-review")
                                .font(.system(.caption2, design: .rounded).bold())
                                .foregroundStyle(LMSColors.amber)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(LMSColors.amber.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Re-review application for \(app.borrowerName)")
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
