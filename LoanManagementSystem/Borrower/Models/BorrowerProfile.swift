import Foundation

struct BorrowerProfile: Codable, Equatable {
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
    var linkedAccounts: [LinkedBankAccount]?
    var gstNumber: String?
    
    var kycVerification: KYCVerification
    var loanOverview: LoanOverview
    
    var profileImageData: Data? = nil
    
    // New Onboarding Questionnaire Fields
    var occupation: String
    var industry: String
    var yearsOfExperience: Int
    var hasExistingBankAccount: Bool
    var existingCustomerId: String?
    var preferredBranch: String
    var existingLoansCount: Int
    var existingCreditCardsCount: Int
    var bankingRelationshipDuration: String
    var averageMonthlyBalance: Double
    
    var emergencyContactName: String
    var emergencyContactNumber: String
    var emergencyContactAlternateNumber: String
    var emergencyContactAddress: String
    var emergencyContactRelationship: String
    var nomineeName: String
    var nomineeRelationship: String
    var isOnboardingCompleted: Bool
    
    var isKYCVerified: Bool {
        return kycVerification.aadhaarStatus == .verified && kycVerification.panStatus == .verified
    }
    
    var profileCompletionPercentage: Int {
        var completedScore = 0
        let totalPossible = 130
        
        // 1. Personal Info
        if !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { completedScore += 10 }
        if !gender.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { completedScore += 5 }
        if !maritalStatus.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { completedScore += 5 }
        if !nationality.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { completedScore += 5 }
        completedScore += 5 // DOB is always populated from setup
        
        // 2. Contact Info
        if !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { completedScore += 5 }
        if isEmailVerified { completedScore += 5 }
        if !mobileNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { completedScore += 5 }
        if isPhoneVerified { completedScore += 5 }
        if let alt = alternateNumber, !alt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { completedScore += 5 }
        
        // 3. Address
        if !currentAddress.streetAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
           !currentAddress.city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { completedScore += 10 }
        
        // 4. Employment & Income
        if !employment.companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
           !employment.designation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { completedScore += 10 }
        if !occupation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { completedScore += 5 }
        if income.monthlyIncome > 0 { completedScore += 10 }
        
        // 5. Bank Account
        if !bankDetails.bankName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
           !bankDetails.accountNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
           !bankDetails.ifscCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { completedScore += 5 }
        
        // 6. Onboarding Questionnaire Details
        if !preferredBranch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { completedScore += 10 }
        if !nomineeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
           !nomineeRelationship.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { completedScore += 5 }
        
        // 7. KYC Uploads
        if kycVerification.aadhaarFileName != nil { completedScore += 5 }
        if kycVerification.panFileName != nil { completedScore += 5 }
        if kycVerification.addressProofFileName != nil { completedScore += 5 }
        
        // 8. Profile Picture
        if profileImageData != nil { completedScore += 5 }
        
        let percentage = (Double(completedScore) / Double(totalPossible)) * 100
        return min(100, max(0, Int(percentage)))
    }
    
    static func empty() -> BorrowerProfile {
        BorrowerProfile(
            id: "",
            fullName: "",
            email: "",
            mobileNumber: "",
            alternateNumber: nil,
            dateOfBirth: Date(),
            gender: "",
            maritalStatus: "",
            nationality: "",
            aadhaarNumber: "",
            panNumber: "",
            isEmailVerified: false,
            isPhoneVerified: false,
            currentAddress: AddressInfo(streetAddress: "", city: "", state: "", zipCode: "", country: "", isSameAsCurrent: false),
            permanentAddress: AddressInfo(streetAddress: "", city: "", state: "", zipCode: "", country: "", isSameAsCurrent: false),
            employment: EmploymentInfo(employmentType: "", companyName: "", designation: "", workExperienceYears: 0, employerAddress: ""),
            income: IncomeInfo(monthlyIncome: 0, annualIncome: 0, existingEMIs: 0, creditScore: 0, incomeSource: ""),
            bankDetails: BankDetails(bankName: "", accountHolderName: "", accountNumber: "", ifscCode: "", upiID: nil, isVerified: false),
            linkedAccounts: [],
            gstNumber: nil,
            kycVerification: KYCVerification(aadhaarStatus: .pending, panStatus: .pending, addressProofStatus: .pending, selfieStatus: .pending),
            loanOverview: LoanOverview(activeLoans: 0, loanHistoryCount: 0, nextEmiDueDate: nil, remainingBalance: 0, currentLoanStatus: "None"),
            occupation: "",
            industry: "",
            yearsOfExperience: 0,
            hasExistingBankAccount: false,
            existingCustomerId: nil,
            preferredBranch: "",
            existingLoansCount: 0,
            existingCreditCardsCount: 0,
            bankingRelationshipDuration: "",
            averageMonthlyBalance: 0,
            emergencyContactName: "",
            emergencyContactNumber: "",
            emergencyContactAlternateNumber: "",
            emergencyContactAddress: "",
            emergencyContactRelationship: "",
            nomineeName: "",
            nomineeRelationship: "",
            isOnboardingCompleted: false
        )
    }
}

