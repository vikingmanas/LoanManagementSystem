import SwiftUI

enum LoanProductCategoryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case personal = "Personal"
    case home = "Home"
    case agriculture = "Agriculture"
    case lap = "LAP"
    case consumer = "Consumer"
    case msme = "MSME"

    var id: String { rawValue }

    var productType: BorrowerLoanProductType? {
        switch self {
        case .all: return nil
        case .personal: return .personal
        case .home: return .home
        case .agriculture: return .agriculture
        case .lap: return .loanAgainstProperty
        case .consumer: return .consumer
        case .msme: return .msmeStartup
        }
    }
}

enum BorrowerLoanProductType: String, Codable, CaseIterable, Identifiable, Hashable {
    case personal
    case home
    case education
    case business
    case vehicle
    case agriculture
    case consumer
    case msmeStartup
    case gold
    case loanAgainstProperty
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .personal: return "Personal Loan"
        case .home: return "Home Loan"
        case .education: return "Education Loan"
        case .business: return "Business Loan"
        case .vehicle: return "Vehicle Loan"
        case .agriculture: return "Agriculture Loan"
        case .consumer: return "Credit Card / Consumer Loan"
        case .msmeStartup: return "MSME / Startup Loan"
        case .gold: return "Gold Loan"
        case .loanAgainstProperty: return "Loan Against Property"
        case .other: return "Special Assistance Loan"
        }
    }

    var iconName: String {
        switch self {
        case .personal: return "person.text.rectangle.fill"
        case .home: return "house.fill"
        case .education: return "graduationcap.fill"
        case .business: return "briefcase.fill"
        case .vehicle: return "car.fill"
        case .agriculture: return "leaf.fill"
        case .consumer: return "creditcard.fill"
        case .msmeStartup: return "chart.line.uptrend.xyaxis"
        case .gold: return "seal.fill"
        case .loanAgainstProperty: return "building.columns.fill"
        case .other: return "sparkles"
        }
    }
}

struct BorrowerLoanFAQ: Codable, Identifiable, Hashable {
    let id: UUID
    var question: String
    var answer: String
    
    init(id: UUID = UUID(), question: String, answer: String) {
        self.id = id
        self.question = question
        self.answer = answer
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case question
        case answer
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.question = try container.decode(String.self, forKey: .question)
        self.answer = try container.decode(String.self, forKey: .answer)
    }
}

