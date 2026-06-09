
import Foundation

enum DocumentType: String, Codable {
    case identityProof = "identity_proof"
    case addressProof = "address_proof"
    case incomeProof = "income_proof"
    case bankStatement = "bank_statement"
    case propertyDocument = "property_document"
}

enum DocumentStatus: String, Codable {
    case uploaded, verified, rejected
}

enum RiskCategory: String, Codable {
    case low, medium, high
}

enum WorkflowAction: String, Codable {
    case submitted, reviewed, approved, rejected, commentAdded = "comment_added", disbursed
}

enum NotificationType: String, Codable {
    case email, sms, push
}

enum ReportType: String, Codable {
    case disbursement, collection, defaultRate = "default_rate", performance
}

enum PeriodType: String, Codable {
    case daily, weekly, monthly, yearly
}

enum ReportFormat: String, Codable {
    case pdf, csv, excel
}

struct Document: Codable, Identifiable {
    let id: UUID
    let borrowerId: UUID
    let applicationId: UUID?
    let docType: DocumentType
    let fileUrl: String
    let fileName: String
    let status: DocumentStatus
    let uploadedAt: Date
    let verifiedBy: UUID?

    enum CodingKeys: String, CodingKey {
        case id = "document_id"
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

struct CreditScore: Codable, Identifiable {
    let id: UUID
    let borrowerId: UUID
    let score: Int
    let riskCategory: RiskCategory
    let bureauName: String
    let assessedAt: Date
    let isCurrent: Bool

    enum CodingKeys: String, CodingKey {
        case id = "score_id"
        case borrowerId = "borrower_id"
        case score
        case riskCategory = "risk_category"
        case bureauName = "bureau_name"
        case assessedAt = "assessed_at"
        case isCurrent = "is_current"
    }
}

struct AppWorkflow: Codable, Identifiable {
    let id: UUID
    let applicationId: UUID
    let actionBy: UUID
    let action: WorkflowAction
    let remarks: String?
    let actionAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "workflow_id"
        case applicationId = "application_id"
        case actionBy = "action_by"
        case action, remarks
        case actionAt = "action_at"
    }
}

struct Message: Codable, Identifiable {
    let id: UUID
    let senderId: UUID
    let receiverId: UUID
    let applicationId: UUID?
    let content: String
    let sentAt: Date
    let isRead: Bool

    enum CodingKeys: String, CodingKey {
        case id = "message_id"
        case senderId = "sender_id"
        case receiverId = "receiver_id"
        case applicationId = "application_id"
        case content
        case sentAt = "sent_at"
        case isRead = "is_read"
    }
}

struct NotificationModel: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let notifType: NotificationType
    let title: String
    let message: String
    let isRead: Bool
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "notification_id"
        case userId = "user_id"
        case notifType = "notif_type"
        case title, message
        case isRead = "is_read"
        case createdAt = "created_at"
    }
}

struct NotificationTemplate: Codable, Identifiable {
    let id: UUID
    let notifType: NotificationType
    let titleTemplate: String
    let bodyTemplate: String
    let createdBy: UUID
    let isActive: Bool

    enum CodingKeys: String, CodingKey {
        case id = "template_id"
        case notifType = "notif_type"
        case titleTemplate = "title_template"
        case bodyTemplate = "body_template"
        case createdBy = "created_by"
        case isActive = "is_active"
    }
}

struct Report: Codable, Identifiable {
    let id: UUID
    let generatedBy: UUID
    let reportType: ReportType
    let periodType: PeriodType
    let fromDate: Date
    let toDate: Date
    let format: ReportFormat
    let fileUrl: String
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id = "report_id"
        case generatedBy = "generated_by"
        case reportType = "report_type"
        case periodType = "period_type"
        case fromDate = "from_date"
        case toDate = "to_date"
        case format
        case fileUrl = "file_url"
        case createdAt = "created_at"
    }
}
