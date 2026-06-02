import SwiftUI


enum ManagerApplicantStatus: String, CaseIterable, Codable, Hashable {
    case sentToManager = "Pending Review"
    case needsClarification = "Needs Clarification"
    case approved = "Approved"
    case rejected = "Rejected"
    case escalated = "Escalated"
    case disbursed = "Disbursed"

    var displayName: String { rawValue }

    var themeColor: Color {
        switch self {
        case .sentToManager:       return LMSColors.amber
        case .needsClarification:  return LMSColors.actionBlue
        case .approved:            return LMSColors.emerald
        case .rejected:            return LMSColors.coral
        case .escalated:           return Color.purple
        case .disbursed:           return LMSColors.teal
        }
    }

    var icon: String {
        switch self {
        case .sentToManager:       return "exclamationmark.shield.fill"
        case .needsClarification:  return "questionmark.circle.fill"
        case .approved:            return "checkmark.seal.fill"
        case .rejected:            return "xmark.octagon.fill"
        case .escalated:           return "arrow.up.forward.circle.fill"
        case .disbursed:           return "banknote.fill"
        }
    }
}


enum ManagerRiskLevel: String, CaseIterable, Codable, Hashable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
    case critical = "Critical"

    var themeColor: Color {
        switch self {
        case .low:      return LMSColors.emerald
        case .medium:   return LMSColors.amber
        case .high:     return LMSColors.coral
        case .critical: return Color.red
        }
    }

    var icon: String {
        switch self {
        case .low:      return "shield.checkmark.fill"
        case .medium:   return "exclamationmark.triangle.fill"
        case .high:     return "flame.fill"
        case .critical: return "exclamationmark.octagon.fill"
        }
    }
}


enum ManagerLoanType: String, CaseIterable, Codable, Hashable {
    case home = "Home Loan"
    case personal = "Personal Loan"
    case business = "Business Loan"
    case vehicle = "Vehicle Loan"
    case education = "Education Loan"

    var symbol: String {
        switch self {
        case .home:      return "house.fill"
        case .personal:  return "person.fill"
        case .business:  return "briefcase.fill"
        case .vehicle:   return "car.fill"
        case .education: return "graduationcap.fill"
        }
    }

    var themeColor: Color {
        switch self {
        case .home:      return LMSColors.brandNavy
        case .personal:  return LMSColors.teal
        case .business:  return Color.purple
        case .vehicle:   return LMSColors.amber
        case .education: return LMSColors.actionBlue
        }
    }
}


enum ManagerOfficerAssignment {
    static let unassignedOfficerId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    static let unassignedOfficerName = "Unassigned"
}


struct ManagerApplicant: Identifiable, Hashable {
    let id: UUID
    var applicationId: String
    var borrowerName: String
    var borrowerInitials: String
    var loanType: ManagerLoanType
    var requestedAmount: Double
    var cibilScore: Int
    var status: ManagerApplicantStatus
    var riskLevel: ManagerRiskLevel
    var assignedOfficer: String
    var assignedOfficerId: UUID
    var submissionDate: Date
    var documents: [ManagerDocument]
    var officerRemarks: String
    var managerRemarks: String
    var verificationProgress: Double
    var tenure: Int
    var interestRate: Double
    var branchName: String
    var escalatedAt: Date? = nil

    var isAssignedToOfficer: Bool {
        assignedOfficerId != ManagerOfficerAssignment.unassignedOfficerId
            && assignedOfficer != ManagerOfficerAssignment.unassignedOfficerName
    }
}


struct ManagerDocument: Identifiable, Hashable {
    let id: UUID
    var name: String
    var type: String
    var status: ManagerDocStatus
}

enum ManagerDocStatus: String, CaseIterable, Codable, Hashable {
    case verified = "Verified"
    case pending = "Pending"
    case rejected = "Rejected"
    case reUploaded = "Re-uploaded"

    var themeColor: Color {
        switch self {
        case .verified:   return LMSColors.emerald
        case .pending:    return LMSColors.amber
        case .rejected:   return LMSColors.coral
        case .reUploaded: return LMSColors.teal
        }
    }

    var icon: String {
        switch self {
        case .verified:   return "checkmark.circle.fill"
        case .pending:    return "clock.fill"
        case .rejected:   return "xmark.circle.fill"
        case .reUploaded: return "arrow.triangle.2.circlepath"
        }
    }
}


