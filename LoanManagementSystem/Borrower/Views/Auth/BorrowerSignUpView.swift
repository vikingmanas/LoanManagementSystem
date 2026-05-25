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
        NavigationStack {
            Form {
                // Header Information
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create Account")
                            .font(.system(.largeTitle, design: .rounded).bold())
                            .foregroundStyle(LMSColors.brandNavy)
                        
                        Text("Join our platform to manage your loans securely and easily.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 20, trailing: 0))
                }
                
                // Personal Information
                Section(header: Text("Personal Details")) {
                    LabeledContent("Name") {
                        TextField("Full Name", text: $viewModel.fullName)
                            .textContentType(.name)
                    }
                    
                    LabeledContent("Email") {
                        TextField("example@mail.com", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                    }
                    
                    LabeledContent("Mobile") {
                        TextField("Phone Number", text: $viewModel.phone)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                    }
                }
                
                // Additional Information (Optional)
                Section(header: Text("Optional Details")) {
                    LabeledContent("Alt. Mobile") {
                        TextField("Optional", text: $viewModel.alternatePhone)
                            .keyboardType(.phonePad)
                    }
                    
                    LabeledContent("Referral") {
                        TextField("Code", text: $viewModel.referralCode)
                            .textInputAutocapitalization(.characters)
                    }
                }
                
                // Security
                Section(header: Text("Security"), footer: passwordRequirementsFooter) {
                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirm Password", text: $viewModel.confirmPassword)
                        .textContentType(.newPassword)
                }
                
                // Agreements
                Section {
                    Toggle("Accept Terms & Conditions", isOn: $viewModel.acceptedTerms)
                        .tint(LMSColors.brandNavy)
                    Toggle("Agree to Privacy Policy", isOn: $viewModel.acceptedPrivacy)
                        .tint(LMSColors.brandNavy)
                }
                
                // Action
                Section {
                    Button {
                        Task {
                            HapticsManager.triggerImpact(style: .medium)
                            await viewModel.signUp(authManager: authManager)
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Create Account")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!viewModel.isFormValid || viewModel.isLoading)
                    .listRowBackground(viewModel.isFormValid ? LMSColors.brandNavy : Color.gray.opacity(0.3))
                    .foregroundStyle(.white)
                }
                
                // Error Section
                if !viewModel.generalError.isEmpty {
                    Section {
                        Label(viewModel.generalError, systemImage: "exclamationmark.triangle.fill")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(.red)
                    }
                }
                
                // Footer
                Section {
                    HStack {
                        Spacer()
                        Text("Already have an account?")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Button("Sign In") {
                            dismiss()
                        }
                        .font(.subheadline.bold())
                        .foregroundStyle(LMSColors.brandNavy)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image(systemName: "indianrupeesign.circle.fill")
                        .foregroundStyle(LMSColors.brandNavy)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .onChange(of: viewModel.showSuccess) { _, success in
            if success {
                appState.login()
            }
        }
    }
    
    private var passwordRequirementsFooter: some View {
        VStack(alignment: .leading, spacing: 4) {
            RequirementRow(isMet: viewModel.isMinLength, text: "At least 8 characters")
            RequirementRow(isMet: viewModel.hasUppercase, text: "One uppercase letter")
            RequirementRow(isMet: viewModel.hasNumber, text: "One number")
            RequirementRow(isMet: viewModel.hasSpecialChar, text: "One special character")
        }
        .padding(.top, 4)
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
