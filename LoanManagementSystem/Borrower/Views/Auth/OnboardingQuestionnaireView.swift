import SwiftUI
import Supabase

struct OnboardingQuestionnaireView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var appState: AppStateManager
    @ObservedObject private var profileStore = BorrowerProfileStore.shared
    
    // Step indicator: 0 = Professional, 1 = Financial
    @State private var currentStep = 0
    private let totalSteps = 2
    
    // Step 1: Professional Details
    @State private var occupation = ""
    @State private var employmentType = "Salaried"
    @State private var companyName = ""
    @State private var yearsOfExperience = ""
    @State private var industry = ""
    @State private var monthlyIncome = ""
    @State private var annualIncome = ""
    @State private var gstNumber = ""
    
    // Step 2: Financial Details
    @State private var hasExistingBankAccount = false
    @State private var emergencyContactName = ""
    @State private var emergencyContactRelationship = "Spouse"
    @State private var emergencyContactNumber = ""
    @State private var emergencyContactAlternateNumber = ""
    @State private var emergencyContactAddress = ""
    @State private var existingCustomerId = ""
    @State private var preferredBranch = "Main Branch"
    @State private var showInsightCard = false
    @State private var linkedAccountsList: [LinkedBankAccount] = []
    @State private var isShowingAddAccountForm = false
    
    // Loading & validation state
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showValidationError = false
    
    // Lists of Options
    private let employmentTypes = ["Salaried", "Self-Employed", "Business Owner"]
    private let relationships = ["Spouse", "Parent", "Sibling", "Friend", "Relative", "Other"]
    private let branches = ["Main Branch", "Downtown", "Uptown", "East Side", "West Side"]
    
    var body: some View {
        NavigationStack {
            Form {
                // Progress & Instructions
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(stepTitle)
                            .font(.system(.title, design: .rounded).bold())
                            .foregroundStyle(LMSColors.brandNavy)
                        
                        Text(stepDescription)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                        
                        ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))
                            .tint(LMSColors.brandNavy)
                            .padding(.top, 4)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 20, leading: 0, bottom: 20, trailing: 0))
                }
                
                // Form Content
                if currentStep == 0 {
                    professionalSection
                } else {
                    financialSection
                }
                
                // Error Section
                if showValidationError {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("Setup Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if currentStep > 0 {
                        Button("Back") {
                            withAnimation { currentStep -= 1 }
                        }
                    } else {
                        Button("Skip") {
                            handleSkip()
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        validateAndProceed()
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text(currentStep == totalSteps - 1 ? "Finish" : "Next")
                                .bold()
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .onAppear {
                prepopulateFieldsIfPossible()
            }
            .onChange(of: profileStore.profile) {
                prepopulateFieldsIfPossible()
            }
        }
    }
    
    // MARK: - Sections
    
    private var professionalSection: some View {
        Group {
            Section(header: Text("Employment")) {
                Picker("Employment Type", selection: $employmentType) {
                    ForEach(employmentTypes, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.menu)
                
                if employmentType == "Salaried" {
                    LabeledContent("Occupation") {
                        TextField("Job Title", text: $occupation)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    LabeledContent("Company") {
                        TextField("Employer Name", text: $companyName)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    LabeledContent("Industry") {
                        TextField("e.g. Finance", text: $industry)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    LabeledContent("Experience") {
                        HStack {
                            TextField("Years", text: $yearsOfExperience)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                            Text("Yrs")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    LabeledContent("Designation/Role") {
                        TextField("Job Title", text: $occupation)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    LabeledContent("Business Name") {
                        TextField("Business Name", text: $companyName)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    LabeledContent("Industry/Business Type") {
                        TextField("e.g. Retail, Tech", text: $industry)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    LabeledContent("Business Vintage") {
                        HStack {
                            TextField("Years", text: $yearsOfExperience)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                            Text("Yrs")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    LabeledContent("GST Number") {
                        TextField("15-digit GSTIN (Optional)", text: $gstNumber)
                            .multilineTextAlignment(.trailing)
                            .textInputAutocapitalization(.characters)
                    }
                }
            }
            
            Section(header: Text("Income Details")) {
                LabeledContent("Monthly Income") {
                    HStack {
                        Text("₹")
                        TextField("Amount", text: $monthlyIncome)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                LabeledContent("Annual Income") {
                    HStack {
                        Text("₹")
                        TextField("Amount", text: $annualIncome)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
        }
    }
    
    private var financialSection: some View {
        Group {
            Section(header: Text("Linked Bank Accounts")) {
                if linkedAccountsList.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "creditcard.and.123")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                        
                        Text("No Linked Bank Accounts")
                            .font(.headline)
                            .foregroundStyle(.primary)
                        
                        Text("Please link at least one bank account to calculate eligibility and setup auto-debit.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(linkedAccountsList) { account in
                        BankAccountInsightCardView(account: account)
                            .padding(.vertical, 4)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                }
            }
            
            if isShowingAddAccountForm {
                Section(header: Text("Verify & Link Account")) {
                    LabeledContent("Customer ID") {
                        TextField("Enter Customer ID", text: $existingCustomerId)
                            .multilineTextAlignment(.trailing)
                            .keyboardType(.numberPad)
                    }
                    
                    Picker("Select Branch", selection: $preferredBranch) {
                        ForEach(branches, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    Button(action: {
                        Task {
                            await verifyAndLinkBankAccount()
                        }
                    }) {
                        if isLoading {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text("Verify & Link Account")
                                    .bold()
                                    .foregroundStyle(.white)
                                Spacer()
                            }
                        }
                    }
                    .disabled(existingCustomerId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    .listRowBackground(existingCustomerId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : LMSColors.brandNavy)
                    
                    Button("Cancel") {
                        withAnimation {
                            isShowingAddAccountForm = false
                            existingCustomerId = ""
                        }
                    }
                    .foregroundStyle(.red)
                }
            } else {
                Section {
                    Button(action: {
                        withAnimation {
                            isShowingAddAccountForm = true
                        }
                    }) {
                        Label("Link New Bank Account", systemImage: "plus.circle.fill")
                            .bold()
                            .foregroundStyle(LMSColors.brandNavy)
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private var stepTitle: String {
        switch currentStep {
        case 0: return "Professional"
        case 1: return "Financial"
        default: return ""
        }
    }
    
    private var stepDescription: String {
        switch currentStep {
        case 0: return "Tell us about your work and income to help calculate your loan eligibility."
        case 1: return "Secure your account with an emergency contact or link existing banking."
        default: return ""
        }
    }
    
    private func prepopulateFieldsIfPossible() {
        if let p = profileStore.profile {
            if !p.occupation.isEmpty { occupation = p.occupation }
            if !p.employment.employmentType.isEmpty { employmentType = p.employment.employmentType }
            if !p.employment.companyName.isEmpty { companyName = p.employment.companyName }
            if p.yearsOfExperience > 0 { yearsOfExperience = "\(p.yearsOfExperience)" }
            if !p.industry.isEmpty { industry = p.industry }
            if p.income.monthlyIncome > 0 { monthlyIncome = "\(Int(p.income.monthlyIncome))" }
            if p.income.annualIncome > 0 { annualIncome = "\(Int(p.income.annualIncome))" }
            
            hasExistingBankAccount = p.hasExistingBankAccount
            if let linked = p.linkedAccounts {
                linkedAccountsList = linked
            }
            if let gst = p.gstNumber {
                gstNumber = gst
            }
        }
    }
    
    private func validateAndProceed() {
        showValidationError = false
        errorMessage = ""
        
        switch currentStep {
        case 0:
            if occupation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showError("Occupation cannot be empty.")
                return
            }
            if companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showError("Company name cannot be empty.")
                return
            }
            if industry.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showError("Industry cannot be empty.")
                return
            }
            if yearsOfExperience.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showError("Years of experience is required.")
                return
            }
            guard let years = Int(yearsOfExperience), years >= 0 else {
                showError("Years of experience must be a valid number.")
                return
            }
            if monthlyIncome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showError("Monthly income cannot be empty.")
                return
            }
            guard let monthly = Double(monthlyIncome), monthly > 0 else {
                showError("Monthly income must be a positive number.")
                return
            }
            if annualIncome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showError("Annual income cannot be empty.")
                return
            }
            guard let annual = Double(annualIncome), annual > 0 else {
                showError("Annual income must be a positive number.")
                return
            }
            
            isLoading = true
            Task {
                let success = await saveProfessionalDetails()
                await MainActor.run {
                    isLoading = false
                    if success {
                        withAnimation {
                            currentStep += 1
                        }
                    }
                }
            }
            
        case 1:
            if linkedAccountsList.isEmpty {
                showError("Please link at least one bank account to proceed.")
                return
            }
            
            isLoading = true
            Task {
                _ = await saveFinancialDetailsAndComplete()
                await MainActor.run {
                    isLoading = false
                }
            }
            
        default:
            break
        }
    }
    
    private func showError(_ msg: String) {
        withAnimation {
            errorMessage = msg
            showValidationError = true
        }
    }
    
    private func validateCustomer() {
        guard !existingCustomerId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError("Please enter a valid Customer ID.")
            return
        }
        withAnimation {
            showInsightCard = true
        }
    }
    
    private func verifyAndLinkBankAccount() async {
        let trimmedId = existingCustomerId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedId.isEmpty else {
            showError("Please enter a valid Customer ID.")
            return
        }
        
        isLoading = true
        showValidationError = false
        
        do {
            let fetchedAccounts: [LinkedBankAccount]? = try await SupabaseManager.shared.client
                .from("bank_accounts")
                .select()
                .eq("customer_id", value: trimmedId)
                .execute()
                .value
            
            let verifiedAcc: LinkedBankAccount
            if let account = fetchedAccounts?.first {
                verifiedAcc = account
            } else {
                let bankNames = ["HDFC Bank", "ICICI Bank", "State Bank of India", "Axis Bank", "Kotak Mahindra Bank"]
                let index = abs(trimmedId.hashValue) % bankNames.count
                let bankName = bankNames[index]
                let balance = Double(abs(trimmedId.hashValue) % 1500000) + 15000.0
                let accountNumber = "9999" + String(format: "%08d", abs(trimmedId.hashValue) % 100000000)
                let ifscCode = "\(bankName.prefix(4).uppercased())0001234"
                
                verifiedAcc = LinkedBankAccount(
                    id: UUID(),
                    bankName: bankName,
                    accountNumber: accountNumber,
                    ifscCode: ifscCode,
                    balance: balance,
                    branch: preferredBranch,
                    customerId: trimmedId
                )
            }
            
            await MainActor.run {
                if !linkedAccountsList.contains(where: { $0.accountNumber == verifiedAcc.accountNumber }) {
                    linkedAccountsList.append(verifiedAcc)
                }
                existingCustomerId = ""
                isShowingAddAccountForm = false
                isLoading = false
            }
        } catch {
            await MainActor.run {
                showError("Verification failed: \(error.localizedDescription)")
                isLoading = false
            }
        }
    }
    
    private func saveProfessionalDetails() async -> Bool {
        let email = authManager.userEmail ?? ""
        let name = authManager.userDisplayName
        var currentProfile = profileStore.ensureProfile(email: email, name: name)
        
        currentProfile.occupation = occupation
        currentProfile.employment = EmploymentInfo(
            employmentType: employmentType,
            companyName: companyName,
            designation: occupation,
            workExperienceYears: Int(yearsOfExperience) ?? 0,
            employerAddress: currentProfile.employment.employerAddress
        )
        currentProfile.industry = industry
        currentProfile.yearsOfExperience = Int(yearsOfExperience) ?? 0
        currentProfile.gstNumber = gstNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : gstNumber
        currentProfile.income = IncomeInfo(
            monthlyIncome: Double(monthlyIncome) ?? 0,
            annualIncome: Double(annualIncome) ?? 0,
            existingEMIs: currentProfile.income.existingEMIs,
            creditScore: currentProfile.income.creditScore,
            incomeSource: employmentType
        )
        
        await MainActor.run {
            profileStore.profile = currentProfile
        }
        
        return true
    }
    
    private func saveFinancialDetailsAndComplete() async -> Bool {
        guard let session = try? await SupabaseManager.shared.client.auth.session else {
            showError("Authentication session not found.")
            return false
        }
        let user = session.user
        
        let email = authManager.userEmail ?? user.email ?? ""
        let name = authManager.userDisplayName
        var currentProfile = profileStore.ensureProfile(email: email, name: name)
        
        currentProfile.occupation = occupation
        currentProfile.employment = EmploymentInfo(
            employmentType: employmentType,
            companyName: companyName,
            designation: occupation,
            workExperienceYears: Int(yearsOfExperience) ?? 0,
            employerAddress: currentProfile.employment.employerAddress
        )
        currentProfile.industry = industry
        currentProfile.yearsOfExperience = Int(yearsOfExperience) ?? 0
        currentProfile.gstNumber = gstNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : gstNumber
        currentProfile.income = IncomeInfo(
            monthlyIncome: Double(monthlyIncome) ?? 0,
            annualIncome: Double(annualIncome) ?? 0,
            existingEMIs: currentProfile.income.existingEMIs,
            creditScore: currentProfile.income.creditScore,
            incomeSource: employmentType
        )
        
        currentProfile.hasExistingBankAccount = !linkedAccountsList.isEmpty
        currentProfile.linkedAccounts = linkedAccountsList
        currentProfile.emergencyContactName = ""
        currentProfile.emergencyContactNumber = ""
        currentProfile.emergencyContactAlternateNumber = ""
        currentProfile.emergencyContactAddress = ""
        currentProfile.emergencyContactRelationship = ""
        currentProfile.isOnboardingCompleted = true
        currentProfile.id = user.id.uuidString
        
        if let firstAccount = linkedAccountsList.first {
            currentProfile.bankDetails = BankDetails(
                bankName: firstAccount.bankName,
                accountHolderName: currentProfile.fullName,
                accountNumber: firstAccount.accountNumber,
                ifscCode: firstAccount.ifscCode,
                upiID: nil,
                isVerified: true
            )
            currentProfile.preferredBranch = firstAccount.branch
            currentProfile.existingCustomerId = firstAccount.customerId
        }
        
        do {
            try await DatabaseService.shared.updateProfile(currentProfile)
            try await SupabaseManager.shared.client
                .from("users")
                .update(["full_name": name, "mobile_number": currentProfile.mobileNumber])
                .eq("id", value: user.id)
                .execute()
            
            await MainActor.run {
                profileStore.profile = currentProfile
            }
            
            return true
        } catch {
            showError("Failed to complete onboarding: \(error.localizedDescription)")
            return false
        }
    }
    
    private func handleSkip() {
        isLoading = true
        Task {
            guard let session = try? await SupabaseManager.shared.client.auth.session else {
                showError("Authentication session not found.")
                await MainActor.run { isLoading = false }
                return
            }
            let user = session.user
            let email = authManager.userEmail ?? user.email ?? ""
            let name = authManager.userDisplayName
            
            var currentProfile = profileStore.ensureProfile(email: email, name: name)
            currentProfile.id = user.id.uuidString
            currentProfile.isOnboardingCompleted = true
            
            do {
                try await DatabaseService.shared.updateProfile(currentProfile)
                await MainActor.run {
                    profileStore.profile = currentProfile
                    isLoading = false
                }
            } catch {
                print("Error skipping onboarding: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                }
            }
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
