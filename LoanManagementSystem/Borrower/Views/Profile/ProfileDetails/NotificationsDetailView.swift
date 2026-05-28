import SwiftUI

struct NotificationsDetailView: View {
    @ObservedObject private var loanRepository = CentralLoanRepository.shared

    private var notifications: [LMSNotification] {
        let live = loanRepository.borrowerNotifications
        let merged = live + LMSMockNotifications.sample
        var seen = Set<UUID>()
        return merged
            .filter { seen.insert($0.id).inserted }
            .sorted { $0.timestamp > $1.timestamp }
    }

    private var groupedNotifications: [(group: NotificationGroup, items: [LMSNotification])] {
        NotificationGroup.allCases.compactMap { group in
            let items = notifications.filter { NotificationGroup.category(for: $0) == group }
            return items.isEmpty ? nil : (group, items)
        }
    }

    var body: some View {
        List {
            if notifications.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Notifications",
                        systemImage: "bell.slash",
                        description: Text("EMI reminders, approval updates, and KYC alerts will appear here.")
                    )
                }
            } else {
                ForEach(groupedNotifications, id: \.group.id) { group, items in
                    Section {
                        ForEach(items) { notification in
                            NotificationListRow(notification: notification)
                        }
                    } header: {
                        Label(group.title, systemImage: group.icon)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.large)
    }
}

private enum NotificationGroup: String, CaseIterable, Identifiable {
    case emi
    case approvals
    case kyc
    case payments
    case alerts

    var id: String { rawValue }

    var title: String {
        switch self {
        case .emi: return "EMI Reminders"
        case .approvals: return "Approval Updates"
        case .kyc: return "KYC Alerts"
        case .payments: return "Payment Confirmations"
        case .alerts: return "Account Alerts"
        }
    }

    var icon: String {
        switch self {
        case .emi: return "calendar.badge.clock"
        case .approvals: return "checkmark.seal"
        case .kyc: return "person.text.rectangle"
        case .payments: return "indianrupeesign.circle"
        case .alerts: return "exclamationmark.triangle"
        }
    }

    static func category(for notification: LMSNotification) -> NotificationGroup {
        let text = "\(notification.title) \(notification.body) \(notification.icon)".lowercased()
        if text.contains("payment") || text.contains("received") || text.contains("debited") || text.contains("disbursement") {
            return .payments
        }
        if text.contains("emi") || text.contains("calendar") {
            return .emi
        }
        if text.contains("approval") || text.contains("approved") || text.contains("rejected") || text.contains("review") {
            return .approvals
        }
        if text.contains("kyc") || text.contains("address proof") || text.contains("profile verification") {
            return .kyc
        }
        return .alerts
    }
}

private struct NotificationListRow: View {
    let notification: LMSNotification

    private var timeText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: notification.timestamp, relativeTo: Date())
    }

    var body: some View {
        HStack(alignment: .top, spacing: LMSSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                    .fill(notification.tint.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: notification.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(notification.tint)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(notification.title)
                        .font(LMSFont.callout.weight(notification.isUnread ? .bold : .medium))
                        .foregroundStyle(LMSColors.textPrimary)
                    Spacer(minLength: LMSSpacing.sm)
                    Text(timeText)
                        .font(LMSFont.caption2)
                        .foregroundStyle(LMSColors.textTertiary)
                }
                Text(notification.body)
                    .font(LMSFont.footnote)
                    .foregroundStyle(LMSColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if notification.isUnread {
                Circle()
                    .fill(LMSColors.actionBlue)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .padding(.vertical, LMSSpacing.xs)
    }
}
