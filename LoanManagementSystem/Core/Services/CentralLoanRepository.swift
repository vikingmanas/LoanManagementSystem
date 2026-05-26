import Foundation
import Combine
import SwiftUI

/// Centralized repository serving as the single source of truth for all loan applications.
/// Bridges real-time state updates across the Customer, Loan Officer, and Manager portals.
@MainActor
final class CentralLoanRepository: ObservableObject {
    static let shared = CentralLoanRepository()
    
    @Published var applications: [BorrowerLoanApplication] = []
    
    private init() {}
    
    // MARK: - Core Operations
    
    func submitApplication(_ app: BorrowerLoanApplication) {
        if let index = applications.firstIndex(where: { $0.id == app.id }) {
            applications[index] = app
        } else {
            applications.insert(app, at: 0)
        }
    }
    
    func updateApplication(_ app: BorrowerLoanApplication) {
        if let index = applications.firstIndex(where: { $0.id == app.id }) {
            applications[index] = app
        }
    }
    
    // MARK: - State Transitions
    
    func updateDocumentStatus(applicationId: String, docId: UUID, status: OfficerDocumentStatus, reason: String?) {
        guard let index = applications.firstIndex(where: { $0.applicationId == applicationId }) else { return }
        var app = applications[index]
        
        if let docIndex = app.documents.firstIndex(where: { $0.id == docId }) {
            let borrowerDocStatus: BorrowerDocumentStatus
            switch status {
            case .pending: borrowerDocStatus = .pendingUpload
            case .uploaded: borrowerDocStatus = .uploaded
            case .underReview: borrowerDocStatus = .underVerification
            case .verified: borrowerDocStatus = .verified
            case .rejectFlag: borrowerDocStatus = .rejected
            case .reUploaded: borrowerDocStatus = .uploaded
            }
            
            app.documents[docIndex].status = borrowerDocStatus
            app.documents[docIndex].lastUpdated = Date()
            
            // Recompute stage based on verification
            recomputeVerificationStage(app: &app)
            applications[index] = app
        }
    }
    
    func sendForFinalApproval(applicationId: String) {
        guard let index = applications.firstIndex(where: { $0.applicationId == applicationId }) else { return }
        var app = applications[index]
        app.currentStage = .bankManagerReview
        app.updatedAt = Date()
        app.stageHistory.append(
            BorrowerStageEntry(
                stage: .bankManagerReview,
                timestamp: Date(),
                note: "Documents verified by Officer Arjun. Forwarded to Manager for final approval."
            )
        )
        applications[index] = app
    }
    
    func approveApplication(id: UUID, remarks: String) {
        guard let index = applications.firstIndex(where: { $0.id == id }) else { return }
        var app = applications[index]
        app.currentStage = .approved
        app.updatedAt = Date()
        app.stageHistory.append(
            BorrowerStageEntry(
                stage: .approved,
                timestamp: Date(),
                note: remarks.isEmpty ? "Approved by Branch Manager." : remarks
            )
        )
        // Automatically disburse for live flow
        app.currentStage = .disbursed
        app.stageHistory.append(
            BorrowerStageEntry(
                stage: .disbursed,
                timestamp: Date(),
                note: "Loan amount disbursed to linked savings account."
            )
        )
        applications[index] = app
    }
    
    func rejectApplication(id: UUID, remarks: String) {
        guard let index = applications.firstIndex(where: { $0.id == id }) else { return }
        var app = applications[index]
        app.currentStage = .rejected
        app.updatedAt = Date()
        app.stageHistory.append(
            BorrowerStageEntry(
                stage: .rejected,
                timestamp: Date(),
                note: remarks.isEmpty ? "Rejected by Branch Manager." : remarks
            )
        )
        applications[index] = app
    }
    
    func sendBackApplication(id: UUID, remarks: String) {
        guard let index = applications.firstIndex(where: { $0.id == id }) else { return }
        var app = applications[index]
        app.currentStage = .underReview
        app.updatedAt = Date()
        app.stageHistory.append(
            BorrowerStageEntry(
                stage: .underReview,
                timestamp: Date(),
                note: "Returned by Manager: \(remarks)"
            )
        )
        applications[index] = app
    }
    
    // MARK: - Private Helpers
    
    private func recomputeVerificationStage(app: inout BorrowerLoanApplication) {
        let docs = app.documents
        if docs.isEmpty { return }
        
        let hasRejected = docs.contains(where: { $0.status == .rejected })
        let allVerified = docs.allSatisfy({ $0.status == .verified })
        
        if allVerified {
            app.currentStage = .loanOfficerReview
        } else if hasRejected {
            app.currentStage = .documentVerification
        } else {
            app.currentStage = .underReview
        }
        app.updatedAt = Date()
    }
    
    // MARK: - Mapping Helpers
    
