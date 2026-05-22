import SwiftUI

struct ActivityFeedRow: View {
    let item: ActivityFeedItem
    var onMarkRead: () -> Void
    var onDismiss: () -> Void
    var onActionTapped: (ActivityActionType) -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            // Native Unread Dot (Blue)
            Circle()
                .fill(item.isRead ? Color.clear : .blue)
                .frame(width: 10, height: 10)
            
            // Native Avatar
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 50, height: 50)
                Text(String(item.borrowerName.prefix(2)).uppercased())
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(.darkGray))
            }
            
            // Text Details Stack
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(item.borrowerName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text(RelativeDateFormatter.shared.relativeString(from: item.timestamp))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(Color(.tertiaryLabel))
                    }
                }
                
                HStack(alignment: .top) {
                    Text(item.eventDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                // Mock Pin Action
                HapticsManager.triggerImpact(style: .light)
            } label: {
                Label("Pin", systemImage: "pin")
            }
            
            Button {
                HapticsManager.triggerImpact(style: .light)
                if !item.isRead {
                    onMarkRead()
                }
            } label: {
                Label(item.isRead ? "Mark as Unread" : "Mark as Read", systemImage: item.isRead ? "message.badge.fill" : "envelope.open")
            }
            
            Button {
                // Mock Hide Alerts Action
                HapticsManager.triggerImpact(style: .light)
            } label: {
                Label("Hide Alerts", systemImage: "bell.slash")
            }
            
            Button(role: .destructive) {
                HapticsManager.triggerImpact(style: .medium)
                onDismiss()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            if !item.isRead {
                Button {
                    onMarkRead()
                } label: {
                    Label("Read", systemImage: "envelope.open.fill")
                }
                .tint(.blue)
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button(role: .destructive) {
                onDismiss()
            } label: {
                Label("Delete", systemImage: "trash.fill")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.borrowerName), \(item.loanType). \(item.eventDescription) Application ID \(item.applicationId), \(RelativeDateFormatter.shared.relativeString(from: item.timestamp)). Status \(item.isRead ? "read" : "unread").")
    }
}
