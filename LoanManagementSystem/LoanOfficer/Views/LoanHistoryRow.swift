import SwiftUI

struct LoanHistoryRow: View {
    typealias LoanApplication = OfficerLoanApplication
    let app: LoanApplication
    var onView: () -> Void
    var onCall: () -> Void
    var onFlag: () -> Void
    
    var body: some View {
        Button(action: onView) {
            HStack(spacing: 16) {

                borrowerAvatar
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(app.borrowerName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("\(app.loanType.rawValue) Loan · \(app.branch)")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text(app.applicationId)
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    Text(CurrencyFormatter.shared.format(app.requestedAmount))
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    statusBadge
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {

            Button {
                HapticsManager.triggerImpact(style: .light)
                onView()
            } label: {
                Label("View", systemImage: "eye.fill")
            }
            .tint(LMSColors.actionBlue)
            
            Button {
                HapticsManager.triggerImpact(style: .light)
                onCall()
            } label: {
                Label("Call", systemImage: "phone.fill")
            }
            .tint(LMSColors.emerald)
            
            Button {
                HapticsManager.triggerImpact(style: .light)
                onFlag()
            } label: {
                Label("Flag", systemImage: "flag.fill")
            }
            .tint(LMSColors.coral)
        }
    }
    
    private var borrowerAvatar: some View {
        let initials = app.borrowerName.components(separatedBy: " ")
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
            .prefix(2)
        
        return ZStack {
            Circle()
                .fill(Color(.secondarySystemBackground))
                .frame(width: 44, height: 44)
                .overlay(
                    Circle()
                        .stroke(Color.primary.opacity(0.04), lineWidth: 1)
                )
            
            Text(initials.uppercased())
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(.secondary)
        }
    }
    
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
