import Observation
import Foundation
import Combine

@MainActor
@Observable
class AdminSignUpViewModel {
    var fullName: String = ""
    var email: String = ""
    var phone: String = ""
    var password: String = ""
    var confirmPassword: String = ""

    var isLoading: Bool = false
    var showSuccess: Bool = false
    var generalError: String = ""

    var isMinLength: Bool { password.count >= 8 }
    var hasUppercase: Bool { password.rangeOfCharacter(from: .uppercaseLetters) != nil }
    var hasNumber: Bool { password.rangeOfCharacter(from: .decimalDigits) != nil }
    var hasSpecialChar: Bool { password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()-_=+[]{}|;:'\",.<>/?")) != nil }

    var isPasswordStrong: Bool {
        isMinLength && hasUppercase && hasNumber && hasSpecialChar
    }

    var isFormValid: Bool {
        return !fullName.isEmpty && !email.isEmpty && !phone.isEmpty &&
               isPasswordStrong && password == confirmPassword
    }

    func signUpAdmin() async {
        generalError = ""

        if password != confirmPassword {
            generalError = "Passwords do not match"
            return
        }

        if !isPasswordStrong {
            generalError = "Please ensure your password meets all requirements."
            return
        }

        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard cleanedEmail.contains("@") else {
            generalError = "Please enter a valid email address."
            return
        }

        isLoading = true

        do {
            try await AdminStaffService.shared.createAdmin(
                name: fullName,
                email: cleanedEmail,
                phone: phone,
                password: password
            )
            isLoading = false
            showSuccess = true
        } catch {
            isLoading = false
            generalError = error.localizedDescription
        }
    }
}
