import SwiftUI

enum LoanHubSegment: String, CaseIterable, Identifiable {
    case discover = "Discover"
    case applications = "My Applications"

    var id: String { rawValue }
}

enum BorrowerLoanProductType: String, CaseIterable, Identifiable, Hashable {
    case personal
    case home
    case education
    case business
    case vehicle
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
        case .gold: return "Gold Loan"
        case .loanAgainstProperty: return "Loan Against Property"
        case .other: return "Other Loan Products"
        }
    }

    var iconName: String {
        switch self {
        case .personal: return "person.text.rectangle.fill"
        case .home: return "house.fill"
        case .education: return "graduationcap.fill"
        case .business: return "briefcase.fill"
        case .vehicle: return "car.fill"
        case .gold: return "seal.fill"
        case .loanAgainstProperty: return "building.columns.fill"
        case .other: return "rectangle.stack.badge.plus"
        }
    }
}

struct BorrowerLoanFAQ: Identifiable, Hashable {
    let id = UUID()
    var question: String
    var answer: String
}

struct BorrowerLoanProduct: Identifiable, Hashable {
    let id: UUID
    var type: BorrowerLoanProductType
    var shortDescription: String
    var maximumAmount: Double
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
}

enum BorrowerDocumentCategory: String, CaseIterable, Identifiable, Hashable {
    case identityVerification = "Identity Verification"
    case addressVerification = "Address Verification"
    case incomeVerification = "Income Verification"
    case loanSpecific = "Loan-Specific Documents"

    var id: String { rawValue }
}

enum BorrowerDocumentStatus: String, CaseIterable, Hashable {
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
            return Color.brandNavy
        case .underVerification:
            return .orange
        case .verified:
            return Color.brandEmerald
        case .rejected:
            return Color.brandCoral
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

enum BorrowerDocumentUploadSource: String, CaseIterable, Identifiable, Hashable {
    case camera = "Camera Upload"
    case gallery = "Gallery Upload"
    case pdf = "PDF Upload"
    case dragAndDrop = "Drag & Drop"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .camera: return "camera.fill"
        case .gallery: return "photo.on.rectangle.angled"
        case .pdf: return "doc.richtext.fill"
        case .dragAndDrop: return "arrow.down.doc.fill"
        }
    }
}

struct BorrowerLoanDocumentItem: Identifiable, Hashable {
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

struct BorrowerLoanFormData: Equatable, Hashable {
    var fullName: String
    var dateOfBirth: Date
    var mobileNumber: String
    var emailAddress: String
    var address: String

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

    // Dropdown selections
    var selectedIdentityDoc: String
    var selectedAddressDoc: String
    var selectedIncomeDoc: String

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
        mobileNumber: String,
        emailAddress: String,
        address: String,
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
        selectedIncomeDoc: String = "Salary Slips"
    ) {
        self.fullName = fullName
        self.dateOfBirth = dateOfBirth
        self.mobileNumber = mobileNumber
        self.emailAddress = emailAddress
        self.address = address
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
    }

    static let empty = BorrowerLoanFormData(
        fullName: "",
        dateOfBirth: Calendar.current.date(byAdding: .year, value: -26, to: Date()) ?? Date(),
        mobileNumber: "",
        emailAddress: "",
        address: "",
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
        guard let profile else { return .empty }
        return BorrowerLoanFormData(
            fullName: profile.fullName,
            dateOfBirth: profile.dateOfBirth,
            mobileNumber: profile.mobileNumber,
            emailAddress: profile.email,
            address: profile.currentAddress.streetAddress,
            occupation: profile.occupation,
            employmentType: profile.employment.employmentType.isEmpty ? "Salaried" : profile.employment.employmentType,
            employerName: profile.employment.companyName,
            workExperienceYears: profile.employment.workExperienceYears,
            monthlyIncome: profile.income.monthlyIncome > 0 ? String(Int(profile.income.monthlyIncome)) : "",
            annualIncome: profile.income.annualIncome > 0 ? String(Int(profile.income.annualIncome)) : "",
            existingLoans: profile.existingLoansCount > 0 ? String(profile.existingLoansCount) : "",
            existingEMIs: profile.income.existingEMIs > 0 ? String(Int(profile.income.existingEMIs)) : "",
            creditCardObligations: "",
            creditScore: profile.income.creditScore > 0 ? String(profile.income.creditScore) : "",
            loanAmountRequested: "",
            loanPurpose: "",
            repaymentPreference: "EMI Auto-Debit",
            preferredTenureMonths: 60,
            hasCoApplicant: false,
            coApplicantDetails: "",
            hasGuarantor: false,
            guarantorDetails: "",
            gstNumber: profile.gstNumber ?? "",
            selectedIdentityDoc: "Aadhaar Card",
            selectedAddressDoc: "Utility Bill",
            selectedIncomeDoc: "Salary Slips"
        )
    }
}

