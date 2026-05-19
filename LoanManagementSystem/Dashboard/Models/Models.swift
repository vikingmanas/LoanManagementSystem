//
//  Models.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 19/05/26.
//

import Foundation

public struct LoanAccount: Identifiable, Hashable, Sendable {
    public let id: UUID
    public var accountNumber: String
    public var loanType: String  // e.g., "Home Loan", "Personal Loan", etc.
    public var sanctionedAmount: Double // original approved amount
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
    public var accountType: AccountType
    public var availableBalance: Double
    public var odLimit: Double?
    public var minBalance: Double?
    public var linkedLoanIds: [UUID]

    public init(id: UUID = UUID(), accountNumber: String, bankName: String = "", accountType: AccountType, availableBalance: Double, odLimit: Double? = nil, minBalance: Double? = nil, linkedLoanIds: [UUID] = []) {
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

public enum AccountType: String, CaseIterable, Identifiable, Hashable, Sendable {
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
    public var status: EMIStatus

    public init(id: UUID = UUID(), dueDate: Date, amount: Double, loanType: String, status: EMIStatus) {
        self.id = id
        self.dueDate = dueDate
        self.amount = amount
        self.loanType = loanType
        self.status = status
    }
}

public enum EMIStatus: String, CaseIterable, Identifiable, Hashable, Sendable {
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

    public init(id: UUID = UUID(), title: String, date: Date, amount: Double, type: TransactionType, referenceNo: String) {
        self.id = id
        self.title = title
        self.date = date
        self.amount = amount
        self.type = type
        self.referenceNo = referenceNo
    }
}

public enum TransactionType: String, CaseIterable, Identifiable, Hashable, Sendable {
    case emiPayment = "EMI Payment"
    case credit = "Credit"
    case penalty = "Penalty"
    case refund = "Refund"
    
    public var id: String { self.rawValue }
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
