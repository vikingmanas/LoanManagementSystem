import SwiftUI

struct AppTheme {
    static let brandNavy      = LMSColors.brandNavy
    static let actionBlue     = LMSColors.actionBlue
    static let successGreen   = LMSColors.emerald
    static let warningAmber   = LMSColors.amber
    static let criticalRed    = LMSColors.coral
    static let neutralSurface = LMSColors.surface
    static let background     = LMSColors.surfaceElevated
}

struct OfficerLoanApplication: Identifiable, Hashable {
    let id: UUID
    var applicationId: String
    var borrowerName: String
    var borrowerId: UUID
    var loanType: OfficerLoanType
    var requestedAmount: Double
    var status: OfficerApplicationStatus
    var submittedDate: Date
    var lastUpdatedDate: Date
    var assignedOfficerId: UUID
    var documents: [LoanDocument]
    var notes: String
    var branch: String
    var cibilScore: Int?
    var sentToManagerDate: Date?
    var managerStatus: ManagerStatus?
    var borrowerDetails: BorrowerDetails = .empty
}

struct BorrowerDetails: Hashable {
    let dob: String
    let age: String
    let gender: String
    let pan: String
    let email: String
    let phone: String
    let address: String
    let occupation: String
    let employer: String
    let annualIncome: String
    let monthlyIncome: String
    let employmentStatus: String
    let workExperience: String
    let existingEMIs: String
    let creditCardObligations: String
    let loanPurpose: String
    let tenure: String
    let repaymentPreference: String

    static let empty = BorrowerDetails(
        dob: "Not provided",
        age: "Not provided",
        gender: "Not provided",
        pan: "Not provided",
        email: "Not provided",
        phone: "Not provided",
        address: "Not provided",
        occupation: "Not provided",
        employer: "Not provided",
        annualIncome: "Not provided",
        monthlyIncome: "Not provided",
        employmentStatus: "Not provided",
        workExperience: "Not provided",
        existingEMIs: "Not provided",
        creditCardObligations: "Not provided",
        loanPurpose: "Not provided",
        tenure: "Not provided",
        repaymentPreference: "Not provided"
    )
}

public enum RegistryFilter: String, CaseIterable, Identifiable {
    case all
    case newCases
    case underCheck
    case approvalQueue
    case completed
    
    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .all: return "All Loans"
        case .newCases: return "New"
        case .underCheck: return "In Progress"
        case .approvalQueue: return "Manager Review"
        case .completed: return "Completed"
        }
    }
}

enum OfficerLoanType: String, CaseIterable, Codable, Hashable {
    case home = "Home Loan"
    case personal = "Personal Loan"
    case business = "Business Loan"
    case vehicle = "Vehicle Loan"
    case education = "Education Loan"
    case agriculture = "Agriculture Loan"
    case consumer = "Credit Card / Consumer Loan"
    case msmeStartup = "MSME / Startup Loan"
    case gold = "Gold Loan"
    case loanAgainstProperty = "Loan Against Property"
    case other = "Special Assistance Loan"

    var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .business: return "briefcase.fill"
        case .personal: return "person.fill"
        case .vehicle: return "car.fill"
        case .education: return "graduationcap.fill"
        case .agriculture: return "leaf.fill"
        case .consumer: return "creditcard.fill"
        case .msmeStartup: return "chart.line.uptrend.xyaxis"
        case .gold: return "seal.fill"
        case .loanAgainstProperty: return "building.columns.fill"
        case .other: return "sparkles"
        }
    }

    var themeColor: Color {
        switch self {
        case .home: return AppTheme.brandNavy
        case .business: return Color.purple
        case .personal: return Color.teal
        case .vehicle: return AppTheme.warningAmber
        case .education: return AppTheme.actionBlue
        case .agriculture: return Color.green
        case .consumer: return Color.indigo
        case .msmeStartup: return Color.cyan
        case .gold: return AppTheme.warningAmber
        case .loanAgainstProperty: return AppTheme.brandNavy
        case .other: return AppTheme.actionBlue
        }
    }
}

