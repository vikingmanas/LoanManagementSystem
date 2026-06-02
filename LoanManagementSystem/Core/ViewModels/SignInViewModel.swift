






import Foundation
import Combine

enum BorrowerSignInMode: String, CaseIterable, Identifiable {
    case password = "Password"
    case emailOTP = "Email OTP"

    var id: String { rawValue }
}

@MainActor
class SignInViewModel: ObservableObject {
    @Published var emailOrPhone: String = ""
    @Published var password: String = ""
    @Published var otpCode: String = ""
    @Published var signInMode: BorrowerSignInMode = .password
    @Published var isOTPSent: Bool = false
    @Published var rememberMe: Bool = false

    @Published var emailError: String = ""
    @Published var passwordError: String = ""
    @Published var otpError: String = ""

    @Published var isLoading: Bool = false
    @Published var showSuccess: Bool = false
    @Published var generalError: String = ""

    var isFormValid: Bool {
        switch signInMode {
        case .password:
            return !emailOrPhone.isEmpty && !password.isEmpty
        case .emailOTP:
            return !emailOrPhone.isEmpty && (!isOTPSent || !otpCode.isEmpty)
        }
    }

    func signIn(authManager: AuthManager, appState: AppStateManager) async {
        emailError = ""
        passwordError = ""
        generalError = ""


        if emailOrPhone.isEmpty {
            emailError = "Email or Phone cannot be empty"
        }
        if password.isEmpty {
            passwordError = "Password cannot be empty"
        }

        if !emailError.isEmpty || !passwordError.isEmpty {
            return
        }

        let cleanedEmail = emailOrPhone.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard cleanedEmail.contains("@") else {
            emailError = "Please sign in with your registered email address."
            return
        }

        isLoading = true
        let result = await authManager.signIn(email: cleanedEmail, password: password)
        isLoading = false

        if result.success {

            completeSuccessfulLogin(role: result.role, email: cleanedEmail, authManager: authManager, appState: appState)
        } else {
            generalError = authManager.errorMessage ?? "Incorrect email or password. Please try again."
        }
    }

    func sendEmailOTP(authManager: AuthManager) async {
        emailError = ""
        otpError = ""
        generalError = ""

        let cleanedEmail = emailOrPhone.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard cleanedEmail.contains("@") else {
            emailError = "Please enter your registered email address."
            return
        }

        isLoading = true
        let success = await authManager.sendEmailOTP(email: cleanedEmail)
        isLoading = false

        if success {
            isOTPSent = true
        } else {
            generalError = authManager.errorMessage ?? "Unable to send OTP. Please try again."
        }
    }

    func verifyEmailOTP(authManager: AuthManager, appState: AppStateManager) async {
        emailError = ""
        otpError = ""
        generalError = ""

        let cleanedEmail = emailOrPhone.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let token = otpCode.trimmingCharacters(in: .whitespacesAndNewlines)

        guard cleanedEmail.contains("@") else {
            emailError = "Please enter your registered email address."
            return
        }

        guard token.count >= 6 else {
            otpError = "Enter the 6-digit OTP from your email."
            return
        }

        isLoading = true
        let result = await authManager.verifyEmailOTP(email: cleanedEmail, token: token)
        isLoading = false

        if result.success {
            completeSuccessfulLogin(role: result.role, email: cleanedEmail, authManager: authManager, appState: appState)
        } else {
            generalError = authManager.errorMessage ?? "Invalid or expired OTP."
        }
    }

    private func completeSuccessfulLogin(role: String?, email: String, authManager: AuthManager, appState: AppStateManager) {
        if let role {
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

        if appState.selectedRole == .customer {
            appState.requiresBorrowerOnboarding = false
            BorrowerProfileStore.shared.ensureProfile(
                email: email,
                name: authManager.userDisplayName
            )
        }

        showSuccess = true
    }
}