enum BorrowerLoanFormField: String, CaseIterable, Hashable {
    case fullName
    case mobileNumber
    case emailAddress
    case address
    case occupation
    case employerName
    case monthlyIncome
    case annualIncome
    case loanAmountRequested
    case loanPurpose
    case coApplicantDetails
    case guarantorDetails
}

enum BorrowerApplicationStage: String, CaseIterable, Identifiable, Hashable {
    case draft = "Draft"
    case submitted = "Submitted"
    case underReview = "Under Review"
    case documentVerification = "Document Verification"
    case loanOfficerReview = "Loan Officer Review"
    case bankManagerReview = "Bank Manager Review"
    case approved = "Approved"
    case rejected = "Rejected"
    case disbursed = "Disbursed"

    var id: String { rawValue }

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
        }
    }

    var tintColor: Color {
        switch self {
        case .draft:
            return Color(.secondaryLabel)
        case .submitted, .underReview, .documentVerification, .loanOfficerReview, .bankManagerReview:
            return Color.brandNavy
        case .approved, .disbursed:
            return Color.brandEmerald
        case .rejected:
            return Color.brandCoral
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

struct BorrowerStageEntry: Identifiable, Hashable {
    let id = UUID()
    var stage: BorrowerApplicationStage
    var timestamp: Date
    var note: String
}

struct BorrowerLoanApplication: Identifiable, Hashable {
    let id: UUID
    var applicationId: String?
    var product: BorrowerLoanProduct
    var formData: BorrowerLoanFormData
    var documents: [BorrowerLoanDocumentItem]
    var currentStage: BorrowerApplicationStage
    var stageHistory: [BorrowerStageEntry]
    var submittedAt: Date?
    var updatedAt: Date
    var assignedQueue: String?
    var outstandingBalance: Double
    var upcomingEMI: Double

    var isDraft: Bool {
        currentStage == .draft
    }

    var displayIdentifier: String {
        applicationId ?? "Draft-\(id.uuidString.prefix(6).uppercased())"
    }
}

enum BorrowerApplicationFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case active = "Active"
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
    static let sampleProducts: [BorrowerLoanProduct] = [
        BorrowerLoanProduct(
            id: UUID(uuidString: "a1d6518c-14d0-4f5b-85c4-3670f4a6ef01") ?? UUID(),
            type: .personal,
            shortDescription: "Quick unsecured funding for personal goals and urgent expenses.",
            maximumAmount: 2_500_000,
            interestRateRange: "10.50% - 18.00%",
            estimatedProcessingTime: "24-72 hours",
            eligibilitySnapshot: "Salaried/Self-employed with stable income and credit score above 700.",
            purpose: "Manage planned expenses such as travel, healthcare, or home improvements.",
            benefits: ["Minimal paperwork", "Fast approval cycle", "Flexible tenure options"],
            eligibilityCriteria: ["Age 21-58 years", "Minimum monthly income ₹25,000", "CIBIL 700+"],
            minimumRequirements: ["KYC completed profile", "6 months bank statements", "Latest salary slips"],
            interestInformation: "Rates are risk-based and depend on profile strength, obligations, and tenure.",
            repaymentOverview: "EMI options from 12 to 84 months with auto-debit support.",
            processingFees: "Up to 2.5% of sanctioned amount + GST.",
            faqs: [
                BorrowerLoanFAQ(question: "Can I prepay the loan?", answer: "Yes, part-prepayment and foreclosure are available as per policy."),
                BorrowerLoanFAQ(question: "How quickly can funds be disbursed?", answer: "Disbursal generally happens within 1-3 working days after approval.")
            ],
            loanSpecificDocuments: []
        ),
        BorrowerLoanProduct(
            id: UUID(uuidString: "0f1e6d6d-6ce2-4df6-a8b8-1c47cbf804f2") ?? UUID(),
            type: .home,
            shortDescription: "High-value financing for home purchase, construction, or resale.",
            maximumAmount: 25_000_000,
            interestRateRange: "8.25% - 11.25%",
            estimatedProcessingTime: "5-10 working days",
            eligibilitySnapshot: "Stable income profile with property and legal verification eligibility.",
            purpose: "Buy, build, or renovate residential property.",
            benefits: ["Long tenure up to 30 years", "Tax benefits", "Competitive rates"],
            eligibilityCriteria: ["Age 23-65 years", "Minimum annual income ₹4,80,000", "Healthy FOIR ratio"],
            minimumRequirements: ["KYC + address proof", "Income proof", "Property chain documents"],
            interestInformation: "Available in floating and fixed variants with periodic benchmark resets.",
            repaymentOverview: "Tenure up to 360 months with step-up/step-down EMI options.",
            processingFees: "0.35% - 1.00% of loan amount + legal and valuation charges.",
            faqs: [
                BorrowerLoanFAQ(question: "Do I need property insurance?", answer: "Property insurance is strongly recommended and may be mandatory in certain cases."),
                BorrowerLoanFAQ(question: "Is co-applicant mandatory?", answer: "For jointly owned property, co-applicant is generally required.")
            ],
            loanSpecificDocuments: ["Property Documents", "Sale Agreement", "Property Valuation"]
        ),
        BorrowerLoanProduct(
            id: UUID(uuidString: "84f596a0-9f58-4e18-b2a8-d1c8669b2cf3") ?? UUID(),
            type: .education,
            shortDescription: "Finance higher studies in India and abroad with moratorium support.",
            maximumAmount: 7_500_000,
            interestRateRange: "9.00% - 13.50%",
            estimatedProcessingTime: "4-8 working days",
            eligibilitySnapshot: "Confirmed admission with co-borrower income proof.",
            purpose: "Cover tuition, accommodation, travel, and education-linked expenses.",
            benefits: ["Moratorium during course period", "Tax deduction on interest", "Co-applicant support"],
            eligibilityCriteria: ["Recognized institute admission", "Co-applicant with repayment capacity", "Academic consistency"],
            minimumRequirements: ["Admission proof", "Fee structure", "Co-applicant KYC and income documents"],
            interestInformation: "Concessions may apply for top institutions and profile categories.",
            repaymentOverview: "Repayment starts after moratorium with tenure up to 180 months.",
            processingFees: "0.5% - 1.5% depending on geography and collateral requirements.",
            faqs: [
                BorrowerLoanFAQ(question: "Does the loan cover living expenses?", answer: "Yes, subject to bank policy and sanctioned amount."),
                BorrowerLoanFAQ(question: "Can I get a concession for girl students?", answer: "Eligible profiles may receive concession under applicable schemes.")
            ],
            loanSpecificDocuments: ["Admission Letter", "Fee Structure", "Academic Records"]
        ),
        BorrowerLoanProduct(
            id: UUID(uuidString: "9f2752fb-2f28-4a31-86f0-0d87122e41f4") ?? UUID(),
            type: .business,
            shortDescription: "Working capital and expansion financing for MSME and enterprise growth.",
            maximumAmount: 15_000_000,
            interestRateRange: "11.00% - 17.00%",
            estimatedProcessingTime: "3-7 working days",
            eligibilitySnapshot: "Registered business with stable turnover and compliant filings.",
            purpose: "Inventory, expansion, machinery, and working capital support.",
            benefits: ["Flexible repayment", "Overdraft/term options", "Dedicated relationship officer"],
            eligibilityCriteria: ["Business vintage 2+ years", "Consistent GST/ITR records", "Healthy bank conduct"],
            minimumRequirements: ["Business KYC", "GST and registration proof", "Financial statements"],
            interestInformation: "Rates vary based on vintage, collateral, bureau score, and cash-flow analysis.",
            repaymentOverview: "Tenure up to 120 months with tailored repayment schedules.",
            processingFees: "1.0% - 2.25% of sanctioned amount + applicable charges.",
            faqs: [
                BorrowerLoanFAQ(question: "Can startups apply?", answer: "Yes, based on business model and underwriting criteria."),
                BorrowerLoanFAQ(question: "Is collateral mandatory?", answer: "Depends on ticket size, profile, and product variant.")
            ],
            loanSpecificDocuments: ["GST Documents", "Business Registration", "Financial Statements"]
        ),
        BorrowerLoanProduct(
            id: UUID(uuidString: "4c72f920-0e3f-4f89-a608-9fbf588f93d5") ?? UUID(),
            type: .vehicle,
            shortDescription: "Finance new and used vehicles for personal and commercial use.",
            maximumAmount: 4_000_000,
            interestRateRange: "8.90% - 14.50%",
            estimatedProcessingTime: "1-3 working days",
            eligibilitySnapshot: "Steady income and dealer quotation with acceptable repayment capacity.",
            purpose: "Purchase two-wheeler, car, or commercial vehicle.",
            benefits: ["Fast dealer disbursal", "Flexible down payment", "Easy top-up eligibility"],
            eligibilityCriteria: ["Age 21-60 years", "Income proof", "Valid driving profile"],
            minimumRequirements: ["KYC", "Income proof", "Vehicle quotation/invoice"],
            interestInformation: "Rates vary by vehicle segment and borrower credit profile.",
            repaymentOverview: "Tenure up to 84 months with EMI auto-debit options.",
            processingFees: "Up to 1.75% of loan amount + RC hypothecation charges.",
            faqs: [
                BorrowerLoanFAQ(question: "Can I finance used vehicles?", answer: "Yes, based on vehicle age and valuation."),
                BorrowerLoanFAQ(question: "Do I need comprehensive insurance?", answer: "Yes, active insurance is required before disbursal.")
            ],
            loanSpecificDocuments: ["Vehicle Quotation", "Dealer Invoice"]
        ),
        BorrowerLoanProduct(
            id: UUID(uuidString: "be84595d-7608-4fb9-9fef-53072cb85f06") ?? UUID(),
            type: .gold,
            shortDescription: "Instant secured credit against household gold ornaments.",
            maximumAmount: 3_000_000,
            interestRateRange: "9.50% - 15.50%",
            estimatedProcessingTime: "Same day",
            eligibilitySnapshot: "Valid KYC with pledged gold valuation as per policy.",
            purpose: "Meet short-term business or personal liquidity requirements.",
            benefits: ["Fast disbursal", "Lower documentation", "Flexible repayment structures"],
            eligibilityCriteria: ["Indian resident", "Valid KYC", "Eligible purity and valuation"],
            minimumRequirements: ["Original gold ornaments", "KYC documents", "Photograph"],
            interestInformation: "LTV and rate depend on prevailing gold prices and policy limits.",
            repaymentOverview: "Bullet and EMI repayment variants available.",
            processingFees: "Nominal appraisal and processing fee as per branch policy.",
            faqs: [
                BorrowerLoanFAQ(question: "Can I release partial pledged gold?", answer: "Yes, after part repayment and as per valuation."),
                BorrowerLoanFAQ(question: "How is gold kept safe?", answer: "Gold is stored in secured vaults with strict audit controls.")
            ],
            loanSpecificDocuments: ["Gold Valuation Slip"]
        ),
        BorrowerLoanProduct(
            id: UUID(uuidString: "7e95a540-c4da-4c52-aa62-bf847cb53a47") ?? UUID(),
            type: .loanAgainstProperty,
            shortDescription: "Leverage existing property value for high-ticket financing.",
            maximumAmount: 20_000_000,
            interestRateRange: "10.00% - 13.75%",
            estimatedProcessingTime: "6-12 working days",
            eligibilitySnapshot: "Clear property title and stable documented income profile.",
            purpose: "Business expansion, education, medical, or other large requirements.",
            benefits: ["Higher loan eligibility", "Longer tenure", "Competitive secured lending rates"],
            eligibilityCriteria: ["Self-owned property", "Stable income and repayment ability", "Legal and technical clearance"],
            minimumRequirements: ["Property ownership documents", "Income proof", "Bank statements"],
            interestInformation: "Final rates depend on LTV, profile quality, and documentation strength.",
            repaymentOverview: "Tenure up to 180 months with structured repayment schedules.",
            processingFees: "0.75% - 1.5% plus legal/technical valuation charges.",
            faqs: [
                BorrowerLoanFAQ(question: "Can commercial property be used?", answer: "Yes, eligible residential/commercial properties may be accepted."),
                BorrowerLoanFAQ(question: "Do I retain ownership?", answer: "Yes, ownership remains with you while property stays mortgaged.")
            ],
            loanSpecificDocuments: ["Property Ownership Records", "Encumbrance Certificate", "Latest Tax Receipts"]
        ),
        BorrowerLoanProduct(
            id: UUID(uuidString: "2d22a0bc-18ab-4f47-bfd0-7c5bdd8f3b18") ?? UUID(),
            type: .other,
            shortDescription: "Explore additional bank-supported products tailored to profile and need.",
            maximumAmount: 5_000_000,
            interestRateRange: "Custom",
            estimatedProcessingTime: "Depends on product",
            eligibilitySnapshot: "Eligibility differs by selected product variant and purpose.",
            purpose: "Access specialized lending products not covered in standard categories.",
            benefits: ["Customized product fit", "Advisory support", "Multi-purpose options"],
            eligibilityCriteria: ["Profile-specific underwriting", "Document support by variant"],
            minimumRequirements: ["KYC and income proof", "Product-specific declarations"],
            interestInformation: "Interest and terms are personalized by product structure.",
            repaymentOverview: "Repayment options vary by chosen loan product.",
            processingFees: "Product-specific and disclosed before final submission.",
            faqs: [
                BorrowerLoanFAQ(question: "How do I pick the right loan?", answer: "Use the loan overview and eligibility guidance to compare options."),
                BorrowerLoanFAQ(question: "Can a relationship manager assist?", answer: "Yes, once submitted, your request is assigned to an officer queue.")
            ],
            loanSpecificDocuments: ["Product-Specific Supporting Documents"]
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

        let loanSpecific = product.loanSpecificDocuments.map {
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
}

private extension String {
    var numericValue: Double {
        let filtered = self.filter { "0123456789.".contains($0) }
        return Double(filtered) ?? 0
    }
}
