import Foundation
import Combine
import SwiftUI
import Supabase
import Auth
import OSLog

/// Centralized repository serving as the single source of truth for all loan applications.
/// Bridges real-time state updates across the Customer, Loan Officer, and Manager portals.
@MainActor
final class CentralLoanRepository: ObservableObject {
    static let shared = CentralLoanRepository()
    private let logger = Logger(subsystem: "galgotias.in.akash", category: "CentralLoanRepository")
    
    struct BorrowerRow: Codable {
        let borrowerId: UUID
    }
    
    @Published var applications: [BorrowerLoanApplication] = []
    
    private init() {
        Task {
            var userIdString = SupabaseManager.shared.client.auth.currentSession?.user.id.uuidString
            
            if userIdString == nil {
                userIdString = await MainActor.run {
                    BorrowerProfileStore.shared.profile?.id
                }
            }
            
            if userIdString == nil {
                userIdString = "C-109482"
            }
            
            guard let userIdRaw = userIdString else { return }
            
            var userId = userIdRaw
            if UUID(uuidString: userIdRaw) == nil {
                let cleaned = userIdRaw.filter { $0.isHexDigit || $0.isNumber }
                let padded = (cleaned + "00000000000000000000000000000000").prefix(32)
                let part1 = padded.prefix(8)
                let part2 = padded.dropFirst(8).prefix(4)
                let part3 = padded.dropFirst(12).prefix(4)
                let part4 = padded.dropFirst(16).prefix(4)
                let part5 = padded.dropFirst(20).prefix(12)
                
                userId = "\(part1)-\(part2)-\(part3)-\(part4)-\(part5)"
            }
            
            if let userUUID = UUID(uuidString: userId) {
                var resolvedBorrowerId = userUUID
                
                // Ensure borrower record exists in Supabase
                do {
                    let rows: [BorrowerRow] = try await SupabaseManager.shared.client
                        .from("borrowers")
                        .select("borrower_id")
                        .eq("user_id", value: userId)
                        .execute()
                        .value
                    
                    if let firstRow = rows.first {
                        resolvedBorrowerId = firstRow.borrowerId
                    } else {
                        print("CentralLoanRepository WARNING: No borrower record found for user_id: \(userId). Syncing...")
                        let newBorrower: [String: String] = [
                            "borrower_id": userId, // Defaulting borrower_id to user_id for simplicity on missing
                            "user_id": userId,
                            "kyc_status": "pending",
                            "address": "",
                            "date_of_birth": "1990-01-01",
                            "pan_number": "PENDING123",
                            "aadhaar_number": "000000000000"
                        ]
                        try? await SupabaseManager.shared.client
                            .from("borrowers")
                            .insert(newBorrower)
                            .execute()
                    }
                } catch {
                    print("CentralLoanRepository: Failed to query/sync borrowers table on start: \(error.localizedDescription)")
                }
                
                await fetchApplicationsFromSupabase(borrowerId: resolvedBorrowerId)
            }
        }
    }
    
    // MARK: - Core Operations
    
    /// Dynamically loads borrower applications from Supabase and populates the local state.
    func fetchApplicationsFromSupabase(borrowerId: UUID) async {
        var resolvedId = borrowerId
        
        // Try to resolve user_id to actual borrower_id
        do {
            let rows: [BorrowerRow] = try await SupabaseManager.shared.client
                .from("borrowers")
                .select("borrower_id")
                .eq("user_id", value: borrowerId.uuidString)
                .execute()
                .value
            
            if let firstRow = rows.first {
                resolvedId = firstRow.borrowerId
                logger.info("CentralLoanRepository: Resolved fetch borrower_id to true database ID: \(resolvedId.uuidString)")
            }
        } catch {
            logger.error("CentralLoanRepository: Error resolving borrower_id for fetch: \(error.localizedDescription)")
        }
        
        do {
            let dbApps = try await ApplicationService.shared.fetchApplications(borrowerId: resolvedId)
            
            var loadedApps: [BorrowerLoanApplication] = []
            for dbApp in dbApps {
                let matchingProduct = BorrowerLoanProduct.sampleProducts.first(where: { $0.id == dbApp.productId })
                    ?? BorrowerLoanProduct.sampleProducts.first!
                
                let app = dbApp.toBorrowerApplication(product: matchingProduct)
                loadedApps.append(app)
            }
            
            self.applications = loadedApps
            logger.info("CentralLoanRepository: Loaded \(loadedApps.count) applications from Supabase.")
        } catch {
            logger.error("CentralLoanRepository: Error fetching from Supabase: \(error.localizedDescription)")
        }
    }
    
