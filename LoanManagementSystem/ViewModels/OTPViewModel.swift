import Foundation
import Combine

class OTPViewModel: ObservableObject {
    @Published var otpCode: String = ""
    @Published var timeRemaining: Int = 30
    @Published var canResend: Bool = false
    @Published var isLoading: Bool = false
    @Published var showSuccess: Bool = false
    @Published var errorMessage: String = ""
    
    private var timerSubscription: AnyCancellable?
    
    init() {
        startTimer()
    }
    
    func startTimer() {
        timeRemaining = 30
        canResend = false
        
        timerSubscription = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                } else {
                    self.canResend = true
                    self.timerSubscription?.cancel()
                }
            }
    }
    
    func resendOTP() {
        // Logic to trigger OTP resend API
        startTimer()
    }
    
    func verifyOTP() {
        errorMessage = ""
        
        if otpCode.count != 6 {
            errorMessage = "Please enter a valid 6-digit OTP."
            return
        }
        
        isLoading = true
        
        // Mock verification API
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.isLoading = false
            if self.otpCode == "123456" {
                self.showSuccess = true
            } else {
                self.errorMessage = "Invalid OTP. Please try again or use '123456'."
            }
        }
    }
    
    deinit {
        timerSubscription?.cancel()
    }
}
