import Foundation
import SwiftUI

// MARK: - Navigation
enum AdminTab: Hashable {
    case dashboard, staff, loanRules, templates
}

// MARK: - Dashboard KPIs
struct AdminKPI: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let trend: Double // Positive for up, negative for down
    let themeColor: Color
}

// MARK: - Branch KPI Data
struct KPIBranchData: Identifiable, Hashable {
    let id = UUID()
    let branchName: String
    let branchCode: String
    let value: String
    let trend: Double // Positive for up, negative for down
}

// MARK: - System Health
struct SystemHealth: Equatable {
    var serverUptime: Double // Percentage (e.g. 99.98)
    var activeSessions: Int
    var lastBackupTime: Date
}

// MARK: - Audit Trail
enum AuditLogType: String, Codable, CaseIterable {
    case userAction = "User Action"
    case documentAction = "Document Action"
    case loanAction = "Loan Action"
    case systemAction = "System Action"
    
    var icon: String {
        switch self {
        case .userAction: return "person.crop.circle.badge.plus"
        case .documentAction: return "doc.text.magnifyingglass"
        case .loanAction: return "banknote"
        case .systemAction: return "gearshape.2"
        }
    }
    
    var color: Color {
        switch self {
        case .userAction: return LMSColors.actionBlue
        case .documentAction: return LMSColors.emerald
        case .loanAction: return LMSColors.amber
        case .systemAction: return LMSColors.brandNavy
        }
    }
}

struct AuditLogEntry: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID
    let userName: String
    let action: String
    let entityType: String
    let entityId: String
    let timestamp: Date
    let details: String
    let type: AuditLogType
}

// MARK: - Admin Communication Center
enum AdminIssueCategory: String, CaseIterable, Identifiable, Hashable {
    case customerFeedback = "Customer Feedback"
    case branchOperations = "Branch Operations"
    case staffingRequest = "Staffing Request"
    case employeeConcern = "Employee Concern"
    case productFeedback = "Product Feedback"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .customerFeedback: return "person.crop.circle.badge.exclamationmark"
        case .branchOperations: return "building.2.crop.circle"
        case .staffingRequest: return "person.2.badge.plus"
        case .employeeConcern: return "person.badge.shield.checkmark"
        case .productFeedback: return "lightbulb.max.fill"
        }
    }
}

enum AdminIssuePriority: String, CaseIterable, Identifiable, Hashable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .low: return LMSColors.actionBlue
        case .medium: return LMSColors.amber
        case .high: return LMSColors.coral
        case .critical: return Color.purple
        }
    }
}

enum AdminIssueStatus: String, CaseIterable, Identifiable, Hashable {
    case open = "Open"
    case inProgress = "In Progress"
    case waitingForResponse = "Waiting For Response"
    case resolved = "Resolved"
    case archived = "Archived"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .open: return LMSColors.coral
        case .inProgress: return LMSColors.actionBlue
        case .waitingForResponse: return LMSColors.amber
        case .resolved: return LMSColors.emerald
        case .archived: return LMSColors.textSecondary
        }
    }
}

struct AdminIssueReply: Identifiable, Hashable {
    let id = UUID()
    let author: String
    let message: String
    let timestamp: Date
}

struct AdminCommunicationIssue: Identifiable, Hashable {
    let id: UUID
    var issueId: String
    var title: String
    var branchName: String
    var raisedBy: String
    var category: AdminIssueCategory
    var priority: AdminIssuePriority
    var createdDate: Date
    var status: AdminIssueStatus
    var issue: String
    var assignedTo: String?
    var supportingDocuments: [String]
    var replies: [AdminIssueReply]
    var createdBy: String
    var responseDate: Date?
    var resolvedDate: Date?
    var lastUpdatedBy: String
}

enum AdminBroadcastRecipient: String, CaseIterable, Identifiable, Hashable {
    case allBranchManagers = "All Branch Managers"
    case selectedBranchManagers = "Selected Branch Managers"
    case allLoanOfficers = "All Loan Officers"
    case selectedLoanOfficers = "Selected Loan Officers"
    case entireOrganization = "Entire Organization"

