//
//  CoreDomainModels.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 20/05/26.
//

import Foundation

// MARK: - Core Domain Enums

enum BranchStatus: String, Codable {
    case active, inactive, closed
}

enum LoanType: String, Codable {
    case personal, home, auto, education, business
}

enum ApplicationStatus: String, Codable {
    case draft, submitted, underReview = "under_review", approved, rejected, disbursed
}

enum AccountStatus: String, Codable {
    case active, closed, defaulted, delinquent
}

enum EMIStatus: String, Codable {
    case pending, paid, overdue, bounced
}

// MARK: - Core Domain Models

struct Branch: Codable, Identifiable {
    let id: UUID
    let name: String
    let code: String
    let region: String
    let address: String
    let managerId: UUID?
    let status: BranchStatus
    
    enum CodingKeys: String, CodingKey {
        case id = "branch_id"
        case name, code, region, address
        case managerId = "manager_id"
        case status
    }
}

struct LoanProduct: Codable, Identifiable {
    let id: UUID
    let name: String
    let loanType: LoanType
    let minAmount: Decimal
    let maxAmount: Decimal
    let minTenureMonths: Int
    let maxTenureMonths: Int
    let baseInterestRate: Decimal
    let processingFeePct: Decimal
    let eligibilityCriteria: String
    let isActive: Bool
    let createdBy: UUID
    
    enum CodingKeys: String, CodingKey {
        case id = "product_id"
        case name
        case loanType = "loan_type"
        case minAmount = "min_amount"
        case maxAmount = "max_amount"
        case minTenureMonths = "min_tenure_months"
        case maxTenureMonths = "max_tenure_months"
        case baseInterestRate = "base_interest_rate"
        case processingFeePct = "processing_fee_pct"
        case eligibilityCriteria = "eligibility_criteria"
        case isActive = "is_active"
        case createdBy = "created_by"
    }
}

struct LoanApplication: Codable, Identifiable {
    let id: UUID
    let borrowerId: UUID
    let officerId: UUID?
    let productId: UUID
    let amountRequested: Decimal
    let tenureMonths: Int
    let purpose: String
    let status: ApplicationStatus
    let submittedAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id = "application_id"
        case borrowerId = "borrower_id"
        case officerId = "officer_id"
        case productId = "product_id"
        case amountRequested = "amount_requested"
        case tenureMonths = "tenure_months"
        case purpose, status
        case submittedAt = "submitted_at"
        case updatedAt = "updated_at"
    }
}

struct LoanAccount: Codable, Identifiable {
    let id: UUID
    let applicationId: UUID
    let borrowerId: UUID
    let principalAmount: Decimal
    let outstandingBalance: Decimal
    let interestRate: Decimal
    let disbursementDate: Date?
    let closureDate: Date?
    let status: AccountStatus
    let nextEmiDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "account_id"
        case applicationId = "application_id"
        case borrowerId = "borrower_id"
        case principalAmount = "principal_amount"
        case outstandingBalance = "outstanding_balance"
        case interestRate = "interest_rate"
        case disbursementDate = "disbursement_date"
        case closureDate = "closure_date"
        case status
        case nextEmiDate = "next_emi_date"
    }
}

struct EMISchedule: Codable, Identifiable {
    let id: UUID
    let accountId: UUID
    let instalmentNo: Int
    let dueDate: Date
    let emiAmount: Decimal
    let principalComponent: Decimal
    let interestComponent: Decimal
    let status: EMIStatus
    let paidDate: Date?
    let paidAmount: Decimal?
    
    enum CodingKeys: String, CodingKey {
        case id = "emi_id"
        case accountId = "account_id"
        case instalmentNo = "instalment_no"
        case dueDate = "due_date"
        case emiAmount = "emi_amount"
        case principalComponent = "principal_component"
        case interestComponent = "interest_component"
        case status
        case paidDate = "paid_date"
        case paidAmount = "paid_amount"
    }
}
