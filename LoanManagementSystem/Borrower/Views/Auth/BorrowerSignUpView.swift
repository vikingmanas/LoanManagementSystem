import SwiftUI

struct BorrowerSignUpView: View {
    var body: some View {
        MockSignUpView()
    }
}

struct MockSignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = SignUpViewModel()

    var body: some View {
        ZStack {
            Color.AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {


                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create Account")
                            .font(Font.AppTheme.title)
                            .foregroundStyle(Color.AppTheme.textPrimary)

                        Text("Create your borrower account securely.")
                            .font(Font.AppTheme.subtitle)
                            .foregroundStyle(Color.AppTheme.textSecondary)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)


                    if !viewModel.generalError.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(viewModel.generalError)
                                .font(Font.AppTheme.caption)
                            Spacer()
                        }
                        .padding()
                        .background(Color.AppTheme.error.opacity(0.1))
                        .foregroundStyle(Color.AppTheme.error)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }


                    VStack(spacing: 16) {
                        CustomTextField(
                            icon: "person",
                            placeholder: "Full Name",
                            text: $viewModel.fullName
                        )

                        CustomTextField(
                            icon: "envelope",
                            placeholder: "Email Address",
                            text: $viewModel.email
                        )

                        CustomTextField(
                            icon: "phone",
                            placeholder: "Mobile Number",
                            text: $viewModel.phone
                        )

                        CustomTextField(
                            icon: "phone.fill",
                            placeholder: "Alternate Mobile Number (Optional)",
                            text: $viewModel.alternatePhone
                        )
                        .keyboardType(.phonePad)

                        CustomTextField(
                            icon: "tag",
                            placeholder: "Referral Code (Optional)",
                            text: $viewModel.referralCode
                        )
                        .textInputAutocapitalization(.characters)

                        VStack(alignment: .leading, spacing: 12) {
                            SecureInputField(
                                placeholder: "Password",
                                text: $viewModel.password
                            )


                            if !viewModel.password.isEmpty {
                                PasswordStrengthView(
                                    isMinLength: viewModel.isMinLength,
                                    hasUppercase: viewModel.hasUppercase,
                                    hasNumber: viewModel.hasNumber,
                                    hasSpecialChar: viewModel.hasSpecialChar
                                )
                                .padding(.horizontal, 4)
                            }
                        }

                        SecureInputField(
                            placeholder: "Confirm Password",
                            text: $viewModel.confirmPassword
                        )
                    }


                    VStack(alignment: .leading, spacing: 12) {
                        CheckboxView(isChecked: $viewModel.acceptedTerms, label: "I accept the Terms and Conditions")
                        CheckboxView(isChecked: $viewModel.acceptedPrivacy, label: "I agree to the Privacy Policy")
                    }
                    .padding(.top, 8)


                    PrimaryButton(
                        title: "Create Account",
                        isLoading: viewModel.isLoading,
                        isDisabled: !viewModel.isFormValid,
                        action: {
                            Task {
                                await viewModel.signUp(authManager: authManager)
                            }
                        }
                    )
                    .padding(.top, 16)

                    Spacer(minLength: 40)


                    HStack {
                        Spacer()
                        Text("Already have an account?")
                            .font(Font.AppTheme.body)
                            .foregroundStyle(Color.AppTheme.textSecondary)

                        Button(action: {
                            dismiss()
                        }) {
                            Text("Sign In")
                                .font(Font.AppTheme.body)
                                .fontWeight(.bold)
                                .foregroundStyle(Color.AppTheme.primary)
                        }
                        Spacer()
                    }
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
            }
        }
        .hideNavigationBar()
        .onChange(of: viewModel.showSuccess) { _, success in
            if success {
                appState.login()
            }
        }
    }
}
#Preview("BorrowerSignUpView") {
    BorrowerSignUpView()
        .environmentObject(AppStateManager())
        .environmentObject(AuthManager())
}

#Preview("MockSignUpView") {
    MockSignUpView()
        .environmentObject(AppStateManager())
        .environmentObject(AuthManager())
}

