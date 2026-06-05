import Observation
import Foundation
import Combine

@MainActor
@Observable
class SignUpViewModel {
    var fullName: String = ""
    var email: String = ""
    var phone: String = "" {
        didSet {
            let filtered = phone.filter { "0123456789".contains($0) }
            let newPhone = filtered.count > 10 ? String(filtered.prefix(10)) : filtered
            if phone != newPhone {
                phone = newPhone
            }
        }
    }
    var password: String = ""
    var confirmPassword: String = ""

    var referralCode: String = ""
    var alternatePhone: String = "" {
        didSet {
            let filtered = alternatePhone.filter { "0123456789".contains($0) }
            let newPhone = filtered.count > 10 ? String(filtered.prefix(10)) : filtered
            if alternatePhone != newPhone {
                alternatePhone = newPhone
            }
        }
    }

    var acceptedTerms: Bool = false
    var acceptedPrivacy: Bool = false

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
               isPasswordStrong && password == confirmPassword &&
               acceptedTerms && acceptedPrivacy
    }

    func signUp(authManager: AuthManager) async {
        generalError = ""

        if password != confirmPassword {
            generalError = "Passwords do not match"
            return
        }

        if !isPasswordStrong {
            generalError = "Please ensure your password meets all requirements."
            return
        }

        if !acceptedTerms || !acceptedPrivacy {
            generalError = "You must accept the Terms and Privacy Policy."
            return
        }

        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard cleanedEmail.contains("@") else {
            generalError = "Please enter a valid email address."
            return
        }

        isLoading = true
        let success = await authManager.signUp(
            name: fullName,
            email: cleanedEmail,
            password: password,
            phone: phone
        )
        isLoading = false

        if success {
            BorrowerProfileStore.shared.ensureProfile(
                email: cleanedEmail,
                name: fullName,
                phone: phone,
                alternatePhone: alternatePhone
            )
            showSuccess = true
        } else {
            generalError = authManager.errorMessage ?? "Unable to create account. Please try again."
        }
    }
}
