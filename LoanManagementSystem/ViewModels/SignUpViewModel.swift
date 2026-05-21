import Foundation
import Combine

class SignUpViewModel: ObservableObject {
    @Published var fullName: String = ""
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var password: String = ""
    @Published var confirmPassword: String = ""
    
    @Published var referralCode: String = ""
    @Published var alternatePhone: String = ""
    
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
    
    func signUp() {
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
        
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let customerId = BorrowerProfileStore.shared.signUp(
                name: self.fullName,
                email: self.email,
                phone: self.phone,
                password: self.password
            )
            
            self.isLoading = false
            if customerId != nil {
                self.showSuccess = true
            } else {
                self.generalError = "This email is already registered. Try logging in instead."
            }
        }
    }
}
