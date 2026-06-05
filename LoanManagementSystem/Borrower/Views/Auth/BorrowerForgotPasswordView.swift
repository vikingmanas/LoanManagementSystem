import SwiftUI

struct BorrowerForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) var authManager: AuthManager
    @State private var viewModel = ForgotPasswordViewModel()

    var body: some View {
        ZStack {
            Color.AppTheme.background.ignoresSafeArea()

            VStack(alignment: .leading, spacing: LMSSpacing.xxl) {
                
                // Title Header Section
                VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                    Text(headerTitle)
                        .font(LMSFont.largeTitle)
                        .foregroundStyle(Color.AppTheme.textPrimary)

                    Text(headerSubtitle)
                        .font(LMSFont.subheadline)
                        .foregroundStyle(Color.AppTheme.textSecondary)
                }
                .padding(.top, 20)

                // Error Message Banner
                if !viewModel.errorMessage.isEmpty {
                    HStack(spacing: LMSSpacing.xs) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text(viewModel.errorMessage)
                            .font(LMSFont.caption)
                        Spacer()
                    }
                    .padding()
                    .background(Color.AppTheme.error.opacity(0.1))
                    .foregroundStyle(Color.AppTheme.error)
                    .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
                    .transition(.move(edge: .top).combined(with: .opacity))
                } 
                
                // Success Message Banner
                if viewModel.showSuccessMessage {
                    HStack(spacing: LMSSpacing.xs) {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Password updated successfully! Please log in with your new password.")
                            .font(LMSFont.caption)
                        Spacer()
                    }
                    .padding()
                    .background(Color.AppTheme.success.opacity(0.1))
                    .foregroundStyle(Color.AppTheme.success)
                    .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
                    .transition(.move(edge: .top).combined(with: .opacity))
                }

                // Content based on Current Step
                switch viewModel.currentStep {
                case .email:
                    emailStepView
                case .otp:
                    otpStepView
                case .resetPassword:
                    resetPasswordStepView
                }

                Spacer()

                // Action Button
                PrimaryButton(
                    title: buttonTitle,
                    isLoading: viewModel.isLoading,
                    isDisabled: isButtonDisabled || viewModel.showSuccessMessage,
                    action: {
                        Task {
                            await handleButtonAction()
                        }
                    }
                )
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    handleBackButton()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.body.weight(.bold))
                        .foregroundStyle(Color.AppTheme.primary)
                }
                .disabled(viewModel.isLoading || viewModel.showSuccessMessage)
            }
        }
    }

    // MARK: - Step Views

    private var emailStepView: some View {
        CustomTextField(
            icon: "envelope.fill",
            placeholder: "Email Address",
            text: $viewModel.emailOrPhone,
            keyboardType: .emailAddress
        )
        .padding(.top, 8)
    }

    private var otpStepView: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            CustomTextField(
                icon: "key.fill",
                placeholder: "6-Digit Code",
                text: $viewModel.otpToken,
                keyboardType: .numberPad
            )
            .onChange(of: viewModel.otpToken) {
                // Allow only digits, max 6 characters
                let filtered = viewModel.otpToken.filter { $0.isNumber }
                if filtered.count > 6 {
                    viewModel.otpToken = String(filtered.prefix(6))
                } else if filtered != viewModel.otpToken {
                    viewModel.otpToken = filtered
                }
            }
            .padding(.top, 8)
            
            Button(action: {
                Task {
                    await viewModel.sendResetCode(authManager: authManager)
                }
            }) {
                Text("Resend Code")
                    .font(LMSFont.footnote.weight(.semibold))
                    .foregroundStyle(Color.AppTheme.primary)
            }
            .disabled(viewModel.isLoading)
            .padding(.leading, LMSSpacing.xs)
        }
    }

    private var resetPasswordStepView: some View {
        VStack(spacing: LMSSpacing.lg) {
            SecureInputField(
                placeholder: "New Password",
                text: $viewModel.newPassword
            )
            
            if !viewModel.newPassword.isEmpty {
                PasswordStrengthView(
                    isMinLength: viewModel.isMinLength,
                    hasUppercase: viewModel.hasUppercase,
                    hasNumber: viewModel.hasNumber,
                    hasSpecialChar: viewModel.hasSpecialChar
                )
                .padding(.horizontal, LMSSpacing.sm)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            SecureInputField(
                placeholder: "Confirm New Password",
                text: $viewModel.confirmPassword,
                isError: viewModel.showConfirmPasswordError,
                errorMessage: viewModel.showConfirmPasswordError ? "Passwords do not match" : ""
            )
        }
    }

    // MARK: - Dynamic Headers & Buttons

    private var headerTitle: String {
        switch viewModel.currentStep {
        case .email:
            return "Forgot Password"
        case .otp:
            return "Verify Code"
        case .resetPassword:
            return "Reset Password"
        }
    }

    private var headerSubtitle: String {
        switch viewModel.currentStep {
        case .email:
            return "Recover your account with a secure in-app verification code."
        case .otp:
            return "Please enter the verification code sent to \(viewModel.emailOrPhone)."
        case .resetPassword:
            return "Create a new strong password for your account."
        }
    }

    private var buttonTitle: String {
        switch viewModel.currentStep {
        case .email:
            return "Send Reset Code"
        case .otp:
            return "Verify Code"
        case .resetPassword:
            return "Reset Password"
        }
    }

    private var isButtonDisabled: Bool {
        switch viewModel.currentStep {
        case .email:
            return !viewModel.isEmailFormValid
        case .otp:
            return !viewModel.isOtpFormValid
        case .resetPassword:
            return !viewModel.isResetFormValid
        }
    }

    // MARK: - Helper Actions

    private func handleButtonAction() async {
        switch viewModel.currentStep {
        case .email:
            await viewModel.sendResetCode(authManager: authManager)
            if viewModel.errorMessage.isEmpty {
                HapticsManager.triggerImpact(style: .medium)
            } else {
                HapticsManager.triggerNotification(type: .error)
            }
        case .otp:
            await viewModel.verifyOTP(authManager: authManager)
            if viewModel.errorMessage.isEmpty {
                HapticsManager.triggerImpact(style: .medium)
            } else {
                HapticsManager.triggerNotification(type: .error)
            }
        case .resetPassword:
            let success = await viewModel.resetPassword(authManager: authManager)
            if success {
                HapticsManager.triggerNotification(type: .success)
                // Dismiss back to login after a short delay so user sees the success message
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    viewModel.resetWizard()
                    dismiss()
                }
            } else {
                HapticsManager.triggerNotification(type: .error)
            }
        }
    }

    private func handleBackButton() {
        switch viewModel.currentStep {
        case .email:
            dismiss()
        case .otp:
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                viewModel.currentStep = .email
                viewModel.otpToken = ""
                viewModel.errorMessage = ""
            }
        case .resetPassword:
            // Abort the flow: sign out the recovery session and go back to login
            authManager.isResettingPassword = false
            authManager.signOut()
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                viewModel.resetWizard()
            }
            dismiss()
        }
    }
}

#Preview {
    BorrowerForgotPasswordView()
        .environment(AuthManager.shared)
}
