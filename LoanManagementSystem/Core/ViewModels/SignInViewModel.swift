






import Foundation
import Combine
import Supabase

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
    
    // 2FA state
    @Published var is2FAInputActive: Bool = false
    @Published var generated2FAOTP: String = ""
    private var pending2FARole: String? = nil
    private var pending2FAEmail: String = ""

    @Published var emailError: String = ""
    @Published var passwordError: String = ""
    @Published var otpError: String = ""

    @Published var isLoading: Bool = false
    @Published var showSuccess: Bool = false
    @Published var generalError: String = ""

    var isFormValid: Bool {
        switch signInMode {
        case .password:
            if is2FAInputActive {
                return !otpCode.isEmpty
            }
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
        
        if result.success {
            authManager.isPending2FA = true
            
            let otp = String(format: "%06d", Int.random(in: 0...999999))
            self.generated2FAOTP = otp
            self.pending2FARole = result.role
            self.pending2FAEmail = cleanedEmail
            
            let sent = await send2FAEmail(email: cleanedEmail, otp: otp)
            isLoading = false
            
            if sent {
                is2FAInputActive = true
            } else {
                generalError = "Failed to send 2FA OTP. Please try again."
                authManager.isPending2FA = false
                authManager.signOut()
            }
        } else {
            isLoading = false
            generalError = authManager.errorMessage ?? "Incorrect email or password. Please try again."
        }
    }
    
    func verify2FAOTP(authManager: AuthManager, appState: AppStateManager) {
        emailError = ""
        otpError = ""
        generalError = ""
        
        let token = otpCode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard token.count >= 6 else {
            otpError = "Enter the 6-digit OTP from your email."
            return
        }
        
        if token == generated2FAOTP {
            authManager.isPending2FA = false
            is2FAInputActive = false
            completeSuccessfulLogin(role: pending2FARole, email: pending2FAEmail, authManager: authManager, appState: appState)
        } else {
            generalError = "Invalid OTP."
        }
    }
    
    private func send2FAEmail(email: String, otp: String) async -> Bool {
        guard let url = URL(string: "http://localhost:3000/api/send-2fa-otp") else { return false }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["userEmail": email, "otp": otp]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                return true
            }
            return false
        } catch {
            print("Error sending 2FA email: \(error.localizedDescription)")
            return false
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
