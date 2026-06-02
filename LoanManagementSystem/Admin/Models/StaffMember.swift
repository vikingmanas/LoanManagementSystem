import Foundation
import SwiftUI

enum StaffRole: String, Codable, CaseIterable, Identifiable {
    case loanOfficer = "loan_officer"
    case bankManager = "manager"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .loanOfficer: return "Loan Officer"
        case .bankManager: return "Bank Manager"
        }
    }

    var themeColor: Color {
        switch self {
        case .loanOfficer: return LMSColors.actionBlue
        case .bankManager: return LMSColors.brandNavy
        }
    }
}

enum StaffStatus: String, Codable, CaseIterable, Identifiable {
    case active = "active"
    case inactive = "inactive"
    case suspended = "suspended"
    case pending = "pending"

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var themeColor: Color {
        switch self {
        case .active: return LMSColors.emerald
        case .inactive: return LMSColors.textSecondary
        case .suspended: return LMSColors.coral
        case .pending: return LMSColors.amber
        }
    }
}

struct StaffMember: Identifiable, Codable, Hashable {
    let id: UUID
    /// `loan_officers.officer_id` used in Supabase `loan_applications.officer_id`.
    var loanOfficerRecordId: UUID?
    var email: String
    var role: StaffRole
    var fullName: String
    var phoneNumber: String
    var status: StaffStatus
    var createdBy: UUID?
    var createdAt: Date
    var employeeCode: String
    var branchId: UUID
    var branchName: String?
    var designation: String?
    var region: String?

    var initials: String {
        let parts = fullName.components(separatedBy: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(fullName.prefix(2)).uppercased()
    }
}

struct BranchInfo: Identifiable, Codable, Hashable {
    let branchId: UUID
    var name: String
    var code: String
    var region: String

    var id: UUID { branchId }
}

