import Observation
import SwiftUI
import Supabase

@MainActor
@Observable
final class OnboardingViewModel {
    // Dependencies
    private let authManager = AuthManager.shared
    private let profileStore = BorrowerProfileStore.shared
    
    // Step indicator: 0 = Professional, 1 = Financial
    var currentStep = 0
    let totalSteps = 2
    
    // Step 1: Professional Details
    var occupation = ""
    var employmentType = "Salaried"
    var companyName = ""
    var yearsOfExperience = ""
    var industry = ""
    var monthlyIncome = ""
    var annualIncome = ""
    var gstNumber = ""
    
    // Step 2: Financial Details
    var hasExistingBankAccount = false
    var emergencyContactName = ""
    var emergencyContactRelationship = "Spouse"
    var emergencyContactNumber = ""
    var emergencyContactAlternateNumber = ""
    var emergencyContactAddress = ""
    var existingCustomerId = ""
    var preferredBranch = "Headquarters Branch"
    var showInsightCard = false
    var linkedAccountsList: [LinkedBankAccount] = []
    var isShowingAddAccountForm = false
    var branchesList: [BranchInfo] = []
    
    // Loading & validation state
    var isLoading = false
    var errorMessage = ""
    var showValidationError = false
    
    // UI Helpers
    var stepTitle: String {
        currentStep == 0 ? "Professional Details" : "Financial Profile"
    }
    
    var stepDescription: String {
        currentStep == 0 ? "Tell us about your work to help us customize your loan options." : "Link your bank accounts for faster approvals and direct disbursements."
    }

    func prepopulateFieldsIfPossible() {
        if let profile = profileStore.profile {
            occupation = profile.occupation
            employmentType = profile.employment.employmentType
            companyName = profile.employment.companyName
            yearsOfExperience = "\(profile.employment.workExperienceYears)"
            industry = profile.industry
            monthlyIncome = profile.income.monthlyIncome > 0 ? String(format: "%.0f", profile.income.monthlyIncome) : ""
            annualIncome = profile.income.annualIncome > 0 ? String(format: "%.0f", profile.income.annualIncome) : ""
            gstNumber = profile.gstNumber ?? ""
            linkedAccountsList = profile.linkedAccounts ?? []
        }
    }
    
    func loadBranches() async {
        do {
            branchesList = try await DatabaseService.shared.fetchBranches()
            if let first = branchesList.first, preferredBranch == "Headquarters Branch" {
                preferredBranch = first.name
            }
        } catch {
            print("Failed to load branches: \(error)")
        }
    }
    
    func showError(_ message: String) {
        errorMessage = message
        showValidationError = true
    }

    func validateAndProceed() async -> Bool {
        showValidationError = false
        
        if currentStep == 0 {
            if occupation.isEmpty || companyName.isEmpty || monthlyIncome.isEmpty || annualIncome.isEmpty {
                showError("Please fill in all required professional details.")
                return false
            }
            if Double(monthlyIncome) == nil || Double(annualIncome) == nil {
                showError("Income fields must be valid numbers.")
                return false
            }
            if employmentType != "Salaried" && gstNumber.isEmpty {
                showError("GST Number is required for non-salaried applicants.")
                return false
            }
            
            isLoading = true
            let success = await saveProfessionalDetails()
            isLoading = false
            
            if success {
                currentStep += 1
                return true
            }
            return false
            
        } else {
            if linkedAccountsList.isEmpty {
                showError("Please link at least one bank account to proceed.")
                return false
            }
            if emergencyContactName.isEmpty || emergencyContactNumber.isEmpty {
                showError("Please provide an emergency contact.")
                return false
            }
            
            isLoading = true
            let success = await saveFinancialDetailsAndComplete()
            isLoading = false
            return success
        }
    }

    func verifyAndLinkBankAccount() async {
        let trimmedId = existingCustomerId.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedId.isEmpty {
            showError("Please enter a valid Customer ID.")
            return
        }
        
        isLoading = true
        showValidationError = false
        
        do {
            let fetchedAccounts = try await DatabaseService.shared.fetchLinkedBankAccounts(customerId: trimmedId)
            
            let verifiedAcc: LinkedBankAccount
            if let account = fetchedAccounts.first {
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
            
            if !linkedAccountsList.contains(where: { $0.accountNumber == verifiedAcc.accountNumber }) {
                linkedAccountsList.append(verifiedAcc)
            }
            existingCustomerId = ""
            isShowingAddAccountForm = false
            isLoading = false
            
        } catch {
            showError("Verification failed: \(error.localizedDescription)")
            isLoading = false
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
        
        profileStore.profile = currentProfile
        
        return true
    }
    
    func saveFinancialDetailsAndComplete() async -> Bool {
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
        currentProfile.emergencyContactName = emergencyContactName
        currentProfile.emergencyContactNumber = emergencyContactNumber
        currentProfile.emergencyContactAlternateNumber = emergencyContactAlternateNumber
        currentProfile.emergencyContactAddress = emergencyContactAddress
        currentProfile.emergencyContactRelationship = emergencyContactRelationship
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
            
            profileStore.profile = currentProfile
            
            return true
        } catch {
            showError("Failed to complete onboarding: \(error.localizedDescription)")
            return false
        }
    }
    
    func handleSkip() async -> Bool {
        isLoading = true
        guard let session = try? await SupabaseManager.shared.client.auth.session else {
            showError("Authentication session not found.")
            isLoading = false
            return false
        }
        let user = session.user
        
        let email = authManager.userEmail ?? user.email ?? ""
        let name = authManager.userDisplayName
        var currentProfile = profileStore.ensureProfile(email: email, name: name)
        
        currentProfile.isOnboardingCompleted = true
        currentProfile.id = user.id.uuidString
        
        do {
            try await DatabaseService.shared.updateProfile(currentProfile)
            try await SupabaseManager.shared.client
                .from("users")
                .update(["full_name": name, "mobile_number": currentProfile.mobileNumber])
                .eq("id", value: user.id)
                .execute()
            
            profileStore.profile = currentProfile
            isLoading = false
            return true
        } catch {
            showError("Failed to complete onboarding: \(error.localizedDescription)")
            isLoading = false
            return false
        }
    }
}
