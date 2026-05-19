import Foundation
import Combine

class ForgotPasswordViewModel: ObservableObject {
    @Published var emailOrPhone: String = ""
    @Published var isLoading: Bool = false
    @Published var showSuccessMessage: Bool = false
    @Published var errorMessage: String = ""
    @Published var navigateToOTP: Bool = false
    
    var isFormValid: Bool {
        return !emailOrPhone.isEmpty
    }
    
    func sendResetLink() {
        errorMessage = ""
        
        if emailOrPhone.isEmpty {
            errorMessage = "Please enter your Email or Mobile Number."
            return
        }
        
        isLoading = true
        
        // Mock API Call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isLoading = false
            self.showSuccessMessage = true
        }
    }
    
    func sendOTPCode() {
        errorMessage = ""
        
        if emailOrPhone.isEmpty {
            errorMessage = "Please enter your Email or Mobile Number."
            return
        }
        
        isLoading = true
        
        // Mock API Call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            self.isLoading = false
            self.navigateToOTP = true
        }
    }
}
