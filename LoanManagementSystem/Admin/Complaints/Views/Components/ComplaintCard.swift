import SwiftUI

struct ComplaintCard: View {
    let ticket: ComplaintTicket
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Row 1: Category Icon + ID/Title + Priority Badge
            HStack(alignment: .top) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous)
                            .fill(ticket.priority.color.opacity(0.12))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: ticket.category.iconName)
                            .font(.system(size: 20))
                            .foregroundStyle(ticket.priority.color)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(ticket.ticketId)
                                .font(LMSFont.caption.weight(.semibold))
                                .foregroundStyle(LMSColors.textSecondary)
                            
                            // Origin pill
                            Text(ticket.origin.rawValue)
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(ticket.origin.tint)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(ticket.origin.tint.opacity(0.1), in: Capsule())
                        }
                        
                        Text(ticket.title)
                            .font(LMSFont.subheadline.weight(.semibold))
                            .foregroundStyle(LMSColors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
                
                Spacer()
                
                Text(ticket.priority.rawValue.uppercased())
                    .font(LMSFont.caption2.weight(.bold))
                    .foregroundStyle(ticket.priority.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(ticket.priority.color.opacity(0.12), in: Capsule())
            }
            
            // Row 2: Metadata (borrower/branch/manager/team)
            HStack(spacing: 16) {
                if let borrower = ticket.borrowerName {
                    metaLabel(icon: "person.fill", text: borrower)
                }
                
                metaLabel(icon: "building.2.fill", text: ticket.branchName)
            }
            
            HStack(spacing: 16) {
                if let manager = ticket.assignedManager {
                    metaLabel(icon: "person.badge.shield.checkmark.fill", text: manager)
                }
                if let team = ticket.assignedTeam {
                    metaLabel(icon: "person.3.fill", text: team)
                }
            }
            
            Divider().background(LMSColors.separatorLight)
            
            // Row 3: Category + Time + Status
            HStack {
                Text(ticket.category.rawValue)
                    .font(LMSFont.caption2)
                    .foregroundStyle(LMSColors.textTertiary)
                
                Spacer()
                
                Text(ticket.dateRaised, style: .relative)
                    .font(LMSFont.caption2)
                    .foregroundStyle(LMSColors.textTertiary)
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(ticket.status.color)
                        .frame(width: 6, height: 6)
                    Text(ticket.status.rawValue)
                        .font(LMSFont.caption.weight(.medium))
                        .foregroundStyle(ticket.status.color)
                }
            }
        }
        .padding(16)
        .lmsCard(radius: LMSRadius.lg)
    }
    
    private func metaLabel(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(LMSColors.textTertiary)
            Text(text)
                .font(LMSFont.caption)
                .foregroundStyle(LMSColors.textSecondary)
                .lineLimit(1)
        }
    }
}

#Preview {
    ZStack {
        LMSColors.background.ignoresSafeArea()
        VStack(spacing: 16) {
            ComplaintCard(ticket: ComplaintTicket(
                id: UUID(), ticketId: "CMP-9082", title: "Excess EMI Deduction",
                origin: .complaint, category: .financialDiscrepancy, branchName: "Mumbai Central",
                dateRaised: Date(), status: .open, priority: .high,
                description: "", borrowerName: "Arjun Mehta",
                assignedManager: "Suresh Pillai", timeline: []
            ))
            ComplaintCard(ticket: ComplaintTicket(
                id: UUID(), ticketId: "ISS-4001", title: "Core Banking Server Unresponsive",
                origin: .operationalIssue, category: .serverDowntime, branchName: "Mumbai Central",
                dateRaised: Date(), status: .escalated, priority: .critical,
                description: "", borrowerName: nil,
                assignedManager: "Suresh Pillai", assignedTeam: "Infra Ops L2", timeline: []
            ))
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