struct BorrowerLoanProduct: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var type: BorrowerLoanProductType
    var minAmount: Double
    var maximumAmount: Double
    var minTenureMonths: Int
    var maxTenureMonths: Int
    var baseInterestRate: Double
    var processingFeePct: Double
    
    var shortDescription: String
    var interestRateRange: String
    var estimatedProcessingTime: String
    var eligibilitySnapshot: String
    var purpose: String
    var benefits: [String]
    var eligibilityCriteria: [String]
    var minimumRequirements: [String]
    var interestInformation: String
    var repaymentOverview: String
    var processingFees: String
    var faqs: [BorrowerLoanFAQ]
    var loanSpecificDocuments: [String]
    
    init(
        id: UUID,
        type: BorrowerLoanProductType,
        shortDescription: String,
        maximumAmount: Double,
        interestRateRange: String,
        estimatedProcessingTime: String,
        eligibilitySnapshot: String,
        purpose: String,
        benefits: [String],
        eligibilityCriteria: [String],
        minimumRequirements: [String],
        interestInformation: String,
        repaymentOverview: String,
        processingFees: String,
        faqs: [BorrowerLoanFAQ],
        loanSpecificDocuments: [String]
    ) {
        self.id = id
        self.name = type.title
        self.type = type
        self.minAmount = 0
        self.maximumAmount = maximumAmount
        self.minTenureMonths = 12
        self.maxTenureMonths = 360
        self.baseInterestRate = 0
        self.processingFeePct = 0
        
        self.shortDescription = shortDescription
        self.interestRateRange = interestRateRange
        self.estimatedProcessingTime = estimatedProcessingTime
        self.eligibilitySnapshot = eligibilitySnapshot
        self.purpose = purpose
        self.benefits = benefits
        self.eligibilityCriteria = eligibilityCriteria
        self.minimumRequirements = minimumRequirements
        self.interestInformation = interestInformation
        self.repaymentOverview = repaymentOverview
        self.processingFees = processingFees
        self.faqs = faqs
        self.loanSpecificDocuments = loanSpecificDocuments
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "productId"
        case name
        case type = "loanType"
        case minAmount
        case maximumAmount = "maxAmount"
        case minTenureMonths
        case maxTenureMonths
        case baseInterestRate
        case processingFeePct
        case richDetails
    }
    
    enum RichDetailsKeys: String, CodingKey {
        case shortDescription
        case interestRateRange
        case estimatedProcessingTime
        case eligibilitySnapshot
        case purpose
        case benefits
        case eligibilityCriteria
        case minimumRequirements
        case interestInformation
        case repaymentOverview
        case processingFees
        case faqs
        case loanSpecificDocuments
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        
        let rawType = try container.decode(String.self, forKey: .type)
        self.type = BorrowerLoanProductType(rawValue: rawType) ?? .other
        
        self.minAmount = try container.decode(Double.self, forKey: .minAmount)
        self.maximumAmount = try container.decode(Double.self, forKey: .maximumAmount)
        self.minTenureMonths = try container.decode(Int.self, forKey: .minTenureMonths)
        self.maxTenureMonths = try container.decode(Int.self, forKey: .maxTenureMonths)
        self.baseInterestRate = try container.decode(Double.self, forKey: .baseInterestRate)
        self.processingFeePct = try container.decode(Double.self, forKey: .processingFeePct)
        
        if container.contains(.richDetails) {
            let richContainer = try container.nestedContainer(keyedBy: RichDetailsKeys.self, forKey: .richDetails)
            self.shortDescription = try richContainer.decodeIfPresent(String.self, forKey: .shortDescription) ?? ""
            self.interestRateRange = try richContainer.decodeIfPresent(String.self, forKey: .interestRateRange) ?? ""
            self.estimatedProcessingTime = try richContainer.decodeIfPresent(String.self, forKey: .estimatedProcessingTime) ?? ""
            self.eligibilitySnapshot = try richContainer.decodeIfPresent(String.self, forKey: .eligibilitySnapshot) ?? ""
            self.purpose = try richContainer.decodeIfPresent(String.self, forKey: .purpose) ?? ""
            self.benefits = try richContainer.decodeIfPresent([String].self, forKey: .benefits) ?? []
            self.eligibilityCriteria = try richContainer.decodeIfPresent([String].self, forKey: .eligibilityCriteria) ?? []
            self.minimumRequirements = try richContainer.decodeIfPresent([String].self, forKey: .minimumRequirements) ?? []
            self.interestInformation = try richContainer.decodeIfPresent(String.self, forKey: .interestInformation) ?? ""
            self.repaymentOverview = try richContainer.decodeIfPresent(String.self, forKey: .repaymentOverview) ?? ""
            self.processingFees = try richContainer.decodeIfPresent(String.self, forKey: .processingFees) ?? ""
            self.faqs = try richContainer.decodeIfPresent([BorrowerLoanFAQ].self, forKey: .faqs) ?? []
            self.loanSpecificDocuments = try richContainer.decodeIfPresent([String].self, forKey: .loanSpecificDocuments) ?? []
        } else {
            self.shortDescription = ""
            self.interestRateRange = ""
            self.estimatedProcessingTime = ""
            self.eligibilitySnapshot = ""
            self.purpose = ""
            self.benefits = []
            self.eligibilityCriteria = []
            self.minimumRequirements = []
            self.interestInformation = ""
            self.repaymentOverview = ""
            self.processingFees = ""
            self.faqs = []
            self.loanSpecificDocuments = []
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(type.rawValue, forKey: .type)
        try container.encode(minAmount, forKey: .minAmount)
        try container.encode(maximumAmount, forKey: .maximumAmount)
        try container.encode(minTenureMonths, forKey: .minTenureMonths)
        try container.encode(maxTenureMonths, forKey: .maxTenureMonths)
        try container.encode(baseInterestRate, forKey: .baseInterestRate)
        try container.encode(processingFeePct, forKey: .processingFeePct)
        
        var richContainer = container.nestedContainer(keyedBy: RichDetailsKeys.self, forKey: .richDetails)
        try richContainer.encode(shortDescription, forKey: .shortDescription)
        try richContainer.encode(interestRateRange, forKey: .interestRateRange)
        try richContainer.encode(estimatedProcessingTime, forKey: .estimatedProcessingTime)
        try richContainer.encode(eligibilitySnapshot, forKey: .eligibilitySnapshot)
        try richContainer.encode(purpose, forKey: .purpose)
        try richContainer.encode(benefits, forKey: .benefits)
        try richContainer.encode(eligibilityCriteria, forKey: .eligibilityCriteria)
        try richContainer.encode(minimumRequirements, forKey: .minimumRequirements)
        try richContainer.encode(interestInformation, forKey: .interestInformation)
        try richContainer.encode(repaymentOverview, forKey: .repaymentOverview)
        try richContainer.encode(processingFees, forKey: .processingFees)
        try richContainer.encode(faqs, forKey: .faqs)
        try richContainer.encode(loanSpecificDocuments, forKey: .loanSpecificDocuments)
    }
}

enum BorrowerDocumentCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case identityVerification = "Identity Verification"
    case addressVerification = "Address Verification"
    case incomeVerification = "Income Verification"
    case loanSpecific = "Loan-Specific Documents"

    var id: String { rawValue }
}

enum BorrowerDocumentStatus: String, Codable, CaseIterable, Hashable {
    case pendingUpload = "Pending Upload"
    case uploaded = "Uploaded"
    case underVerification = "Under Verification"
    case verified = "Verified"
    case rejected = "Rejected"
    case requiresResubmission = "Requires Resubmission"

    var iconName: String {
        switch self {
        case .pendingUpload: return "tray"
        case .uploaded: return "arrow.up.doc.fill"
        case .underVerification: return "clock.badge.checkmark.fill"
        case .verified: return "checkmark.seal.fill"
        case .rejected: return "xmark.octagon.fill"
        case .requiresResubmission: return "arrow.triangle.2.circlepath.doc.on.clipboard"
        }
    }

    var tintColor: Color {
        switch self {
        case .pendingUpload:
            return Color(.secondaryLabel)
        case .uploaded:
            return LMSColors.brandNavy
        case .underVerification:
            return .orange
        case .verified:
            return LMSColors.emerald
        case .rejected:
            return LMSColors.coral
        case .requiresResubmission:
            return .orange
        }
    }

    var uploadStatusText: String {
        switch self {
        case .pendingUpload:
            return "Not Uploaded"
        case .uploaded, .underVerification, .verified:
            return "Uploaded"
        case .rejected, .requiresResubmission:
            return "Uploaded (Needs Update)"
        }
    }

    var verificationStatusText: String {
        switch self {
        case .pendingUpload:
            return "Pending Upload"
        case .uploaded:
            return "Pending Verification"
        case .underVerification:
            return "Under Verification"
        case .verified:
            return "Verified"
        case .rejected:
            return "Rejected"
        case .requiresResubmission:
            return "Requires Resubmission"
        }
    }