struct AddressInfo: Codable, Equatable {
    let streetAddress: String
    let city: String
    let state: String
    let zipCode: String
    let country: String
    let isSameAsCurrent: Bool

    init(streetAddress: String, city: String, state: String, zipCode: String, country: String, isSameAsCurrent: Bool) {
        self.streetAddress = streetAddress
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
        self.isSameAsCurrent = isSameAsCurrent
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        streetAddress = try container.decodeIfPresent(String.self, forKey: .streetAddress) ?? ""
        city = try container.decodeIfPresent(String.self, forKey: .city) ?? ""
        state = try container.decodeIfPresent(String.self, forKey: .state) ?? ""
        zipCode = try container.decodeIfPresent(String.self, forKey: .zipCode) ?? ""
        country = try container.decodeIfPresent(String.self, forKey: .country) ?? ""
        isSameAsCurrent = try container.decodeIfPresent(Bool.self, forKey: .isSameAsCurrent) ?? false
    }
}

struct EmploymentInfo: Codable, Equatable {
    let employmentType: String // e.g. Salaried, Self-employed
    let companyName: String
    let designation: String
    let workExperienceYears: Int
    let employerAddress: String

    init(employmentType: String, companyName: String, designation: String, workExperienceYears: Int, employerAddress: String) {
        self.employmentType = employmentType
        self.companyName = companyName
        self.designation = designation
        self.workExperienceYears = workExperienceYears
        self.employerAddress = employerAddress
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        employmentType = try container.decodeIfPresent(String.self, forKey: .employmentType) ?? ""
        companyName = try container.decodeIfPresent(String.self, forKey: .companyName) ?? ""
        designation = try container.decodeIfPresent(String.self, forKey: .designation) ?? ""
        workExperienceYears = try container.decodeIfPresent(Int.self, forKey: .workExperienceYears) ?? 0
        employerAddress = try container.decodeIfPresent(String.self, forKey: .employerAddress) ?? ""
    }
}

struct IncomeInfo: Codable, Equatable {
    let monthlyIncome: Double
    let annualIncome: Double
    let existingEMIs: Double
    let creditScore: Int
    let incomeSource: String
    
    var eligibility: String {
        return creditScore > 750 ? "High" : (creditScore > 650 ? "Medium" : "Low")
    }

    init(monthlyIncome: Double, annualIncome: Double, existingEMIs: Double, creditScore: Int, incomeSource: String) {
        self.monthlyIncome = monthlyIncome
        self.annualIncome = annualIncome
        self.existingEMIs = existingEMIs
        self.creditScore = creditScore
        self.incomeSource = incomeSource
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        monthlyIncome = try container.decodeIfPresent(Double.self, forKey: .monthlyIncome) ?? 0.0
        annualIncome = try container.decodeIfPresent(Double.self, forKey: .annualIncome) ?? 0.0
        existingEMIs = try container.decodeIfPresent(Double.self, forKey: .existingEMIs) ?? 0.0
        creditScore = try container.decodeIfPresent(Int.self, forKey: .creditScore) ?? 700
        incomeSource = try container.decodeIfPresent(String.self, forKey: .incomeSource) ?? ""
    }
}

struct BankDetails: Codable, Equatable {
    let bankName: String
    let accountHolderName: String
    let accountNumber: String 
    let ifscCode: String
    let upiID: String?
    let isVerified: Bool

    init(bankName: String, accountHolderName: String, accountNumber: String, ifscCode: String, upiID: String?, isVerified: Bool) {
        self.bankName = bankName
        self.accountHolderName = accountHolderName
        self.accountNumber = accountNumber
        self.ifscCode = ifscCode
        self.upiID = upiID
        self.isVerified = isVerified
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bankName = try container.decodeIfPresent(String.self, forKey: .bankName) ?? ""
        accountHolderName = try container.decodeIfPresent(String.self, forKey: .accountHolderName) ?? ""
        accountNumber = try container.decodeIfPresent(String.self, forKey: .accountNumber) ?? ""
        ifscCode = try container.decodeIfPresent(String.self, forKey: .ifscCode) ?? ""
        upiID = try container.decodeIfPresent(String.self, forKey: .upiID)
        isVerified = try container.decodeIfPresent(Bool.self, forKey: .isVerified) ?? false
    }
}

enum LinkedAccountKind: String, Codable, Equatable {
    case savings
    case overdraft
}

