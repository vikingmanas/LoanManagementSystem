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
    @Published var navigateToOTP: Bool = false
    
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
        
        // Mock API Call
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            self.showSuccess = true
        }
    }
    
    func loginWithOTP() {
        generalError = ""
        
        if emailOrPhone.isEmpty {
            generalError = "Please enter your Email or Mobile Number to receive an OTP."
            return
        }
        
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
            self.navigateToOTP = true
        }
    }
}
