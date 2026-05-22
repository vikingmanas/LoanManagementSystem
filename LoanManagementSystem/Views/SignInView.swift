import SwiftUI

struct SignInView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = SignInViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: LMSSpacing.xxl) {

                        // Back to roles
                        Button(action: {
                            HapticsManager.triggerImpact(style: .medium)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                appState.showRoleSelection = true
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("Back to Roles")
                            }
                            .font(LMSFont.subheadline.weight(.semibold))
                            .foregroundStyle(LMSColors.brandNavy)
                        }
                        .padding(.top, LMSSpacing.lg)

                        // Header
                        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                            Text("Welcome Back")
                                .font(LMSFont.largeTitle)
                                .foregroundStyle(LMSColors.textPrimary)

                            Text("Sign in securely to manage your loans.")
                                .font(LMSFont.subheadline)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                        .padding(.bottom, LMSSpacing.sm)

                        // Error banner
                        if !viewModel.generalError.isEmpty {
                            HStack(alignment: .top, spacing: LMSSpacing.sm) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(LMSColors.coral)
                                Text(viewModel.generalError)
                                    .font(LMSFont.caption)
                                    .foregroundStyle(LMSColors.coral)
                                Spacer()
                            }
                            .padding(LMSSpacing.lg)
                            .background(LMSColors.coral.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // Fields
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

                        // Secondary actions
                        HStack {
                            CheckboxView(isChecked: $viewModel.rememberMe, label: "Remember Me")

                            Spacer()

                            NavigationLink(destination: BorrowerForgotPasswordView()) {
                                Text("Forgot Password?")
                                    .font(LMSFont.footnote.weight(.semibold))
                                    .foregroundStyle(LMSColors.brandNavy)
                            }
                        }

                        // Sign In
                        PrimaryButton(
                            title: "Sign In",
                            icon: "arrow.right",
                            isLoading: viewModel.isLoading,
                            isDisabled: !viewModel.isFormValid,
                            action: {
                                Task {
                                    await viewModel.signIn(authManager: authManager)
                                }
                            }
                        )
                        .padding(.top, LMSSpacing.sm)

                        // Divider
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

                        // Sign Up link
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
                    }
                    .padding(.horizontal, LMSSpacing.xxl)
                }
            }
            .lmsScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .hideNavigationBar()
            .onChange(of: viewModel.showSuccess) { _, success in
                if success {
                    appState.login()
                }
            }
        }
    }
}

#Preview {
    SignInView()
        .environmentObject(AppStateManager())
        .environmentObject(AuthManager())
}