    var requiresAction: Bool {
        self == .pendingUpload || self == .rejected || self == .requiresResubmission
    }
}

enum BorrowerDocumentUploadSource: String, Identifiable, Hashable {
    case camera = "Take Photo"
    case gallery = "Choose from Gallery"
    case pdf = "PDF Upload"
    case dragAndDrop = "Drag & Drop"

    var id: String { rawValue }

    static var mobileSources: [BorrowerDocumentUploadSource] {
        [.camera, .gallery, .pdf]
    }

    var iconName: String {
        switch self {
        case .camera: return "camera.fill"
        case .gallery: return "photo.on.rectangle.angled"
        case .pdf: return "doc.richtext.fill"
        case .dragAndDrop: return "arrow.down.doc.fill"
        }
    }

    var sourceDescription: String {
        switch self {
        case .camera: return "Choose document using camera"
        case .gallery: return "Upload JPG, PNG, or HEIC from Photos"
        case .pdf: return "Upload a PDF document from Files"
        case .dragAndDrop: return "Drag and drop is unavailable on mobile"
        }
    }
}

struct BorrowerLoanDocumentItem: Codable, Identifiable, Hashable {
    let id: UUID
    var name: String
    var category: BorrowerDocumentCategory
    var status: BorrowerDocumentStatus
    var fileName: String?
    var fileUrl: String?
    var uploadDate: Date?
    var lastUpdated: Date?
    var isLocked: Bool
}

struct BorrowerLoanFormData: Codable, Equatable, Hashable {
    var fullName: String
    var dateOfBirth: Date
    var gender: String
    var mobileNumber: String
    var emailAddress: String
    var address: String
    var preferredBranch: String

    var occupation: String
    var employmentType: String
    var employerName: String
    var workExperienceYears: Int

    var monthlyIncome: String
    var annualIncome: String
    var existingLoans: String
    var existingEMIs: String
    var creditCardObligations: String
    var creditScore: String

    var loanAmountRequested: String
    var loanPurpose: String
    var repaymentPreference: String
    var preferredTenureMonths: Int

    var hasCoApplicant: Bool
    var coApplicantDetails: String
    var hasGuarantor: Bool
    var guarantorDetails: String
    var gstNumber: String

    var selectedIdentityDoc: String
    var selectedAddressDoc: String
    var selectedIncomeDoc: String

    var draftStepIndex: Int
    var bankName: String
    var bankAccountNumber: String
    var bankIFSCCode: String
    var bankRegisteredMobile: String
    var monthlySalaryDeposited: String
    var employmentJoiningDate: Date?
    var creditCardLimit: String
    var savingsInvestments: String
    var coApplicantMobile: String
    var coApplicantPAN: String
    var coApplicantAadhaar: String
    var coApplicantIncome: String
    var autoDebitConsent: Bool
    var nomineeName: String
    var nomineeRelation: String
    var nomineeMobile: String
    var referenceName: String
    var referenceMobile: String
    var emergencyContactName: String
    var emergencyContactMobile: String
    var signatureImageData: String
    var signatureVerificationStatus: String
    var liveVerificationCompleted: Bool
    var liveVerificationReference: String
    var selfieVerificationStatus: String
    var acceptedTerms: Bool
    var acceptedBureauConsent: Bool
    var acceptedDebitConsent: Bool

    enum CodingKeys: String, CodingKey {
        case fullName
        case dateOfBirth
        case gender
        case mobileNumber
        case emailAddress
        case address
        case preferredBranch
        case occupation
        case employmentType
        case employerName
        case workExperienceYears
        case monthlyIncome
        case annualIncome
        case existingLoans
        case existingEMIs = "existingEmIs"
        case creditCardObligations
        case creditScore
        case loanAmountRequested
        case loanPurpose
        case repaymentPreference
        case preferredTenureMonths
        case hasCoApplicant
        case coApplicantDetails
        case hasGuarantor
        case guarantorDetails
        case gstNumber
        case selectedIdentityDoc
        case selectedAddressDoc
        case selectedIncomeDoc
        case draftStepIndex
        case bankName
        case bankAccountNumber
        case bankIFSCCode
        case bankRegisteredMobile
        case monthlySalaryDeposited
        case employmentJoiningDate
        case creditCardLimit
        case savingsInvestments
        case coApplicantMobile
        case coApplicantPAN
        case coApplicantAadhaar
        case coApplicantIncome
        case autoDebitConsent
        case nomineeName
        case nomineeRelation
        case nomineeMobile
        case referenceName
        case referenceMobile
        case emergencyContactName
        case emergencyContactMobile
        case signatureImageData
        case signatureVerificationStatus
        case liveVerificationCompleted
        case liveVerificationReference
        case selfieVerificationStatus
        case acceptedTerms
        case acceptedBureauConsent
        case acceptedDebitConsent
    }

    var monthlyIncomeValue: Double { monthlyIncome.numericValue }
    var annualIncomeValue: Double { annualIncome.numericValue }
    var existingLoansValue: Double { existingLoans.numericValue }
    var existingEMIsValue: Double { existingEMIs.numericValue }
    var creditCardObligationsValue: Double { creditCardObligations.numericValue }
    var creditScoreValue: Int { Int(creditScore.numericValue) }
    var requestedAmountValue: Double { loanAmountRequested.numericValue }

