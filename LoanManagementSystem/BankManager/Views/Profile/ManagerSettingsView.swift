import SwiftUI


struct ManagerSettingsView: View {
    @Environment(\.dismiss) var dismiss
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var settingsAlertTitle = ""
    @State private var settingsAlertMessage = ""
    @State private var showSettingsAlert = false

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
    
    @AppStorage("biometricEnabled") private var biometricEnabled = false
    @StateObject private var localSecurity = LocalSecurityService.shared

    var body: some View {
        List {
            Section("Display Mode") {
                Toggle(isOn: $isDarkMode) {
                    Label("Dark Mode", systemImage: "moon.fill")
                }
            }

            Section {
                HStack {
                    Text("Home Loan Limit (₹ Cr)")
                    Spacer()
                    TextField("", text: $homeLoanLimit)
                        .keyboardType(.decimalPad)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                        .font(.body.bold())
                }
                HStack {
                    Text("Personal Loan Limit (₹ Cr)")
                    Spacer()
                    TextField("", text: $personalLoanLimit)
                        .keyboardType(.decimalPad)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                        .font(.body.bold())
                }
                HStack {
                    Text("Business Loan Limit (₹ Cr)")
                    Spacer()
                    TextField("", text: $businessLoanLimit)
                        .keyboardType(.decimalPad)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                        .font(.body.bold())
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
                        .font(.body.bold())
                }
                HStack {
                    Text("Max Debt-to-Income (%)")
                    Spacer()
                    TextField("", text: $maxDebtToIncome)
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                        .font(.body.bold())
                }
            } header: {
                Label("Risk Thresholds", systemImage: "shield.fill")
            }

            Section {
                NavigationLink {
                    ManagerLoanProductConfigurationView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Loan Product Pricing")
                            .font(.body.weight(.semibold))
                        Text("Interest rates and processing fees per product")
                            .font(.caption)
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                }
            } header: {
                Label("Loan Product Configuration", systemImage: "doc.text.fill")
            } footer: {
                Text("Configure base interest rate and processing fee for each loan product at your branch.")
            }

            Section {
                Toggle(isOn: $biometricEnabled) {
                    Label("\(localSecurity.biometricTypeName) Login", systemImage: "faceid")
                }
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
                Button(action: {
                    Task { await saveBranchSettings() }
                }) {
                    HStack {
                        Spacer()
                        Text("Save Settings")
                            .bold()
                        Spacer()
                    }
                }
                .foregroundStyle(.white)
                .listRowBackground(LMSColors.brandNavy)
            }
        }
        .navigationTitle("Branch Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert(settingsAlertTitle, isPresented: $showSettingsAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(settingsAlertMessage)
        }
    }

    private func saveBranchSettings() async {
        let rules = GlobalLoanRules(
            minCibilScore: Int(minCIBILScore) ?? CentralLoanRepository.shared.globalRules.minCibilScore,
            maxDTI: Double(maxDebtToIncome) ?? CentralLoanRepository.shared.globalRules.maxDTI,
            maxLTV: CentralLoanRepository.shared.globalRules.maxLTV
        )

        do {
            try await AdminDashboardService.shared.updateGlobalRules(rules)
            CentralLoanRepository.shared.globalRules = rules
            if let encoded = try? JSONEncoder().encode(rules) {
                UserDefaults.standard.set(encoded, forKey: "GlobalLoanRules")
            }
            HapticsManager.triggerNotification(type: .success)
            settingsAlertTitle = "Settings Saved"
            settingsAlertMessage = "Branch limits and risk thresholds were updated."
            showSettingsAlert = true
            dismiss()
        } catch {
            HapticsManager.triggerNotification(type: .error)
            settingsAlertTitle = "Save Failed"
            settingsAlertMessage = "Could not sync risk thresholds. Loan product pricing is saved separately under Loan Product Configuration."
            showSettingsAlert = true
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