struct ManagerOfficerEscalation: Identifiable, Hashable {
    let id: UUID
    var applicationId: String
    var borrowerName: String
    var loanType: ManagerLoanType
    var requestedAmount: Double
    var escalatedAt: Date
    var reason: String
    var riskLevel: ManagerRiskLevel
}

struct ManagerOfficerPerformanceSummary: Identifiable, Hashable {
    var id: UUID { officer.id }
    let officer: ManagerOfficer
    let escalations: [ManagerOfficerEscalation]
    let managerRating: Double?
    let suggestedRating: Double

    var displayRating: Double {
        managerRating ?? suggestedRating
    }

    var officerEscalationCount: Int { escalations.count }
}

struct ManagerOfficer: Identifiable, Hashable {
    let id: UUID
    var name: String
    var role: String
    var activeCases: Int
    var maxCapacity: Int
    var rating: Double
    var managerRating: Double? = nil
    var performance: Double
    var loansProcessedYTD: Int
    var approvalRate: Double

    var initials: String {
        let parts = name.components(separatedBy: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    var capacityPercentage: Double {
        Double(activeCases) / Double(maxCapacity)
    }

    var capacityColor: Color {
        if capacityPercentage > 0.85 { return LMSColors.coral }
        if capacityPercentage > 0.60 { return LMSColors.amber }
        return LMSColors.emerald
    }
}

struct ManagerStaffProfile: Hashable {
    var name: String
    var email: String
    var phone: String
    var employeeCode: String
    var branchName: String
    var branchCode: String
    var region: String
    var roleTitle: String
    var joinedAt: Date?

    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        if !name.isEmpty {
            return String(name.prefix(2)).uppercased()
        }
        if !email.isEmpty {
            return String(email.prefix(1)).uppercased()
        }
        return "M"
    }

    static let empty = ManagerStaffProfile(
        name: "Manager",
        email: "",
        phone: "",
        employeeCode: "",
        branchName: "Assigned Branch",
        branchCode: "BR",
        region: "Regional Office",
        roleTitle: "Branch Manager",
        joinedAt: nil
    )
}



struct ManagerNotificationItem: Identifiable, Hashable {
    let id: UUID
    var title: String
    var message: String
    var timestamp: Date
    var type: NotifType
    var isRead: Bool
    var relatedApplicantId: UUID?

    enum NotifType: String, CaseIterable, Hashable {
        case alert, warning, info, success

        var icon: String {
            switch self {
            case .alert:   return "exclamationmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info:    return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            }
        }

        var color: Color {
            switch self {
            case .alert:   return LMSColors.coral
            case .warning: return LMSColors.amber
            case .info:    return LMSColors.actionBlue
            case .success: return LMSColors.emerald
            }
        }
    }
}


struct ManagerChatConversation: Identifiable, Hashable {
    let id: UUID
    var officerUserId: UUID
    var officerName: String
    var officerInitials: String
    var officerRole: String
    var lastMessage: String
    var timestamp: Date
    var unreadCount: Int
    var isPinned: Bool
    var priority: ChatPriority
    var messages: [ManagerChatMessage]

    enum ChatPriority: String, CaseIterable, Hashable {
        case normal, high, urgent

        var color: Color {
            switch self {
            case .normal: return LMSColors.textSecondary
            case .high:   return LMSColors.amber
            case .urgent: return LMSColors.coral
            }
        }
    }
}


struct ManagerChatMessage: Identifiable, Hashable {
    let id: UUID
    var senderName: String
    var text: String
    var timestamp: Date
    var isFromManager: Bool
    var isSystemMessage: Bool
    var referencedApplicantId: UUID?
    var referencedApplicantName: String?
}


struct BranchOverview: Hashable {
    var name: String
    var code: String
    var region: String
    var staffCount: Int
    var activeLoanCount: Int
    var totalDisbursed: Double
    var totalRecovered: Double
    var nplRate: Double
    var auditRating: String
    var monthlyTarget: Double
}


struct ManagerAuditEvent: Identifiable, Hashable {
    let id: UUID
    var timestamp: Date
    var action: String
    var user: String
    var severity: Severity

    enum Severity: String, Hashable {
        case info, success, warning, critical

        var color: Color {
            switch self {
            case .info:     return LMSColors.actionBlue
            case .success:  return LMSColors.emerald
            case .warning:  return LMSColors.amber
            case .critical: return LMSColors.coral
            }
        }

        var icon: String {
            switch self {
            case .info:     return "info.circle.fill"
            case .success:  return "checkmark.circle.fill"
            case .warning:  return "exclamationmark.triangle.fill"
            case .critical: return "xmark.octagon.fill"
            }
        }
    }
}