    init(
        fullName: String,
        dateOfBirth: Date,
        gender: String = "",
        mobileNumber: String,
        emailAddress: String,
        address: String,
        preferredBranch: String = "",
        occupation: String,
        employmentType: String,
        employerName: String,
        workExperienceYears: Int,
        monthlyIncome: String,
        annualIncome: String,
        existingLoans: String,
        existingEMIs: String,
        creditCardObligations: String,
        creditScore: String,
        loanAmountRequested: String,
        loanPurpose: String,
        repaymentPreference: String,
        preferredTenureMonths: Int,
        hasCoApplicant: Bool,
        coApplicantDetails: String,
        hasGuarantor: Bool,
        guarantorDetails: String,
        gstNumber: String = "",
        selectedIdentityDoc: String = "Aadhaar Card",
        selectedAddressDoc: String = "Utility Bill",
        selectedIncomeDoc: String = "Salary Slips",
        draftStepIndex: Int = 1,
        bankName: String = "",
        bankAccountNumber: String = "",
        bankIFSCCode: String = "",
        bankRegisteredMobile: String = "",
        monthlySalaryDeposited: String = "",
        employmentJoiningDate: Date? = nil,
        creditCardLimit: String = "",
        savingsInvestments: String = "",
        coApplicantMobile: String = "",
        coApplicantPAN: String = "",
        coApplicantAadhaar: String = "",
        coApplicantIncome: String = "",
        autoDebitConsent: Bool = false,
        nomineeName: String = "",
        nomineeRelation: String = "",
        nomineeMobile: String = "",
        referenceName: String = "",
        referenceMobile: String = "",
        emergencyContactName: String = "",
        emergencyContactMobile: String = "",
        signatureImageData: String = "",
        signatureVerificationStatus: String = "",
        liveVerificationCompleted: Bool = false,
        liveVerificationReference: String = "",
        selfieVerificationStatus: String = "",
        acceptedTerms: Bool = false,
        acceptedBureauConsent: Bool = false,
        acceptedDebitConsent: Bool = false
    ) {
        self.fullName = fullName
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.mobileNumber = mobileNumber
        self.emailAddress = emailAddress
        self.address = address
        self.preferredBranch = preferredBranch
        self.occupation = occupation
        self.employmentType = employmentType
        self.employerName = employerName
        self.workExperienceYears = workExperienceYears
        self.monthlyIncome = monthlyIncome
        self.annualIncome = annualIncome
        self.existingLoans = existingLoans
        self.existingEMIs = existingEMIs
        self.creditCardObligations = creditCardObligations
        self.creditScore = creditScore
        self.loanAmountRequested = loanAmountRequested
        self.loanPurpose = loanPurpose
        self.repaymentPreference = repaymentPreference
        self.preferredTenureMonths = preferredTenureMonths
        self.hasCoApplicant = hasCoApplicant
        self.coApplicantDetails = coApplicantDetails
        self.hasGuarantor = hasGuarantor
        self.guarantorDetails = guarantorDetails
        self.gstNumber = gstNumber
        self.selectedIdentityDoc = selectedIdentityDoc
        self.selectedAddressDoc = selectedAddressDoc
        self.selectedIncomeDoc = selectedIncomeDoc
        self.draftStepIndex = min(max(draftStepIndex, 1), 9)
        self.bankName = bankName
        self.bankAccountNumber = bankAccountNumber
        self.bankIFSCCode = bankIFSCCode
        self.bankRegisteredMobile = bankRegisteredMobile
        self.monthlySalaryDeposited = monthlySalaryDeposited
        self.employmentJoiningDate = employmentJoiningDate
        self.creditCardLimit = creditCardLimit
        self.savingsInvestments = savingsInvestments
        self.coApplicantMobile = coApplicantMobile
        self.coApplicantPAN = coApplicantPAN
        self.coApplicantAadhaar = coApplicantAadhaar
        self.coApplicantIncome = coApplicantIncome
        self.autoDebitConsent = autoDebitConsent
        self.nomineeName = nomineeName
        self.nomineeRelation = nomineeRelation
        self.nomineeMobile = nomineeMobile
        self.referenceName = referenceName
        self.referenceMobile = referenceMobile
        self.emergencyContactName = emergencyContactName
        self.emergencyContactMobile = emergencyContactMobile
        self.signatureImageData = signatureImageData
        self.signatureVerificationStatus = signatureVerificationStatus
        self.liveVerificationCompleted = liveVerificationCompleted
        self.liveVerificationReference = liveVerificationReference
        self.selfieVerificationStatus = selfieVerificationStatus
        self.acceptedTerms = acceptedTerms
        self.acceptedBureauConsent = acceptedBureauConsent
        self.acceptedDebitConsent = acceptedDebitConsent
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            fullName: try container.decodeIfPresent(String.self, forKey: .fullName) ?? "",
            dateOfBirth: try container.decodeIfPresent(Date.self, forKey: .dateOfBirth) ?? Self.empty.dateOfBirth,
            gender: try container.decodeIfPresent(String.self, forKey: .gender) ?? "",
            mobileNumber: try container.decodeIfPresent(String.self, forKey: .mobileNumber) ?? "",
            emailAddress: try container.decodeIfPresent(String.self, forKey: .emailAddress) ?? "",
            address: try container.decodeIfPresent(String.self, forKey: .address) ?? "",
            preferredBranch: try container.decodeIfPresent(String.self, forKey: .preferredBranch) ?? "",
            occupation: try container.decodeIfPresent(String.self, forKey: .occupation) ?? "",
            employmentType: try container.decodeIfPresent(String.self, forKey: .employmentType) ?? "Salaried",
            employerName: try container.decodeIfPresent(String.self, forKey: .employerName) ?? "",
            workExperienceYears: try container.decodeIfPresent(Int.self, forKey: .workExperienceYears) ?? 0,
            monthlyIncome: try container.decodeIfPresent(String.self, forKey: .monthlyIncome) ?? "",
            annualIncome: try container.decodeIfPresent(String.self, forKey: .annualIncome) ?? "",
            existingLoans: try container.decodeIfPresent(String.self, forKey: .existingLoans) ?? "",
            existingEMIs: try container.decodeIfPresent(String.self, forKey: .existingEMIs) ?? "",
            creditCardObligations: try container.decodeIfPresent(String.self, forKey: .creditCardObligations) ?? "",
            creditScore: try container.decodeIfPresent(String.self, forKey: .creditScore) ?? "",
            loanAmountRequested: try container.decodeIfPresent(String.self, forKey: .loanAmountRequested) ?? "",
            loanPurpose: try container.decodeIfPresent(String.self, forKey: .loanPurpose) ?? "",
            repaymentPreference: try container.decodeIfPresent(String.self, forKey: .repaymentPreference) ?? "EMI Auto-Debit",
            preferredTenureMonths: try container.decodeIfPresent(Int.self, forKey: .preferredTenureMonths) ?? 60,
            hasCoApplicant: try container.decodeIfPresent(Bool.self, forKey: .hasCoApplicant) ?? false,
            coApplicantDetails: try container.decodeIfPresent(String.self, forKey: .coApplicantDetails) ?? "",
            hasGuarantor: try container.decodeIfPresent(Bool.self, forKey: .hasGuarantor) ?? false,
            guarantorDetails: try container.decodeIfPresent(String.self, forKey: .guarantorDetails) ?? "",
            gstNumber: try container.decodeIfPresent(String.self, forKey: .gstNumber) ?? "",
            selectedIdentityDoc: try container.decodeIfPresent(String.self, forKey: .selectedIdentityDoc) ?? "Aadhaar Card",
            selectedAddressDoc: try container.decodeIfPresent(String.self, forKey: .selectedAddressDoc) ?? "Utility Bill",
            selectedIncomeDoc: try container.decodeIfPresent(String.self, forKey: .selectedIncomeDoc) ?? "Salary Slips",
            draftStepIndex: try container.decodeIfPresent(Int.self, forKey: .draftStepIndex) ?? 1,
            bankName: try container.decodeIfPresent(String.self, forKey: .bankName) ?? "",
            bankAccountNumber: try container.decodeIfPresent(String.self, forKey: .bankAccountNumber) ?? "",
            bankIFSCCode: try container.decodeIfPresent(String.self, forKey: .bankIFSCCode) ?? "",
            bankRegisteredMobile: try container.decodeIfPresent(String.self, forKey: .bankRegisteredMobile) ?? "",
            monthlySalaryDeposited: try container.decodeIfPresent(String.self, forKey: .monthlySalaryDeposited) ?? "",
            employmentJoiningDate: try container.decodeIfPresent(Date.self, forKey: .employmentJoiningDate),
            creditCardLimit: try container.decodeIfPresent(String.self, forKey: .creditCardLimit) ?? "",
            savingsInvestments: try container.decodeIfPresent(String.self, forKey: .savingsInvestments) ?? "",
            coApplicantMobile: try container.decodeIfPresent(String.self, forKey: .coApplicantMobile) ?? "",
            coApplicantPAN: try container.decodeIfPresent(String.self, forKey: .coApplicantPAN) ?? "",
            coApplicantAadhaar: try container.decodeIfPresent(String.self, forKey: .coApplicantAadhaar) ?? "",
            coApplicantIncome: try container.decodeIfPresent(String.self, forKey: .coApplicantIncome) ?? "",
            autoDebitConsent: try container.decodeIfPresent(Bool.self, forKey: .autoDebitConsent) ?? false,
            nomineeName: try container.decodeIfPresent(String.self, forKey: .nomineeName) ?? "",
            nomineeRelation: try container.decodeIfPresent(String.self, forKey: .nomineeRelation) ?? "",
            nomineeMobile: try container.decodeIfPresent(String.self, forKey: .nomineeMobile) ?? "",
            referenceName: try container.decodeIfPresent(String.self, forKey: .referenceName) ?? "",
            referenceMobile: try container.decodeIfPresent(String.self, forKey: .referenceMobile) ?? "",
            emergencyContactName: try container.decodeIfPresent(String.self, forKey: .emergencyContactName) ?? "",
            emergencyContactMobile: try container.decodeIfPresent(String.self, forKey: .emergencyContactMobile) ?? "",
            signatureImageData: try container.decodeIfPresent(String.self, forKey: .signatureImageData) ?? "",
            signatureVerificationStatus: try container.decodeIfPresent(String.self, forKey: .signatureVerificationStatus) ?? "",
            liveVerificationCompleted: try container.decodeIfPresent(Bool.self, forKey: .liveVerificationCompleted) ?? false,
            liveVerificationReference: try container.decodeIfPresent(String.self, forKey: .liveVerificationReference) ?? "",
            selfieVerificationStatus: try container.decodeIfPresent(String.self, forKey: .selfieVerificationStatus) ?? "",
            acceptedTerms: try container.decodeIfPresent(Bool.self, forKey: .acceptedTerms) ?? false,
            acceptedBureauConsent: try container.decodeIfPresent(Bool.self, forKey: .acceptedBureauConsent) ?? false,
            acceptedDebitConsent: try container.decodeIfPresent(Bool.self, forKey: .acceptedDebitConsent) ?? false
        )
    }

    static let empty = BorrowerLoanFormData(
        fullName: "",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -26, to: Date()) ?? Date(),
        gender: "",
        mobileNumber: "",
        emailAddress: "",
        address: "",
        preferredBranch: "",
        occupation: "",
        employmentType: "Salaried",
        employerName: "",
        workExperienceYears: 0,
        monthlyIncome: "",
        annualIncome: "",
        existingLoans: "",
        existingEMIs: "",
        creditCardObligations: "",
        creditScore: "",
        loanAmountRequested: "",
        loanPurpose: "",
        repaymentPreference: "EMI Auto-Debit",
        preferredTenureMonths: 60,
        hasCoApplicant: false,
        coApplicantDetails: "",
        hasGuarantor: false,
        guarantorDetails: "",
        gstNumber: "",
        selectedIdentityDoc: "Aadhaar Card",
        selectedAddressDoc: "Utility Bill",
        selectedIncomeDoc: "Salary Slips"
    )

    static func prefilled(from profile: BorrowerProfile?) -> BorrowerLoanFormData {
        .empty.mergedWithProfile(profile)
    }

    static let branchOptions: [String] = []

    static func formattedAddress(from address: AddressInfo) -> String {
        var components: [String] = []
        if !address.streetAddress.isEmpty { components.append(address.streetAddress) }
        if !address.city.isEmpty { components.append(address.city) }
        if !address.state.isEmpty { components.append(address.state) }
        if !address.zipCode.isEmpty { components.append(address.zipCode) }
        return components.joined(separator: ", ")
    }

    static func isMockValue(_ value: String) -> Bool {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalized.isEmpty else { return false }
        let mockValues: Set<String> = [
            "sample",
            "sample user",
            "test",
            "test user",
            "demo",
            "demo user",
            "john doe",
            "jane doe",
            "default applicant",
            "mock applicant",
            "abc123",
            "9999999999"
        ]
        return mockValues.contains(normalized)
            || normalized.contains("placeholder")
            || normalized.contains("dummy")
            || normalized.contains("mock applicant")
    }

    func isPlaceholderDateOfBirth() -> Bool {
        Calendar.current.isDate(dateOfBirth, inSameDayAs: Self.empty.dateOfBirth)
    }

    func mergedWithProfile(
        _ profile: BorrowerProfile?,
        authEmail: String? = nil,
        authDisplayName: String? = nil
    ) -> BorrowerLoanFormData {
        var result = self

        let resolvedName: String = {
            if let profile, !profile.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return profile.fullName
            }
            return authDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        }()

        let resolvedEmail: String = {
            if let profile, !profile.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return profile.email
            }
            return authEmail?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        }()

        if result.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !resolvedName.isEmpty,
           !Self.isMockValue(resolvedName) {
            result.fullName = resolvedName
        }
        if result.mobileNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let profile, !profile.mobileNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           !Self.isMockValue(profile.mobileNumber) {
            result.mobileNumber = profile.mobileNumber
        }
        if result.emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !resolvedEmail.isEmpty {
            result.emailAddress = resolvedEmail
        }
        if result.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let profile {
            let formatted = Self.formattedAddress(from: profile.currentAddress)
            if !formatted.isEmpty {
                result.address = formatted
            }
        }
        if result.preferredBranch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let profile,
           !profile.preferredBranch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result.preferredBranch = profile.preferredBranch
        }
        if result.isPlaceholderDateOfBirth(), let profile {
            result.dateOfBirth = profile.dateOfBirth
        }
        if result.gender.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let profile, !profile.gender.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result.gender = profile.gender
        }

        guard let profile else { return result }

        if result.employmentType.isEmpty || result.employmentType == "Salaried" {
            if !profile.employment.employmentType.isEmpty {
                result.employmentType = profile.employment.employmentType
            }
        }
        if result.employerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            result.employerName = profile.employment.companyName
        }
        if result.occupation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let designation = profile.employment.designation.trimmingCharacters(in: .whitespacesAndNewlines)
            result.occupation = designation.isEmpty ? profile.occupation : profile.employment.designation
        }
        if result.workExperienceYears == 0, profile.employment.workExperienceYears > 0 {
            result.workExperienceYears = profile.employment.workExperienceYears
        }
        if result.monthlyIncome.isEmpty, profile.income.monthlyIncome > 0 {
            result.monthlyIncome = String(Int(profile.income.monthlyIncome))
        }
        if result.annualIncome.isEmpty, profile.income.annualIncome > 0 {
            result.annualIncome = String(Int(profile.income.annualIncome))
        }
        if result.existingLoans.isEmpty, profile.existingLoansCount > 0 {
            result.existingLoans = String(profile.existingLoansCount)
        }
        if result.existingEMIs.isEmpty, profile.income.existingEMIs > 0 {
            result.existingEMIs = String(Int(profile.income.existingEMIs))
        }
        if result.creditScore.isEmpty, profile.income.creditScore > 0 {
            result.creditScore = String(profile.income.creditScore)
        }
        if result.gstNumber.isEmpty, let gst = profile.gstNumber, !gst.isEmpty {
            result.gstNumber = gst
        }

        return result
    }
}

