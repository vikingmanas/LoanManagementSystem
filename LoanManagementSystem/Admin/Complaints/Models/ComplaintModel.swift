import Foundation
import SwiftUI

// MARK: - Ticket Origin (Complaint vs Operational Issue)
enum TicketOrigin: String, CaseIterable, Identifiable {
    case complaint = "Complaint"
    case operationalIssue = "Operational Issue"
    
    var id: String { self.rawValue }
    
    var iconName: String {
        switch self {
        case .complaint: return "person.crop.circle.badge.exclamationmark"
        case .operationalIssue: return "server.rack"
        }
    }
    
    var tint: Color {
        switch self {
        case .complaint: return LMSColors.brandNavy
        case .operationalIssue: return LMSColors.teal
        }
    }
}

// MARK: - Status
enum ComplaintStatus: String, CaseIterable, Identifiable {
    case open = "Open"
    case inProgress = "In Progress"
    case inReview = "In Review"
    case pending = "Pending"
    case escalated = "Escalated"
    case resolved = "Resolved"
    case closed = "Closed"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .resolved:
            return LMSColors.emerald
        case .pending, .open:
            return LMSColors.amber
        case .escalated:
            return LMSColors.coral
        case .inReview, .inProgress:
            return LMSColors.actionBlue
        case .closed:
            return LMSColors.textSecondary
        }
    }
    
    var iconName: String {
        switch self {
        case .open: return "circle"
        case .inProgress: return "arrow.triangle.2.circlepath"
        case .inReview: return "eye.fill"
        case .pending: return "clock.fill"
        case .escalated: return "exclamationmark.triangle.fill"
        case .resolved: return "checkmark.circle.fill"
        case .closed: return "xmark.circle.fill"
        }
    }
}

// MARK: - Priority / Severity
enum ComplaintPriority: String, CaseIterable, Identifiable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .low:
            return LMSColors.emerald
        case .medium:
            return LMSColors.amber
        case .high:
            return Color(UIColor { tc in
                tc.userInterfaceStyle == .dark
                    ? UIColor(red: 255/255, green: 159/255, blue: 67/255, alpha: 1)
                    : UIColor(red: 230/255, green: 126/255, blue: 34/255, alpha: 1)
            })
        case .critical:
            return LMSColors.coral
        }
    }
    
    var weight: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .critical: return 3
        }
    }
}

// MARK: - Category (unified for complaints + operational issues)
enum ComplaintCategory: String, CaseIterable, Identifiable {
    // Borrower Complaint Types
    case customerService = "Customer Service"
    case financialDiscrepancy = "Financial Discrepancy"
    case policyViolation = "Policy Violation"
    
    // Operational / Technical Issue Types
    case serverDowntime = "Server Downtime"
    case loanProcessingFailure = "Loan Processing Failure"
    case paymentGateway = "Payment Gateway Issue"
    case authenticationIssue = "Authentication Issue"
    case databaseSync = "Database Sync Issue"
    case kycVerification = "KYC Verification Failure"
    case branchOutage = "Branch System Outage"
    case apiFailure = "API Failure"
    case technicalBug = "Technical Bug"
    case workflowIssue = "Internal Workflow Issue"
    
    var id: String { self.rawValue }
    
    var origin: TicketOrigin {
        switch self {
        case .customerService, .financialDiscrepancy, .policyViolation:
            return .complaint
        default:
            return .operationalIssue
        }
    }
    
    var iconName: String {
        switch self {
        case .customerService: return "person.2.fill"
        case .financialDiscrepancy: return "indianrupeesign.circle.fill"
        case .policyViolation: return "doc.text.fill"
        case .serverDowntime: return "server.rack"
        case .loanProcessingFailure: return "doc.text.magnifyingglass"
        case .paymentGateway: return "creditcard.trianglebadge.exclamationmark"
        case .authenticationIssue: return "lock.trianglebadge.exclamationmark"
        case .databaseSync: return "arrow.triangle.2.circlepath.icloud"
        case .kycVerification: return "person.badge.shield.checkmark.fill"
        case .branchOutage: return "building.2.crop.circle.badge.exclamationmark"
        case .apiFailure: return "network.slash"
        case .technicalBug: return "ladybug.fill"
        case .workflowIssue: return "arrow.rectanglepath"
        }
    }
}

// MARK: - Unified Ticket Model
struct ComplaintTicket: Identifiable, Hashable {
    let id: UUID
    let ticketId: String
    let title: String
    let origin: TicketOrigin
    let category: ComplaintCategory
    let branchName: String
    let dateRaised: Date
    
    var status: ComplaintStatus
    var priority: ComplaintPriority
    let description: String
    
    // Complaint-specific (optional)
    let borrowerName: String?
    
    // Internal Operational Fields
    var assignedManager: String?
    var assignedTeam: String?
    var managerNotes: String?
    var adminRemarks: String?
    var timeline: [TicketTimelineEvent]
    
    // Hashable / Equatable
    static func == (lhs: ComplaintTicket, rhs: ComplaintTicket) -> Bool {
        lhs.id == rhs.id && lhs.status == rhs.status && lhs.priority == rhs.priority
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(status)
        hasher.combine(priority)
    }
}

// MARK: - Timeline Event
struct TicketTimelineEvent: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let action: String
    let note: String?
    let user: String?
}
