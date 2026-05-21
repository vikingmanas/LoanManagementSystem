import Foundation
import Combine

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
    
    func signIn() {
        // Reset errors
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
        
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let success = BorrowerProfileStore.shared.signIn(
                emailOrPhone: self.emailOrPhone,
                password: self.password
            )
            
            self.isLoading = false
            if success {
                self.showSuccess = true
            } else {
                self.generalError = "Incorrect email/mobile or password. Please try again."
            }
        }
    }

}
