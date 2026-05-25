import SwiftUI
import Supabase

struct OnboardingQuestionnaireView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var appState: AppStateManager
    @ObservedObject private var profileStore = BorrowerProfileStore.shared

    @State private var currentStep = 0
    private let totalSteps = 3


    @State private var employmentType = "Salaried"
    @State private var designation = ""
    @State private var companyName = ""
    @State private var industry = "Technology"
    @State private var yearsOfExperience = ""
    @State private var employerCity = ""
    @State private var monthlyIncome = ""
    @State private var annualIncome = ""
    @State private var existingEMIs = ""


    @State private var hasExistingBankAccount = false
    @State private var existingCustomerId = ""
    @State private var preferredBranch = "Mumbai Main Branch"
    @State private var existingLoansCount = 0
    @State private var existingCreditCardsCount = 0
    @State private var bankingRelationshipDuration = "1–3 Years"
    @State private var showInsightCard = false


    @State private var emergencyContactName = ""
    @State private var emergencyContactRelationship = "Spouse"
    @State private var emergencyContactNumber = ""
    @State private var emergencyContactAlternateNumber = ""
    @State private var emergencyContactAddress = ""
    @State private var nomineeName = ""
    @State private var nomineeRelationship = "Spouse"

    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showValidationError = false

    private let employmentTypes = ["Salaried", "Self-Employed", "Business Owner"]
    private let industries = ["Technology", "Banking & Finance", "Healthcare", "Manufacturing", "Retail", "Government", "Education", "Other"]
    private let emergencyRelationships = ["Spouse", "Parent", "Sibling", "Friend", "Relative", "Other"]
    private let nomineeRelationships = ["Spouse", "Mother", "Father", "Brother", "Sister", "Child", "Other"]
    private let branches = [
        "Mumbai Main Branch",
        "Andheri Tech Park Branch",
        "Mindspace Malad Branch",
        "Bandra Kurla Complex Branch",
        "Delhi Connaught Place Branch",
        "Bengaluru Whitefield Branch"
    ]
    private let bankingDurations = ["Less than 1 Year", "1–3 Years", "3–5 Years", "5+ Years"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                progressHeader

                Form {
                    stepContent
                }
                .scrollContentBackground(.visible)
                .animation(.easeInOut(duration: 0.25), value: currentStep)
            }
            .lmsScreenBackground()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Sign Out") {
                        authManager.signOut()
                    }
                    .font(LMSFont.subheadline.weight(.medium))
                    .foregroundStyle(LMSColors.coral)
                    .disabled(isLoading)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip", action: handleSkip)
                        .font(LMSFont.subheadline.weight(.semibold))
                        .disabled(isLoading)
                }
            }
            .safeAreaInset(edge: .bottom) {
                footerBar
            }
            .onAppear { prepopulateFieldsIfPossible() }
            .onChange(of: profileStore.profile) { prepopulateFieldsIfPossible() }
            .onChange(of: monthlyIncome) { syncAnnualIncomeFromMonthly() }
        }
    }



    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                    Text("Step \(currentStep + 1) of \(totalSteps)")
                        .font(LMSFont.caption.weight(.semibold))
                        .foregroundStyle(LMSColors.actionBlue)

                    Text(stepTitle)
                        .font(LMSFont.title)
                        .foregroundStyle(LMSColors.textPrimary)

                    Text(stepSubtitle)
                        .font(LMSFont.footnote)
                        .foregroundStyle(LMSColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: LMSSpacing.sm)

                Text("\(Int(progressFraction * 100))%")
                    .font(LMSFont.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(LMSColors.textSecondary)
            }

            ProgressView(value: progressFraction)
                .tint(LMSColors.actionBlue)
        }
        .padding(.horizontal, LMSSpacing.screenHorizontal)
        .padding(.top, LMSSpacing.lg)
        .padding(.bottom, LMSSpacing.sm)
        .background(LMSColors.surface)
    }

    private var footerBar: some View {
        VStack(spacing: LMSSpacing.sm) {
            if showValidationError {
                validationBanner
            }

            HStack(spacing: LMSSpacing.md) {
                if currentStep > 0 {
                    Button {
                        withAnimation {
                            currentStep -= 1
                            showValidationError = false
                        }
                    } label: {
                        Text("Back")
                            .font(LMSFont.button)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, LMSSpacing.md)
                    }
                    .buttonStyle(.bordered)
                    .disabled(isLoading)
                }

                Button(action: validateAndProceed) {
                    Group {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(currentStep == totalSteps - 1 ? "Complete Setup" : "Continue")
                                .font(LMSFont.button)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LMSSpacing.md)
                }
                .buttonStyle(.borderedProminent)
                .tint(LMSColors.actionBlue)
                .disabled(isLoading)
            }
        }
        .padding(.horizontal, LMSSpacing.screenHorizontal)
        .padding(.vertical, LMSSpacing.md)
        .background(.bar)
    }

    private var validationBanner: some View {
        HStack(spacing: LMSSpacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
            Text(errorMessage)
                .font(LMSFont.footnote.weight(.medium))
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            Button {
                withAnimation { showValidationError = false }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(LMSColors.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .foregroundStyle(LMSColors.coral)
        .padding(LMSSpacing.md)
        .background(LMSColors.coral.opacity(0.12), in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
    }



    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            workAndIncomeStep
        case 1:
            bankingStep
        case 2:
            referencesStep
        default:
            EmptyView()
        }
    }

    private var workAndIncomeStep: some View {
        Group {
            Section {
                Picker("Employment Type", selection: $employmentType) {
                    ForEach(employmentTypes, id: \.self) { Text($0).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
            } footer: {
                Text("Helps us tailor income verification for your loan application.")
            }

            Section("Role & Employer") {
                TextField("Designation", text: $designation, prompt: Text("e.g. Software Engineer"))
                    .textContentType(.jobTitle)

                TextField("Company / Business Name", text: $companyName, prompt: Text("e.g. Acme Corp"))
                    .textContentType(.organizationName)

                Picker("Industry", selection: $industry) {
                    ForEach(industries, id: \.self) { Text($0).tag($0) }
                }

                TextField("Years of Experience", text: $yearsOfExperience, prompt: Text("e.g. 5"))
                    .keyboardType(.numberPad)

                TextField("Work City", text: $employerCity, prompt: Text("e.g. Bengaluru"))
                    .textContentType(.addressCity)
            }

            Section {
                TextField("Monthly Income (₹)", text: $monthlyIncome, prompt: Text("e.g. 80,000"))
                    .keyboardType(.numberPad)

                TextField("Annual Income (₹)", text: $annualIncome, prompt: Text("Auto-calculated"))
                    .keyboardType(.numberPad)

                TextField("Existing Monthly EMIs (₹)", text: $existingEMIs, prompt: Text("0 if none"))
                    .keyboardType(.numberPad)
            } header: {
                Text("Income Details")
            } footer: {
                Text("Annual income updates when you enter monthly income. EMIs help assess repayment capacity.")
            }
        }
    }

    private var bankingStep: some View {
        Group {
            Section {
                Toggle("I already bank with Astra", isOn: $hasExistingBankAccount.animation())
            } footer: {
                Text("Link your existing relationship for faster processing.")
            }

            if hasExistingBankAccount {
                Section("Existing Relationship") {
                    TextField("Customer ID", text: $existingCustomerId, prompt: Text("e.g. C-109482"))
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()

                    if !existingCustomerId.isEmpty && !showInsightCard {
                        Button("Verify Customer ID") {
                            validateCustomer()
                        }
                    }

                    if showInsightCard, let profile = profileStore.profile {
                        CustomerInsightCardView(profile: profile)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }
                }
            }

            Section("Branch & Credit Profile") {
                Picker("Preferred Home Branch", selection: $preferredBranch) {
                    ForEach(branches, id: \.self) { Text($0).tag($0) }
                }

                Picker("Banking Relationship", selection: $bankingRelationshipDuration) {
                    ForEach(bankingDurations, id: \.self) { Text($0).tag($0) }
                }

                Stepper("Active Loans: \(existingLoansCount)", value: $existingLoansCount, in: 0...10)
                Stepper("Credit Cards: \(existingCreditCardsCount)", value: $existingCreditCardsCount, in: 0...10)
            }
        }
    }

    private var referencesStep: some View {
        Group {
            Section {
                TextField("Contact Full Name", text: $emergencyContactName, prompt: Text("Full name"))
                    .textContentType(.name)

                Picker("Relationship", selection: $emergencyContactRelationship) {
                    ForEach(emergencyRelationships, id: \.self) { Text($0).tag($0) }
                }

                TextField("Mobile Number", text: $emergencyContactNumber, prompt: Text("10-digit number"))
                    .keyboardType(.phonePad)
                    .textContentType(.telephoneNumber)

                TextField("Alternate Number (Optional)", text: $emergencyContactAlternateNumber, prompt: Text("Optional"))
                    .keyboardType(.phonePad)

                TextField("City / Area", text: $emergencyContactAddress, prompt: Text("e.g. Mumbai"))
                    .textContentType(.addressCity)
            } header: {
                Text("Emergency Reference")
            } footer: {
                Text("Required for loan disbursement and account safety verification.")
            }

            Section {
                TextField("Nominee Full Name", text: $nomineeName, prompt: Text("Full name"))
                    .textContentType(.name)

                Picker("Relationship to You", selection: $nomineeRelationship) {
                    ForEach(nomineeRelationships, id: \.self) { Text($0).tag($0) }
                }
            } header: {
                Text("Nominee Details")
            } footer: {
                Text("Used for insurance and account nomination as shown in your profile.")
            }
        }
    }



    private var progressFraction: Double {
        Double(currentStep + 1) / Double(totalSteps)
    }

    private var stepTitle: String {
        switch currentStep {
        case 0: return "Work & Income"
        case 1: return "Banking Preferences"
        case 2: return "References & Nominee"
        default: return ""
        }
    }

    private var stepSubtitle: String {
        switch currentStep {
        case 0: return "Employment and income details used in your loan profile."
        case 1: return "Branch preference and existing banking relationship."
        case 2: return "Emergency contact and nominee for your account."
        default: return ""
        }
    }



    private func prepopulateFieldsIfPossible() {
        guard let p = profileStore.profile else { return }

        if !p.occupation.isEmpty { designation = p.occupation }
        if !p.employment.employmentType.isEmpty { employmentType = p.employment.employmentType }
        if !p.employment.companyName.isEmpty { companyName = p.employment.companyName }
        if !p.employment.designation.isEmpty && designation.isEmpty { designation = p.employment.designation }
        if !p.industry.isEmpty { industry = p.industry }
        if p.yearsOfExperience > 0 { yearsOfExperience = "\(p.yearsOfExperience)" }
        if !p.employment.employerAddress.isEmpty { employerCity = p.employment.employerAddress }
        if p.income.monthlyIncome > 0 { monthlyIncome = formatWholeNumber(p.income.monthlyIncome) }
        if p.income.annualIncome > 0 { annualIncome = formatWholeNumber(p.income.annualIncome) }
        if p.income.existingEMIs > 0 { existingEMIs = formatWholeNumber(p.income.existingEMIs) }

        hasExistingBankAccount = p.hasExistingBankAccount
        if let cid = p.existingCustomerId, !cid.isEmpty { existingCustomerId = cid }
        if !p.preferredBranch.isEmpty { preferredBranch = p.preferredBranch }
        existingLoansCount = p.existingLoansCount
        existingCreditCardsCount = p.existingCreditCardsCount
        if !p.bankingRelationshipDuration.isEmpty { bankingRelationshipDuration = p.bankingRelationshipDuration }

        if !p.emergencyContactName.isEmpty { emergencyContactName = p.emergencyContactName }
        if !p.emergencyContactNumber.isEmpty { emergencyContactNumber = p.emergencyContactNumber }
        if !p.emergencyContactAlternateNumber.isEmpty { emergencyContactAlternateNumber = p.emergencyContactAlternateNumber }
        if !p.emergencyContactAddress.isEmpty { emergencyContactAddress = p.emergencyContactAddress }
        if !p.emergencyContactRelationship.isEmpty { emergencyContactRelationship = p.emergencyContactRelationship }
        if !p.nomineeName.isEmpty { nomineeName = p.nomineeName }
        if !p.nomineeRelationship.isEmpty { nomineeRelationship = p.nomineeRelationship }
    }

    private func syncAnnualIncomeFromMonthly() {
        let digits = monthlyIncome.filter(\.isNumber)
        guard let monthly = Double(digits), monthly > 0 else { return }
        annualIncome = formatWholeNumber(monthly * 12)
    }

    private func formatWholeNumber(_ value: Double) -> String {
        String(format: "%.0f", value)
    }



    private func validateAndProceed() {
        showValidationError = false
        errorMessage = ""

        switch currentStep {
        case 0:
            guard validateWorkAndIncome() else { return }
            advanceAfterSave(saveProfessionalDetails)
        case 1:
            guard validateBanking() else { return }
            withAnimation { currentStep += 1 }
        case 2:
            guard validateReferences() else { return }
            isLoading = true
            Task {
                let success = await saveFinancialDetailsAndComplete()
                await MainActor.run { isLoading = false }
                if !success {  }
            }
        default:
            break
        }
    }

    private func advanceAfterSave(_ save: @escaping () async -> Bool) {
        isLoading = true
        Task {
            let success = await save()
            await MainActor.run {
                isLoading = false
                if success {
                    withAnimation { currentStep += 1 }
                }
            }
        }
    }

    private func validateWorkAndIncome() -> Bool {
        if designation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError("Please enter your designation.")
            return false
        }
        if companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError("Please enter your company or business name.")
            return false
        }
        if yearsOfExperience.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError("Years of experience is required.")
            return false
        }
        guard let years = Int(yearsOfExperience.filter(\.isNumber)), years >= 0, years <= 50 else {
            showError("Enter a valid number of years (0–50).")
            return false
        }
        guard let monthly = parseAmount(monthlyIncome), monthly > 0 else {
            showError("Enter a valid monthly income.")
            return false
        }
        if annualIncome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            annualIncome = formatWholeNumber(monthly * 12)
        }
        guard let annual = parseAmount(annualIncome), annual > 0 else {
            showError("Enter a valid annual income.")
            return false
        }
        if !existingEMIs.isEmpty {
            guard let emi = parseAmount(existingEMIs), emi >= 0 else {
                showError("Existing EMIs must be a valid amount.")
                return false
            }
            _ = emi
        }
        return true
    }

    private func validateBanking() -> Bool {
        if hasExistingBankAccount && existingCustomerId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError("Enter your existing customer ID or turn off the toggle.")
            return false
        }
        if preferredBranch.isEmpty {
            showError("Select your preferred home branch.")
            return false
        }
        return true
    }

    private func validateReferences() -> Bool {
        if emergencyContactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError("Emergency contact name is required.")
            return false
        }
        let phoneDigits = emergencyContactNumber.filter(\.isNumber)
        if phoneDigits.count != 10 {
            showError("Emergency mobile number must be 10 digits.")
            return false
        }
        let alt = emergencyContactAlternateNumber.filter(\.isNumber)
        if !emergencyContactAlternateNumber.isEmpty && alt.count != 10 {
            showError("Alternate number must be 10 digits when provided.")
            return false
        }
        if emergencyContactAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError("Enter the emergency contact's city or area.")
            return false
        }
        if nomineeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError("Nominee name is required.")
            return false
        }
        return true
    }

    private func parseAmount(_ text: String) -> Double? {
        let digits = text.filter(\.isNumber)
        guard !digits.isEmpty else { return nil }
        return Double(digits)
    }

    private func showError(_ msg: String) {
        withAnimation {
            errorMessage = msg
            showValidationError = true
        }
    }

    private func validateCustomer() {
        guard !existingCustomerId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showError("Enter a valid customer ID to verify.")
            return
        }
        withAnimation { showInsightCard = true }
    }



    private func applyFormFields(to profile: inout BorrowerProfile) {
        let years = Int(yearsOfExperience.filter(\.isNumber)) ?? 0
        let monthly = parseAmount(monthlyIncome) ?? 0
        let annual = parseAmount(annualIncome) ?? monthly * 12
        let emis = parseAmount(existingEMIs) ?? 0

        profile.occupation = designation
        profile.industry = industry
        profile.yearsOfExperience = years
        profile.employment = EmploymentInfo(
            employmentType: employmentType,
            companyName: companyName,
            designation: designation,
            workExperienceYears: years,
            employerAddress: employerCity
        )
        profile.income = IncomeInfo(
            monthlyIncome: monthly,
            annualIncome: annual,
            existingEMIs: emis,
            creditScore: profile.income.creditScore,
            incomeSource: employmentType
        )

        profile.hasExistingBankAccount = hasExistingBankAccount
        profile.existingCustomerId = hasExistingBankAccount ? existingCustomerId : nil
        profile.preferredBranch = preferredBranch
        profile.existingLoansCount = existingLoansCount
        profile.existingCreditCardsCount = existingCreditCardsCount
        profile.bankingRelationshipDuration = bankingRelationshipDuration

        profile.emergencyContactName = emergencyContactName
        profile.emergencyContactNumber = emergencyContactNumber
        profile.emergencyContactAlternateNumber = emergencyContactAlternateNumber
        profile.emergencyContactAddress = emergencyContactAddress
        profile.emergencyContactRelationship = emergencyContactRelationship
        profile.nomineeName = nomineeName
        profile.nomineeRelationship = nomineeRelationship
    }

    private func saveProfessionalDetails() async -> Bool {
        let email = authManager.userEmail ?? ""
        let name = authManager.userDisplayName
        var currentProfile = profileStore.ensureProfile(email: email, name: name)
        applyFormFields(to: &currentProfile)

        await MainActor.run {
            profileStore.profile = currentProfile
        }
        return true
    }

    private func saveFinancialDetailsAndComplete() async -> Bool {
        guard let session = try? await SupabaseManager.shared.client.auth.session else {
            await MainActor.run { showError("Authentication session not found.") }
            return false
        }
        let user = session.user
        let email = authManager.userEmail ?? user.email ?? ""
        let name = authManager.userDisplayName
        var currentProfile = profileStore.ensureProfile(email: email, name: name)

        applyFormFields(to: &currentProfile)
        currentProfile.isOnboardingCompleted = true
        currentProfile.id = user.id.uuidString

        do {
            try await DatabaseService.shared.updateProfile(currentProfile)
            _ = try? await SupabaseManager.shared.client
                .from("users")
                .update(["full_name": name, "mobile_number": currentProfile.mobileNumber])
                .eq("id", value: user.id)
                .execute()

            await MainActor.run {
                profileStore.profile = currentProfile
            }
            return true
        } catch {
            await MainActor.run {
                showError("Failed to complete setup: \(error.localizedDescription)")
            }
            return false
        }
    }

    private func handleSkip() {
        isLoading = true
        Task {
            guard let session = try? await SupabaseManager.shared.client.auth.session else {
                await MainActor.run {
                    showError("Authentication session not found.")
                    isLoading = false
                }
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
                await MainActor.run {
                    showError("Failed to skip: \(error.localizedDescription)")
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    OnboardingQuestionnaireView()
        .environmentObject(PreviewSupport.appState(role: .customer))
        .environmentObject(PreviewSupport.authManager)
}

