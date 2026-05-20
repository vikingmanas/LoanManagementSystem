import SwiftUI

struct BorrowerSignUpView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var appState: AppStateManager
    @StateObject private var viewModel = SignUpViewModel()
    
    var body: some View {
        ZStack {
            Color.AppTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Header Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create Account")
                            .font(Font.AppTheme.title)
                            .foregroundColor(Color.AppTheme.textPrimary)
                        
                        Text("Create your borrower account securely.")
                            .font(Font.AppTheme.subtitle)
                            .foregroundColor(Color.AppTheme.textSecondary)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 10)
                    
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
                        .autocapitalization(.allCharacters)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            SecureInputField(
                                placeholder: "Password",
                                text: $viewModel.password
                            )
                            
                            // Password Strength Indicator
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
                    
                    // Checkboxes
                    VStack(alignment: .leading, spacing: 12) {
                        CheckboxView(isChecked: $viewModel.acceptedTerms, label: "I accept the Terms and Conditions")
                        CheckboxView(isChecked: $viewModel.acceptedPrivacy, label: "I agree to the Privacy Policy")
                    }
                    .padding(.top, 8)
                    
                    // Sign Up Button
                    PrimaryButton(
                        title: "Create Account",
                        isLoading: viewModel.isLoading,
                        isDisabled: !viewModel.isFormValid,
                        action: {
                            viewModel.signUp()
                        }
                    )
                    .padding(.top, 16)
                    
                    Spacer(minLength: 40)
                    
                    // Footer
                    HStack {
                        Spacer()
                        Text("Already have an account?")
                            .font(Font.AppTheme.body)
                            .foregroundColor(Color.AppTheme.textSecondary)
                        
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Sign In")
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
        .navigationDestination(isPresented: $viewModel.navigateToOTP) {
            OTPVerificationView(isForLogin: false)
        }
    }
}

struct BorrowerSignUpView_Previews: PreviewProvider {
    static var previews: some View {
        BorrowerSignUpView()
            .environmentObject(AppStateManager())
    }
}
