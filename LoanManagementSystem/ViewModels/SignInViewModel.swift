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

    func signIn(authManager: AuthManager) async {
        emailError = ""
        passwordError = ""
        generalError = ""

        // Basic validation
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
        let success = await authManager.signIn(email: cleanedEmail, password: password)
        isLoading = false

        if success {
            BorrowerProfileStore.shared.ensureProfile(
                email: cleanedEmail,
                name: authManager.userDisplayName
            )
            showSuccess = true
        } else {
            generalError = authManager.errorMessage ?? "Incorrect email or password. Please try again."
        }
    }
}