enum BorrowerLoanFormField: String, CaseIterable, Hashable {
    case fullName
    case mobileNumber
    case emailAddress
    case address
    case preferredBranch
    case occupation
    case employerName
    case monthlyIncome
    case annualIncome
    case loanAmountRequested
    case loanPurpose
    case coApplicantDetails
    case guarantorDetails
}

enum BorrowerApplicationStage: String, Codable, CaseIterable, Identifiable, Hashable {
    case draft = "Draft"
    case submitted = "Submitted"
    case underReview = "Under Review"
    case documentVerification = "Document Verification"
    case loanOfficerReview = "Loan Officer Review"
    case bankManagerReview = "Bank Manager Review"
    case approved = "Approved"
    case rejected = "Rejected"
    case disbursed = "Disbursed"
    case escalated = "Escalated"

    var id: String { rawValue }

    var databaseValue: String {
        switch self {
        case .draft: return "draft"
        case .submitted: return "submitted"
        case .underReview: return "under_review"
        case .documentVerification: return "document_verification"
        case .loanOfficerReview: return "officer_review"
        case .bankManagerReview: return "manager_review"
        case .approved: return "approved"
        case .rejected: return "rejected"
        case .disbursed: return "disbursed"
        case .escalated: return "escalated"
        }
    }
    
