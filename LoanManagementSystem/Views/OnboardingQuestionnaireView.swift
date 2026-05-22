import SwiftUI

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
    @State private var existingCustomerId = ""
    @State private var preferredBranch = "Mumbai Main Branch"
    
    // Emergency Reference (Conditional for New Customers)
    @State private var emergencyContactName = ""
    @State private var emergencyContactRelationship = "Spouse"
    @State private var emergencyContactNumber = ""
    @State private var emergencyContactAlternateNumber = ""
    @State private var emergencyContactAddress = ""
    
    // Validation state
    @State private var isValidatingCustomer = false
    @State private var showInsightCard = false
    
    // Error feedback
    @State private var errorMessage = ""
    @State private var showValidationError = false
    
    // Lists of Options
    private let employmentTypes = ["Salaried", "Self-Employed", "Business Owner", "Student", "Retired"]
    private let relationships = ["Spouse", "Mother", "Father", "Brother", "Sister", "Friend", "Other"]
    private let branches = [
        "Mumbai Main Branch",
        "Andheri Tech Park Branch",
        "Mindspace Malad Branch",
        "Bandra Kurla Complex Branch",
        "Delhi Connaught Place Branch",
        "Bengaluru Whitefield Branch"
    ]
    
    // Colors based on requirements
    private let primaryBlue = Color(hex: "0A84FF")
    private let navyBackground = Color(hex: "1C1C1E")
    private let successGreen = Color(hex: "34C759")
    
    var body: some View {
        NavigationView {
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
            .navigationBarHidden(true)
            .onAppear {
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
                        .foregroundColor(primaryBlue)
                        .tracking(1.0)
                    
                    Text(stepTitle)
                        .font(.system(size: 28, weight: .bold, design: .default))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Button {
                    profileStore.skipOnboarding()
                } label: {
                    Text("Skip for Now")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundColor(primaryBlue)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(primaryBlue.opacity(0.1))
                        .cornerRadius(12)
                }
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
                            .foregroundColor(.primary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color(UIColor.secondarySystemGroupedBackground))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
                
                Button {
                    validateAndProceed()
                } label: {
                    Text(currentStep == totalSteps - 1 ? "Complete Setup" : "Continue")
                        .font(.system(.body, weight: .bold))
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(primaryBlue)
                        .cornerRadius(16)
                        .shadow(color: primaryBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(UIColor.secondarySystemGroupedBackground))
        }
    }
    
    private var errorBanner: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.white)
            
            Text(errorMessage)
                .font(.system(.subheadline, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(2)
            
            Spacer()
            
            Button {
                withAnimation { showValidationError = false }
            } label: {
                Image(systemName: "xmark")
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding()
        .background(Color.red.opacity(0.9))
        .cornerRadius(12)
        .padding(.horizontal, 20)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    // MARK: - Step 1: Professional Details
    
    private var stepProfessionalView: some View {
        VStack(spacing: 24) {
            // Employment Type (Segmented Control style)
            VStack(alignment: .leading, spacing: 8) {
                Text("Employment Type")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(employmentTypes, id: \.self) { item in
                            Button {
                                withAnimation { employmentType = item }
                            } label: {
                                Text(item)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(employmentType == item ? .white : .primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(employmentType == item ? primaryBlue : Color(UIColor.secondarySystemGroupedBackground))
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                    )
                            }
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
            .cornerRadius(12)
            
            // Income Group
            VStack(spacing: 0) {
                formRow(title: "Monthly Income (₹)", placeholder: "e.g. 80000", text: $monthlyIncome, keyboardType: .numberPad)
                Divider().padding(.leading, 16)
                formRow(title: "Annual Income (₹)", placeholder: "e.g. 960000", text: $annualIncome, keyboardType: .numberPad)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
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
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .tint(successGreen)
                .padding()
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(12)
            
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
                            .font(.subheadline)
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
            .cornerRadius(12)
            
            // Trigger Validation
            if !existingCustomerId.isEmpty && !showInsightCard {
                Button {
                    validateCustomer()
                } label: {
                    Text("Verify Customer ID")
                        .font(.system(.body, weight: .semibold))
                        .foregroundColor(primaryBlue)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(primaryBlue.opacity(0.1))
                        .cornerRadius(12)
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
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.leading, 4)
            
            VStack(spacing: 0) {
                formRow(title: "Contact Name", placeholder: "Full Name", text: $emergencyContactName)
                Divider().padding(.leading, 16)
                
                HStack {
                    Text("Relationship")
                        .font(.subheadline)
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
            .cornerRadius(12)
        }
        .transition(.opacity)
    }
    
    // MARK: - Helpers
    
    private func formRow(title: String, placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .frame(width: 130, alignment: .leading)
            
            TextField(placeholder, text: text)
                .font(.body)
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
    
    private func validateCustomer() {
        isValidatingCustomer = true
        // Simulate network call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isValidatingCustomer = false
            withAnimation(.spring()) {
                showInsightCard = true
            }
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
            if let cid = p.existingCustomerId { existingCustomerId = cid }
            if !p.preferredBranch.isEmpty { preferredBranch = p.preferredBranch }
            
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
                showError("Company Name cannot be empty.")
                return
            }
            if monthlyIncome.isEmpty || annualIncome.isEmpty {
                showError("Please enter your income details.")
                return
            }
            
            withAnimation { currentStep += 1 }
            
        case 1:
            if hasExistingBankAccount {
                if existingCustomerId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    showError("Please provide your Customer ID or disable the option.")
                    return
                }
            } else {
                if emergencyContactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    showError("Emergency contact name is required.")
                    return
                }
                if emergencyContactNumber.trimmingCharacters(in: .whitespacesAndNewlines).count < 10 {
                    showError("Valid 10-digit emergency number is required.")
                    return
                }
            }
            
            submitOnboardingQuestionnaire()
            
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
    
    private func submitOnboardingQuestionnaire() {
        guard var updatedProfile = profileStore.profile else {
            showError("Active user profile session not found.")
            return
        }
        
        // Save Step 1
        updatedProfile.occupation = occupation
        updatedProfile.employment = EmploymentInfo(
            employmentType: employmentType,
            companyName: companyName,
            designation: occupation,
            workExperienceYears: Int(yearsOfExperience) ?? 0,
            employerAddress: updatedProfile.employment.employerAddress
        )
        updatedProfile.industry = industry
        updatedProfile.yearsOfExperience = Int(yearsOfExperience) ?? 0
        updatedProfile.income = IncomeInfo(
            monthlyIncome: Double(monthlyIncome) ?? 0,
            annualIncome: Double(annualIncome) ?? 0,
            existingEMIs: updatedProfile.income.existingEMIs,
            creditScore: updatedProfile.income.creditScore,
            incomeSource: employmentType
        )
        
        // Save Step 2
        updatedProfile.hasExistingBankAccount = hasExistingBankAccount
        if hasExistingBankAccount {
            updatedProfile.existingCustomerId = existingCustomerId
            updatedProfile.preferredBranch = preferredBranch
            updatedProfile.existingLoansCount = 1 // Simulated for existing customer
            updatedProfile.existingCreditCardsCount = 1 // Simulated
            updatedProfile.bankingRelationshipDuration = "2 Years" // Simulated
        } else {
            updatedProfile.existingCustomerId = nil
            updatedProfile.emergencyContactName = emergencyContactName
            updatedProfile.emergencyContactNumber = emergencyContactNumber
            updatedProfile.emergencyContactAlternateNumber = emergencyContactAlternateNumber
            updatedProfile.emergencyContactAddress = emergencyContactAddress
            updatedProfile.emergencyContactRelationship = emergencyContactRelationship
        }
        
        updatedProfile.isOnboardingCompleted = true
        
        // Push updates to store
        profileStore.updateProfile(updatedProfile)
    }
}
