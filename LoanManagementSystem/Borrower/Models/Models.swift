
import Foundation

public struct DashboardLoanAccount: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var accountNumber: String
    public var loanType: String
    public var sanctionedAmount: Double
    public var principalOutstanding: Double
    public var totalEMI: Double
    public var nextEMIDate: Date
    public var tenureRemainingMonths: Int
    public var totalTenureMonths: Int
    public var repaidPercentage: Double
    public var linkedBankAccountId: UUID

    public init(id: UUID = UUID(), accountNumber: String, loanType: String, sanctionedAmount: Double = 0, principalOutstanding: Double, totalEMI: Double, nextEMIDate: Date, tenureRemainingMonths: Int, totalTenureMonths: Int, repaidPercentage: Double, linkedBankAccountId: UUID = UUID()) {
        self.id = id
        self.accountNumber = accountNumber
        self.loanType = loanType
        self.sanctionedAmount = sanctionedAmount
        self.principalOutstanding = principalOutstanding
        self.totalEMI = totalEMI
        self.nextEMIDate = nextEMIDate
        self.tenureRemainingMonths = tenureRemainingMonths
        self.totalTenureMonths = totalTenureMonths
        self.repaidPercentage = repaidPercentage
        self.linkedBankAccountId = linkedBankAccountId
    }
}

public struct BankAccount: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var accountNumber: String
    public var bankName: String
    public var accountType: DashboardAccountType
    public var availableBalance: Double
    public var odLimit: Double?
    public var minBalance: Double?
    public var linkedLoanIds: [UUID]

    public init(id: UUID = UUID(), accountNumber: String, bankName: String = "", accountType: DashboardAccountType, availableBalance: Double, odLimit: Double? = nil, minBalance: Double? = nil, linkedLoanIds: [UUID] = []) {
        self.id = id
        self.accountNumber = accountNumber
        self.bankName = bankName
        self.accountType = accountType
        self.availableBalance = availableBalance
        self.odLimit = odLimit
        self.minBalance = minBalance
        self.linkedLoanIds = linkedLoanIds
    }
}

public enum DashboardAccountType: String, CaseIterable, Identifiable, Hashable, Sendable {
    case savings = "Savings Account"
    case current = "Current Account"
    case overdraft = "OD Account"

    public var id: String { self.rawValue }
    public var displayName: String { self.rawValue.uppercased() }
}

public struct EMIRecord: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var dueDate: Date
    public var amount: Double
    public var loanType: String
    public var status: DashboardEMIStatus

    public init(id: UUID = UUID(), dueDate: Date, amount: Double, loanType: String, status: DashboardEMIStatus) {
        self.id = id
        self.dueDate = dueDate
        self.amount = amount
        self.loanType = loanType
        self.status = status
    }
}

public enum DashboardEMIStatus: String, CaseIterable, Identifiable, Hashable, Sendable {
    case paid = "Paid"
    case upcoming = "Upcoming"
    case dueSoon = "Due Soon"
    case overdue = "Overdue"

    public var id: String { self.rawValue }
}

public struct Transaction: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var date: Date
    public var amount: Double
    public var type: TransactionType
    public var referenceNo: String
    public var bankAccountId: UUID?

    public init(id: UUID = UUID(), title: String, date: Date, amount: Double, type: TransactionType, referenceNo: String, bankAccountId: UUID? = nil) {
        self.id = id
        self.title = title
        self.date = date
        self.amount = amount
        self.type = type
        self.referenceNo = referenceNo
        self.bankAccountId = bankAccountId
    }
}

public enum TransactionType: String, CaseIterable, Identifiable, Hashable, Sendable {
    case emiPayment = "EMI Payment"
    case credit = "Credit"
    case penalty = "Penalty"
    case refund = "Refund"
    case failedDebit = "Failed Debit"

    public var id: String { self.rawValue }

    public var isDebit: Bool {
        switch self {
        case .emiPayment, .penalty, .failedDebit:
            return true
        case .credit, .refund:
            return false
        }
    }
}

public enum ForeclosureRequestStatus: String, CaseIterable, Identifiable, Hashable, Sendable {
    case submitted = "Submitted"
    case officerReview = "Under Loan Officer Review"
    case recommended = "Recommended"
    case managerApproval = "Under Manager Approval"
    case approved = "Approved"
    case awaitingPayment = "Awaiting Payment"
    case closed = "Closed"
    case rejected = "Rejected"

    public var id: String { rawValue }

    public var isPaymentReady: Bool {
        self == .awaitingPayment || self == .approved
    }
}

public struct ForeclosureRequest: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var requestID: String
    public var loanID: UUID
    public var loanType: String
    public var loanAccountNumber: String
    public var outstandingPrincipal: Double
    public var accruedInterest: Double
    public var foreclosureCharges: Double
    public var gst: Double
    public var totalPayable: Double
    public var status: ForeclosureRequestStatus
    public var submittedAt: Date
    public var updatedAt: Date
    public var officerRecommendation: String?
    public var managerDecision: String?
    public var paymentReference: String?

    public init(
        id: UUID = UUID(),
        requestID: String,
        loanID: UUID,
        loanType: String,
        loanAccountNumber: String,
        outstandingPrincipal: Double,
        accruedInterest: Double,
        foreclosureCharges: Double,
        gst: Double,
        totalPayable: Double,
        status: ForeclosureRequestStatus = .submitted,
        submittedAt: Date = Date(),
        updatedAt: Date = Date(),
        officerRecommendation: String? = nil,
        managerDecision: String? = nil,
        paymentReference: String? = nil
    ) {
        self.id = id
        self.requestID = requestID
        self.loanID = loanID
        self.loanType = loanType
        self.loanAccountNumber = loanAccountNumber
        self.outstandingPrincipal = outstandingPrincipal
        self.accruedInterest = accruedInterest
        self.foreclosureCharges = foreclosureCharges
        self.gst = gst
        self.totalPayable = totalPayable
        self.status = status
        self.submittedAt = submittedAt
        self.updatedAt = updatedAt
        self.officerRecommendation = officerRecommendation
        self.managerDecision = managerDecision
        self.paymentReference = paymentReference
    }
}

public struct GovernmentScheme: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var title: String
    public var description: String
    public var category: SchemeCategory
    public var validTill: Date
    public var benefitSummary: String

    public init(id: UUID = UUID(), title: String, description: String, category: SchemeCategory, validTill: Date, benefitSummary: String) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.validTill = validTill
        self.benefitSummary = benefitSummary
    }
}

public enum SchemeCategory: String, CaseIterable, Identifiable, Hashable, Sendable {
    case businessLoan = "Business Loan"
    case homeLoan = "Home Loan"
    case agriculture = "Agriculture"
    case education = "Education"

    public var id: String { self.rawValue }
}

public struct DBTransaction: Codable, Sendable {
    public let id: UUID
    public var title: String
    public var date: Date
    public var amount: Double
    public var type: String
    public var referenceNo: String
    public var bankAccountId: UUID?
    public var borrowerId: UUID

    public init(id: UUID = UUID(), title: String, date: Date = Date(), amount: Double, type: String, referenceNo: String, bankAccountId: UUID? = nil, borrowerId: UUID) {
        self.id = id
        self.title = title
        self.date = date
        self.amount = amount
        self.type = type
        self.referenceNo = referenceNo
        self.bankAccountId = bankAccountId
        self.borrowerId = borrowerId
    }
}
