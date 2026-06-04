import SwiftUI

struct BorrowerSignUpView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppStateManager.self) var appState: AppStateManager
    @Environment(AuthManager.self) var authManager: AuthManager
    @State private var viewModel = SignUpViewModel()
    @State private var showTermsSheet = false
    
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
                    HStack {
                        Text("Name")
                            .frame(width: 95, alignment: .leading)
                        TextField("Full Name", text: $viewModel.fullName)
                            .textContentType(.name)
                    }
                    
                    HStack {
                        Text("Email")
                            .frame(width: 95, alignment: .leading)
                        TextField("Email", text: $viewModel.email)
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .foregroundStyle(LMSColors.textPrimary)
                    }
                    
                    HStack {
                        Text("Mobile")
                            .frame(width: 95, alignment: .leading)
                        TextField("Phone Number", text: $viewModel.phone)
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                    }
                }
                
                // Additional Information (Optional)
                Section(header: Text("Optional Details")) {
                    HStack {
                        Text("Alt. Mobile")
                            .frame(width: 95, alignment: .leading)
                        TextField("Optional", text: $viewModel.alternatePhone)
                            .keyboardType(.phonePad)
                    }
                    
                    HStack {
                        Text("Referral")
                            .frame(width: 95, alignment: .leading)
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
                    termsAgreementRow
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
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
        }
        .onChange(of: viewModel.showSuccess) { _, success in
            if success {
                appState.login(requiresBorrowerOnboarding: true)
            }
        }
        .accessibleSheet(isPresented: $showTermsSheet) {
            TermsAndConditionsSheet()
        }
    }
    
    private var passwordRequirementsFooter: some View {
        HStack(){
            VStack(alignment: .leading){
                RequirementRow(isMet: viewModel.isMinLength, text: "At least 8 characters")
                Spacer()
                RequirementRow(isMet: viewModel.hasUppercase, text: "One uppercase letter")
            }
            Spacer()
            VStack(alignment: .leading){
                RequirementRow(isMet: viewModel.hasNumber, text: "One number")
                Spacer()
                RequirementRow(isMet: viewModel.hasSpecialChar, text: "One special character")
            }
        }
        .padding(.top, 4)
    }

    private var termsAgreementRow: some View {
        HStack(alignment: .center, spacing: 12) {
            Button {
                toggleAgreement()
            } label: {
                Image(systemName: viewModel.acceptedTerms ? "checkmark.square.fill" : "square")
                    .font(.system(size: 24, weight: .medium, design: .rounded))
                    .foregroundStyle(viewModel.acceptedTerms ? LMSColors.brandNavy : LMSColors.textTertiary)
                    .contentTransition(.symbolEffect(.replace))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Agree to terms and conditions")
            .accessibilityValue(viewModel.acceptedTerms ? "Checked" : "Unchecked")

            HStack(spacing: 4) {
                Text("I agree to")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(.primary)

                Button {
                    showTermsSheet = true
                } label: {
                    Text("Terms and Conditions*")
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
            }
            .onTapGesture {
                toggleAgreement()
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func toggleAgreement() {
        HapticsManager.triggerImpact(style: .light)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            let newValue = !viewModel.acceptedTerms
            viewModel.acceptedTerms = newValue
            viewModel.acceptedPrivacy = newValue
        }
    }
}

private struct TermsAndConditionsSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Terms and Conditions")
                        .font(.system(.title2, design: .rounded).bold())
                        .foregroundStyle(LMSColors.brandNavy)

                    TermsSection(
                        title: "Accurate Information",
                        content: "You agree to provide true personal, contact, employment, and financial details during registration and loan application."
                    )

                    TermsSection(
                        title: "Document Verification",
                        content: "Uploaded KYC, income, and bank documents may be reviewed by authorized bank staff for eligibility and fraud prevention."
                    )

                    TermsSection(
                        title: "Loan Processing",
                        content: "Submitting an application does not guarantee approval. Final approval depends on policy checks, credit assessment, and bank review."
                    )

                    TermsSection(
                        title: "Privacy and Consent",
                        content: "Your data is used to manage your account, process loans, verify documents, and provide important service updates."
                    )

                    TermsSection(
                        title: "Account Responsibility",
                        content: "You are responsible for keeping your login details secure and reporting unauthorized access immediately."
                    )
                }
                .padding(24)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(LMSColors.brandNavy)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

private struct TermsSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(.headline, design: .rounded))
                .foregroundStyle(.primary)

            Text(content)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview("BorrowerSignUpView") {
    BorrowerSignUpView()
        .environment(AppStateManager())
        .environment(AuthManager())
}

