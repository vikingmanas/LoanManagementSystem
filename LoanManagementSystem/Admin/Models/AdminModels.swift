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
