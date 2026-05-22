import SwiftUI

// MARK: - Manager Settings View
struct ManagerSettingsView: View {
    @Environment(\.dismiss) var dismiss

    @State private var homeLoanLimit = "5.0"
    @State private var personalLoanLimit = "1.0"
    @State private var businessLoanLimit = "3.0"
    @State private var minCIBILScore = "650"
    @State private var maxDebtToIncome = "50"
    @State private var twoFactorEnabled = true
    @State private var sessionTimeout = "30"
    @State private var notifApprovals = true
    @State private var notifEscalations = true
    @State private var notifReports = true

    var body: some View {
        NavigationStack {
            Form {
                // MARK: — Branch Configuration
                Section {
                    HStack {
                        Text("Home Loan Limit (₹ Cr)")
                        Spacer()
                        TextField("", text: $homeLoanLimit)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                            .font(.system(.body, design: .rounded).bold())
                    }
                    HStack {
                        Text("Personal Loan Limit (₹ Cr)")
                        Spacer()
                        TextField("", text: $personalLoanLimit)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                            .font(.system(.body, design: .rounded).bold())
                    }
                    HStack {
                        Text("Business Loan Limit (₹ Cr)")
                        Spacer()
                        TextField("", text: $businessLoanLimit)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                            .font(.system(.body, design: .rounded).bold())
                    }
                } header: {
                    Label("Branch Loan Configuration", systemImage: "building.columns.fill")
                }

                // MARK: — Risk Thresholds
                Section {
                    HStack {
                        Text("Minimum CIBIL Score")
                        Spacer()
                        TextField("", text: $minCIBILScore)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                            .font(.system(.body, design: .rounded).bold())
                    }
                    HStack {
                        Text("Max Debt-to-Income (%)")
                        Spacer()
                        TextField("", text: $maxDebtToIncome)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                            .font(.system(.body, design: .rounded).bold())
                    }
                } header: {
                    Label("Risk Thresholds", systemImage: "shield.fill")
                }

                // MARK: — Security Settings
                Section {
                    Toggle(isOn: $twoFactorEnabled) {
                        Text("Two-Factor Authentication")
                    }
                    HStack {
                        Text("Session Timeout (mins)")
                        Spacer()
                        TextField("", text: $sessionTimeout)
                            .keyboardType(.numberPad)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                            .font(.system(.body, design: .rounded).bold())
                    }
                } header: {
                    Label("Security", systemImage: "lock.shield.fill")
                }

                // MARK: — Notification Preferences
                Section {
                    Toggle(isOn: $notifApprovals) {
                        Text("Approval Requests")
                    }
                    Toggle(isOn: $notifEscalations) {
                        Text("Escalation Alerts")
                    }
                    Toggle(isOn: $notifReports) {
                        Text("Weekly Reports")
                    }
                } header: {
                    Label("Notifications", systemImage: "bell.fill")
                }

                // MARK: — Permissions
                Section {
                    VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                        PermissionRow(label: "Loan Approval", value: "Up to ₹1 Cr", color: LMSColors.emerald)
                        PermissionRow(label: "Staff Reassignment", value: "Branch Level", color: LMSColors.actionBlue)
                        PermissionRow(label: "Report Export", value: "Full Access", color: LMSColors.teal)
                        PermissionRow(label: "Admin Escalation", value: "Enabled", color: Color.purple)
                    }
                } header: {
                    Label("Permissions Overview", systemImage: "key.fill")
                }

                // MARK: — Save
                Section {
                    Button(action: {
                        HapticsManager.triggerNotification(type: .success)
                        dismiss()
                    }) {
                        Text("Save Settings")
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .listRowBackground(LMSColors.brandNavy)
                }
            }
            .navigationTitle("Branch Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(.body, design: .rounded).bold())
                }
            }
        }
    }
}

// MARK: - Permission Row
private struct PermissionRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(LMSColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(.caption, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
        }
    }
}