    static func from(databaseValue: String) -> BorrowerApplicationStage {
        switch databaseValue.lowercased() {
        case "draft": return .draft
        case "submitted": return .submitted
        case "under_review", "under review": return .underReview
        case "document_verification", "document verification": return .documentVerification
        case "officer_review", "loan officer review", "loan_officer_review": return .loanOfficerReview
        case "manager_review", "bank manager review", "bank_manager_review": return .bankManagerReview
        case "approved": return .approved
        case "rejected": return .rejected
        case "disbursed": return .disbursed
        case "escalated": return .escalated
        default: return .draft
        }
    }

    var iconName: String {
        switch self {
        case .draft: return "square.and.pencil"
        case .submitted: return "paperplane.fill"
        case .underReview: return "doc.text.magnifyingglass"
        case .documentVerification: return "doc.badge.gearshape"
        case .loanOfficerReview: return "person.badge.shield.checkmark"
        case .bankManagerReview: return "person.2.badge.gearshape"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .disbursed: return "indianrupeesign.circle.fill"
        case .escalated: return "arrow.up.forward.circle.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .draft:
            return Color(.secondaryLabel)
        case .submitted, .underReview, .documentVerification, .loanOfficerReview, .bankManagerReview:
            return LMSColors.brandNavy
        case .escalated:
            return Color.purple
        case .approved, .disbursed:
            return LMSColors.emerald
        case .rejected:
            return LMSColors.coral
        }
    }

