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
    
    // Colors based on requirements
    private let primaryBlue = Color(hex: "0A84FF")
    private let successGreen = Color(hex: "34C759")
    
    var body: some View {
        NavigationStack {
            ZStack {
                // System Grouped Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header Block with progress bar
                    headerSection
                    
                    // Form Content
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            formStepView
                                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                            
                            // Error message banner
                            if showValidationError {
                                errorBanner
                            }
                        }
                        .padding(.vertical, 24)
                    }
                    
                    // Footer Navigation Controls
                    footerSection
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                prepopulateFieldsIfPossible()
            }
            .onChange(of: profileStore.profile) {
                prepopulateFieldsIfPossible()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CUSTOMER ONBOARDING")
                        .font(.system(size: 12, weight: .bold, design: .default))
                        .foregroundStyle(primaryBlue)
                        .tracking(1.0)
                    
                    Text(stepTitle)
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundStyle(LMSColors.textPrimary)
                }
                
                Spacer()
                
                Button {
                    handleSkip()
                } label: {
                    Text("Skip for Now")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(primaryBlue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(primaryBlue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .disabled(isLoading)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            
            // Modern Step Indicators
            HStack(spacing: 8) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentStep ? primaryBlue : Color.gray.opacity(0.3))
                        .frame(height: 6)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentStep)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 5)
    }
    
    private var formStepView: some View {
        Group {
            switch currentStep {
            case 0:
                stepProfessionalView
            case 1:
                stepFinancialView
            default:
                EmptyView()
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var footerSection: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                if currentStep > 0 {
                    Button {
                        withAnimation {
                            currentStep -= 1
                            showValidationError = false
                        }
                    } label: {
                        Text("Back")
                            .font(.system(.body, weight: .semibold))
                            .foregroundStyle(LMSColors.textPrimary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .disabled(isLoading)
                }
                
                Button {
                    validateAndProceed()
                } label: {
                    HStack(spacing: 8) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text(currentStep == totalSteps - 1 ? "Complete Setup" : "Continue")
                                .font(.system(.body, weight: .bold))
                        }
                    }
                    .foregroundStyle(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(isLoading ? primaryBlue.opacity(0.6) : primaryBlue)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: primaryBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isLoading)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
        }
    }
    
    private var errorBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.white)
            
            Text(errorMessage)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
            
            Spacer()
            
            Button {
                withAnimation { showValidationError = false }
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding()
        .background(Color.red.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 20)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // MARK: - Step 1: Professional Details
    
    private var stepProfessionalView: some View {
        VStack(spacing: 24) {
            // Employment Type
            VStack(alignment: .leading, spacing: 8) {
                Text("Employment Type")
                    .font(LMSFont.subheadline)
                    .foregroundStyle(LMSColors.textSecondary)
                
                HStack(spacing: 10) {
                    ForEach(employmentTypes, id: \.self) { item in
                        Button {
                            withAnimation { employmentType = item }
                        } label: {
                            Text(item)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(employmentType == item ? .white : .primary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(employmentType == item ? primaryBlue : Color(UIColor.secondarySystemGroupedBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                }
            }
            
            // Professional Details Group
            VStack(spacing: 0) {
                formRow(title: "Occupation", placeholder: "e.g. Software Engineer", text: $occupation)
                Divider().padding(.leading, 16)
                formRow(title: "Company Name", placeholder: "e.g. Acme Corp", text: $companyName)
                Divider().padding(.leading, 16)
                formRow(title: "Industry", placeholder: "e.g. Technology", text: $industry)
                Divider().padding(.leading, 16)
                formRow(title: "Years of Experience", placeholder: "e.g. 5", text: $yearsOfExperience, keyboardType: .numberPad)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            // Income Group
            VStack(spacing: 0) {
                formRow(title: "Monthly Income (₹)", placeholder: "e.g. 80000", text: $monthlyIncome, keyboardType: .numberPad)
                Divider().padding(.leading, 16)
                formRow(title: "Annual Income (₹)", placeholder: "e.g. 960000", text: $annualIncome, keyboardType: .numberPad)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
    
    // MARK: - Step 2: Financial Details
    
    private var stepFinancialView: some View {
        VStack(spacing: 24) {
            // Existing Relationship Toggle
            VStack(spacing: 0) {
                Toggle(isOn: $hasExistingBankAccount.animation()) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Existing Bank Account")
                            .font(.system(.body, weight: .semibold))
                        Text("Do you have an account with us?")
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                }
                .tint(successGreen)
                .padding()
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            if hasExistingBankAccount {
                existingCustomerSection
            } else {
                newCustomerEmergencySection
            }
        }
    }

    private var existingCustomerSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 0) {
                formRow(title: "Customer ID", placeholder: "e.g. C-109482", text: $existingCustomerId)

                if !existingCustomerId.isEmpty {
                    Divider().padding(.leading, 16)

                    HStack {
                        Text("Preferred Branch")
                            .font(LMSFont.subheadline)
                        Spacer()
                        Picker("Branch", selection: $preferredBranch) {
                            ForEach(branches, id: \.self) {
                                Text($0)
                            }
                        }
                        .tint(.primary)
                    }
                    .padding()
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            if !existingCustomerId.isEmpty && !showInsightCard {
                Button {
                    validateCustomer()
                } label: {
                    Text("Verify Customer ID")
                        .font(.system(.body, weight: .semibold))
                        .foregroundStyle(primaryBlue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(primaryBlue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }

            if showInsightCard, let profile = profileStore.profile {
                CustomerInsightCardView(profile: profile)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private var newCustomerEmergencySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Emergency Reference")
                .font(LMSFont.subheadline)
                .foregroundStyle(LMSColors.textSecondary)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                formRow(title: "Contact Name", placeholder: "Full Name", text: $emergencyContactName)
                Divider().padding(.leading, 16)
                
                HStack {
                    Text("Relationship")
                        .font(LMSFont.subheadline)
                    Spacer()
                    Picker("Relationship", selection: $emergencyContactRelationship) {
                        ForEach(relationships, id: \.self) {
                            Text($0)
                        }
                    }
                    .tint(.primary)
                }
                .padding()
                
                Divider().padding(.leading, 16)
                formRow(title: "Mobile Number", placeholder: "10-digit number", text: $emergencyContactNumber, keyboardType: .phonePad)
                Divider().padding(.leading, 16)
                formRow(title: "Alternate Number", placeholder: "Optional", text: $emergencyContactAlternateNumber, keyboardType: .phonePad)
                Divider().padding(.leading, 16)
                formRow(title: "Address", placeholder: "City or Area", text: $emergencyContactAddress)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .transition(.opacity)
    }
    
    // MARK: - Helpers
    
    private func formRow(title: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        HStack {
            Text(title)
                .font(LMSFont.subheadline)
                .frame(width: 130, alignment: .leading)
            
            TextField(placeholder, text: text)
                .font(LMSFont.body)
                .keyboardType(keyboardType)
                .multilineTextAlignment(.trailing)
        }
        .padding()
    }
    
    private var stepTitle: String {
        switch currentStep {
        case 0: return "Professional Details"
        case 1: return "Financial Details"
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
            
            // Validate & save step 1 professional details to local cache / Supabase
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
            
            let altPhone = emergencyContactAlternateNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            if !altPhone.isEmpty {
                let altDigits = altPhone.filter { $0.isNumber }
                if altDigits.count != 10 {
                    showError("Alternate mobile number must be a valid 10-digit number.")
                    return
                }
            }
            
            if emergencyContactAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showError("Emergency contact address is required.")
                return
            }
            
            // Validate & save step 2 financial details & complete onboarding
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
        
        // Re-apply step 1 fields
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
        
        // Apply step 2 fields
        currentProfile.hasExistingBankAccount = hasExistingBankAccount
        currentProfile.emergencyContactName = emergencyContactName
        currentProfile.emergencyContactNumber = emergencyContactNumber
        currentProfile.emergencyContactAlternateNumber = emergencyContactAlternateNumber
        currentProfile.emergencyContactAddress = emergencyContactAddress
        currentProfile.emergencyContactRelationship = emergencyContactRelationship
        currentProfile.isOnboardingCompleted = true
        
        // Set profile ID to user's UID
        currentProfile.id = user.id.uuidString
        
        do {
            // Update profile via DatabaseService which saves locally and tries to sync to Supabase
            try await DatabaseService.shared.updateProfile(currentProfile)
            
            // Also update the users table with full_name and mobile_number
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
