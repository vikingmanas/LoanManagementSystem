import SwiftUI

struct LoanOfficerProfileView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState: AppStateManager
    @Environment(AuthManager.self) var authManager: AuthManager
    
    @AppStorage("biometricEnabled") private var biometricEnabled = false
    @AppStorage("isDarkMode") private var isDarkMode = false

    @State private var localSecurity = LocalSecurityService.shared
    @State private var showChangePassword = false
    
    private var officerApplications: [BorrowerLoanApplication] {
        guard let officerId = authManager.currentStaffProfile?.id else { return [] }
        return CentralLoanRepository.shared.applications.filter { app in
            app.assignedOfficerId == officerId || CentralLoanRepository.shared.isVisibleToOfficer(app, userId: officerId)
        }
    }

    private var loansVerifiedCount: Int {
        officerApplications.filter {
            [.bankManagerReview, .approved, .rejected, .disbursed].contains($0.currentStage)
        }.count
    }

    private var accuracyRate: Int {
        let verified = loansVerifiedCount
        if verified == 0 { return 100 }
        return 98
    }

    private var portfolioCapValue: Double {
        officerApplications.reduce(0.0) { (result: Double, app: BorrowerLoanApplication) -> Double in
            result + app.formData.requestedAmountValue
        }
    }
    
    private var avgCycleTime: Int {
        let verifiedApps = officerApplications.filter {
             [.bankManagerReview, .approved, .rejected, .disbursed].contains($0.currentStage)
        }
        if verifiedApps.isEmpty { return 2 }
        let totalDays = verifiedApps.reduce(0) { (total: Int, app: BorrowerLoanApplication) -> Int in
            let days = Calendar.current.dateComponents([.day], from: app.submittedAt ?? app.updatedAt, to: app.updatedAt).day ?? 1
            return total + max(1, days)
        }
        return max(1, totalDays / verifiedApps.count)
    }
    
    var body: some View {
        NavigationStack {
            List {
                // 1. OFFICER PROFILE HEADER CARD
                Section {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [LMSColors.brandNavy, LMSColors.actionBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                                .shadow(color: LMSColors.actionBlue.opacity(0.2), radius: 8, x: 0, y: 4)
                            
                            Text(authManager.currentStaffProfile?.initials ?? "")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text(authManager.currentStaffProfile?.fullName ?? "")
                                .font(.title3.bold())
                                .foregroundStyle(LMSColors.textPrimary)
                            
                            Text(authManager.currentStaffProfile?.designation ?? "")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(LMSColors.actionBlue)
                            
                            Text(authManager.currentStaffProfile?.branchName ?? "Branch not assigned")
                                .font(.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                
                // 2. EMPLOYEE DETAILS SECTION
                Section("Employee Information") {
                    LabeledContent("Employee ID", value: authManager.currentStaffProfile?.employeeCode ?? "")
                    LabeledContent("Department", value: "Retail Lending Operations")
                    LabeledContent("Role Level", value: authManager.currentStaffProfile?.designation ?? "")
                    
                    let dateStr: String = {
                        if let date = authManager.currentStaffProfile?.createdAt {
                            return RelativeDateFormatter.shared.absoluteString(from: date)
                        }
                        return ""
                    }()
                    LabeledContent("Date of Joining", value: dateStr)
                }
                
                // 3. CONTACT DETAILS SECTION
                Section("Contact Information") {
                    LabeledContent("Official Email", value: authManager.currentStaffProfile?.email ?? "")
                    LabeledContent("Work Phone", value: authManager.currentStaffProfile?.phoneNumber ?? "")
                }
                
                // 4. PERFORMANCE STATS SECTION
                Section("Performance & Operations") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Loans Verified")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                            Text("\(loansVerifiedCount)")
                                .font(.headline.bold())
                                .foregroundStyle(LMSColors.brandNavy)
                            Text("Year to Date")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Accuracy Rate")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                            Text("\(accuracyRate)%")
                                .font(.headline.bold())
                                .foregroundStyle(LMSColors.brandNavy)
                            Text("Audit Score")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Portfolio Cap")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                            Text(CurrencyFormatter.shared.format(portfolioCapValue))
                                .font(.headline.bold())
                                .foregroundStyle(LMSColors.brandNavy)
                            Text("Active Limit")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Avg. Cycle Time")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                            Text("\(avgCycleTime) Days")
                                .font(.headline.bold())
                                .foregroundStyle(LMSColors.brandNavy)
                            Text("TAT Score")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }


                
                // 5. SYSTEM SETTINGS
                Section("System Settings") {
                    
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
                    
                    Button {
                        showChangePassword = true
                    } label: {
                        Label("Change Password", systemImage: "lock.fill")
                    }
                    .foregroundStyle(Color(.label))

                    NavigationLink(destination: AccessibilitySettingsView()) {
                        Label("Accessibility", systemImage: "figure.walk.circle")
                    }
                }
                
                // 6. LOGOUT BUTTON
                Section {
                    Button(role: .destructive) {
                        HapticsManager.triggerImpact(style: .medium)
                        dismiss()
                        appState.logout()
                        authManager.signOut()
                    } label: {
                        Text("Log Out Session")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .accessibleSheet(isPresented: $showChangePassword) {
                ChangePasswordSheet()
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}
