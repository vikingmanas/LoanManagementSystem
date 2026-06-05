import SwiftUI

struct StaffOTPVerificationView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(AppStateManager.self) var appState: AppStateManager
    @Environment(AuthManager.self) var authManager: AuthManager

    let email: String
    let pendingRole: String

    @State private var otp: String = ""
    @State private var errorMessage: String = ""
    @State private var isVerifying: Bool = false
    @State private var isResending: Bool = false
    
    var body: some View {
        ZStack {
            Color.AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                
                VStack(spacing: 8) {
                    Image(systemName: "envelope.badge.shield.half.filled")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(LMSColors.actionBlue)
                        .padding(.bottom, 8)
                    
                    Text("Verify Your Identity")
                        .font(Font.AppTheme.title)
                        .foregroundColor(Color.AppTheme.textPrimary)
                    
                    Text("We sent a 6-digit verification code to\n\(email)")
                        .font(Font.AppTheme.subtitle)
                        .foregroundColor(Color.AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                if !errorMessage.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(errorMessage)
                    }
                    .font(Font.AppTheme.caption)
                    .foregroundColor(Color.AppTheme.error)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.AppTheme.error.opacity(0.1))
                    .cornerRadius(12)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Verification Code")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.AppTheme.textSecondary)
                    
                    TextField("Enter 6-digit OTP", text: $otp)
                        .keyboardType(.numberPad)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color.AppTheme.secondary)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(LMSColors.separatorLight, lineWidth: 1)
                        )
                        .onChange(of: otp) { oldValue, newValue in
                            if newValue.count > 6 {
                                otp = String(newValue.prefix(6))
                            }
                        }
                }
                
                Button {
                    verifyOTP()
                } label: {
                    HStack {
                        if isVerifying {
                            ProgressView()
                                .tint(.white)
                                .padding(.trailing, 4)
                        }
                        Text("Verify & Sign In")
                            .font(LMSFont.button)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                }
                .buttonStyle(.borderedProminent)
                .tint(LMSColors.actionBlue)
                .disabled(otp.count != 6 || isVerifying)
                
                Button {
                    resendOTP()
                } label: {
                    HStack {
                        if isResending {
                            ProgressView()
                                .tint(LMSColors.actionBlue)
                                .padding(.trailing, 4)
                        }
                        Text("Didn't receive code? Resend")
                            .font(Font.AppTheme.caption.weight(.semibold))
                    }
                }
                .foregroundColor(LMSColors.actionBlue)
                .disabled(isResending)
                .padding(.top, 8)
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color.AppTheme.textPrimary)
                }
            }
        }
    }
    
    private func verifyOTP() {
        errorMessage = ""
        isVerifying = true
        
        Task {
            let result = await authManager.verifyEmailOTP(email: email, token: otp)
            isVerifying = false
            
            if result.success {
                HapticsManager.triggerImpact(style: .heavy)
                
                switch pendingRole {
                case "admin":
                    appState.selectedRole = .admin
                case "manager", "loan_manager":
                    appState.selectedRole = .bankManager
                case "loan_officer":
                    appState.selectedRole = .loanOfficer
                default:
                    appState.selectedRole = .customer
                }
                
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    appState.login()
                }
            } else {
                HapticsManager.triggerImpact(style: .light)
                errorMessage = authManager.errorMessage ?? "Invalid OTP code. Please try again."
            }
        }
    }
    
    private func resendOTP() {
        errorMessage = ""
        isResending = true
        
        Task {
            let success = await authManager.sendEmailOTP(email: email)
            isResending = false
            
            if success {
                HapticsManager.triggerImpact(style: .medium)
            } else {
                errorMessage = authManager.errorMessage ?? "Failed to resend code."
            }
        }
    }
}
