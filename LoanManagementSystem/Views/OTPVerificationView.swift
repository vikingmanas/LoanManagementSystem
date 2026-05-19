import SwiftUI

struct OTPVerificationView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppStateManager
    @StateObject private var viewModel = OTPViewModel()
    
    // Whether this OTP screen was triggered from Login or Signup
    var isForLogin: Bool
    
    // Callback when OTP is verified successfully
    var onVerificationSuccess: (() -> Void)? = nil
    
    var body: some View {
        ZStack {
            Color.AppTheme.background.ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    // Custom Back Button
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(Color.AppTheme.primary)
                    }
                    .padding(.bottom, 8)
                    
                    Text("Verify Your Account")
                        .font(Font.AppTheme.title)
                        .foregroundColor(Color.AppTheme.textPrimary)
                    
                    Text("We've sent a 6-digit OTP to your registered mobile number/email.")
                        .font(Font.AppTheme.subtitle)
                        .foregroundColor(Color.AppTheme.textSecondary)
                }
                .padding(.top, 10)
                
                // Error Banner
                if !viewModel.errorMessage.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(viewModel.errorMessage)
                            .font(Font.AppTheme.caption)
                        Spacer()
                    }
                    .padding()
                    .background(Color.AppTheme.error.opacity(0.1))
                    .foregroundColor(Color.AppTheme.error)
                    .cornerRadius(8)
                }
                
                // OTP Input
                VStack(spacing: 24) {
                    OTPInputView(otpCode: $viewModel.otpCode)
                    
                    HStack {
                        Text("Didn't receive the code?")
                            .font(Font.AppTheme.body)
                            .foregroundColor(Color.AppTheme.textSecondary)
                        
                        Button(action: {
                            viewModel.resendOTP()
                        }) {
                            Text(viewModel.canResend ? "Resend OTP" : "Resend in \(viewModel.timeRemaining)s")
                                .font(Font.AppTheme.body)
                                .fontWeight(.bold)
                                .foregroundColor(viewModel.canResend ? Color.AppTheme.primary : Color.gray)
                        }
                        .disabled(!viewModel.canResend)
                    }
                }
                .padding(.top, 20)
                
                Spacer()
                
                // Verify Button
                PrimaryButton(
                    title: "Verify & Continue",
                    isLoading: viewModel.isLoading,
                    isDisabled: viewModel.otpCode.count != 6,
                    action: {
                        viewModel.verifyOTP()
                    }
                )
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
        .hideNavigationBar()
        .navigationBarBackButtonHidden(true)
        .onChange(of: viewModel.showSuccess) { success in
            if success {
                if let onVerificationSuccess = onVerificationSuccess {
                    onVerificationSuccess()
                } else {
                    appState.login()
                }
            }
        }
    }
}

struct OTPVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        OTPVerificationView(isForLogin: true)
            .environmentObject(AppStateManager())
    }
}