struct LinkedBankAccount: Codable, Equatable, Identifiable {
    var id: UUID
    var bankName: String
    var accountNumber: String
    var ifscCode: String
    var balance: Double
    var branch: String
    var customerId: String
    var accountHolderName: String
    var accountKind: LinkedAccountKind
    var linkedLoanApplicationId: UUID?
    var odSanctionLimit: Double?

    var isOverdraftAccount: Bool {
        accountKind == .overdraft
    }

    init(
        id: UUID = UUID(),
        bankName: String,
        accountNumber: String,
        ifscCode: String,
        balance: Double,
        branch: String,
        customerId: String,
        accountHolderName: String = "",
        accountKind: LinkedAccountKind = .savings,
        linkedLoanApplicationId: UUID? = nil,
        odSanctionLimit: Double? = nil
    ) {
        self.id = id
        self.bankName = bankName
        self.accountNumber = accountNumber
        self.ifscCode = ifscCode
        self.balance = balance
        self.branch = branch
        self.customerId = customerId
        self.accountHolderName = accountHolderName
        self.accountKind = accountKind
        self.linkedLoanApplicationId = linkedLoanApplicationId
        self.odSanctionLimit = odSanctionLimit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        bankName = try container.decode(String.self, forKey: .bankName)
        accountNumber = try container.decode(String.self, forKey: .accountNumber)
        ifscCode = try container.decode(String.self, forKey: .ifscCode)
        balance = try container.decode(Double.self, forKey: .balance)
        branch = try container.decode(String.self, forKey: .branch)
        customerId = try container.decode(String.self, forKey: .customerId)
        accountHolderName = try container.decodeIfPresent(String.self, forKey: .accountHolderName) ?? ""
        accountKind = try container.decodeIfPresent(LinkedAccountKind.self, forKey: .accountKind) ?? .savings
        linkedLoanApplicationId = try container.decodeIfPresent(UUID.self, forKey: .linkedLoanApplicationId)
        odSanctionLimit = try container.decodeIfPresent(Double.self, forKey: .odSanctionLimit)
    }
}

struct KYCVerification: Codable, Equatable {
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

    init(aadhaarStatus: VerificationStatus, panStatus: VerificationStatus, addressProofStatus: VerificationStatus, selfieStatus: VerificationStatus, aadhaarFileName: String? = nil, panFileName: String? = nil, addressProofFileName: String? = nil) {
        self.aadhaarStatus = aadhaarStatus
        self.panStatus = panStatus
        self.addressProofStatus = addressProofStatus
        self.selfieStatus = selfieStatus
        self.aadhaarFileName = aadhaarFileName
        self.panFileName = panFileName
        self.addressProofFileName = addressProofFileName
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        aadhaarStatus = try container.decodeIfPresent(VerificationStatus.self, forKey: .aadhaarStatus) ?? .pending
        panStatus = try container.decodeIfPresent(VerificationStatus.self, forKey: .panStatus) ?? .pending
        addressProofStatus = try container.decodeIfPresent(VerificationStatus.self, forKey: .addressProofStatus) ?? .pending
        selfieStatus = try container.decodeIfPresent(VerificationStatus.self, forKey: .selfieStatus) ?? .pending
        aadhaarFileName = try container.decodeIfPresent(String.self, forKey: .aadhaarFileName)
        panFileName = try container.decodeIfPresent(String.self, forKey: .panFileName)
        addressProofFileName = try container.decodeIfPresent(String.self, forKey: .addressProofFileName)
    }
}

struct LoanOverview: Codable, Equatable {
    let activeLoans: Int
    let loanHistoryCount: Int
    let nextEmiDueDate: Date?
    let remainingBalance: Double
    let currentLoanStatus: String

    init(activeLoans: Int, loanHistoryCount: Int, nextEmiDueDate: Date?, remainingBalance: Double, currentLoanStatus: String) {
        self.activeLoans = activeLoans
        self.loanHistoryCount = loanHistoryCount
        self.nextEmiDueDate = nextEmiDueDate
        self.remainingBalance = remainingBalance
        self.currentLoanStatus = currentLoanStatus
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activeLoans = try container.decodeIfPresent(Int.self, forKey: .activeLoans) ?? 0
        loanHistoryCount = try container.decodeIfPresent(Int.self, forKey: .loanHistoryCount) ?? 0
        nextEmiDueDate = try container.decodeIfPresent(Date.self, forKey: .nextEmiDueDate)
        remainingBalance = try container.decodeIfPresent(Double.self, forKey: .remainingBalance) ?? 0.0
        currentLoanStatus = try container.decodeIfPresent(String.self, forKey: .currentLoanStatus) ?? "None"
    }
}

enum VerificationStatus: String, Codable, Equatable {
    case pending = "Pending"
    case underReview = "Under Review"
    case verified = "Verified"
    case rejected = "Rejected"
}
