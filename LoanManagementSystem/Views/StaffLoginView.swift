import SwiftUI

struct StaffLoginView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var authManager: AuthManager

    @State private var employeeID: String = ""
    @State private var password: String = ""

    @State private var employeeIDError: String = ""
    @State private var passwordError: String = ""
    @State private var generalError: String = ""
    @State private var isLoading: Bool = false

    var isFormValid: Bool {
        return !employeeID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !password.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LMSColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: LMSSpacing.xxl) {

                        // Back button
                        Button(action: {
                            HapticsManager.triggerImpact(style: .medium)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                appState.showRoleSelection = true
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("Back to Roles")
                            }
                            .font(LMSFont.subheadline.weight(.semibold))
                            .foregroundColor(LMSColors.brandNavy)
                        }
                        .padding(.top, LMSSpacing.lg)

                        // Header
                        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                            HStack(spacing: LMSSpacing.md) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                                        .fill(LMSColors.brandNavy.opacity(0.10))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: appState.selectedRole.icon)
                                        .font(LMSFont.title3)
                                        .foregroundColor(LMSColors.brandNavy)
                                }

                                Text("Branch Staff")
                                    .font(LMSFont.caption.weight(.bold))
                                    .foregroundColor(LMSColors.textSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(LMSColors.surface)
                                    .clipShape(Capsule())
                            }

                            Text("\(appState.selectedRole.rawValue) Portal")
                                .font(LMSFont.largeTitle)
                                .foregroundColor(LMSColors.textPrimary)

                            Text("Secure branch sign-in. Access credentials require verification.")
                                .font(LMSFont.subheadline)
                                .foregroundColor(LMSColors.textSecondary)
                        }
                        .padding(.bottom, LMSSpacing.sm)

                        // Error Banner
                        if !generalError.isEmpty {
                            HStack(alignment: .top, spacing: LMSSpacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(LMSColors.coral)
                                Text(generalError)
                                    .font(LMSFont.caption)
                                    .foregroundColor(LMSColors.coral)
                                Spacer()
                            }
                            .padding(LMSSpacing.lg)
                            .background(LMSColors.coral.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Fields
                        VStack(spacing: LMSSpacing.xl) {
                            VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                                Text("EMPLOYEE ID")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(LMSColors.textSecondary)
                                    .padding(.leading, LMSSpacing.xs)

                                CustomTextField(
                                    icon: "person.text.rectangle",
                                    placeholder: employeeIDPlaceholder,
                                    text: $employeeID,
                                    isError: !employeeIDError.isEmpty,
                                    errorMessage: employeeIDError
                                )
                            }

                            VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                                Text("PASSWORD")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(LMSColors.textSecondary)
                                    .padding(.leading, LMSSpacing.xs)

                                SecureInputField(
                                    placeholder: "Branch Password",
                                    text: $password,
                                    isError: !passwordError.isEmpty,
                                    errorMessage: passwordError
                                )
                            }
                        }

                        // Info note
                        HStack(alignment: .top, spacing: LMSSpacing.sm) {
                            Image(systemName: "info.circle")
                                .foregroundColor(LMSColors.textTertiary)
                                .font(LMSFont.footnote)

                            Text("Staff IDs correspond to branch assignments (e.g. Loan Officer starts with 'LO', Bank Manager with 'BM', Admin with 'AD').")
                                .font(LMSFont.caption)
                                .foregroundColor(LMSColors.textTertiary)
                        }

                        // Login button
                        PrimaryButton(
                            title: "Authorize Portal Access",
                            icon: "lock.open.fill",
                            isLoading: isLoading,
                            isDisabled: !isFormValid,
                            action: {
                                handleStaffLogin()
                            }
                        )
                        .padding(.top, LMSSpacing.sm)

                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.horizontal, LMSSpacing.xxl)
                }
            }
            .hideNavigationBar()
        }
    }

    // MARK: - Role Placeholder Helper
    private var employeeIDPlaceholder: String {
        switch appState.selectedRole {
        case .loanOfficer: return "e.g., LO1234"
        case .bankManager: return "e.g., BM1234"
        case .admin: return "e.g., AD1234"
        default: return "Branch Employee ID"
        }
    }

    // MARK: - Credentials Validation Handler
    private func handleStaffLogin() {
        // Reset Error State
        employeeIDError = ""
        passwordError = ""
        generalError = ""

        let cleanedID = employeeID.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

        // 1. Basic Format Validations
        if cleanedID.isEmpty {
            employeeIDError = "Employee ID cannot be empty"
            return
        }

        if password.isEmpty {
            passwordError = "Password cannot be empty"
            return
        }

        // 2. Validate prefix based on selected role
        switch appState.selectedRole {
        case .loanOfficer:
            if !cleanedID.hasPrefix("LO") {
                employeeIDError = "Loan Officer Employee ID must start with 'LO'"
                return
            }
        case .bankManager:
            if !cleanedID.hasPrefix("BM") {
                employeeIDError = "Bank Manager Employee ID must start with 'BM'"
                return
            }
        case .admin:
            if !cleanedID.hasPrefix("AD") {
                employeeIDError = "Admin Employee ID must start with 'AD'"
                return
            }
        default:
            break
        }

        isLoading = true

        // Simulate secure API/LDAP authorization ping
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.isLoading = false

            // Check mock passwords (universal 'password' for testing)
            if self.password == "password" {
                HapticsManager.triggerImpact(style: .heavy)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    appState.login()
                }
            } else {
                HapticsManager.triggerImpact(style: .light)
                self.generalError = "Access Denied: Invalid credentials. Check your Employee ID and password."
            }
        }
    }
}

struct StaffLoginView_Previews: PreviewProvider {
    static var previews: some View {
        StaffLoginView()
            .environmentObject(AppStateManager())
            .environmentObject(AuthManager())
    }
}
