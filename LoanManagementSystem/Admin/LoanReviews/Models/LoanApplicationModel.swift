import Foundation
import SwiftUI

// MARK: - Loan Status
enum LoanApplicationStatus: String, CaseIterable, Identifiable {
    case pending = "Pending"
    case underReview = "Under Review"
    case changesRequested = "Changes Requested"
    case approved = "Approved"
    case rejected = "Rejected"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .pending: return LMSColors.amber
        case .underReview: return LMSColors.actionBlue
        case .changesRequested: return LMSColors.coral
        case .approved: return LMSColors.emerald
        case .rejected: return LMSColors.coral
        }
    }
}

// MARK: - Recommendation Status
enum RecommendationBadge: String, CaseIterable, Identifiable {
    case eligible = "Eligible for Approval"
    case mediumRisk = "Medium Risk"
    case highRisk = "High Risk"
    case additionalVerification = "Additional Verification Required"
    case recommendedEMI = "Recommended EMI Plan Available"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .eligible, .recommendedEMI: return LMSColors.emerald
        case .mediumRisk, .additionalVerification: return LMSColors.amber
        case .highRisk: return LMSColors.coral
        }
    }
}

// MARK: - Admin Loan Type
enum AdminLoanType: String, CaseIterable, Identifiable {
    case personal = "Personal Loan"
    case home = "Home Loan"
    case auto = "Auto Loan"
    case education = "Education Loan"
    case business = "Business Loan"
    
    var id: String { self.rawValue }
}

// MARK: - Applicant Model
struct LoanApplicantModel: Identifiable, Hashable {
    let id: UUID
    let loanId: String
    let applicantName: String
    let loanType: AdminLoanType
    let requestedAmount: Double
    let applicationDate: Date
    
    var status: LoanApplicationStatus
    let cibilScore: Int
    let recommendation: RecommendationBadge
    
    // Detailed Info
    let employmentType: String
    let monthlyIncome: Double
    let existingEMI: Double
    
    var timeline: [ApplicationTimelineEvent]
    var internalNotes: String?
    
    // Equatable / Hashable
    static func == (lhs: LoanApplicantModel, rhs: LoanApplicantModel) -> Bool {
        lhs.id == rhs.id && lhs.status == rhs.status
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(status)
    }
}

// MARK: - Timeline Event
struct ApplicationTimelineEvent: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let action: String
    let user: String?
}
