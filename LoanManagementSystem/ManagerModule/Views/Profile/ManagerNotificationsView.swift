import SwiftUI

// MARK: - Manager Notifications View
struct ManagerNotificationsView: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.notifications.isEmpty {
                    ContentUnavailableView(
                        "No Notifications",
                        systemImage: "bell.slash",
                        description: Text("All clear — no pending alerts.")
                    )
                } else {
                    List {
                        // Mark All Read
                        if viewModel.unreadNotificationCount > 0 {
                            Button(action: {
                                HapticsManager.triggerImpact(style: .medium)
                                viewModel.markAllNotificationsRead()
                            }) {
                                HStack {
                                    Spacer()
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Mark All Read")
                                        .font(.system(.caption, design: .rounded).bold())
                                    Spacer()
                                }
                                .foregroundStyle(LMSColors.actionBlue)
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color.clear)
                        }

                        ForEach(viewModel.notifications) { notification in
                            Button(action: {
                                viewModel.markNotificationRead(notification.id)
                            }) {
                                HStack(alignment: .top, spacing: LMSSpacing.md) {
                                    Image(systemName: notification.type.icon)
                                        .foregroundStyle(notification.type.color)
                                        .font(.system(size: 22, weight: .semibold))
                                        .frame(width: 28)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(notification.title)
                                            .font(.system(.callout, design: .rounded).weight(notification.isRead ? .medium : .bold))
                                            .foregroundStyle(LMSColors.textPrimary)

                                        Text(notification.message)
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundStyle(LMSColors.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)

                                        Text(notification.timestamp, style: .relative)
                                            .font(.system(.caption2, design: .rounded).bold())
                                            .foregroundStyle(LMSColors.textTertiary)
                                    }

                                    Spacer()

                                    if !notification.isRead {
                                        Circle()
                                            .fill(notification.type.color)
                                            .frame(width: 8, height: 8)
                                            .padding(.top, 6)
                                    }
                                }
                            }
                            .listRowBackground(
                                notification.isRead ? Color.clear : notification.type.color.opacity(0.04)
                            )
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .font(.system(.body, design: .rounded).bold())
                }
            }
        }
    }
}