    var isTerminal: Bool {
        self == .approved || self == .rejected || self == .disbursed
    }

    static var approvalFlow: [BorrowerApplicationStage] {
        [.draft, .submitted, .underReview, .documentVerification, .loanOfficerReview, .bankManagerReview, .approved, .disbursed]
    }

    static var rejectionFlow: [BorrowerApplicationStage] {
        [.draft, .submitted, .underReview, .documentVerification, .loanOfficerReview, .bankManagerReview, .rejected]
    }
}

struct BorrowerStageEntry: Codable, Identifiable, Hashable {
    let id: UUID
    var stage: BorrowerApplicationStage
    var timestamp: Date
    var note: String
    
    init(id: UUID = UUID(), stage: BorrowerApplicationStage, timestamp: Date, note: String) {
        self.id = id
        self.stage = stage
        self.timestamp = timestamp
        self.note = note
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case stage
        case timestamp
        case note
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.stage = try container.decode(BorrowerApplicationStage.self, forKey: .stage)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.note = try container.decode(String.self, forKey: .note)
    }
}


struct BorrowerLoanApplication: Identifiable, Hashable {
    let id: UUID
    var applicationId: String?
    var borrowerId: UUID?
    var product: BorrowerLoanProduct
    var formData: BorrowerLoanFormData
    var documents: [BorrowerLoanDocumentItem]
    var currentStage: BorrowerApplicationStage
    var stageHistory: [BorrowerStageEntry]
    var draftStepIndex: Int = 1
    var submittedAt: Date?
    var updatedAt: Date
    var assignedQueue: String?
    var assignedOfficerId: UUID?
    var assignedOfficer: AssignedLoanOfficer?
    var outstandingBalance: Double
    var upcomingEMI: Double

    var isDraft: Bool {
        currentStage == .draft
    }

    var displayIdentifier: String {
        applicationId ?? "Draft-\(id.uuidString.prefix(6).uppercased())"
    }
}

struct DBLoanApplication: Codable {
    let applicationId: UUID
    let borrowerId: UUID
    let officerId: UUID?
    let productId: UUID
    let amountRequested: Double
    let tenureMonths: Int
    let purpose: String
    let status: String
    let formData: BorrowerLoanFormData
    let stageHistory: [BorrowerStageEntry]
    let submittedAt: Date?
    let updatedAt: Date
    
    func toBorrowerApplication(product: BorrowerLoanProduct, documents: [BorrowerLoanDocumentItem] = []) -> BorrowerLoanApplication {
        return BorrowerLoanApplication(
            id: applicationId,
            applicationId: "APP-\(applicationId.uuidString.prefix(6).uppercased())",
            borrowerId: borrowerId,
            product: product,
            formData: formData,
            documents: documents,
            currentStage: BorrowerApplicationStage.from(databaseValue: status),
            stageHistory: stageHistory,
            draftStepIndex: min(max(formData.draftStepIndex, 1), 9),
            submittedAt: submittedAt,
            updatedAt: updatedAt,
            assignedQueue: status == "draft" ? nil : "Loan Officer Assignment Pending",
            assignedOfficerId: officerId,
            assignedOfficer: nil,
            outstandingBalance: max(0, amountRequested * 0.92),
            upcomingEMI: max(0, amountRequested / Double(max(1, tenureMonths)))
        )
    }
    
    static func from(borrowerApplication app: BorrowerLoanApplication, borrowerId: UUID) -> DBLoanApplication {
        var formData = app.formData
        formData.draftStepIndex = min(max(app.draftStepIndex, 1), 9)

        return DBLoanApplication(
            applicationId: app.id,
            borrowerId: borrowerId,
            officerId: app.assignedOfficer?.officerId ?? app.assignedOfficerId,
            productId: app.product.id,
            amountRequested: app.formData.requestedAmountValue,
            tenureMonths: app.formData.preferredTenureMonths,
            purpose: app.formData.loanPurpose,
            status: app.currentStage.databaseValue,
            formData: formData,
            stageHistory: app.stageHistory,
            submittedAt: app.submittedAt,
            updatedAt: app.updatedAt
        )
    }
}

