import Foundation

/// Swift representation of the `public.documents` database table.
struct DBDocument: Codable, Identifiable, Sendable {
    var id: UUID { documentId }
    
    let documentId: UUID
    let borrowerId: UUID
    let applicationId: UUID?
    let docType: String
    let fileUrl: String
    let fileName: String
    let status: String
    let uploadedAt: Date
    let verifiedBy: UUID?

    enum CodingKeys: String, CodingKey {
        case documentId = "document_id"
        case borrowerId = "borrower_id"
        case applicationId = "application_id"
        case docType = "doc_type"
        case fileUrl = "file_url"
        case fileName = "file_name"
        case status
        case uploadedAt = "uploaded_at"
        case verifiedBy = "verified_by"
    }
}

/// Swift representation of the `public.loan_accounts` database table.
struct DBLoanAccount: Codable, Identifiable, Sendable {
    var id: UUID { accountId }
    
    let accountId: UUID
    let applicationId: UUID
    let borrowerId: UUID
    let principalAmount: Double
    let outstandingBalance: Double
    let interestRate: Double
    let disbursementDate: Date?
    let closureDate: Date?
    let status: String
    let nextEmiDate: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case accountId = "account_id"
        case applicationId = "application_id"
        case borrowerId = "borrower_id"
        case principalAmount = "principal_amount"
        case outstandingBalance = "outstanding_balance"
        case interestRate = "interest_rate"
        case disbursementDate = "disbursement_date"
        case closureDate = "closure_date"
        case status
        case nextEmiDate = "next_emi_date"
        case createdAt = "created_at"
    }
}

/// Swift representation of the `public.emi_schedule` database table.
struct DBEMISchedule: Codable, Identifiable, Sendable {
    var id: UUID { emiId }
    
    let emiId: UUID
    let accountId: UUID
    let instalmentNo: Int
    let dueDate: Date
    let emiAmount: Double
    let principalComponent: Double
    let interestComponent: Double
    let status: String
    let paidDate: Date?
    let paidAmount: Double?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case emiId = "emi_id"
        case accountId = "account_id"
        case instalmentNo = "instalment_no"
        case dueDate = "due_date"
        case emiAmount = "emi_amount"
        case principalComponent = "principal_component"
        case interestComponent = "interest_component"
        case status
        case paidDate = "paid_date"
        case paidAmount = "paid_amount"
        case createdAt = "created_at"
    }
}

/// Swift representation of the `public.messages` database table.
struct DBMessage: Codable, Identifiable, Sendable {
    var id: UUID { messageId }
    
    let messageId: UUID
    let senderId: UUID
    let receiverId: UUID
    let applicationId: UUID?
    let content: String
    let sentAt: Date
    let isRead: Bool

    enum CodingKeys: String, CodingKey {
        case messageId = "message_id"
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case applicationId = "application_id"
        case content
        case sentAt = "sent_at"
        case isRead = "is_read"
    }
}
