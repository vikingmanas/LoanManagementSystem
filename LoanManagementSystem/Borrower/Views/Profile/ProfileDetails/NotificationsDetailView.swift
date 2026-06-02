import SwiftUI

struct NotificationsDetailView: View {
    var showSettings: Bool = true
    @State private var loanUpdates = true
    @State private var paymentReminders = true
    @State private var securityAlerts = true
    @State private var promoOffers = false
    @ObservedObject var notificationViewModel: NotificationViewModel

    var body: some View {
        Form {
            Section {
                if notificationViewModel.notifications.isEmpty {
                    ContentUnavailableView(
                        "No Messages",
                        systemImage: "bell.slash",
                        description: Text("Loan approval and payment updates will appear here.")
                    )
                } else {
                    ForEach(notificationViewModel.lmsNotifications) { notification in
                        LMSNotificationRow(notification: notification)
                            .onTapGesture {
                                withAnimation {
                                    notificationViewModel.markRead(id: notification.id)
                                }
                            }
                    }
                }
            } header: {
                HStack {
                    Text("Messages")
                    Spacer()
                    if notificationViewModel.unreadCount > 0 {
                        Button("Mark All Read") {
                            withAnimation {
                                notificationViewModel.markAllRead()
                            }
                        }
                        .font(.caption)
                    }
                }
            }

            if showSettings {
                Section {
                    Toggle(isOn: $loanUpdates) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Loan Status Updates")
                                Text("Disbursals, approvals, and EMI receipts")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "banknote")
                        }
                    }
                    
                    Toggle(isOn: $paymentReminders) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Payment Reminders")
                                Text("Receive alerts 3 days before your EMI is due")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "calendar.badge.clock")
                        }
                    }
                } header: {
                    Text("Loan Activity")
                }
                
                Section {
                    Toggle(isOn: $securityAlerts) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Security Alerts")
                                Text("Notifications on password change or new login")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "shield")
                        }
                    }
                } header: {
                    Text("Security")
                }
                
                Section {
                    Toggle(isOn: $promoOffers) {
                        Label {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Promotional Offers")
                                Text("Rate cuts, top-ups, and special credit offers")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } icon: {
                            Image(systemName: "percent")
                        }
                    }
                } header: {
                    Text("Offers & Updates")
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await notificationViewModel.loadNotifications()
        }
    }
}
