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
                Color.AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {


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
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundColor(Color.AppTheme.primary)
                        }
                        .padding(.top, 16)


                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.AppTheme.primary.opacity(0.12))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: appState.selectedRole.icon)
                                        .font(.title3)
                                        .foregroundColor(Color.AppTheme.primary)
                                }

                                Text("Branch Staff")
                                    .font(.system(.caption, design: .rounded).weight(.bold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.1))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }

                            Text("\(appState.selectedRole.rawValue) Portal")
                                .font(Font.AppTheme.title)
                                .foregroundColor(Color.AppTheme.textPrimary)

                            Text("Secure branch sign-in. Access credentials require verification.")
                                .font(Font.AppTheme.subtitle)
                                .foregroundColor(Color.AppTheme.textSecondary)
                        }
                        .padding(.top, 12)


                        if !generalError.isEmpty {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Color.AppTheme.error)
                                Text(generalError)
                                    .font(Font.AppTheme.caption)
                                    .foregroundColor(Color.AppTheme.error)
                                Spacer()
                            }
                            .padding()
                            .background(Color.AppTheme.error.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }


                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("EMPLOYEE ID")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.AppTheme.textSecondary)
                                    .padding(.leading, 4)

                                CustomTextField(
                                    icon: "person.text.rectangle",
                                    placeholder: employeeIDPlaceholder,
                                    text: $employeeID,
                                    isError: !employeeIDError.isEmpty,
                                    errorMessage: employeeIDError
                                )
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("PASSWORD")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.AppTheme.textSecondary)
                                    .padding(.leading, 4)

                                SecureInputField(
                                    placeholder: "Branch Password",
                                    text: $password,
                                    isError: !passwordError.isEmpty,
                                    errorMessage: passwordError
                                )
                            }
                        }


                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                                .font(.footnote)

                            Text("Staff IDs correspond to branch assignments (e.g. Loan Officer starts with 'LO', Bank Manager with 'BM', Admin with 'AD').")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)


                        PrimaryButton(
                            title: "Authorize Portal Access",
                            isLoading: isLoading,
                            isDisabled: !isFormValid,
                            action: {
                                handleStaffLogin()
                            }
                        )
                        .padding(.top, 12)

                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .hideNavigationBar()
        }
    }


    private var employeeIDPlaceholder: String {
        switch appState.selectedRole {
        case .loanOfficer: return "e.g., LO1234"
        case .bankManager: return "e.g., BM1234"
        case .admin: return "e.g., admin@lms.com or ADMIN"
        default: return "Branch Employee ID"
        }
    }


    private func handleStaffLogin() {

        employeeIDError = ""
        passwordError = ""
        generalError = ""

        let cleanedID = employeeID.trimmingCharacters(in: .whitespacesAndNewlines)


        if cleanedID.isEmpty {
            employeeIDError = "Employee ID or Email cannot be empty"
            return
        }

        if password.isEmpty {
            passwordError = "Password cannot be empty"
            return
        }


        let emailToAuthenticate: String
        if cleanedID.contains("@") {
            emailToAuthenticate = cleanedID.lowercased()
        } else {

            let upperID = cleanedID.uppercased()
            switch appState.selectedRole {
            case .loanOfficer:
                if !upperID.hasPrefix("LO") {
                    employeeIDError = "Loan Officer Employee ID must start with 'LO'"
                    return
                }
            case .bankManager:
                if !upperID.hasPrefix("BM") {
                    employeeIDError = "Bank Manager Employee ID must start with 'BM'"
                    return
                }
            case .admin:
                if !upperID.hasPrefix("AD") {
                    employeeIDError = "Admin Employee ID must start with 'AD'"
                    return
                }
            default:
                break
            }
            emailToAuthenticate = "\(upperID.lowercased())@lms.com"
        }

        isLoading = true

        Task {
            let result = await authManager.signIn(email: emailToAuthenticate, password: password)
            self.isLoading = false

            if result.success {

                if let role = result.role {
                    switch role {
                    case "admin":
                        appState.selectedRole = .admin
                    case "manager", "loan_manager":
                        appState.selectedRole = .bankManager
                    case "loan_officer":
                        appState.selectedRole = .loanOfficer
                    default:
                        appState.selectedRole = .customer
                    }
                }

                HapticsManager.triggerImpact(style: .heavy)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    appState.login()
                }
            } else {
                HapticsManager.triggerImpact(style: .light)
                self.generalError = authManager.errorMessage ?? "Access Denied: Invalid credentials. Check your employee credentials."
            }
        }
    }
}

#Preview {
    StaffLoginView()
        .environmentObject(PreviewSupport.appState(showRoleSelection: true))
        .environmentObject(PreviewSupport.authManager)
}

