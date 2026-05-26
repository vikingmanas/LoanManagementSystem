






import Foundation
import Combine

@MainActor
class SignInViewModel: ObservableObject {
    @Published var emailOrPhone: String = ""
    @Published var password: String = ""
    @Published var rememberMe: Bool = false

    @Published var emailError: String = ""
    @Published var passwordError: String = ""

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


            if appState.selectedRole == .customer {
                BorrowerProfileStore.shared.ensureProfile(
                    email: cleanedEmail,
                    name: authManager.userDisplayName
                )
            }

            showSuccess = true
        } else {
            generalError = authManager.errorMessage ?? "Incorrect email or password. Please try again."
        }
    }
}

