import Foundation

public struct BorrowerProfile: Codable, Equatable {
    public var id: String
    public var fullName: String
    public var email: String
    public var mobileNumber: String
    public var alternateNumber: String?
    public var dateOfBirth: Date
    public var gender: String
    public var maritalStatus: String
    public var nationality: String
    public var aadhaarNumber: String
    public var panNumber: String
    
    public var isEmailVerified: Bool
    public var isPhoneVerified: Bool
    
    public var currentAddress: AddressInfo
    public var permanentAddress: AddressInfo
    
    public var employment: EmploymentInfo
    public var income: IncomeInfo
    
    public var bankDetails: BankDetails
    public var linkedAccounts: [LinkedBankAccount]?
    public var gstNumber: String?
    
    public var kycVerification: KYCVerification
    public var loanOverview: LoanOverview
    
    public var profileImageData: Data? = nil
    
    // New Onboarding Questionnaire Fields
    public var occupation: String
    public var industry: String
    public var yearsOfExperience: Int
    public var hasExistingBankAccount: Bool
    public var existingCustomerId: String?
    public var preferredBranch: String
    public var existingLoansCount: Int
    public var existingCreditCardsCount: Int
    public var bankingRelationshipDuration: String
    public var averageMonthlyBalance: Double
    
    public var emergencyContactName: String
    public var emergencyContactNumber: String
    public var emergencyContactAlternateNumber: String
    public var emergencyContactAddress: String
    public var emergencyContactRelationship: String
    public var nomineeName: String
    public var nomineeRelationship: String
    public var isOnboardingCompleted: Bool
    
    public var isKYCVerified: Bool {
        return kycVerification.aadhaarStatus == .verified && kycVerification.panStatus == .verified
    }
    
    public var profileCompletionPercentage: Int {
        var completedScore = 0
        let totalPossible = 110
        
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
        
        // 5. Onboarding Questionnaire Details
        if !preferredBranch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { completedScore += 10 }
        if !nomineeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
           !nomineeRelationship.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { completedScore += 5 }
        
        // 6. Profile Picture
        if profileImageData != nil { completedScore += 5 }
        
        let percentage = (Double(completedScore) / Double(totalPossible)) * 100
        return min(100, max(0, Int(percentage)))
    }
    