enum OfficerApplicationStatus: String, CaseIterable, Codable, Hashable {
    case pending = "Pending"
    case underReview = "Under Review"
    case approved = "Approved"
    case rejected = "Rejected"
    case disbursed = "Disbursed"
    case onHold = "On Hold"

    case applied = "Applied"
    case documentsPending = "Documents Pending"
    case documentsRejected = "Documents Rejected"
    case verificationCompleted = "Verification Completed"
    case sentToManager = "Sent to Manager"
    case finalApprovalPending = "Final Approval Pending"
    case escalated = "Escalated"

    var displayName: String {
        self.rawValue
    }

    var themeColor: Color {
        switch self {
        case .pending, .applied: return AppTheme.warningAmber
        case .underReview: return AppTheme.actionBlue
        case .approved: return AppTheme.successGreen
        case .rejected: return AppTheme.criticalRed
        case .disbursed: return Color.teal
        case .onHold, .documentsPending: return Color.gray
        case .documentsRejected: return AppTheme.criticalRed
        case .verificationCompleted: return AppTheme.successGreen
        case .sentToManager, .finalApprovalPending: return AppTheme.brandNavy
        case .escalated: return Color.purple
        }
    }
}

enum ManagerStatus: String, CaseIterable, Codable, Hashable {
    case underReview = "Under Review"
    case approved = "Approved ✓"
    case needsClarification = "Needs Clarification"
    case rejected = "Rejected ✗"
    case sentBack = "Sent Back"
    case escalated = "Escalated"

    var themeColor: Color {
        switch self {
        case .underReview: return AppTheme.warningAmber
        case .approved: return AppTheme.successGreen
        case .needsClarification: return AppTheme.criticalRed
        case .rejected: return AppTheme.criticalRed
        case .sentBack: return AppTheme.warningAmber
        case .escalated: return Color.purple
        }
    }
}

struct LoanDocument: Identifiable, Hashable {
    let id: UUID
    var docType: OfficerDocumentType
    var status: OfficerDocumentStatus
    var uploadedDate: Date?
    var reviewedDate: Date?
    var rejectionReason: String?
    var fileURL: String?
    var ocrStatus: String = "Pending Review"
    var extractedFields: [String: String] = [:]
}

enum OfficerDocumentStatus: String, CaseIterable, Codable, Hashable {
    case pending = "Missing"
    case uploaded = "New Upload"
    case underReview = "In Review"
    case verified = "Verified ✓"
    case rejectFlag = "Re-upload Req."
    case reUploaded = "Re-Uploaded"

    var themeColor: Color {
        switch self {
        case .pending: return AppTheme.warningAmber
        case .uploaded: return AppTheme.actionBlue
        case .underReview: return Color.purple
        case .verified: return AppTheme.successGreen
        case .rejectFlag: return AppTheme.criticalRed
        case .reUploaded: return Color.teal
        }
    }
}

enum OfficerDocumentType: String, CaseIterable, Codable, Hashable {
    case aadhaar = "Aadhaar"
    case pan = "PAN Card"
    case salarySlip = "Salary Slip"
    case bankStatement = "Bank Statement"
    case propertyDoc = "Property Document"
    case gstCertificate = "GST Certificate"
    case admissionLetter = "Admission Letter"
    case incomeTaxReturn = "ITR"
    case photograph = "Photograph"
    case signature = "Signature"
    case selfie = "Selfie Verification"

