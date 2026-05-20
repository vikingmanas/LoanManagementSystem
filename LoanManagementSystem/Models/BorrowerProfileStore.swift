import Foundation
import Combine

class BorrowerProfileStore: ObservableObject {
    static let shared = BorrowerProfileStore()
    
    @Published var profile: BorrowerProfile?
    
    private init() {
        loadMockProfile()
    }
    
    func loadMockProfile() {
        // Shared mock profile configuration
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
    }
    
    func updateProfile(_ updatedProfile: BorrowerProfile) {
        self.profile = updatedProfile
    }
}
