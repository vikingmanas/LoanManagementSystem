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
            Section(header: Text("Banking Status")) {
                Toggle("Existing Customer", isOn: $hasExistingBankAccount.animation())
            }
            
            if hasExistingBankAccount {
                Section(header: Text("Account Verification")) {
                    LabeledContent("Customer ID") {
                        TextField("ID Number", text: $existingCustomerId)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("Branch", selection: $preferredBranch) {
                        ForEach(branches, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    Button("Verify Account") {
                        validateCustomer()
                    }
                    .foregroundStyle(LMSColors.brandNavy)
                }
                
                if showInsightCard, let profile = profileStore.profile {
                    Section(header: Text("Account Insights")) {
                        LMSAccountInsightCardView(profile: profile)
                            .listRowInsets(EdgeInsets())
                    }
                }
            } else {
                Section(header: Text("Emergency Contact")) {
                    LabeledContent("Full Name") {
                        TextField("Name", text: $emergencyContactName)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    Picker("Relationship", selection: $emergencyContactRelationship) {
                        ForEach(relationships, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    LabeledContent("Mobile") {
                        TextField("Phone", text: $emergencyContactNumber)
                            .keyboardType(.phonePad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    LabeledContent("Alt. Mobile") {
                        TextField("Optional", text: $emergencyContactAlternateNumber)
                            .keyboardType(.phonePad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    LabeledContent("Address") {
                        TextField("City/Area", text: $emergencyContactAddress)
                            .multilineTextAlignment(.trailing)
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
            
            if !p.emergencyContactName.isEmpty { emergencyContactName = p.emergencyContactName }
            if !p.emergencyContactNumber.isEmpty { emergencyContactNumber = p.emergencyContactNumber }
            if !p.emergencyContactAlternateNumber.isEmpty { emergencyContactAlternateNumber = p.emergencyContactAlternateNumber }
            if !p.emergencyContactAddress.isEmpty { emergencyContactAddress = p.emergencyContactAddress }
            if !p.emergencyContactRelationship.isEmpty { emergencyContactRelationship = p.emergencyContactRelationship }
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
            if emergencyContactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showError("Emergency contact name is required.")
                return
            }
            
            let phone = emergencyContactNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            if phone.isEmpty {
                showError("Emergency contact mobile number is required.")
                return
            }
            let phoneDigits = phone.filter { $0.isNumber }
            if phoneDigits.count != 10 {
                showError("Emergency contact mobile number must be a valid 10-digit number.")
                return
            }
            
            if emergencyContactAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showError("Emergency contact address is required.")
                return
            }
            
            isLoading = true
            Task {
                let success = await saveFinancialDetailsAndComplete()
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
    
    private func saveProfessionalDetails() async -> Bool {
        let email = authManager.userEmail ?? ""
        let name = authManager.userDisplayName
        var currentProfile = await profileStore.ensureProfile(email: email, name: name)
        
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
        var currentProfile = await profileStore.ensureProfile(email: email, name: name)
        
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
        currentProfile.income = IncomeInfo(
            monthlyIncome: Double(monthlyIncome) ?? 0,
            annualIncome: Double(annualIncome) ?? 0,
            existingEMIs: currentProfile.income.existingEMIs,
            creditScore: currentProfile.income.creditScore,
            incomeSource: employmentType
        )
        
        currentProfile.hasExistingBankAccount = hasExistingBankAccount
        currentProfile.emergencyContactName = emergencyContactName
        currentProfile.emergencyContactNumber = emergencyContactNumber
        currentProfile.emergencyContactAlternateNumber = emergencyContactAlternateNumber
        currentProfile.emergencyContactAddress = emergencyContactAddress
        currentProfile.emergencyContactRelationship = emergencyContactRelationship
        currentProfile.isOnboardingCompleted = true
        currentProfile.id = user.id.uuidString
        
        do {
            try await DatabaseService.shared.updateProfile(currentProfile)
            try? await SupabaseManager.shared.client
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
            
            var currentProfile = await profileStore.ensureProfile(email: email, name: name)
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
