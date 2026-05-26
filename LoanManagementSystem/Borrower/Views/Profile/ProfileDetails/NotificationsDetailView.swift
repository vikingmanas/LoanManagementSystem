import SwiftUI

struct NotificationsDetailView: View {
    @State private var loanUpdates = true
    @State private var paymentReminders = true
    @State private var securityAlerts = true
    @State private var promoOffers = false
    @ObservedObject private var loanRepository = CentralLoanRepository.shared

    private var notifications: [LMSNotification] {
        (loanRepository.borrowerNotifications + LMSMockNotifications.sample)
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        Form {
            Section {
                if notifications.isEmpty {
                    ContentUnavailableView(
                        "No Messages",
                        systemImage: "bell.slash",
                        description: Text("Loan approval and payment updates will appear here.")
                    )
                } else {
                    ForEach(notifications) { notification in
                        LMSNotificationRow(notification: notification)
                    }
                }
            } header: {
                Text("Messages")
            }

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
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        NotificationsDetailView()
    }
}
