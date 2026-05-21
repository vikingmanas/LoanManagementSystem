import Foundation

struct BorrowerProfile: Codable {
    var id: String
    var fullName: String
    var email: String
    var mobileNumber: String
    var alternateNumber: String?
    var dateOfBirth: Date
    var gender: String
    var maritalStatus: String
    var nationality: String
    var aadhaarNumber: String
    var panNumber: String
    
    var isEmailVerified: Bool
    var isPhoneVerified: Bool
    
    var currentAddress: AddressInfo
    var permanentAddress: AddressInfo
    
    var employment: EmploymentInfo
    var income: IncomeInfo
    
    var bankDetails: BankDetails
    
    var kycVerification: KYCVerification
    var loanOverview: LoanOverview
    
    var profileImageData: Data? = nil
    
    // New Onboarding Questionnaire Fields
    var occupation: String
    var hasExistingBankAccount: Bool
    var existingCustomerId: String?
    var preferredBranch: String
    var emergencyContactName: String
    var emergencyContactNumber: String
    var nomineeName: String
    var nomineeRelationship: String
    var loanPurposeInterests: [String]
    var isOnboardingCompleted: Bool
    
    var isKYCVerified: Bool {
        return kycVerification.aadhaarStatus == .verified && kycVerification.panStatus == .verified
    }
    
    var profileCompletionPercentage: Int {
        var completedScore = 0
        var totalPossible = 0
        
        // 1. Personal Info
        totalPossible += 10
        if !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completedScore += 10
        }
        
        totalPossible += 5
        if !gender.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completedScore += 5
        }
        
        totalPossible += 5
        if !maritalStatus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completedScore += 5
        }
        
        totalPossible += 5
        if !nationality.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completedScore += 5
        }
        
        totalPossible += 5
        completedScore += 5 // DOB is always populated from setup
        
        // 2. Contact Info
        totalPossible += 5
        if !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completedScore += 5
        }
        totalPossible += 5
        if isEmailVerified {
            completedScore += 5
        }
        
        totalPossible += 5
        if !mobileNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completedScore += 5
        }
        totalPossible += 5
        if isPhoneVerified {
            completedScore += 5
        }
        
        totalPossible += 5
        if let alt = alternateNumber, !alt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completedScore += 5
        }
        
        // 3. Address
        totalPossible += 10
        if !currentAddress.streetAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
           !currentAddress.city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completedScore += 10
        }
        
        // 4. Employment & Income
        totalPossible += 10
        if !employment.companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
           !employment.designation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completedScore += 10
        }
        
        totalPossible += 5
        if !occupation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completedScore += 5
        }
        
        totalPossible += 10
        if income.monthlyIncome > 0 {
            completedScore += 10
        }
        
        // 5. Bank Account
        totalPossible += 5
        if !bankDetails.bankName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
           !bankDetails.accountNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
           !bankDetails.ifscCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completedScore += 5
        }
        
        // 6. Onboarding Questionnaire Details
        totalPossible += 5
        if !preferredBranch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completedScore += 5
        }
        
        totalPossible += 5
        if !emergencyContactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
           !emergencyContactNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completedScore += 5
        }
        
        totalPossible += 5
        if !nomineeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
           !nomineeRelationship.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            completedScore += 5
        }
        
        totalPossible += 5
        if !loanPurposeInterests.isEmpty {
            completedScore += 5
        }
        
        // 7. KYC Uploads
        totalPossible += 5
        if kycVerification.aadhaarFileName != nil {
            completedScore += 5
        }
        totalPossible += 5
        if kycVerification.panFileName != nil {
            completedScore += 5
        }
        totalPossible += 5
        if kycVerification.addressProofFileName != nil {
            completedScore += 5
        }
        
        // 8. Profile Picture
        totalPossible += 5
        if profileImageData != nil {
            completedScore += 5
        }
        
        guard totalPossible > 0 else { return 0 }
        let percentage = (Double(completedScore) / Double(totalPossible)) * 100
        let finalPercent = min(100, max(0, Int(percentage)))
        print("DEBUG COMPLETION: completedScore = \(completedScore), totalPossible = \(totalPossible), percentage = \(finalPercent)%")
        return finalPercent
    }
}

struct AddressInfo: Codable {
    let streetAddress: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
    let isSameAsCurrent: Bool
}

struct EmploymentInfo: Codable {
    let employmentType: String // e.g. Salaried, Self-employed
    let companyName: String
    let designation: String
    let workExperienceYears: Int
    let employerAddress: String
}

struct IncomeInfo: Codable {
    let monthlyIncome: Double
    let annualIncome: Double
    let existingEMIs: Double
    let creditScore: Int
    let incomeSource: String
    
    var eligibility: String {
        return creditScore > 750 ? "High" : (creditScore > 650 ? "Medium" : "Low")
    }
}

struct BankDetails: Codable {
    let bankName: String
    let accountHolderName: String
    let accountNumber: String 
    let ifscCode: String
    let upiID: String?
    let isVerified: Bool
}

struct KYCVerification: Codable {
    var aadhaarStatus: VerificationStatus
    var panStatus: VerificationStatus
    var addressProofStatus: VerificationStatus
    var selfieStatus: VerificationStatus
    
    var aadhaarFileName: String?
    var panFileName: String?
    var addressProofFileName: String?
    
    var overallStatus: VerificationStatus {
        if aadhaarStatus == .verified && panStatus == .verified && addressProofStatus == .verified && selfieStatus == .verified {
            return .verified
        } else if aadhaarStatus == .rejected || panStatus == .rejected || addressProofStatus == .rejected || selfieStatus == .rejected {
            return .rejected
        } else {
            return .pending
        }
    }
}

struct LoanOverview: Codable {
    let activeLoans: Int
    let loanHistoryCount: Int
    let nextEmiDueDate: Date?
    let remainingBalance: Double
    let currentLoanStatus: String
}

enum VerificationStatus: String, Codable {
    case pending = "Pending"
    case underReview = "Under Review"
    case verified = "Verified"
    case rejected = "Rejected"
}