    func toOfficerApplication(from app: BorrowerLoanApplication) -> OfficerLoanApplication? {
        // Skip drafts in Officer portal
        guard app.currentStage != .draft else { return nil }
        
        let type: OfficerLoanType
        switch app.product.type {
        case .home: type = .home
        case .personal: type = .personal
        case .business: type = .business
        case .vehicle: type = .vehicle
        case .education: type = .education
        default: type = .personal
        }
        
        let officerStatus: OfficerApplicationStatus
        switch app.currentStage {
        case .draft: officerStatus = .onHold
        case .submitted: officerStatus = .pending
        case .underReview: officerStatus = .underReview
        case .documentVerification: officerStatus = .documentsPending
        case .loanOfficerReview: officerStatus = .verificationCompleted
        case .bankManagerReview: officerStatus = .finalApprovalPending
        case .approved: officerStatus = .approved
        case .rejected: officerStatus = .rejected
        case .disbursed: officerStatus = .disbursed
        }
        
        let managerStatus: ManagerStatus?
        switch app.currentStage {
        case .bankManagerReview: managerStatus = .underReview
        case .approved, .disbursed: managerStatus = .approved
        case .rejected: managerStatus = .needsClarification
        default: managerStatus = nil
        }
        
        let sentToManagerDate = app.stageHistory.first(where: { $0.stage == .bankManagerReview })?.timestamp
        let assignedOfficerId = UUID(uuidString: "00000000-0000-0000-0000-000000000002") ?? app.id
        
        return OfficerLoanApplication(
            id: app.id,
            applicationId: app.applicationId ?? "APP-2026-\(app.id.uuidString.prefix(4))",
            borrowerName: app.formData.fullName.isEmpty ? "Borrower" : app.formData.fullName,
            borrowerId: app.id,
            loanType: type,
            requestedAmount: app.formData.requestedAmountValue,
            status: officerStatus,
            submittedDate: app.submittedAt ?? Date(),
            lastUpdatedDate: app.updatedAt,
            assignedOfficerId: assignedOfficerId,
            documents: app.documents.map { mapToLoanDocument(from: $0) },
            notes: app.formData.loanPurpose.isEmpty ? "General financing requirement" : app.formData.loanPurpose,
            branch: "Main Branch",
            cibilScore: app.formData.creditScoreValue > 0 ? app.formData.creditScoreValue : 750,
            sentToManagerDate: sentToManagerDate,
            managerStatus: managerStatus
        )
    }
    
    func toManagerApplicant(from app: BorrowerLoanApplication) -> ManagerApplicant? {
        // Manager only sees items that are sent for approval or higher
        guard app.currentStage == .bankManagerReview || app.currentStage == .approved || app.currentStage == .disbursed || app.currentStage == .rejected else {
            return nil
        }
        
        let type: ManagerLoanType
        switch app.product.type {
        case .home: type = .home
        case .personal: type = .personal
        case .business: type = .business
        case .vehicle: type = .vehicle
        case .education: type = .education
        default: type = .personal
        }
        
        let status: ManagerApplicantStatus
        switch app.currentStage {
        case .bankManagerReview: status = .sentToManager
        case .approved: status = .approved
        case .rejected: status = .rejected
        case .disbursed: status = .disbursed
        default: status = .sentToManager
        }
        
        let initials = app.formData.fullName.components(separatedBy: " ").compactMap { $0.first }.map { String($0) }.joined().uppercased()
        
        let assignedOfficerName = app.assignedQueue ?? "Loan Officer Queue"
        let assignedOfficerId = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? app.id

        return ManagerApplicant(
            id: app.id,
            applicationId: app.applicationId ?? "APP-2026-\(app.id.uuidString.prefix(4))",
            borrowerName: app.formData.fullName.isEmpty ? "Borrower" : app.formData.fullName,
            borrowerInitials: initials.isEmpty ? "B" : initials,
            loanType: type,
            requestedAmount: app.formData.requestedAmountValue,
            cibilScore: app.formData.creditScoreValue > 0 ? app.formData.creditScoreValue : 750,
            status: status,
            riskLevel: app.formData.creditScoreValue >= 750 ? .low : (app.formData.creditScoreValue >= 650 ? .medium : .high),
            assignedOfficer: assignedOfficerName,
            assignedOfficerId: assignedOfficerId,
            submissionDate: app.submittedAt ?? Date(),
            documents: app.documents.map { mapToManagerDocument(from: $0) },
            officerRemarks: app.stageHistory.last(where: { $0.stage == .bankManagerReview })?.note ?? "Forwarded for manager approval after officer review.",
            managerRemarks: "",
            verificationProgress: app.documents.isEmpty ? 0 : Double(app.documents.filter { $0.status == .verified }.count) / Double(app.documents.count),
            tenure: app.formData.preferredTenureMonths,
            interestRate: 10.5
        )
    }
    
    private func mapToLoanDocument(from item: BorrowerLoanDocumentItem) -> LoanDocument {
        let officerDocType: OfficerDocumentType
        switch item.name.lowercased() {
        case let s where s.contains("aadhaar"): officerDocType = .aadhaar
        case let s where s.contains("pan"): officerDocType = .pan
        case let s where s.contains("salary"): officerDocType = .salarySlip
        case let s where s.contains("statement"): officerDocType = .bankStatement
        case let s where s.contains("property"): officerDocType = .propertyDoc
        case let s where s.contains("gst"): officerDocType = .gstCertificate
        case let s where s.contains("admission"): officerDocType = .admissionLetter
        case let s where s.contains("income tax") || s.contains("itr"): officerDocType = .incomeTaxReturn
        default: officerDocType = .photograph
        }
        
        let officerStatus: OfficerDocumentStatus
        switch item.status {
        case .pendingUpload: officerStatus = .pending
        case .uploaded: officerStatus = .uploaded
        case .underVerification: officerStatus = .underReview
        case .verified: officerStatus = .verified
        case .rejected, .requiresResubmission: officerStatus = .rejectFlag
        }
        
        return LoanDocument(
            id: item.id,
            docType: officerDocType,
            status: officerStatus,
            uploadedDate: item.uploadDate,
            reviewedDate: item.lastUpdated,
            rejectionReason: nil,
            fileURL: item.fileName
        )
    }
    
    private func mapToManagerDocument(from item: BorrowerLoanDocumentItem) -> ManagerDocument {
        let status: ManagerDocStatus
        switch item.status {
        case .verified: status = .verified
        case .pendingUpload, .underVerification, .uploaded: status = .pending
        case .rejected, .requiresResubmission: status = .rejected
        }
        return ManagerDocument(
            id: item.id,
            name: item.name,
            type: item.category.rawValue,
            status: status
        )
    }
}
