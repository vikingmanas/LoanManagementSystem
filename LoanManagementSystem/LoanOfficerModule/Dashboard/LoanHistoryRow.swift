import SwiftUI

struct LoanHistoryRow: View {
    typealias LoanApplication = OfficerLoanApplication
    let app: LoanApplication
    var onView: () -> Void
    var onCall: () -> Void
    var onFlag: () -> Void
    
    var body: some View {
        Button(action: onView) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    borrowerAvatar

                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 6) {
                            Image(systemName: app.loanType.symbol)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(app.loanType.themeColor)

                            Text(app.loanType.rawValue)
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(app.loanType.themeColor)
                                .lineLimit(1)
                        }

                        Text(app.borrowerName)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)

                        Text(app.applicationId)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(.secondary.opacity(0.75))
                    }

                    Spacer(minLength: 10)

                    VStack(alignment: .trailing, spacing: 7) {
                        Text(CurrencyFormatter.shared.format(app.requestedAmount))
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        statusBadge
                    }
                }

                Divider()
                    .opacity(0.45)

                HStack(spacing: 10) {
                    detailPill(icon: "mappin.and.ellipse", title: "Branch", value: app.branch)
                    detailPill(icon: "calendar", title: "Submitted", value: Self.shortDateFormatter.string(from: app.submittedDate))
                }

                HStack(spacing: 10) {
                    detailPill(icon: "doc.text.fill", title: "Docs", value: "\(verifiedDocumentCount)/\(app.documents.count) verified")

                    if let cibilScore = app.cibilScore {
                        detailPill(icon: "gauge.with.dots.needle.67percent", title: "CIBIL", value: "\(cibilScore)")
                    } else {
                        detailPill(icon: "gauge.with.dots.needle.67percent", title: "CIBIL", value: "Pending")
                    }
                }
            }
            .padding(16)
            .background(AppTheme.neutralSurface)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            // View Action
            Button {
                HapticsManager.triggerImpact(style: .light)
                onView()
            } label: {
                Label("View", systemImage: "eye.fill")
            }
            .tint(AppTheme.actionBlue)
            
            // Call Action
            Button {
                HapticsManager.triggerImpact(style: .light)
                onCall()
            } label: {
                Label("Call", systemImage: "phone.fill")
            }
            .tint(AppTheme.successGreen)
            
            // Flag Action
            Button {
                HapticsManager.triggerImpact(style: .light)
                onFlag()
            } label: {
                Label("Flag", systemImage: "flag.fill")
            }
            .tint(AppTheme.criticalRed)
        }
    }
    
    private var verifiedDocumentCount: Int {
        app.documents.filter { $0.status == .verified }.count
    }

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    // Grayscale Initials Avatar
    private var borrowerAvatar: some View {
        let initials = app.borrowerName.components(separatedBy: " ")
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
            .prefix(2)
        
        return ZStack {
            Circle()
                .fill(app.loanType.themeColor.opacity(0.13))
                .frame(width: 48, height: 48)
                .overlay(
                    Circle()
                        .stroke(app.loanType.themeColor.opacity(0.18), lineWidth: 1)
                )
            
            Text(initials.uppercased())
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(app.loanType.themeColor)
        }
    }

    private func detailPill(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
                .frame(width: 14)

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary.opacity(0.75))
                    .textCase(.uppercase)

                Text(value)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color(.systemBackground).opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    // Simplified status badge colors and tags matching specs
    private var statusDetails: (text: String, color: Color) {
        switch app.status {
        case .pending, .applied, .documentsPending:
            return ("Pending", .orange)
        case .underReview:
            return ("Under Review", .blue)
        case .sentToManager, .finalApprovalPending, .verificationCompleted:
            return ("In Review", .purple)
        case .approved, .disbursed:
            return ("Approved", .green)
        case .rejected, .documentsRejected:
            return ("Rejected", .red)
        default:
            return ("On Hold", .gray)
        }
    }
    
    private var statusBadge: some View {
        let details = statusDetails
        return Text(details.text)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(details.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(details.color.opacity(0.12))
            .cornerRadius(6)
    }
}