    public static func empty() -> BorrowerProfile {
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

public struct AddressInfo: Codable, Equatable {
    public let streetAddress: String
    public let city: String
    public let state: String
    public let zipCode: String
    public let country: String
    public let isSameAsCurrent: Bool

    public init(streetAddress: String, city: String, state: String, zipCode: String, country: String, isSameAsCurrent: Bool) {
        self.streetAddress = streetAddress
        self.city = city
        self.state = state
        self.zipCode = zipCode
        self.country = country
        self.isSameAsCurrent = isSameAsCurrent
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        streetAddress = try container.decodeIfPresent(String.self, forKey: .streetAddress) ?? ""
        city = try container.decodeIfPresent(String.self, forKey: .city) ?? ""
        state = try container.decodeIfPresent(String.self, forKey: .state) ?? ""
        zipCode = try container.decodeIfPresent(String.self, forKey: .zipCode) ?? ""
        country = try container.decodeIfPresent(String.self, forKey: .country) ?? ""
        isSameAsCurrent = try container.decodeIfPresent(Bool.self, forKey: .isSameAsCurrent) ?? false
    }
}

public struct EmploymentInfo: Codable, Equatable {
    public let employmentType: String // e.g. Salaried, Self-employed
    public let companyName: String
    public let designation: String
    public let workExperienceYears: Int
    public let employerAddress: String

    public init(employmentType: String, companyName: String, designation: String, workExperienceYears: Int, employerAddress: String) {
        self.employmentType = employmentType
        self.companyName = companyName
        self.designation = designation
        self.workExperienceYears = workExperienceYears
        self.employerAddress = employerAddress
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        employmentType = try container.decodeIfPresent(String.self, forKey: .employmentType) ?? ""
        companyName = try container.decodeIfPresent(String.self, forKey: .companyName) ?? ""
        designation = try container.decodeIfPresent(String.self, forKey: .designation) ?? ""
        workExperienceYears = try container.decodeIfPresent(Int.self, forKey: .workExperienceYears) ?? 0
        employerAddress = try container.decodeIfPresent(String.self, forKey: .employerAddress) ?? ""
    }
}

public struct IncomeInfo: Codable, Equatable {
    public let monthlyIncome: Double
    public let annualIncome: Double
    public let existingEMIs: Double
    public let creditScore: Int
    public let incomeSource: String
    
    public var eligibility: String {
        return creditScore > 750 ? "High" : (creditScore > 650 ? "Medium" : "Low")
    }

    public init(monthlyIncome: Double, annualIncome: Double, existingEMIs: Double, creditScore: Int, incomeSource: String) {
        self.monthlyIncome = monthlyIncome
        self.annualIncome = annualIncome
        self.existingEMIs = existingEMIs
        self.creditScore = creditScore
        self.incomeSource = incomeSource
    }

    enum CodingKeys: String, CodingKey {
        case monthlyIncome
        case annualIncome
        case existingEMIs = "existingEmIs"
        case creditScore
        case incomeSource
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        monthlyIncome = try container.decodeIfPresent(Double.self, forKey: .monthlyIncome) ?? 0.0
        annualIncome = try container.decodeIfPresent(Double.self, forKey: .annualIncome) ?? 0.0
        existingEMIs = try container.decodeIfPresent(Double.self, forKey: .existingEMIs) ?? 0.0
        creditScore = try container.decodeIfPresent(Int.self, forKey: .creditScore) ?? 0
        incomeSource = try container.decodeIfPresent(String.self, forKey: .incomeSource) ?? ""
    }
}

public struct BankDetails: Codable, Equatable {
    public let bankName: String
    public let accountHolderName: String
    public let accountNumber: String 
    public let ifscCode: String
    public let upiID: String?
    public let isVerified: Bool

    public init(bankName: String, accountHolderName: String, accountNumber: String, ifscCode: String, upiID: String?, isVerified: Bool) {
        self.bankName = bankName
        self.accountHolderName = accountHolderName
        self.accountNumber = accountNumber
        self.ifscCode = ifscCode
        self.upiID = upiID
        self.isVerified = isVerified
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        bankName = try container.decodeIfPresent(String.self, forKey: .bankName) ?? ""
        accountHolderName = try container.decodeIfPresent(String.self, forKey: .accountHolderName) ?? ""
        accountNumber = try container.decodeIfPresent(String.self, forKey: .accountNumber) ?? ""
        ifscCode = try container.decodeIfPresent(String.self, forKey: .ifscCode) ?? ""
        upiID = try container.decodeIfPresent(String.self, forKey: .upiID)
        isVerified = try container.decodeIfPresent(Bool.self, forKey: .isVerified) ?? false
    }
}

public enum LinkedAccountKind: String, Codable, Equatable {
    case savings
    case overdraft
}

public struct LinkedBankAccount: Codable, Equatable, Identifiable {
    public var id: UUID
    public var bankName: String
    public var accountNumber: String
    public var ifscCode: String
    public var balance: Double
    public var branch: String
    public var customerId: String
    public var accountHolderName: String
    public var accountKind: LinkedAccountKind
    public var linkedLoanApplicationId: UUID?
    public var odSanctionLimit: Double?

    public var isOverdraftAccount: Bool {
        accountKind == .overdraft
    }

    public init(
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

    public init(from decoder: Decoder) throws {
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

public struct KYCVerification: Codable, Equatable {
    public var aadhaarStatus: VerificationStatus
    public var panStatus: VerificationStatus
    public var addressProofStatus: VerificationStatus
    public var selfieStatus: VerificationStatus
    
    public var aadhaarFileName: String?
    public var panFileName: String?
    public var addressProofFileName: String?
    
    public var overallStatus: VerificationStatus {
        if aadhaarStatus == .verified && panStatus == .verified && addressProofStatus == .verified && selfieStatus == .verified {
            return .verified
        } else if aadhaarStatus == .rejected || panStatus == .rejected || addressProofStatus == .rejected || selfieStatus == .rejected {
            return .rejected
        } else {
            return .pending
        }
    }

    public init(aadhaarStatus: VerificationStatus, panStatus: VerificationStatus, addressProofStatus: VerificationStatus, selfieStatus: VerificationStatus, aadhaarFileName: String? = nil, panFileName: String? = nil, addressProofFileName: String? = nil) {
        self.aadhaarStatus = aadhaarStatus
        self.panStatus = panStatus
        self.addressProofStatus = addressProofStatus
        self.selfieStatus = selfieStatus
        self.aadhaarFileName = aadhaarFileName
        self.panFileName = panFileName
        self.addressProofFileName = addressProofFileName
    }

    public init(from decoder: Decoder) throws {
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

public struct LoanOverview: Codable, Equatable {
    public let activeLoans: Int
    public let loanHistoryCount: Int
    public let nextEmiDueDate: Date?
    public let remainingBalance: Double
    public let currentLoanStatus: String

    public init(activeLoans: Int, loanHistoryCount: Int, nextEmiDueDate: Date?, remainingBalance: Double, currentLoanStatus: String) {
        self.activeLoans = activeLoans
        self.loanHistoryCount = loanHistoryCount
        self.nextEmiDueDate = nextEmiDueDate
        self.remainingBalance = remainingBalance
        self.currentLoanStatus = currentLoanStatus
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        activeLoans = try container.decodeIfPresent(Int.self, forKey: .activeLoans) ?? 0
        loanHistoryCount = try container.decodeIfPresent(Int.self, forKey: .loanHistoryCount) ?? 0
        nextEmiDueDate = try container.decodeIfPresent(Date.self, forKey: .nextEmiDueDate)
        remainingBalance = try container.decodeIfPresent(Double.self, forKey: .remainingBalance) ?? 0.0
        currentLoanStatus = try container.decodeIfPresent(String.self, forKey: .currentLoanStatus) ?? "None"
    }
}

public enum VerificationStatus: String, Codable, Equatable {
    case pending = "Pending"
    case underReview = "Under Review"
    case verified = "Verified"
    case rejected = "Rejected"
}
