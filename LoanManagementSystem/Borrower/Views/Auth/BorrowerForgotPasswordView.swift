import SwiftUI

struct BorrowerForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = ForgotPasswordViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color.AppTheme.background.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 24) {


                    VStack(alignment: .leading, spacing: 8) {
                        Text("Forgot Password")
                            .font(Font.AppTheme.title)
                            .foregroundStyle(Color.AppTheme.textPrimary)

                        Text("Recover your account with a secure email reset link.")
                            .font(Font.AppTheme.subtitle)
                            .foregroundStyle(Color.AppTheme.textSecondary)
                    }
                    .padding(.top, 20)


                    if !viewModel.errorMessage.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                            Text(viewModel.errorMessage)
                                .font(Font.AppTheme.caption)
                            Spacer()
                        }
                        .padding()
                        .background(Color.AppTheme.error.opacity(0.1))
                        .foregroundStyle(Color.AppTheme.error)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    } else if viewModel.showSuccessMessage {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Reset link sent! Please check your email inbox.")
                                .font(Font.AppTheme.caption)
                            Spacer()
                        }
                        .padding()
                        .background(Color.AppTheme.success.opacity(0.1))
                        .foregroundStyle(Color.AppTheme.success)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }


                    CustomTextField(
                        icon: "envelope",
                        placeholder: "Email Address",
                        text: $viewModel.emailOrPhone
                    )
                    .padding(.top, 8)

                    Spacer()


                    PrimaryButton(
                        title: "Send Reset Link via Email",
                        isLoading: viewModel.isLoading,
                        isDisabled: !viewModel.isFormValid || viewModel.showSuccessMessage,
                        action: {
                            Task {
                                await viewModel.sendResetLink(authManager: authManager)
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
                        dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .fontWeight(.bold)
                            Text("Back")
                                .font(Font.AppTheme.body)
                        }
                        .foregroundStyle(Color.AppTheme.primary)
                    }
                }
            }
        }
    }
}

#Preview {
    BorrowerForgotPasswordView()
        .environmentObject(AuthManager())
}

