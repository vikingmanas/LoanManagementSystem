import SwiftUI

struct KPIGridView: View {
    typealias ApplicationStatus = OfficerApplicationStatus
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onCardSelected: (ApplicationStatus?) -> Void
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            
            // Card A1: Total Applications
            KPICard(
                symbol: "doc.text.fill",
                symbolColor: AppTheme.actionBlue,
                value: "\(viewModel.totalApplications)",
                label: "Total Applications",
                sub: "This Month",
                bottomContent: AnyView(
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppTheme.successGreen)
                        Text("+12%")
                            .font(.system(.caption2, design: .rounded).bold())
                            .foregroundColor(AppTheme.successGreen)
                        Text("vs last month")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(LMSColors.textSecondary)
                    }
                ),
                accessibilityLabel: "Total Applications: \(viewModel.totalApplications). Twelve percent increase since last month."
            )
            .onTapGesture {
                HapticsManager.triggerImpact(style: .light)
                onCardSelected(nil) // Shows all history
            }
            
            // Card A2: Pending Review
            KPICard(
                symbol: "hourglass.circle.fill",
                symbolColor: AppTheme.warningAmber,
                value: "\(viewModel.pendingCount)",
                label: "Pending Review",
                sub: "Awaiting your action",
                bottomContent: AnyView(
                    Text("Oldest: 3 days ago")
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundColor(AppTheme.criticalRed)
                ),
                accessibilityLabel: "Pending Review: \(viewModel.pendingCount). Awaiting action. Oldest submitted three days ago."
            )
            .onTapGesture {
                HapticsManager.triggerImpact(style: .light)
                onCardSelected(.pending) // Filter history to Pending
            }
            
            // Card A3: Approved
            KPICard(
                symbol: "checkmark.circle.fill",
                symbolColor: AppTheme.successGreen,
                value: "\(viewModel.approvedCount)",
                label: "Approved",
                sub: "Sent to Manager",
                bottomContent: AnyView(
                    Text("₹ 4.2 Cr disbursed")
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundColor(AppTheme.successGreen)
                ),
                accessibilityLabel: "Approved Applications: \(viewModel.approvedCount). Sent to Manager. Four point two Crore Rupees disbursed."
            )
            .onTapGesture {
                HapticsManager.triggerImpact(style: .light)
                onCardSelected(.approved) // Filter history to Approved
            }
            
            // Card A4: Rejected / On Hold
            KPICard(
                symbol: "xmark.circle.fill",
                symbolColor: AppTheme.criticalRed,
                value: "\(viewModel.rejectedOrHoldCount)",
                label: "Rejected / On Hold",
                sub: "Requires re-evaluation",
                bottomContent: AnyView(
                    Text("6 rejected · 5 on hold")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(LMSColors.textSecondary)
                ),
                accessibilityLabel: "Rejected or On Hold: \(viewModel.rejectedOrHoldCount). Requires re-evaluation."
            )
            .onTapGesture {
                HapticsManager.triggerImpact(style: .light)
                onCardSelected(.onHold) // Filter history to On Hold
            }
        }
    }
}

struct KPICard: View {
    let symbol: String
    let symbolColor: Color
    let value: String
    let label: String
    let sub: String
    let bottomContent: AnyView
    let accessibilityLabel: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: symbol)
                    .font(.system(size: 22))
                    .foregroundColor(symbolColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(.placeholderText))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.title, design: .rounded).bold())
                    .foregroundColor(LMSColors.textPrimary)
                
                Text(label)
                    .font(.system(.callout, design: .rounded).weight(.semibold))
                    .foregroundColor(LMSColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(sub)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(LMSColors.textSecondary)
            }
            
            Spacer(minLength: 4)
            
            Divider()
                .padding(.vertical, 2)
            
            bottomContent
        }
        .padding(16)
        .frame(minHeight: 125)
        .background(AppTheme.neutralSurface)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 3)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tap to view details in the history tab.")
    }
}
