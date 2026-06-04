import SwiftUI


struct ManagerSettingsView: View {
    @Environment(\.dismiss) var dismiss

    @AppStorage("managerTwoFactorEnabled") private var twoFactorEnabled = true
    @AppStorage("managerSessionTimeout") private var sessionTimeout = "30"
    @AppStorage("managerNotifApprovals") private var notifApprovals = true
    @AppStorage("managerNotifEscalations") private var notifEscalations = true
    @AppStorage("managerNotifReports") private var notifReports = true
    
    @AppStorage("biometricEnabled") private var biometricEnabled = false
    @StateObject private var localSecurity = LocalSecurityService.shared

    var body: some View {
        List {
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
                HStack {
                    Text("Session Timeout (mins)")
                    Spacer()
                    TextField("", text: $sessionTimeout)
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                        .font(.body.bold())
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
        .navigationTitle("App Settings")
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

