






import Foundation
import Combine
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

    var isFormValid: Bool {
        return !emailOrPhone.isEmpty && !password.isEmpty
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
