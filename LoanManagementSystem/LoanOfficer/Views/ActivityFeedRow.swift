import SwiftUI

struct ActivityFeedRow: View {
    let item: ActivityFeedItem
    var onMarkRead: () -> Void
    var onDismiss: () -> Void
    var onActionTapped: (ActivityActionType) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            ZStack(alignment: .topTrailing) {
                ZStack {
                    Circle()
                        .fill(item.eventType.themeColor.opacity(0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: item.eventType.symbol)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(item.eventType.themeColor)
                }

                if !item.isRead {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle()
                                .stroke(Color(.systemBackground), lineWidth: 2)
                        )
                        .offset(x: 2, y: -2)
                }
            }


            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(item.borrowerName)
                        .font(.system(.callout, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)

                    Text("·")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)

                    Text(item.loanType)
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(LMSColors.textSecondary)

                    Spacer()

                    Text(RelativeDateFormatter.shared.relativeString(from: item.timestamp))
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(Color(.placeholderText))
                }

                Text(item.eventDescription)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    Text(item.applicationId)
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundStyle(Color(.placeholderText))
                }
                .padding(.top, 2)
            }

            Spacer()


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
                        .foregroundStyle(actionType.color)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Action: \(actionType.label) for \(item.borrowerName)")
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color(.systemBackground))
        .contentShape(Rectangle())
        .contextMenu {
            Button {

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

#Preview {
    ActivityFeedRow(
        item: PreviewSupport.sampleActivityFeedItem,
        onMarkRead: {},
        onDismiss: {},
        onActionTapped: { _ in }
    )
    .padding()
}

