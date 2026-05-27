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
