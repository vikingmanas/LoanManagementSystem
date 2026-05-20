import SwiftUI

struct BorrowerForgotPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
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
                        
                        Text("Choose how you would like to recover your password.")
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
                        placeholder: "Email or Mobile Number",
                        text: $viewModel.emailOrPhone
                    )
                    .padding(.top, 8)
                    
                    Spacer()
                    
                    // Options buttons
                    VStack(spacing: 12) {
                        PrimaryButton(
                            title: "Send Reset Link via Email",
                            isLoading: viewModel.isLoading && !viewModel.navigateToOTP,
                            isDisabled: !viewModel.isFormValid || viewModel.showSuccessMessage,
                            action: {
                                viewModel.sendResetLink()
                            }
                        )
                        
                        Button(action: {
                            viewModel.sendOTPCode()
                        }) {
                            HStack {
                                Spacer()
                                if viewModel.isLoading && viewModel.navigateToOTP {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color.AppTheme.primary))
                                } else {
                                    Image(systemName: "phone.bubble.left.fill")
                                        .font(.system(size: 15))
                                    Text("Recover via OTP")
                                        .font(Font.AppTheme.button)
                                }
                                Spacer()
                            }
                            .frame(height: 50)
                            .foregroundColor(Color.AppTheme.primary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.AppTheme.primary, lineWidth: 1.5)
                            )
                        }
                        .disabled(!viewModel.isFormValid || viewModel.showSuccessMessage)
                    }
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
            .navigationDestination(isPresented: $viewModel.navigateToOTP) {
                OTPVerificationView(isForLogin: false) {
                    // Navigate to password change after OTP verified
                    print("OTP Verified for Password Reset")
                }
            }
        }
    }
}

#Preview {
    BorrowerForgotPasswordView()
}
