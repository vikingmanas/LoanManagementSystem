import SwiftUI

struct ActivityFeedRow: View {
    let item: ActivityFeedItem
    var onMarkRead: () -> Void
    var onDismiss: () -> Void
    var onActionTapped: (ActivityActionType) -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon + Unread Badge Stack
            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(item.eventType.themeColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: item.eventType.symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(item.eventType.themeColor)
                }
                
                if !item.isRead {
                    Circle()
                        .fill(AppTheme.actionBlue)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 1.5)
                        )
                        .offset(x: 2, y: -2)
                }
            }
            
            // Text Details Stack
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(item.borrowerName)
                        .font(.system(.callout, design: .rounded).bold())
                        .foregroundColor(.primary)
                    
                    Text("·")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text(item.loanType)
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundColor(.secondary)
                }
                
                Text(item.eventDescription)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                HStack(spacing: 6) {
                    Text(item.applicationId)
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundColor(Color(.placeholderText))
                    
                    Text("•")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(Color(.placeholderText))
                    
                    Text(RelativeDateFormatter.shared.relativeString(from: item.timestamp))
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(Color(.placeholderText))
                }
                .padding(.top, 2)
            }
            
            Spacer()
            
            // Optional CTA Button
            if item.requiresAction, let actionType = item.actionType {
                Button(action: {
                    HapticsManager.triggerImpact(style: .medium)
                    onActionTapped(actionType)
                }) {
                    Text(actionType.label)
                        .font(.system(.caption, design: .rounded).bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(actionType.color.opacity(0.15))
                        .foregroundColor(actionType.color)
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Action: \(actionType.label) for \(item.borrowerName)")
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(item.isRead ? Color.clear : AppTheme.actionBlue.opacity(0.04))
        .contentShape(Rectangle())
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if !item.isRead {
                Button {
                    onMarkRead()
                } label: {
                    Label("Mark Read", systemImage: "envelope.open.fill")
                }
                .tint(AppTheme.actionBlue)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDismiss()
            } label: {
                Label("Dismiss", systemImage: "xmark")
            }
            .tint(Color.gray)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.borrowerName), \(item.loanType). \(item.eventDescription) Application ID \(item.applicationId), \(RelativeDateFormatter.shared.relativeString(from: item.timestamp)). Status \(item.isRead ? "read" : "unread").")
    }
}
