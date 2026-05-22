import SwiftUI

struct BorrowerForgotPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = ForgotPasswordViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.AppTheme.background.ignoresSafeArea()
                
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Forgot Password")
                            .font(Font.AppTheme.title)
                            .foregroundColor(Color.AppTheme.textPrimary)
                        
                        Text("Recover your account with a secure email reset link.")
                            .font(Font.AppTheme.subtitle)
                            .foregroundColor(Color.AppTheme.textSecondary)
                    }
                    .padding(.top, 20)
                    
                    // Error / Success Banner
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
                    } else if viewModel.showSuccessMessage {
                        HStack {
                            Image(systemName: "checkmark.seal.fill")
                            Text("Reset link sent! Please check your email inbox.")
                                .font(Font.AppTheme.caption)
                            Spacer()
                        }
                        .padding()
                        .background(Color.AppTheme.success.opacity(0.1))
                        .foregroundColor(Color.AppTheme.success)
                        .cornerRadius(8)
                    }
                    
                    // Input Field
                    CustomTextField(
                        icon: "envelope",
                        placeholder: "Email Address",
                        text: $viewModel.emailOrPhone
                    )
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    // Options buttons
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
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                                .fontWeight(.bold)
                            Text("Back")
                                .font(Font.AppTheme.body)
                        }
                        .foregroundColor(Color.AppTheme.primary)
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
