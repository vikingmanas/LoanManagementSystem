import Foundation
import Combine

enum KYCDocumentType {
    case aadhaar, pan, addressProof
}

class BorrowerProfileViewModel: ObservableObject {
    @Published var profile: BorrowerProfile?
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Observe changes from the shared store
        BorrowerProfileStore.shared.$profile
            .sink { [weak self] updatedProfile in
                self?.profile = updatedProfile
            }
            .store(in: &cancellables)
    }
    
    func updatePersonalInfo(fullName: String, gender: String, maritalStatus: String, nationality: String, dateOfBirth: Date, aadhaarNumber: String, panNumber: String) {
        guard var updatedProfile = profile else { return }
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
        guard var updatedProfile = profile else { return }
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
        guard var updatedProfile = profile else { return }
        let newAddress = AddressInfo(streetAddress: street, city: city, state: state, zipCode: zip, country: updatedProfile.currentAddress.country, isSameAsCurrent: isSame)
        updatedProfile.currentAddress = newAddress
        updatedProfile.permanentAddress = isSame ? newAddress : updatedProfile.permanentAddress
        
        BorrowerProfileStore.shared.updateProfile(updatedProfile)
    }
    
    func updateEmployment(type: String, company: String, designation: String, income: Double) {
        guard var updatedProfile = profile else { return }
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
    
    func updateBankDetails(bank: String, holder: String, account: String, ifsc: String, upi: String) {
        guard var updatedProfile = profile else { return }
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
    
    func updateKYC(
        aadhaar: VerificationStatus,
        pan: VerificationStatus,
        addressProof: VerificationStatus,
        aadhaarFile: String? = nil,
        panFile: String? = nil,
        addressProofFile: String? = nil
    ) {
        guard var updatedProfile = profile else { return }
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
        guard var updatedProfile = profile else { return }
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
        guard var updatedProfile = profile else { return }
        updatedProfile.isPhoneVerified = true
        BorrowerProfileStore.shared.updateProfile(updatedProfile)
    }
    
    func verifyEmail() {
        guard var updatedProfile = profile else { return }
        updatedProfile.isEmailVerified = true
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