enum BorrowerApplicationFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case draft = "Draft"
    case underReview = "Under Review"
    case approved = "Approved"
    case rejected = "Rejected"

    var id: String { rawValue }
}

enum BorrowerContextHelpTopic: String, CaseIterable, Identifiable, Hashable {
    case interestRate
    case coApplicant
    case processingFee
    case annualIncome
    case existingLiabilities
    case creditScore
    case employmentType

    var id: String { rawValue }
}

struct BorrowerContextHelpItem: Identifiable, Hashable {
    var topic: BorrowerContextHelpTopic
    var title: String
    var explanation: String
    var examples: [String]
    var recommendation: String

    var id: BorrowerContextHelpTopic { topic }
}

struct BorrowerLoanDashboardMetrics {
    var activeApplications: Int
    var draftApplications: Int
    var approvedLoans: Int
    var rejectedLoans: Int
    var outstandingBalance: Double
    var upcomingEMIs: Double
    var averageProgress: Double
}

extension BorrowerLoanProduct {
    /// Representative minimum EMI at base rate for display on marketplace cards.
    var emiStartingFrom: Double {
        let principal = minAmount > 0 ? minAmount : max(maximumAmount * 0.25, 100_000)
        let months = max(maxTenureMonths, 12)
        let annualRate = baseInterestRate > 0 ? baseInterestRate / 100 : 0.105
        let monthlyRate = annualRate / 12
        guard monthlyRate > 0 else { return principal / Double(months) }
        let factor = pow(1 + monthlyRate, Double(months))
        let emi = (principal * monthlyRate * factor) / (factor - 1)
        return emi.isNaN || emi.isInfinite ? principal / Double(months) : emi
    }

    static let sampleProducts: [BorrowerLoanProduct] = [
        BorrowerLoanProduct(
            id: UUID(),
            type: .personal,
            shortDescription: "Product Details Unavailable",
            maximumAmount: 0,
            interestRateRange: "Unknown",
            estimatedProcessingTime: "Unknown",
            eligibilitySnapshot: "Unknown",
            purpose: "Unknown",
            benefits: [],
            eligibilityCriteria: [],
            minimumRequirements: [],
            interestInformation: "",
            repaymentOverview: "",
            processingFees: "",
            faqs: [],
            loanSpecificDocuments: []
        )
    ]
}

extension BorrowerLoanDocumentItem {
    static func defaultRequirements(for product: BorrowerLoanProduct) -> [BorrowerLoanDocumentItem] {
        return defaultRequirements(for: product, identityDoc: "Aadhaar Card", addressDoc: "Utility Bill", incomeDoc: "Salary Slips")
    }

    static func defaultRequirements(
        for product: BorrowerLoanProduct,
        identityDoc: String,
        addressDoc: String,
        incomeDoc: String
    ) -> [BorrowerLoanDocumentItem] {
        let identity = [
            BorrowerLoanDocumentItem(
                id: UUID(),
                name: identityDoc,
                category: .identityVerification,
                status: .pendingUpload,
                fileName: nil,
                uploadDate: nil,
                lastUpdated: nil,
                isLocked: false
            )
        ]

        let address = [
            BorrowerLoanDocumentItem(
                id: UUID(),
                name: addressDoc,
                category: .addressVerification,
                status: .pendingUpload,
                fileName: nil,
                uploadDate: nil,
                lastUpdated: nil,
                isLocked: false
            )
        ]

        let income = [
            BorrowerLoanDocumentItem(
                id: UUID(),
                name: incomeDoc,
                category: .incomeVerification,
                status: .pendingUpload,
                fileName: nil,
                uploadDate: nil,
                lastUpdated: nil,
                isLocked: false
            )
        ]

        let baseDocKeys = Set([
            canonicalDocumentKey(identityDoc),
            canonicalDocumentKey(addressDoc),
            canonicalDocumentKey(incomeDoc)
        ])
        let loanSpecific = product.loanSpecificDocuments
            .filter { !baseDocKeys.contains(canonicalDocumentKey($0)) }
            .map {
                BorrowerLoanDocumentItem(
                    id: UUID(),
                    name: $0,
                    category: .loanSpecific,
                    status: .pendingUpload,
                    fileName: nil,
                    uploadDate: nil,
                    lastUpdated: nil,
                    isLocked: false
                )
            }

        return identity + address + income + loanSpecific
    }

    static func canonicalDocumentKey(_ name: String) -> String {
        let normalized = name.lowercased()

        if normalized.contains("aadhaar") || normalized.contains("aadhar") {
            return "aadhaar"
        }
        if normalized.contains("pan") {
            return "pan"
        }
        if normalized.contains("salary") || normalized.contains("payslip") || normalized.contains("pay slip") {
            return "salary_slip"
        }
        if normalized.contains("bank") && normalized.contains("statement") {
            return "bank_statement"
        }
        if normalized.contains("utility") {
            return "utility_bill"
        }
        if normalized.contains("passport") {
            return "passport"
        }
        if normalized.contains("driving") {
            return "driving_license"
        }

        let compact = normalized.filter { $0.isLetter || $0.isNumber }
        return compact.hasSuffix("s") ? String(compact.dropLast()) : compact
    }
}

private extension String {
    var numericValue: Double {
        let filtered = self.filter { "0123456789.".contains($0) }
        return Double(filtered) ?? 0
    }
}
