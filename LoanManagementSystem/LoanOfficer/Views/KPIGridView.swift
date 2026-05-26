import SwiftUI

struct KPIGridView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onCardSelected: (RegistryFilter?) -> Void
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: LMSSpacing.md), GridItem(.flexible(), spacing: LMSSpacing.md)], spacing: LMSSpacing.md) {
            
            // Card A1: Total Applications
            KPICard(
                symbol: "doc.text.fill",
                symbolColor: LMSColors.actionBlue,
                value: "\(viewModel.totalApplications)",
                label: "All Records",
                sub: "Historical database",
                bottomContent: AnyView(
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(LMSColors.actionBlue)
                        Text("View all activity")
                            .font(.system(.caption2, design: .rounded).bold())
                            .foregroundStyle(LMSColors.actionBlue)
                    }
                ),
                accessibilityLabel: "Total Records: \(viewModel.totalApplications)."
            )
            .onTapGesture {
                HapticsManager.triggerImpact(style: .light)
                onCardSelected(.all)
            }
            
            // Card A2: New Cases
            KPICard(
                symbol: "sparkles",
                symbolColor: LMSColors.amber,
                value: "\(viewModel.pendingCount)",
                label: "New Cases",
                sub: "Pending initial review",
                bottomContent: AnyView(
                    Text("Action required")
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundStyle(LMSColors.amber)
                ),
                accessibilityLabel: "New Cases: \(viewModel.pendingCount)."
            )
            .onTapGesture {
                HapticsManager.triggerImpact(style: .light)
                onCardSelected(.newCases)
            }
            
            // Card A3: Approval Queue
            KPICard(
                symbol: "person.badge.shield.checkmark",
                symbolColor: LMSColors.brandNavy,
                value: "\(viewModel.sentToManagerApps.count)",
                label: "Approval Queue",
                sub: "Sent to Manager",
                bottomContent: AnyView(
                    Text("Awaiting sign-off")
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundStyle(LMSColors.brandNavy)
                ),
                accessibilityLabel: "Approval Queue: \(viewModel.sentToManagerApps.count)."
            )
            .onTapGesture {
                HapticsManager.triggerImpact(style: .light)
                onCardSelected(.approvalQueue)
            }
            
            // Card A4: Completed
            KPICard(
                symbol: "checkmark.seal.fill",
                symbolColor: LMSColors.emerald,
                value: "\(viewModel.closedThisMonthCount)",
                label: "Completed",
                sub: "Closed cases",
                bottomContent: AnyView(
                    Text("Disbursed/Declined")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                ),
                accessibilityLabel: "Completed Cases: \(viewModel.closedThisMonthCount)."
            )
            .onTapGesture {
                HapticsManager.triggerImpact(style: .light)
                onCardSelected(.completed)
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
                    .foregroundStyle(symbolColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(.placeholderText))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(.title, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)
                
                Text(label)
                    .font(.system(.callout, design: .rounded).weight(.semibold))
                    .foregroundStyle(LMSColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(sub)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
            }
            
            Spacer(minLength: 4)
            
            Divider()
                .padding(.vertical, 2)
            
            bottomContent
        }
        .padding(LMSSpacing.lg)
        .frame(minHeight: 125)
        .background(LMSColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 3)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Tap to view details in the history tab.")
    }
}
