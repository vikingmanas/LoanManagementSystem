import SwiftUI
import Supabase

struct OnboardingQuestionnaireView: View {
    @Environment(AppStateManager.self) private var appState: AppStateManager
    @State private var viewModel = OnboardingViewModel()
    
    // Lists of Options
    private let employmentTypes = ["Salaried", "Self-Employed", "Business Owner"]
    private let relationships = ["Spouse", "Parent", "Sibling", "Friend", "Relative", "Other"]

    
    var body: some View {
        NavigationStack {
            Form {
                // Progress & Instructions
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(viewModel.stepTitle)
                            .font(.system(.title, design: .rounded).bold())
                            .foregroundStyle(LMSColors.brandNavy)
                        
                        Text(viewModel.stepDescription)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        ProgressView(value: Double(viewModel.currentStep + 1), total: Double(viewModel.totalSteps))
                            .tint(LMSColors.brandNavy)
                            .padding(.top, 4)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
                }
                
                // Form Content
                if viewModel.currentStep == 0 {
                    professionalSection
                } else {
                    financialSection
                }
                
                // Error Section
                if viewModel.showValidationError {
                    Section {
                        Label(viewModel.errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Setup Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if viewModel.currentStep > 0 {
                        Button("Back") {
                            withAnimation { viewModel.currentStep -= 1 }
                        }
                    } else {
                        Button("Skip") {
                            Task {
                                if await viewModel.handleSkip() {
                                    appState.requiresBorrowerOnboarding = false
                                }
                            }
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task {
                            if await viewModel.validateAndProceed() {
                                if viewModel.currentStep == viewModel.totalSteps {
                                    // Finished
                                    appState.requiresBorrowerOnboarding = false
                                }
                            }
                        }
                    } label: {
                        if viewModel.isLoading {
                            ProgressView()
                        } else {
                            Text(viewModel.currentStep == viewModel.totalSteps - 1 ? "Finish" : "Next")
                                .bold()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .onAppear {
                viewModel.prepopulateFieldsIfPossible()
                Task {
                    await viewModel.loadBranches()
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var professionalSection: some View {
        Group {
            Section(header: Text("Employment")) {
                Picker("Employment Type", selection: $viewModel.employmentType) {
                    ForEach(employmentTypes, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.menu)
                
                if viewModel.employmentType == "Salaried" {
                    LabeledContent("Occupation") {
                        TextField("Job Title", text: $viewModel.occupation)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    LabeledContent("Company") {
                        TextField("Employer Name", text: $viewModel.companyName)
                            .multilineTextAlignment(.trailing)
                    }
                } else {
                    LabeledContent("Business Nature") {
                        TextField("e.g. Retail, IT Services", text: $viewModel.occupation)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    LabeledContent("Business Name") {
                        TextField("Your Company Name", text: $viewModel.companyName)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    LabeledContent("GST Number") {
                        TextField("Optional but recommended", text: $viewModel.gstNumber)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                LabeledContent("Industry") {
                    TextField("e.g. Technology, Healthcare", text: $viewModel.industry)
                        .multilineTextAlignment(.trailing)
                }
                
                LabeledContent("Experience (Years)") {
                    TextField("0", text: $viewModel.yearsOfExperience)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            Section(header: Text("Income Details")) {
                LabeledContent("Monthly Income") {
                    TextField("₹", text: $viewModel.monthlyIncome)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
                
                LabeledContent("Annual Income") {
                    TextField("₹", text: $viewModel.annualIncome)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }
    
    private var financialSection: some View {
        Group {
            Section(header: Text("Bank Accounts")) {
                if !viewModel.linkedAccountsList.isEmpty {
                    ForEach(viewModel.linkedAccountsList) { account in
                        HStack {
                            Image(systemName: "building.columns.fill")
                                .foregroundStyle(LMSColors.brandNavy)
                                .frame(width: 30)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(account.bankName)
                                    .font(.subheadline).bold()
                                Text("A/C Ending in \(account.accountNumber.suffix(4))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
                
                Button(action: {
                    viewModel.isShowingAddAccountForm = true
                }) {
                    Label(viewModel.linkedAccountsList.isEmpty ? "Link Bank Account" : "Add Another Account", systemImage: "plus.circle.fill")
                        .foregroundStyle(LMSColors.brandNavy)
                }
            }
            
            Section(header: Text("Preferred Branch")) {
                Picker("Branch", selection: $viewModel.preferredBranch) {
                    ForEach(viewModel.branchesList) { branch in
                        Text(branch.name).tag(branch.name)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Section(header: Text("Emergency Contact"), footer: Text("We only contact them if we cannot reach you for an extended period.")) {
                LabeledContent("Name") {
                    TextField("Full Name", text: $viewModel.emergencyContactName)
                        .multilineTextAlignment(.trailing)
                }
                
                Picker("Relationship", selection: $viewModel.emergencyContactRelationship) {
                    ForEach(relationships, id: \.self) {
                        Text($0)
                    }
                }
                
                LabeledContent("Phone Number") {
                    TextField("+91", text: $viewModel.emergencyContactNumber)
                        .keyboardType(.phonePad)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
        .sheet(isPresented: $viewModel.isShowingAddAccountForm) {
            NavigationStack {
                Form {
                    Section(header: Text("Customer Details"), footer: Text("Enter your Customer ID for your primary bank account.")) {
                        LabeledContent("Customer ID") {
                            TextField("Enter ID", text: $viewModel.existingCustomerId)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    
                    if viewModel.showValidationError {
                        Section {
                            Label(viewModel.errorMessage, systemImage: "exclamationmark.triangle.fill")
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }
                    }
                    
                    Section {
                        Button {
                            Task {
                                await viewModel.verifyAndLinkBankAccount()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                if viewModel.isLoading {
                                    ProgressView()
                                } else {
                                    Text("Verify & Link Account")
                                        .bold()
                                }
                                Spacer()
                            }
                        }
                        .disabled(viewModel.isLoading)
                        .listRowBackground(LMSColors.brandNavy)
                        .foregroundStyle(.white)
                    }
                }
                .navigationTitle("Link Account")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            viewModel.isShowingAddAccountForm = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
        }
    }
}

// MARK: - Premium Bank Account Insight Card View
struct BankAccountInsightCardView: View {
    let account: LinkedBankAccount
    
    var body: some View {
        VStack(spacing: 0) {
            // Header: Bank Name and Icon
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.bankName)
                        .font(.system(.headline, design: .rounded).bold())
                        .foregroundStyle(.white)
                    
                    Text("Branch: \(account.branch)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 36, height: 36)
                    Image(systemName: "landmark.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                }
            }
            .padding(.all, 16)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Body: Details
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Account Number")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                        Text(maskedAccount(account.accountNumber))
                            .font(.system(.body, design: .monospaced, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("IFSC Code")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                        Text(account.ifscCode)
                            .font(.system(.body, design: .monospaced, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Customer ID")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                        Text(account.customerId)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.white)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Account Status")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white.opacity(0.6))
                        Text("VERIFIED")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(LMSColors.emerald)
                    }
                }
            }
            .padding(.all, 16)
            .background(Color.white.opacity(0.04))
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            // Balance Footer
            HStack {
                Text("Available Balance")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.white.opacity(0.8))
                
                Spacer()
                
                Text(account.balance.formattedAsINR())
                    .font(.system(.headline, design: .rounded).bold())
                    .foregroundStyle(.white)
            }
            .padding(.all, 16)
        }
        .background(
            LinearGradient(
                colors: [LMSColors.brandNavy, LMSColors.brandNavyLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private func maskedAccount(_ account: String) -> String {
        guard account.count > 4 else { return account }
        let suffix = account.suffix(4)
        return "•••• \(suffix)"
    }
}
