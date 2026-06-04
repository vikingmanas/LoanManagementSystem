

import Foundation
import Combine
import SwiftUI
import Supabase

@MainActor
class SignInViewModel: ObservableObject {
    @Published var emailOrPhone: String = ""
    @Published var password: String = ""
    @Published var rememberMe: Bool = false

    @Published var emailError: String = ""
    @Published var passwordError: String = ""
    @Published var otpError: String = ""

    @Published var isLoading: Bool = false
    @Published var showSuccess: Bool = false
    @Published var generalError: String = ""

    // MARK: - OTP Step State
    @Published var otpCode: String = ""
    @Published var isOtpStep: Bool = false
    @Published var otpSentMessage: String = ""

    /// The cleaned email stored after credential validation, used for OTP send/verify.
    private var validatedEmail: String = ""
    /// The role fetched during credential validation, reused after OTP verification.
    private var validatedRole: String?

    var isFormValid: Bool {
        return !emailOrPhone.isEmpty && !password.isEmpty
    }

    var isOtpFormValid: Bool {
        let digits = otpCode.filter { $0.isNumber }
        return digits.count == 6
    }

    // MARK: - Step 1: Validate Credentials & Send OTP

    func signIn(authManager: AuthManager, appState: AppStateManager) async {
        emailError = ""
        passwordError = ""
        generalError = ""
        otpSentMessage = ""

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

        // 1. Validate credentials by signing in
        let result = await authManager.signIn(email: cleanedEmail, password: password)

        if result.success {
            // Store validated data for after OTP verification
            validatedEmail = cleanedEmail
            validatedRole = result.role

            // 2. Sign out immediately — user must complete OTP before accessing dashboard
            authManager.signOut()

            // 3. Send OTP to the user's email
            let otpSent = await authManager.sendEmailOTP(email: cleanedEmail)
            isLoading = false

            if otpSent {
                // Transition to OTP entry step
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    isOtpStep = true
                    otpSentMessage = "A 6-digit verification code has been sent to \(cleanedEmail)"
                }
            } else {
                generalError = authManager.errorMessage ?? "Failed to send verification code. Please try again."
            }
        } else {
            isLoading = false
            generalError = authManager.errorMessage ?? "Incorrect email or password. Please try again."
        }
    }

    // MARK: - Step 2: Verify OTP

    func verifyOTP(authManager: AuthManager, appState: AppStateManager) async {
        otpError = ""
        generalError = ""

        let cleanedOtp = otpCode.filter { $0.isNumber }
        guard cleanedOtp.count == 6 else {
            otpError = "Please enter the complete 6-digit code."
            return
        }

        isLoading = true
        let result = await authManager.verifyEmailOTP(email: validatedEmail, token: cleanedOtp)
        isLoading = false

        if result.success {
            let role = result.role ?? validatedRole
            completeSuccessfulLogin(role: role, email: validatedEmail, authManager: authManager, appState: appState)
        } else {
            otpError = authManager.errorMessage ?? "Invalid verification code. Please try again."
        }
    }

    // MARK: - Resend OTP

    func resendOTP(authManager: AuthManager) async {
        generalError = ""
        otpError = ""
        otpSentMessage = ""

        isLoading = true
        let success = await authManager.sendEmailOTP(email: validatedEmail)
        isLoading = false

        if success {
            otpSentMessage = "A new verification code has been sent to \(validatedEmail)"
        } else {
            generalError = authManager.errorMessage ?? "Failed to resend code. Please try again."
        }
    }

    // MARK: - Go Back to Credentials Step

    func goBackToCredentials() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            isOtpStep = false
            otpCode = ""
            otpError = ""
            otpSentMessage = ""
            generalError = ""
        }
    }

    // MARK: - Complete Login

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
            Task {
                if let session = try? await SupabaseManager.shared.client.auth.session {
                    await BorrowerProfileStore.shared.fetchProfileFromSupabase(
                        uid: session.user.id.uuidString,
                        email: session.user.email ?? email,
                        name: authManager.userDisplayName
                    )
                }
            }
        }

        showSuccess = true
    }
}
