import Foundation
import Combine

@MainActor
class ForgotPasswordViewModel: ObservableObject {
    @Published var emailOrPhone: String = ""
    @Published var isLoading: Bool = false
    @Published var showSuccessMessage: Bool = false
    @Published var errorMessage: String = ""


    var isFormValid: Bool {
        return !emailOrPhone.isEmpty
    }

    func sendResetLink(authManager: AuthManager) async {
        errorMessage = ""

        if emailOrPhone.isEmpty {
            errorMessage = "Please enter your email address."
            return
        }

        let cleanedEmail = emailOrPhone.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard cleanedEmail.contains("@") else {
            errorMessage = "Please enter a valid email address."
            return
        }

        isLoading = true
        
        // 1. Verify if the email is actually registered in the database
        let isRegistered = await AuthService.shared.isEmailRegistered(cleanedEmail)
        
        if isRegistered {
            // 2. If registered, proceed to send the reset link
            let success = await authManager.resetPassword(email: cleanedEmail)
            showSuccessMessage = success
            errorMessage = success ? "" : (authManager.errorMessage ?? "Unable to send reset link. Please try again.")
        } else {
            // 3. If not registered, show the requested error message
            showSuccessMessage = false
            errorMessage = "You are not registered."
        }
        
        isLoading = false
    }
}
