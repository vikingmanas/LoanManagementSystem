import SwiftUI

struct LoanHistoryRow: View {
    let app: LoanApplication
    var onView: () -> Void
    var onCall: () -> Void
    var onFlag: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Left: Loan Type icon circle (44x44)
            ZStack {
                Circle()
                    .fill(app.loanType.themeColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: app.loanType.symbol)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(app.loanType.themeColor)
            }
            
            // Center Details
            VStack(alignment: .leading, spacing: 4) {
                Text(app.borrowerName)
                    .font(.system(.callout, design: .rounded).bold())
                    .foregroundColor(.primary)
                
                Text("\(app.loanType.rawValue) · \(CurrencyFormatter.shared.format(app.requestedAmount))")
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundColor(.secondary)
                
                Text("\(app.applicationId) · Branch: \(app.branch)")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(Color(.placeholderText))
            }
            
            Spacer()
            
            // Right: Status badge & date
            VStack(alignment: .trailing, spacing: 6) {
                Text(app.status.displayName)
                    .font(.system(.caption2, design: .rounded).bold())
                    .foregroundColor(app.status == .pending ? AppTheme.warningAmber : .white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(app.status == .pending ? AppTheme.warningAmber.opacity(0.15) : app.status.themeColor)
                    .cornerRadius(8)
                
                Text(RelativeDateFormatter.shared.absoluteString(from: app.submittedDate))
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(Color(.placeholderText))
                
                Text(CurrencyFormatter.shared.format(app.requestedAmount))
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundColor(app.loanType.themeColor)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            onView()
        }
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(app.borrowerName), applied for a \(app.loanType.rawValue) of \(CurrencyFormatter.shared.format(app.requestedAmount)) on \(RelativeDateFormatter.shared.absoluteString(from: app.submittedDate)). Status is \(app.status.rawValue). Branch is \(app.branch).")
    }
}
