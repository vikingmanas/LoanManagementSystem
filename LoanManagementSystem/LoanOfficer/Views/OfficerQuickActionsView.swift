import SwiftUI

struct OfficerQuickActionsView: View {
    let onVerifyDocs: () -> Void
    let onReports: () -> Void
    let onEscalate: () -> Void
    
    var body: some View {
        SectionContainer(
            title: "Quick Actions",
            subtitle: "Manage documents, reports, and escalations"
        ) {
            HStack(spacing: 0) {
                OfficerQuickActionButton(
                    title: "Verify Docs",
                    icon: "doc.text.magnifyingglass",
                    tint: LMSColors.actionBlue,
                    action: onVerifyDocs
                )
                
                OfficerQuickActionButton(
                    title: "Reports",
                    icon: "chart.bar.fill",
                    tint: Color.purple,
                    action: onReports
                )
                
                OfficerQuickActionButton(
                    title: "Escalate",
                    icon: "arrow.up.circle.fill",
                    tint: LMSColors.coral,
                    action: onEscalate
                )
            }
            .padding(.vertical, LMSSpacing.lg)
            .padding(.horizontal, LMSSpacing.md)
            .lmsCard(radius: LMSRadius.xl)
        }
    }
}

struct OfficerQuickActionButton: View {
    let title: String
    let icon: String
    let tint: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            HapticsManager.triggerImpact(style: .medium)
            action()
        }) {
            VStack(spacing: LMSSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                        .fill(tint.opacity(0.12))
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(tint)
                        .symbolRenderingMode(.hierarchical)
                }
                
                Text(title)
                    .font(LMSFont.caption2.weight(.medium))
                    .foregroundStyle(LMSColors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(LMSPressableStyle())
    }
}
