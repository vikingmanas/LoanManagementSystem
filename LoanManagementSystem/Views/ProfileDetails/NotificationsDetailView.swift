import SwiftUI

struct NotificationsDetailView: View {
    @State private var loanUpdates = true
    @State private var paymentReminders = true
    @State private var securityAlerts = true
    @State private var promoOffers = false
    
    var body: some View {
        Form {
            Section(header: Text("Loan Activity")) {
                Toggle(isOn: $loanUpdates) {
                    HStack {
                        Image(systemName: "banknote.fill")
                            .foregroundStyle(Color.AppTheme.success)
                        VStack(alignment: .leading) {
                            Text("Loan Status Updates")
                            Text("Disbursals, approvals, and EMI receipts")
                                .font(Font.AppTheme.caption)
                                .foregroundStyle(Color.AppTheme.textSecondary)
                        }
                    }
                }
                
                Toggle(isOn: $paymentReminders) {
                    HStack {
                        Image(systemName: "calendar.badge.clock")
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading) {
                            Text("Payment Reminders")
                            Text("Receive alerts 3 days before your EMI is due")
                                .font(Font.AppTheme.caption)
                                .foregroundStyle(Color.AppTheme.textSecondary)
                        }
                    }
                }
            }
            
            Section(header: Text("Security")) {
                Toggle(isOn: $securityAlerts) {
                    HStack {
                        Image(systemName: "shield.fill")
                            .foregroundStyle(Color.AppTheme.primary)
                        VStack(alignment: .leading) {
                            Text("Security Alerts")
                            Text("Notifications on password change or new login")
                                .font(Font.AppTheme.caption)
                                .foregroundStyle(Color.AppTheme.textSecondary)
                        }
                    }
                }
            }
            
            Section(header: Text("Offers & Updates")) {
                Toggle(isOn: $promoOffers) {
                    HStack {
                        Image(systemName: "percent")
                            .foregroundStyle(.purple)
                        VStack(alignment: .leading) {
                            Text("Promotional Offers")
                            Text("Rate cuts, top-ups, and special credit offers")
                                .font(Font.AppTheme.caption)
                                .foregroundStyle(Color.AppTheme.textSecondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
    }
}
