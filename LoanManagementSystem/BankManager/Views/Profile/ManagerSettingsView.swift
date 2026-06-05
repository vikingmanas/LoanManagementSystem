import SwiftUI


struct ManagerSettingsView: View {
    @Environment(\.dismiss) var dismiss

    @State private var settingsAlertTitle = ""
    @State private var settingsAlertMessage = ""
    @State private var showSettingsAlert = false

    @AppStorage("managerHomeLoanLimit") private var homeLoanLimit = "5.0"
    @AppStorage("managerPersonalLoanLimit") private var personalLoanLimit = "1.0"
    @AppStorage("managerBusinessLoanLimit") private var businessLoanLimit = "3.0"
    @AppStorage("managerMinCIBILScore") private var minCIBILScore = "650"
    @AppStorage("managerMaxDebtToIncome") private var maxDebtToIncome = "50"
    @AppStorage("managerTwoFactorEnabled") private var twoFactorEnabled = true
    @AppStorage("managerNotifApprovals") private var notifApprovals = true
    @AppStorage("managerNotifEscalations") private var notifEscalations = true
    @AppStorage("managerNotifReports") private var notifReports = true
    
    @AppStorage("biometricEnabled") private var biometricEnabled = false
    @State private var localSecurity = LocalSecurityService.shared

    var body: some View {
        List {

            Section {
                HStack {
                    Text("Minimum CIBIL Score")
                    Spacer()
                    Text("\(CentralLoanRepository.shared.globalRules.minCibilScore)")
                        .font(.body.bold())
                        .foregroundStyle(LMSColors.textSecondary)
                }
                HStack {
                    Text("Max Debt-to-Income (%)")
                    Spacer()
                    Text("\(Int(CentralLoanRepository.shared.globalRules.maxDTI))")
                        .font(.body.bold())
                        .foregroundStyle(LMSColors.textSecondary)
                }
            } header: {
                Label("Risk Thresholds", systemImage: "shield.fill")
            }

            Section {
                Toggle(isOn: Binding(
                    get: { biometricEnabled },
                    set: { newValue in
                        if newValue {
                            Task {
                                let success = await localSecurity.authenticate(reason: "Verify identity to enable biometric login")
                                biometricEnabled = success
                            }
                        } else {
                            biometricEnabled = false
                        }
                    }
                )) {
                    Label("\(localSecurity.biometricTypeName) Login", systemImage: "faceid")
                }
                .disabled(!localSecurity.canUseBiometrics())
                Toggle(isOn: $twoFactorEnabled) {
                    Text("Two-Factor Authentication")
                }
            } header: {
                Label("Security", systemImage: "lock.shield.fill")
            }

            Section {
                Toggle(isOn: $notifApprovals) {
                    Text("Approval Requests")
                }
                Toggle(isOn: $notifEscalations) {
                    Text("Review Alerts")
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
                    PermissionRow(label: "Admin Review", value: "Enabled", color: Color.purple)
                }
            } header: {
                Label("Permissions Overview", systemImage: "key.fill")
            }

            Section {
                NavigationLink(destination: AccessibilitySettingsView()) {
                    Label("Accessibility", systemImage: "figure.walk.circle")
                }
            } header: {
                Text("General")
            }

        }
        .navigationTitle("Branch Settings")
        .navigationBarTitleDisplayMode(.inline)
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
