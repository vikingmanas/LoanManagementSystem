import SwiftUI

struct AdminSignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = AdminSignUpViewModel()

    var body: some View {
        ZStack {
            Color.AppTheme.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create Admin Account")
                            .font(Font.AppTheme.title)
                            .foregroundStyle(Color.AppTheme.textPrimary)

                        Text("Register a new system administrator.")
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

                    if viewModel.showSuccess {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Admin account created successfully! You can now sign in.")
                                .font(Font.AppTheme.caption)
                            Spacer()
                        }
                        .padding()
                        .background(LMSColors.emerald.opacity(0.1))
                        .foregroundStyle(LMSColors.emerald)
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
                        .keyboardType(.phonePad)

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

                    PrimaryButton(
                        title: "Create Admin",
                        isLoading: viewModel.isLoading,
                        isDisabled: !viewModel.isFormValid || viewModel.showSuccess,
                        action: {
                            Task {
                                await viewModel.signUpAdmin()
                            }
                        }
                    )
                    .padding(.top, 16)

                    Spacer(minLength: 40)

                    HStack {
                        Spacer()
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Back to Role Selection")
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
    }
}

#Preview {
    AdminSignUpView()
}