    func submitApplication(_ app: BorrowerLoanApplication) {
        if let index = applications.firstIndex(where: { $0.id == app.id }) {
            applications[index] = app
        } else {
            applications.insert(app, at: 0)
        }
        persistApplicationToSupabase(app)
    }
    
    func updateApplication(_ app: BorrowerLoanApplication) {
        if let index = applications.firstIndex(where: { $0.id == app.id }) {
            applications[index] = app
        }
        persistApplicationToSupabase(app)
    }
    
    private func persistApplicationToSupabase(_ app: BorrowerLoanApplication) {
        Task {
            var userIdString = SupabaseManager.shared.client.auth.currentSession?.user.id.uuidString
            
            if userIdString == nil {
                userIdString = await MainActor.run {
                    BorrowerProfileStore.shared.profile?.id
                }
            }
            
            if userIdString == nil {
                userIdString = "C-109482"
                logger.info("CentralLoanRepository: Both auth and profile were nil, falling back to default mock ID: C-109482")
            }
            
            guard let userIdRaw = userIdString else {
                logger.error("CentralLoanRepository: Could not fetch logged in user ID to persist application (userIdString is nil)")
                return
            }
            
            var userId = userIdRaw
            if UUID(uuidString: userIdRaw) == nil {
                let cleaned = userIdRaw.filter { $0.isHexDigit || $0.isNumber }
                let padded = (cleaned + "00000000000000000000000000000000").prefix(32)
                let part1 = padded.prefix(8)
                let part2 = padded.dropFirst(8).prefix(4)
                let part3 = padded.dropFirst(12).prefix(4)
                let part4 = padded.dropFirst(16).prefix(4)
                let part5 = padded.dropFirst(20).prefix(12)
                
                userId = "\(part1)-\(part2)-\(part3)-\(part4)-\(part5)"
                logger.info("CentralLoanRepository: Standardized non-UUID '\(userIdRaw)' to stable UUID format: '\(userId)'")
            }
            
            guard let borrowerId = UUID(uuidString: userId) else {
                logger.error("CentralLoanRepository Error: Standardized UUID '\(userId)' was still invalid.")
                return
            }
            
            // Query borrowers table to resolve the real borrower_id (since borrower_id != user_id)
            
            var resolvedBorrowerId = borrowerId
            do {
                let rows: [BorrowerRow] = try await SupabaseManager.shared.client
                    .from("borrowers")
                    .select("borrower_id")
                    .eq("user_id", value: userId)
                    .execute()
                    .value
                
                if let firstRow = rows.first {
                    resolvedBorrowerId = firstRow.borrowerId
                    logger.info("CentralLoanRepository: Resolved real borrower_id: \(resolvedBorrowerId.uuidString) for user_id: \(userId)")
                } else {
                    logger.warning("CentralLoanRepository WARNING: No borrower record found for user_id: \(userId). Attempting sync...")
                    let newBorrower: [String: String] = [
                        "borrower_id": userId,
                        "user_id": userId,
                        "kyc_status": "pending",
                        "address": "",
                        "date_of_birth": "1990-01-01",
                        "pan_number": "PENDING123",
                        "aadhaar_number": "000000000000"
                    ]
                    try await SupabaseManager.shared.client
                        .from("borrowers")
                        .insert(newBorrower)
                        .execute()
                    
                    resolvedBorrowerId = borrowerId
                }
            } catch {
                logger.error("CentralLoanRepository: Failed to query borrowers table: \(error.localizedDescription)")
            }
            
            let dbApp = DBLoanApplication.from(borrowerApplication: app, borrowerId: resolvedBorrowerId)
            logger.info("CentralLoanRepository: Persisting app \(dbApp.applicationId) | borrower: \(dbApp.borrowerId) | product: \(dbApp.productId) | status: \(dbApp.status) | amount: \(dbApp.amountRequested)")
            do {
                try await ApplicationService.shared.upsertApplication(dbApp)
                logger.info("CentralLoanRepository: ✅ Successfully persisted application \(dbApp.applicationId) to Supabase.")
            } catch {
                logger.error("CentralLoanRepository Error: Failed to persist application to Supabase: \(String(describing: error))")
            }
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
            persistApplicationToSupabase(app)
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
        persistApplicationToSupabase(app)
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
        persistApplicationToSupabase(app)
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
        persistApplicationToSupabase(app)
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
        persistApplicationToSupabase(app)
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
            assignedOfficerId: UUID(),
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
            assignedOfficer: "Officer Arjun",
            assignedOfficerId: UUID(),
            submissionDate: app.submittedAt ?? Date(),
            documents: app.documents.map { mapToManagerDocument(from: $0) },
            officerRemarks: "All required KYC and income documents successfully verified. Profile is strong. Recommended for immediate approval.",
            managerRemarks: "",
            verificationProgress: 1.0,
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
