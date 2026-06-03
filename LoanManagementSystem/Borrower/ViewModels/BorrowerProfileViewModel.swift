import Foundation
import Combine
import Supabase

enum KYCDocumentType {
    case aadhaar, pan, addressProof
}

class BorrowerProfileViewModel: ObservableObject {
    @Published var profile: BorrowerProfile?
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        profile = BorrowerProfileStore.shared.profile

        BorrowerProfileStore.shared.$profile
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedProfile in
                self?.profile = updatedProfile
                if updatedProfile != nil {
                    self?.isLoading = false
                }
            }
            .store(in: &cancellables)
    }

    @MainActor
    func loadProfile(email: String?, displayName: String?) {
        isLoading = true

        let cleanedEmail = email?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""

        Task { [weak self] in
            var didRequestRemoteProfile = false

            if let session = try? await SupabaseManager.shared.client.auth.session {
                let user = session.user
                let sessionEmail = user.email?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                let resolvedEmail = sessionEmail ?? cleanedEmail

                if cleanedEmail.isEmpty || sessionEmail == cleanedEmail {
                    didRequestRemoteProfile = true
                    await BorrowerProfileStore.shared.fetchProfileFromSupabase(
                        uid: user.id.uuidString,
                        email: resolvedEmail,
                        name: displayName
                    )
                }
            }

            if !didRequestRemoteProfile, !cleanedEmail.isEmpty {
                _ = BorrowerProfileStore.shared.ensureProfile(
                    email: cleanedEmail,
                    name: displayName
                )
            }

            await MainActor.run {
                self?.profile = BorrowerProfileStore.shared.profile
                self?.isLoading = false
            }
        }
    }
    
    private var activeProfile: BorrowerProfile? {
        BorrowerProfileStore.shared.profile ?? profile
    }

    func updatePersonalInfo(fullName: String, gender: String, maritalStatus: String, nationality: String, dateOfBirth: Date, aadhaarNumber: String, panNumber: String) {
        guard var updatedProfile = activeProfile else { return }
        updatedProfile.fullName = fullName
        updatedProfile.gender = gender
        updatedProfile.maritalStatus = maritalStatus
        updatedProfile.nationality = nationality
        updatedProfile.dateOfBirth = dateOfBirth
        updatedProfile.aadhaarNumber = aadhaarNumber
        updatedProfile.panNumber = panNumber
        
        BorrowerProfileStore.shared.updateProfile(updatedProfile)
    }
    
    func updateContact(mobile: String, email: String, alternate: String) {
        guard var updatedProfile = activeProfile else { return }
        if updatedProfile.mobileNumber != mobile {
            updatedProfile.mobileNumber = mobile
            updatedProfile.isPhoneVerified = false
        }
        if updatedProfile.email != email {
            updatedProfile.email = email
            updatedProfile.isEmailVerified = false
        }
        updatedProfile.alternateNumber = alternate.isEmpty ? nil : alternate
        
        BorrowerProfileStore.shared.updateProfile(updatedProfile)
    }
    
    func updateAddress(street: String, city: String, state: String, zip: String, isSame: Bool) {
        guard var updatedProfile = activeProfile else { return }
        let newAddress = AddressInfo(streetAddress: street, city: city, state: state, zipCode: zip, country: updatedProfile.currentAddress.country, isSameAsCurrent: isSame)
        updatedProfile.currentAddress = newAddress
        updatedProfile.permanentAddress = isSame ? newAddress : updatedProfile.permanentAddress
        
        BorrowerProfileStore.shared.updateProfile(updatedProfile)
    }
    
    func updateEmployment(type: String, company: String, designation: String, income: Double) {
        guard var updatedProfile = activeProfile else { return }
        updatedProfile.employment = EmploymentInfo(
            employmentType: type,
            companyName: company,
            designation: designation,
            workExperienceYears: updatedProfile.employment.workExperienceYears,
            employerAddress: updatedProfile.employment.employerAddress
        )
        updatedProfile.income = IncomeInfo(
            monthlyIncome: income,
            annualIncome: income * 12.0,
            existingEMIs: updatedProfile.income.existingEMIs,
            creditScore: updatedProfile.income.creditScore,
            incomeSource: updatedProfile.income.incomeSource
        )
        
        BorrowerProfileStore.shared.updateProfile(updatedProfile)
    }
    
    func updateAdditionalInfo(
        occupation: String,
        hasExistingBankAccount: Bool,
        existingCustomerId: String?,
        preferredBranch: String,
        emergencyContactName: String,
        emergencyContactNumber: String,
        nomineeName: String,
        nomineeRelationship: String
    ) {
        guard var updatedProfile = activeProfile else { return }
        updatedProfile.occupation = occupation
        updatedProfile.hasExistingBankAccount = hasExistingBankAccount
        updatedProfile.existingCustomerId = existingCustomerId
        updatedProfile.preferredBranch = preferredBranch
        updatedProfile.emergencyContactName = emergencyContactName
        updatedProfile.emergencyContactNumber = emergencyContactNumber
        updatedProfile.nomineeName = nomineeName
        updatedProfile.nomineeRelationship = nomineeRelationship
        
        BorrowerProfileStore.shared.updateProfile(updatedProfile)
    }
    
    func updateBankDetails(bank: String, holder: String, account: String, ifsc: String, upi: String) {
        guard var updatedProfile = activeProfile else { return }
        updatedProfile.bankDetails = BankDetails(
            bankName: bank,
            accountHolderName: holder,
            accountNumber: account,
            ifscCode: ifsc,
            upiID: upi.isEmpty ? nil : upi,
            isVerified: updatedProfile.bankDetails.isVerified
        )
        
        BorrowerProfileStore.shared.updateProfile(updatedProfile)
    }
    
    func deletePrimaryBankDetails() {
        guard var updatedProfile = activeProfile else { return }
        updatedProfile.bankDetails = BankDetails(
            bankName: "",
            accountHolderName: "",
            accountNumber: "",
            ifscCode: "",
            upiID: nil,
            isVerified: false
        )
        
        BorrowerProfileStore.shared.updateProfile(updatedProfile)
    }

    func deleteLinkedBankAccount(withId id: UUID) {
        guard var updatedProfile = activeProfile else { return }
        var accounts = updatedProfile.linkedAccounts ?? []
        accounts.removeAll { $0.id == id }
        updatedProfile.linkedAccounts = accounts
        
        BorrowerProfileStore.shared.updateProfile(updatedProfile)
    }

    func addLinkedBankAccount(bank: String, account: String, ifsc: String, branch: String, customerId: String) {
        guard var updatedProfile = activeProfile else { return }

        let linkedAccount = LinkedBankAccount(
            id: UUID(),
            bankName: bank,
            accountNumber: account,
            ifscCode: ifsc,
            balance: 1_000_000,
            branch: branch,
            customerId: customerId
        )

        var accounts = updatedProfile.linkedAccounts ?? []
        accounts.append(linkedAccount)
        updatedProfile.linkedAccounts = accounts

        if updatedProfile.bankDetails.bankName.isEmpty && updatedProfile.bankDetails.accountNumber.isEmpty {
            updatedProfile.bankDetails = BankDetails(
                bankName: bank,
                accountHolderName: updatedProfile.fullName,
                accountNumber: account,
                ifscCode: ifsc,
                upiID: nil,
                isVerified: true
            )
        }

        BorrowerProfileStore.shared.updateProfile(updatedProfile)
    }
    
    func updateKYC(
        aadhaar: VerificationStatus,
        pan: VerificationStatus,
        addressProof: VerificationStatus,
        aadhaarFile: String? = nil,
        panFile: String? = nil,
        addressProofFile: String? = nil
    ) {
        guard var updatedProfile = activeProfile else { return }
        updatedProfile.kycVerification = KYCVerification(
            aadhaarStatus: aadhaar,
            panStatus: pan,
            addressProofStatus: addressProof,
            selfieStatus: updatedProfile.kycVerification.selfieStatus,
            aadhaarFileName: aadhaarFile ?? updatedProfile.kycVerification.aadhaarFileName,
            panFileName: panFile ?? updatedProfile.kycVerification.panFileName,
            addressProofFileName: addressProofFile ?? updatedProfile.kycVerification.addressProofFileName
        )
        
        BorrowerProfileStore.shared.updateProfile(updatedProfile)
    }
    
    func updateKYCDoc(type: KYCDocumentType, status: VerificationStatus, fileName: String? = nil) {
        guard var updatedProfile = activeProfile else { return }
        var currentKYC = updatedProfile.kycVerification
        
        switch type {
        case .aadhaar:
            currentKYC.aadhaarStatus = status
            currentKYC.aadhaarFileName = (status == .pending || status == .rejected) ? nil : (fileName ?? currentKYC.aadhaarFileName)
        case .pan:
            currentKYC.panStatus = status
            currentKYC.panFileName = (status == .pending || status == .rejected) ? nil : (fileName ?? currentKYC.panFileName)
        case .addressProof:
            currentKYC.addressProofStatus = status
            currentKYC.addressProofFileName = (status == .pending || status == .rejected) ? nil : (fileName ?? currentKYC.addressProofFileName)
        }
        
        updatedProfile.kycVerification = currentKYC
        BorrowerProfileStore.shared.updateProfile(updatedProfile)
    }
    
    func verifyMobile() {
        guard var updatedProfile = activeProfile else { return }
        updatedProfile.isPhoneVerified = true
        BorrowerProfileStore.shared.updateProfile(updatedProfile)
    }
    
    func verifyEmail() {
        guard var updatedProfile = activeProfile else { return }
        updatedProfile.isEmailVerified = true
        BorrowerProfileStore.shared.updateProfile(updatedProfile)
    }
    
    func updateProfileImage(data: Data) {
        guard var updatedProfile = activeProfile else { return }
        updatedProfile.profileImageData = data
        BorrowerProfileStore.shared.updateProfile(updatedProfile)
    }
    
    // Formatting Helpers
    func maskedAccountNumber(_ number: String) -> String {
        guard number.count > 4 else { return number }
        let suffix = number.suffix(4)
        return "•••• •••• \(suffix)"
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_IN")
        return formatter.string(from: NSNumber(value: amount)) ?? "₹0.00"
    }
}