    var symbol: String {
        switch self {
        case .aadhaar: return "person.text.rectangle"
        case .pan: return "creditcard"
        case .salarySlip: return "banknote"
        case .bankStatement: return "building.columns"
        case .propertyDoc: return "house"
        case .gstCertificate: return "briefcase"
        case .admissionLetter: return "graduationcap"
        case .incomeTaxReturn: return "doc.text"
        case .photograph: return "photo"
        case .signature: return "signature"
        case .selfie: return "faceid"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .aadhaar, .pan:
            return .blue
        case .salarySlip, .bankStatement, .incomeTaxReturn:
            return .green
        case .propertyDoc:
            return .purple
        case .gstCertificate:
            return .orange
        case .admissionLetter:
            return .teal
        case .photograph, .signature, .selfie:
            return .pink
        }
    }
}

struct ActivityFeedItem: Identifiable, Hashable {
    let id: UUID
    var borrowerName: String
    var applicationId: String
    var loanType: String
    var eventType: ActivityEventType
    var eventDescription: String
    var timestamp: Date
    var isRead: Bool
    var requiresAction: Bool
    var actionType: ActivityActionType?
}

enum ActivityEventType: String, Codable, Hashable {
    case documentUploaded
    case documentReUploaded
    case queryRaised
    case applicationSubmitted
    case emiOverdue
    case consentGiven
    case profileUpdated

    var symbol: String {
        switch self {
        case .documentUploaded, .documentReUploaded:
            return "doc.badge.arrow.up"
        case .queryRaised:
            return "bubble.left.fill"
        case .applicationSubmitted:
            return "person.crop.circle.badge.plus"
        case .emiOverdue:
            return "exclamationmark.circle.fill"
        case .consentGiven:
            return "checkmark.seal.fill"
        case .profileUpdated:
            return "pencil.circle.fill"
        }
    }

    var themeColor: Color {
        switch self {
        case .documentUploaded, .documentReUploaded:
            return Color.teal
        case .queryRaised:
            return AppTheme.actionBlue
        case .applicationSubmitted:
            return AppTheme.brandNavy
        case .emiOverdue:
            return AppTheme.criticalRed
        case .consentGiven:
            return AppTheme.successGreen
        case .profileUpdated:
            return Color.purple
        }
    }
}

enum ActivityActionType: String, Codable, Hashable {
    case reviewDocument
    case replyQuery
    case verifyApplication
    case viewEMIAlert

    var label: String {
        switch self {
        case .reviewDocument: return "Review"
        case .replyQuery: return "Reply"
        case .verifyApplication: return "Verify"
        case .viewEMIAlert: return "Alert"
        }
    }

    var color: Color {
        switch self {
        case .reviewDocument: return AppTheme.actionBlue
        case .replyQuery: return Color.teal
        case .verifyApplication: return AppTheme.successGreen
        case .viewEMIAlert: return AppTheme.criticalRed
        }
    }
}

struct CurrencyFormatter {
    static let shared = CurrencyFormatter()

    private let formatter: NumberFormatter

    init() {
        formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 0
    }

    func format(_ val: Double) -> String {

        if val >= 10_000_000 {
            let crVal = val / 10_000_000
            return String(format: "₹ %.1f Cr", crVal)
        } else if val >= 100_000 {
            let LVal = val / 100_000
            return String(format: "₹ %.1f Lakh", LVal)
        }
        return formatter.string(from: NSNumber(value: val)) ?? "₹\(val)"
    }
}

struct RelativeDateFormatter {
    static let shared = RelativeDateFormatter()

    private let formatter: RelativeDateTimeFormatter
    private let textFormatter: DateFormatter

    init() {
        formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full

        textFormatter = DateFormatter()
        textFormatter.dateFormat = "d MMM yyyy"
    }

    func relativeString(from date: Date) -> String {
        formatter.localizedString(for: date, relativeTo: Date())
    }

    func absoluteString(from date: Date) -> String {
        textFormatter.string(from: date)
    }
}

struct HapticsManager {
    static var isEnabled: Bool {
        if UserDefaults.standard.object(forKey: "enableHaptics") == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: "enableHaptics")
    }

    static func triggerImpact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard isEnabled else { return }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func triggerNotification(type: UINotificationFeedbackGenerator.FeedbackType) {
        guard isEnabled else { return }
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