    var id: String { rawValue }
}

enum AdminAnnouncementType: String, CaseIterable, Identifiable, Hashable {
    case operationalUpdate = "Operational Update"
    case policyChange = "Policy Change"
    case interestRateChange = "Interest Rate Change"
    case holidayNotification = "Holiday Notification"
    case systemMaintenance = "System Maintenance"
    case trainingAnnouncement = "Training Announcement"
    case complianceAlert = "Compliance Alert"

    var id: String { rawValue }
}

struct AdminBroadcastMessage: Identifiable, Hashable {
    let id = UUID()
    var subject: String
    var message: String
    var recipients: AdminBroadcastRecipient
    var type: AdminAnnouncementType
    var createdDate: Date
}

// MARK: - Loan Products
struct AdminLoanProduct: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var loanType: String
    var isActive: Bool
    var minRate: Double
    var maxRate: Double
    var minAmount: Double
    var maxAmount: Double
    var maxTenure: Int // in months
    var processingFee: Double // Percentage
    var requiredDocuments: [String]
}

// MARK: - Global Rules
struct GlobalLoanRules: Codable, Equatable {
    var minCibilScore: Int
    var maxDTI: Double // Debt-to-Income ratio max percentage
    var maxLTV: Double // Loan-to-Value ratio max percentage

    enum CodingKeys: String, CodingKey {
        case minCibilScore, maxDTI, maxLTV
        case minCibilScoreSnake = "min_cibil_score"
        case maxDTISnake = "max_dti"
        case maxLTVSnake = "max_ltv"
    }

    init(minCibilScore: Int, maxDTI: Double, maxLTV: Double) {
        self.minCibilScore = minCibilScore
        self.maxDTI = maxDTI
        self.maxLTV = maxLTV
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode minCibilScore (try camelCase, snake_case, or auto-converted key)
        if let val = try? container.decode(Int.self, forKey: .minCibilScore) {
            self.minCibilScore = val
        } else if let val = try? container.decode(Int.self, forKey: .minCibilScoreSnake) {
            self.minCibilScore = val
        } else {
            self.minCibilScore = try container.decode(Int.self, forKey: .minCibilScore)
        }

        // Decode maxDTI (try Double then Int)
        if let val = try? container.decode(Double.self, forKey: .maxDTI) {
            self.maxDTI = val
        } else if let val = try? container.decode(Int.self, forKey: .maxDTI) {
            self.maxDTI = Double(val)
        } else if let val = try? container.decode(Double.self, forKey: .maxDTISnake) {
            self.maxDTI = val
        } else if let val = try? container.decode(Int.self, forKey: .maxDTISnake) {
            self.maxDTI = Double(val)
        } else {
            self.maxDTI = try container.decode(Double.self, forKey: .maxDTI)
        }

        // Decode maxLTV (try Double then Int)
        if let val = try? container.decode(Double.self, forKey: .maxLTV) {
            self.maxLTV = val
        } else if let val = try? container.decode(Int.self, forKey: .maxLTV) {
            self.maxLTV = Double(val)
        } else if let val = try? container.decode(Double.self, forKey: .maxLTVSnake) {
            self.maxLTV = val
        } else if let val = try? container.decode(Int.self, forKey: .maxLTVSnake) {
            self.maxLTV = Double(val)
        } else {
            self.maxLTV = try container.decode(Double.self, forKey: .maxLTV)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(minCibilScore, forKey: .minCibilScore)
        try container.encode(maxDTI, forKey: .maxDTI)
        try container.encode(maxLTV, forKey: .maxLTV)
    }
}

// MARK: - Message Templates
enum MessageTemplateType: String, Codable, CaseIterable {
    case email = "Email"
    case sms = "SMS"
    case push = "Push Notification"
    
    var icon: String {
        switch self {
        case .email: return "envelope.fill"
        case .sms: return "message.fill"
        case .push: return "bell.badge.fill"
        }
    }
}

struct MessageTemplate: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var subject: String
    var body: String
    var type: MessageTemplateType
    var isActive: Bool
}
