import SwiftUI


struct ManagerSettingsView: View {
    @Environment(\.dismiss) var dismiss

    @AppStorage("managerHomeLoanLimit") private var homeLoanLimit = "5.0"
    @AppStorage("managerPersonalLoanLimit") private var personalLoanLimit = "1.0"
    @AppStorage("managerBusinessLoanLimit") private var businessLoanLimit = "3.0"
    @AppStorage("managerMinCIBILScore") private var minCIBILScore = "650"
    @AppStorage("managerMaxDebtToIncome") private var maxDebtToIncome = "50"
    @AppStorage("managerTwoFactorEnabled") private var twoFactorEnabled = true
    @AppStorage("managerSessionTimeout") private var sessionTimeout = "30"
    @AppStorage("managerNotifApprovals") private var notifApprovals = true
    @AppStorage("managerNotifEscalations") private var notifEscalations = true
    @AppStorage("managerNotifReports") private var notifReports = true

    var body: some View {
        NavigationStack {
            Form {

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

#Preview {
    NavigationStack {
        ManagerSettingsView()
    }
    .previewManagerEnvironment()
}

