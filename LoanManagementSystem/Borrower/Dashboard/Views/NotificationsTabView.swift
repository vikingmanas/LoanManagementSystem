import SwiftUI

struct NotificationsTabView: View {
    @State private var notifications = LMSMockNotifications.sample
    @State private var showUnreadOnly = false

    private var filtered: [LMSNotification] {
        showUnreadOnly ? notifications.filter(\.isUnread) : notifications
    }

    private var grouped: [(String, [LMSNotification])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today

        var todayItems: [LMSNotification] = []
        var yesterdayItems: [LMSNotification] = []
        var earlierItems: [LMSNotification] = []

        for item in filtered {
            let day = calendar.startOfDay(for: item.timestamp)
            if day >= today {
                todayItems.append(item)
            } else if day >= yesterday {
                yesterdayItems.append(item)
            } else {
                earlierItems.append(item)
            }
        }

        var sections: [(String, [LMSNotification])] = []
        if !todayItems.isEmpty { sections.append(("Today", todayItems)) }
        if !yesterdayItems.isEmpty { sections.append(("Yesterday", yesterdayItems)) }
        if !earlierItems.isEmpty { sections.append(("Earlier", earlierItems)) }
        return sections
    }

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    ContentUnavailableView {
                        Label("No Notifications", systemImage: "bell.slash")
                    } description: {
                        Text(showUnreadOnly
                             ? "You've read everything. Turn off the filter to see older alerts."
                             : "You're all caught up. We'll notify you about EMIs, payments, and loan updates.")
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(grouped, id: \.0) { section, items in
                            Section(section) {
                                ForEach(items) { notification in
                                    Button {
                                        markRead(notification)
                                    } label: {
                                        LMSNotificationRow(notification: notification)
                                    }
                                    .buttonStyle(.plain)
                                    .listRowInsets(EdgeInsets())
                                    .listRowSeparator(.hidden)
                                    .listRowBackground(Color.clear)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .lmsScreenBackground()
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Toggle("Unread only", isOn: $showUnreadOnly)
                        Button("Mark all as read") {
                            markAllRead()
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel("Filter notifications")
                }
            }
        }
    }

    private func markRead(_ notification: LMSNotification) {
        guard let index = notifications.firstIndex(where: { $0.id == notification.id }) else { return }
        notifications[index].isUnread = false
        HapticsManager.triggerImpact(style: .light)
    }

    private func markAllRead() {
        notifications = notifications.map { item in
            var copy = item
            copy.isUnread = false
            return copy
        }
        HapticsManager.triggerImpact(style: .medium)
    }
}

struct NotificationsTabView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsTabView()
    }
}
