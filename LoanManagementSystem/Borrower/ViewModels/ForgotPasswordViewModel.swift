import Observation
import Foundation
import Combine

enum ForgotPasswordStep {
    case email
    case otp
    case resetPassword
}

@MainActor
@Observable
class ForgotPasswordViewModel {
    var emailOrPhone: String = ""
    var otpToken: String = ""
    var newPassword: String = ""
    var confirmPassword: String = ""
    
    var currentStep: ForgotPasswordStep = .email
    var isLoading: Bool = false
    var showSuccessMessage: Bool = false
    var errorMessage: String = ""
    
    var isEmailFormValid: Bool {
        let cleanedEmail = emailOrPhone.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return !cleanedEmail.isEmpty && cleanedEmail.contains("@")
    }
    
    var isOtpFormValid: Bool {
        let cleaned = otpToken.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.count == 6 && cleaned.allSatisfy({ $0.isNumber })
    }
    
    var isMinLength: Bool { newPassword.count >= 8 }
    var hasUppercase: Bool { newPassword.rangeOfCharacter(from: CharacterSet.uppercaseLetters) != nil }
    var hasNumber: Bool { newPassword.rangeOfCharacter(from: CharacterSet.decimalDigits) != nil }
    var hasSpecialChar: Bool { newPassword.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;':\",./<>?`~")) != nil }
    
    var isPasswordStrong: Bool {
        isMinLength && hasUppercase && hasNumber && hasSpecialChar
    }
    
    var isResetFormValid: Bool {
        isPasswordStrong && newPassword == confirmPassword && !newPassword.isEmpty
    }
    
    var showConfirmPasswordError: Bool {
        !confirmPassword.isEmpty && newPassword != confirmPassword
    }
    
    func sendResetCode(authManager: AuthManager) async {
        errorMessage = ""
        
        guard isEmailFormValid else {
            errorMessage = "Please enter a valid email address."
            return
        }
        
        let cleanedEmail = emailOrPhone.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        isLoading = true
        
        let isRegistered = await AuthService.shared.isEmailRegistered(cleanedEmail)
        
        if isRegistered {

            let success = await authManager.resetPassword(email: cleanedEmail)
            if success {
                currentStep = .otp
                errorMessage = ""
            } else {
                errorMessage = authManager.errorMessage ?? "Unable to send reset code. Please try again."
            }
        } else {

            errorMessage = "You are not registered."
        }
        
        isLoading = false
    }
    
    func verifyOTP(authManager: AuthManager) async {
        errorMessage = ""
        
        guard isOtpFormValid else {
            errorMessage = "Please enter the 6-digit verification code."
            return
        }
        
        let cleanedEmail = emailOrPhone.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanedToken = otpToken.trimmingCharacters(in: .whitespacesAndNewlines)
        isLoading = true
        
        let success = await authManager.verifyRecoveryOTP(email: cleanedEmail, token: cleanedToken)
        if success {
            currentStep = .resetPassword
            errorMessage = ""
        } else {
            errorMessage = authManager.errorMessage ?? "Invalid code. Please try again."
        }
        
        isLoading = false
    }
    
    func resetPassword(authManager: AuthManager) async -> Bool {
        errorMessage = ""
        
        guard isResetFormValid else {
            errorMessage = "Please make sure your password is strong and matches."
            return false
        }
        
        isLoading = true
        let success = await authManager.updatePassword(newPassword: newPassword)
        
        if success {
            showSuccessMessage = true
            errorMessage = ""
        } else {
            errorMessage = authManager.errorMessage ?? "Failed to reset password. Please try again."
        }
        
        isLoading = false
        return success
    }
    
    func resetWizard() {
        emailOrPhone = ""
        otpToken = ""
        newPassword = ""
        confirmPassword = ""
        currentStep = .email
        errorMessage = ""
        showSuccessMessage = false
        isLoading = false
    }
}
