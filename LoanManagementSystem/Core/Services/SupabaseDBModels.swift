import Foundation

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
}

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
}

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
}

struct DBMessage: Codable, Identifiable, Sendable, Equatable {
    var id: UUID { messageId }
    
    let messageId: UUID
    let senderId: UUID
    let receiverId: UUID
    let applicationId: UUID?
    let content: String
    let sentAt: Date
    let isRead: Bool
}

struct AssignedLoanOfficer: Codable, Identifiable, Sendable, Equatable, Hashable {
    var id: UUID { officerId }
    
    let officerId: UUID
    let userId: UUID
    let fullName: String
    let employeeCode: String
    let branchId: UUID
    let branchName: String
    let designation: String
    let lastAssignedAt: Date?
    let activeWorkload: Int
    
    var initials: String {
        let formatter = PersonNameComponentsFormatter()
        if let components = formatter.personNameComponents(from: fullName) {
            formatter.style = .abbreviated
            return formatter.string(from: components)
        }
        return ""
    }
}
