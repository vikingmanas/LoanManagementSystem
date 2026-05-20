import SwiftUI

struct SignInView: View {
    @EnvironmentObject var appState: AppStateManager
    @StateObject private var viewModel = SignInViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Header Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Welcome Back")
                                .font(Font.AppTheme.title)
                                .foregroundColor(Color.AppTheme.textPrimary)
                            
                            Text("Login securely to manage your loans.")
                                .font(Font.AppTheme.subtitle)
                                .foregroundColor(Color.AppTheme.textSecondary)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 20)
                        
                        // Error Banner
                        if !viewModel.generalError.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(viewModel.generalError)
                                    .font(Font.AppTheme.caption)
                                Spacer()
                            }
                            .padding()
                            .background(Color.AppTheme.error.opacity(0.1))
                            .foregroundColor(Color.AppTheme.error)
                            .cornerRadius(8)
                        }
                        
                        // Input Fields
                        VStack(spacing: 16) {
                            CustomTextField(
                                icon: "envelope",
                                placeholder: "Email or Mobile Number",
                                text: $viewModel.emailOrPhone,
                                isError: !viewModel.emailError.isEmpty,
                                errorMessage: viewModel.emailError
                            )
                            
                            SecureInputField(
                                placeholder: "Password",
                                text: $viewModel.password,
                                isError: !viewModel.passwordError.isEmpty,
                                errorMessage: viewModel.passwordError
                            )
                        }
                        
                        // Secondary Actions
                        HStack {
                            CheckboxView(isChecked: $viewModel.rememberMe, label: "Remember Me")
                            
                            Spacer()
                            
                            NavigationLink(destination: BorrowerForgotPasswordView()) {
                                Text("Forgot Password?")
                                    .font(Font.AppTheme.body)
                                    .fontWeight(.semibold)
                                    .foregroundColor(Color.AppTheme.primary)
                            }
                        }
                        .padding(.top, 4)
                        
                        // Action Buttons
                        PrimaryButton(
                            title: "Sign In",
                            isLoading: viewModel.isLoading,
                            isDisabled: !viewModel.isFormValid,
                            action: {
                                viewModel.signIn()
                            }
                        )
                        .padding(.top, 8)
                        
                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                            Text("OR")
                                .font(Font.AppTheme.caption)
                                .foregroundColor(Color.AppTheme.textSecondary)
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(height: 1)
                        }
                        .padding(.vertical, 16)
                       
                        HStack {
                            Spacer()
                            Text("Don't have an account?")
                                .font(Font.AppTheme.body)
                                .foregroundColor(Color.AppTheme.textSecondary)
                            
                            NavigationLink(destination: BorrowerSignUpView()) {
                                Text("Sign Up")
                                    .font(Font.AppTheme.body)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.AppTheme.primary)
                            }
                            Spacer()
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .hideNavigationBar()
            .onChange(of: viewModel.showSuccess) { success in
                if success {
                    appState.login()
                }
            }

        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
            .environmentObject(AppStateManager())
    }
}
