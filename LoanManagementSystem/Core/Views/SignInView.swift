import SwiftUI

struct SignInView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = SignInViewModel()
    @State private var showBankAccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    Spacer()
                        .frame(width: 0, height: 90)
                    VStack(alignment: .leading, spacing: LMSSpacing.xxl) {
                        // Header
                        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                            Text("Welcome")
                                .font(LMSFont.largeTitle)
                                .foregroundStyle(LMSColors.textPrimary)
                            
                        }
                        .padding(.top, LMSSpacing.sm)

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
                            Picker("Sign In Mode", selection: $viewModel.signInMode) {
                                ForEach(BorrowerSignInMode.allCases) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)

                            CustomTextField(
                                icon: "envelope",
                                placeholder: "Email Address",
                                text: $viewModel.emailOrPhone,
                                isError: !viewModel.emailError.isEmpty,
                                errorMessage: viewModel.emailError,
                                keyboardType: .emailAddress
                            )

                            if viewModel.signInMode == .password {
                                SecureInputField(
                                    placeholder: "Password",
                                    text: $viewModel.password,
                                    isError: !viewModel.passwordError.isEmpty,
                                    errorMessage: viewModel.passwordError
                                )
                            } else if viewModel.isOTPSent {
                                CustomTextField(
                                    icon: "number",
                                    placeholder: "6-digit OTP",
                                    text: $viewModel.otpCode,
                                    isError: !viewModel.otpError.isEmpty,
                                    errorMessage: viewModel.otpError,
                                    keyboardType: .numberPad
                                )

                                Button {
                                    Task { await viewModel.sendEmailOTP(authManager: authManager) }
                                } label: {
                                    Text("Resend OTP")
                                        .font(LMSFont.footnote.weight(.semibold))
                                        .foregroundStyle(LMSColors.brandNavy)
                                }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            } else {
                                HStack(spacing: 10) {
                                    Image(systemName: "envelope.badge.shield.half.filled")
                                        .foregroundStyle(LMSColors.brandNavy)
                                    Text("We will send a Supabase OTP to your registered email.")
                                        .font(LMSFont.caption)
                                        .foregroundStyle(LMSColors.textSecondary)
                                    Spacer()
                                }
                                .padding(LMSSpacing.lg)
                                .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
                            }
                        }
                        Spacer()
                            .frame(width:0,height:7)
                        // Secondary actions
                        HStack(alignment:.center) {
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
                            title: primaryButtonTitle,
                            isLoading: viewModel.isLoading,
                            isDisabled: !viewModel.isFormValid,
                            action: {
                                Task {
                                    switch viewModel.signInMode {
                                    case .password:
                                        await viewModel.signIn(authManager: authManager, appState: appState)
                                    case .emailOTP:
                                        if viewModel.isOTPSent {
                                            await viewModel.verifyEmailOTP(authManager: authManager, appState: appState)
                                        } else {
                                            await viewModel.sendEmailOTP(authManager: authManager)
                                        }
                                    }
                                }
                            }
                        )
                        .padding(.top, LMSSpacing.sm)

                        

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
                        staffLoginButton
                            .padding(.bottom, LMSSpacing.xl)
                    }
                    .padding(.horizontal, LMSSpacing.xxl)
                }
            }
            .lmsScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .hideNavigationBar()
            .sheet(isPresented: $showBankAccess) {
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

    private var primaryButtonTitle: String {
        switch viewModel.signInMode {
        case .password:
            return "Sign In"
        case .emailOTP:
            return viewModel.isOTPSent ? "Verify OTP" : "Send OTP"
        }
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
        .environmentObject(AppStateManager())
        .environmentObject(AuthManager())
}
