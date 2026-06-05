import SwiftUI

struct StaffLoginView: View {
    @Environment(AppStateManager.self) var appState: AppStateManager
    @Environment(AuthManager.self) var authManager: AuthManager

    @State private var employeeID: String = ""
    @State private var password: String = ""

    @State private var employeeIDError: String = ""
    @State private var passwordError: String = ""
    @State private var generalError: String = ""
    @State private var isLoading: Bool = false
    @State private var showOTPVerification: Bool = false
    @State private var pendingRole: String = ""
    @State private var emailForOTP: String = ""

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
                                appState.selectedRole = .customer
                            }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color.AppTheme.textPrimary)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color(UIColor.systemGray5)))
                                .overlay(
                                    Circle()
                                        .stroke(LMSColors.separatorLight, lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 16)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {

                            }

                            Text("\(appState.selectedRole.rawValue) Portal")
                                .font(Font.AppTheme.title)
                                .foregroundColor(Color.AppTheme.textPrimary)

                            Text("Secure branch sign-in. Access credentials require verification.")
                                .font(Font.AppTheme.subtitle)
                                .foregroundColor(Color.AppTheme.textSecondary)
                        }

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

                        VStack(alignment: .leading, spacing: 20) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Staff Email")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color.AppTheme.textSecondary)

                                CustomTextField(
                                    icon: "person.text.rectangle",
                                    placeholder: employeeIDPlaceholder,
                                    text: $employeeID,
                                    isError: !employeeIDError.isEmpty,
                                    errorMessage: employeeIDError
                                )
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(Color.AppTheme.textSecondary)

                                SecureInputField(
                                    placeholder: "Branch Password",
                                    text: $password,
                                    isError: !passwordError.isEmpty,
                                    errorMessage: passwordError
                                )
                            }

                            Button {
                                handleStaffLogin()
                            } label: {
                                HStack(spacing: 10) {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                            .tint(.white)
                                    }
                                    Text("Sign In")
                                        .font(LMSFont.button)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.blue)
                            .disabled(!isFormValid || isLoading)
                            .accessibilityLabel("Sign In")
                            .accessibilityAddTraits(.isButton)
                            .padding(.top, 4)
                        }

                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .hideNavigationBar()
            .navigationDestination(isPresented: $showOTPVerification) {
                StaffOTPVerificationView(email: emailForOTP, pendingRole: pendingRole)
            }
        }
    }

    private var employeeIDPlaceholder: String {
        "Staff email address"
    }

    private func handleStaffLogin() {

        employeeIDError = ""
        passwordError = ""
        generalError = ""

        let cleanedID = employeeID.trimmingCharacters(in: .whitespacesAndNewlines)

        if cleanedID.isEmpty {
            employeeIDError = "Staff email cannot be empty"
            return
        }

        if password.isEmpty {
            passwordError = "Password cannot be empty"
            return
        }

        guard cleanedID.contains("@") else {
            employeeIDError = "Enter the staff email address created by the admin."
            return
        }
        let emailToAuthenticate = cleanedID.lowercased()

        isLoading = true

        Task {
            let result = await authManager.verifyPasswordAndTriggerOTP(email: emailToAuthenticate, password: password)
            self.isLoading = false

            if result.success {
                if let role = result.role {
                    if role == "admin" {
                        appState.selectedRole = .admin
                        HapticsManager.triggerImpact(style: .heavy)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            appState.login()
                        }
                    } else {
                        // Manager or Loan Officer: Needs OTP
                        HapticsManager.triggerImpact(style: .medium)
                        self.pendingRole = role
                        self.emailForOTP = emailToAuthenticate
                        self.showOTPVerification = true
                    }
                }
            } else {
                HapticsManager.triggerImpact(style: .light)
                self.generalError = authManager.errorMessage ?? "Access Denied: Invalid credentials. Check your employee credentials."
            }
        }
    }
}
