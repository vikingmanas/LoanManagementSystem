import SwiftUI

struct SignInView: View {
    @Environment(AppStateManager.self) var appState: AppStateManager
    @Environment(AuthManager.self) var authManager: AuthManager
    @State private var viewModel = SignInViewModel()
    @State private var showBankAccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    Spacer()
                        .frame(width: 0, height: 90)

                    if viewModel.isOtpStep {
                        otpVerificationStep
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else {
                        credentialsStep
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading).combined(with: .opacity),
                                removal: .move(edge: .trailing).combined(with: .opacity)
                            ))
                    }
                }
            }
            .lmsScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .hideNavigationBar()
            .accessibleSheet(isPresented: $showBankAccess) {
                BankRoleAccessSheet { role in
                    HapticsManager.triggerImpact(style: .heavy)
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                        appState.selectedRole = role
                    }
                }
            }
            .onChange(of: viewModel.showSuccess) { _, success in
                if success {
                    appState.login()
                }
            }
        }
    }


    private var credentialsStep: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.xxl) {
            VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                Text("Welcome")
                    .font(LMSFont.largeTitle)
                    .foregroundStyle(LMSColors.textPrimary)
                
            }
            .padding(.top, LMSSpacing.sm)

            if !viewModel.generalError.isEmpty {
                errorBanner(message: viewModel.generalError)
            }
            
            VStack(spacing: LMSSpacing.lg) {

                CustomTextField(
                    icon: "envelope",
                    placeholder: "Email Address",
                    text: $viewModel.emailOrPhone,
                    isError: !viewModel.emailError.isEmpty,
                    errorMessage: viewModel.emailError,
                    keyboardType: .emailAddress
                )

                SecureInputField(
                    placeholder: "Password",
                    text: $viewModel.password,
                    isError: !viewModel.passwordError.isEmpty,
                    errorMessage: viewModel.passwordError
                )
            }
            Spacer()
                .frame(width:0,height:7)
            HStack(alignment:.center) {
                CheckboxView(isChecked: $viewModel.rememberMe, label: "Remember Me")

                Spacer()

                NavigationLink(destination: BorrowerForgotPasswordView()) {
                    Text("Forgot Password?")
                        .font(LMSFont.footnote.weight(.semibold))
                        .foregroundStyle(LMSColors.brandNavy)
                }
            }

            PrimaryButton(
                title: "Sign In",
                isLoading: viewModel.isLoading,
                isDisabled: !viewModel.isFormValid,
                action: {
                    Task {
                        await viewModel.signIn(authManager: authManager, appState: appState)
                    }
                }
            )
            .padding(.top, LMSSpacing.sm)

            

            HStack {
                Spacer()
                Text("Don't have an account?")
                    .font(LMSFont.footnote)
                    .foregroundStyle(LMSColors.textSecondary)

                NavigationLink(destination: BorrowerSignUpView()) {
                    Text("Sign Up")
                        .font(LMSFont.footnote.weight(.bold))
                        .foregroundStyle(LMSColors.brandNavy)
                }
                Spacer()
            }
            .padding(.bottom, LMSSpacing.xxxl)
            HStack(spacing: LMSSpacing.md) {
                Rectangle()
                    .fill(LMSColors.separator)
                    .frame(height: 0.5)
                Text("OR")
                    .font(LMSFont.caption.weight(.medium))
                    .foregroundStyle(LMSColors.textTertiary)
                Rectangle()
                    .fill(LMSColors.separator)
                    .frame(height: 0.5)
            }
            staffLoginButton
                .padding(.bottom, LMSSpacing.xl)
        }
        .padding(.horizontal, LMSSpacing.xxl)
    }


    private var otpVerificationStep: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.xxl) {
            Button {
                HapticsManager.triggerImpact(style: .light)
                viewModel.goBackToCredentials()
            } label: {
                HStack(spacing: LMSSpacing.xs) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                    Text("Back")
                        .font(LMSFont.footnote.weight(.semibold))
                }
                .foregroundStyle(LMSColors.brandNavy)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)

            VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                Text("Verify Your Identity")
                    .font(LMSFont.largeTitle)
                    .foregroundStyle(LMSColors.textPrimary)

                Text("Enter the 6-digit verification code sent to your email.")
                    .font(LMSFont.subheadline)
                    .foregroundStyle(LMSColors.textSecondary)
            }

            if !viewModel.otpSentMessage.isEmpty {
                HStack(alignment: .top, spacing: LMSSpacing.sm) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(LMSColors.emerald)
                    Text(viewModel.otpSentMessage)
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.emerald)
                    Spacer()
                }
                .padding(LMSSpacing.lg)
                .background(LMSColors.emerald.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if !viewModel.generalError.isEmpty {
                errorBanner(message: viewModel.generalError)
            }

            if !viewModel.otpError.isEmpty {
                errorBanner(message: viewModel.otpError)
            }

            VStack(alignment: .leading, spacing: LMSSpacing.md) {
                CustomTextField(
                    icon: "key.fill",
                    placeholder: "6-Digit Verification Code",
                    text: $viewModel.otpCode,
                    keyboardType: .numberPad
                )
                .onChange(of: viewModel.otpCode) {
                    let filtered = viewModel.otpCode.filter { $0.isNumber }
                    if filtered.count > 6 {
                        viewModel.otpCode = String(filtered.prefix(6))
                    } else if filtered != viewModel.otpCode {
                        viewModel.otpCode = filtered
                    }
                }

                Button {
                    Task {
                        await viewModel.resendOTP(authManager: authManager)
                    }
                } label: {
                    Text("Resend Code")
                        .font(LMSFont.footnote.weight(.semibold))
                        .foregroundStyle(LMSColors.brandNavy)
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
                .padding(.leading, LMSSpacing.xs)
            }

            PrimaryButton(
                title: "Verify & Sign In",
                isLoading: viewModel.isLoading,
                isDisabled: !viewModel.isOtpFormValid,
                action: {
                    Task {
                        await viewModel.verifyOTP(authManager: authManager, appState: appState)
                    }
                }
            )
            .padding(.top, LMSSpacing.sm)

            Spacer()
        }
        .padding(.horizontal, LMSSpacing.xxl)
    }


    private func errorBanner(message: String) -> some View {
        HStack(alignment: .top, spacing: LMSSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(LMSColors.coral)
            Text(message)
                .font(LMSFont.caption)
                .foregroundStyle(LMSColors.coral)
            Spacer()
        }
        .padding(LMSSpacing.lg)
        .background(LMSColors.coral.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private var staffLoginButton: some View {
        HStack {

            Button {
                HapticsManager.triggerImpact(style: .medium)
                showBankAccess = true
            } label: {
                HStack(spacing: LMSSpacing.sm) {
                    Spacer()
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 15, weight: .semibold))

                    Text("Staff Login")
                        .font(LMSFont.footnote.weight(.semibold))
                    Spacer()
                }
                .foregroundStyle(LMSColors.brandNavy)
                .padding(.horizontal, LMSSpacing.lg)
                .padding(.vertical, LMSSpacing.sm)
                .background(LMSColors.brandNavy.opacity(0.08), in: Capsule())
                .overlay(
                    Capsule()
                        .stroke(LMSColors.separatorLight, lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Bank access")
            .accessibilityHint("Opens staff role selection")

            Spacer()
        }
    }
}

private struct BankRoleAccessSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onRoleSelected: (PortalRole) -> Void

    private let staffRoles: [PortalRole] = [.loanOfficer, .bankManager, .admin]

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: LMSSpacing.xl) {
                VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                    Text("Bank Access")
                        .font(LMSFont.title)
                        .foregroundStyle(LMSColors.textPrimary)

                    Text("Select your staff workspace.")
                        .font(LMSFont.subheadline)
                        .foregroundStyle(LMSColors.textSecondary)
                }
                .padding(.top, LMSSpacing.lg)

                VStack(spacing: LMSSpacing.md) {
                    ForEach(staffRoles) { role in
                        Button {
                            onRoleSelected(role)
                            dismiss()
                        } label: {
                            HStack(spacing: LMSSpacing.lg) {
                                Image(systemName: role.icon)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(LMSColors.brandNavy)
                                    .frame(width: 48, height: 48)
                                    .background(LMSColors.brandNavy.opacity(0.08), in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))

                                VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                                    Text(role.rawValue)
                                        .font(LMSFont.callout.weight(.bold))
                                        .foregroundStyle(LMSColors.textPrimary)

                                    Text(role.description)
                                        .font(LMSFont.caption)
                                        .foregroundStyle(LMSColors.textSecondary)
                                        .multilineTextAlignment(.leading)
                                        .lineLimit(2)
                                }

                                Spacer()

                                Image(systemName: "arrow.right")
                                    .font(.system(.callout, design: .rounded).weight(.bold))
                                    .foregroundStyle(LMSColors.textTertiary)
                            }
                            .padding(LMSSpacing.lg)
                            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                                    .stroke(LMSColors.separatorLight, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, LMSSpacing.xxl)
            .lmsScreenBackground()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(LMSColors.brandNavy)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    SignInView()
        .environment(AppStateManager())
        .environment(AuthManager())
}
