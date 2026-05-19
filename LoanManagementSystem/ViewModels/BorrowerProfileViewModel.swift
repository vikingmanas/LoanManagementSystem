import Foundation
import Combine

enum KYCDocumentType {
    case aadhaar, pan, addressProof
}

class BorrowerProfileViewModel: ObservableObject {
    @Published var profile: BorrowerProfile?
    @Published var isLoading: Bool = false
    
    init() {
        loadProfile()
    }
    
    func loadProfile() {
        isLoading = true
        
        // Mocking a network call delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.profile = BorrowerProfile(
                id: "B-109482",
                fullName: "Rahul Sharma",
                email: "rahul.sharma@example.com",
                mobileNumber: "+91 98765 43210",
                alternateNumber: "+91 91234 56789",
                dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date(),
                gender: "Male",
                maritalStatus: "Single",
                nationality: "Indian",
                aadhaarNumber: "123456789012",
                panNumber: "ABCDE1234F",
                isEmailVerified: true,
                isPhoneVerified: true,
                currentAddress: AddressInfo(streetAddress: "14B, Tech Park Road, Andheri East", city: "Mumbai", state: "Maharashtra", zipCode: "400069", country: "India", isSameAsCurrent: true),
                permanentAddress: AddressInfo(streetAddress: "14B, Tech Park Road, Andheri East", city: "Mumbai", state: "Maharashtra", zipCode: "400069", country: "India", isSameAsCurrent: true),
                employment: EmploymentInfo(employmentType: "Salaried", companyName: "Tech Global Pvt Ltd.", designation: "Senior Software Engineer", workExperienceYears: 8, employerAddress: "Mindspace, Malad West, Mumbai"),
                income: IncomeInfo(monthlyIncome: 120000.0, annualIncome: 1440000.0, existingEMIs: 15000.0, creditScore: 780, incomeSource: "Salary"),
                bankDetails: BankDetails(bankName: "HDFC Bank", accountHolderName: "Rahul Sharma", accountNumber: "50100234567890", ifscCode: "HDFC0001234", upiID: "rahulsharma@okhdfcbank", isVerified: true),
                kycVerification: KYCVerification(aadhaarStatus: .verified, panStatus: .verified, addressProofStatus: .rejected, selfieStatus: .verified, aadhaarFileName: "aadhaar_card.pdf", panFileName: "pan_card.pdf", addressProofFileName: nil),
                loanOverview: LoanOverview(activeLoans: 1, loanHistoryCount: 2, nextEmiDueDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()), remainingBalance: 450000.0, currentLoanStatus: "Active")
            )
            self.isLoading = false
        }
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
        self.profile = updatedProfile
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
        self.profile = updatedProfile
    }
    
    func updateAddress(street: String, city: String, state: String, zip: String, isSame: Bool) {
        guard var updatedProfile = profile else { return }
        let newAddress = AddressInfo(streetAddress: street, city: city, state: state, zipCode: zip, country: updatedProfile.currentAddress.country, isSameAsCurrent: isSame)
        updatedProfile.currentAddress = newAddress
        updatedProfile.permanentAddress = isSame ? newAddress : updatedProfile.permanentAddress
        self.profile = updatedProfile
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
        self.profile = updatedProfile
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
        self.profile = updatedProfile
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
        self.profile = updatedProfile
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
        self.profile = updatedProfile
    }
    
    func verifyMobile() {
        guard var updatedProfile = profile else { return }
        updatedProfile.isPhoneVerified = true
        self.profile = updatedProfile
    }
    
    func verifyEmail() {
        guard var updatedProfile = profile else { return }
        updatedProfile.isEmailVerified = true
        self.profile = updatedProfile
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
