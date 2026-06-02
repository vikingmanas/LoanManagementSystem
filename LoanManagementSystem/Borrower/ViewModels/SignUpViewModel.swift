import Foundation
import Combine

@MainActor
class SignUpViewModel: ObservableObject {
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var phone: String = "" {
        didSet {
            let filtered = phone.filter { "0123456789".contains($0) }
            let newPhone = filtered.count > 10 ? String(filtered.prefix(10)) : filtered
            if phone != newPhone {
                phone = newPhone
            }
        }
    }
    @Published var password: String = ""
    @Published var confirmPassword: String = ""

    @Published var referralCode: String = ""
    @Published var alternatePhone: String = "" {
        didSet {
            let filtered = alternatePhone.filter { "0123456789".contains($0) }
            let newPhone = filtered.count > 10 ? String(filtered.prefix(10)) : filtered
            if alternatePhone != newPhone {
                alternatePhone = newPhone
            }
        }
    }

    @Published var acceptedTerms: Bool = false
    @Published var acceptedPrivacy: Bool = false

    @Published var isLoading: Bool = false
    @Published var showSuccess: Bool = false

    @Published var generalError: String = ""

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

