import Foundation
import Combine
import SwiftUI
import Supabase

struct LoanDisbursementEvent: Identifiable, Hashable {
    let id: UUID
    var applicationId: UUID
    var applicationNumber: String
    var borrowerEmail: String
    var borrowerName: String
    var amount: Double
    var accountNumber: String
    var referenceNumber: String
    var creditedAt: Date

    init(
        id: UUID = UUID(),
        applicationId: UUID,
        applicationNumber: String,
        borrowerEmail: String,
        borrowerName: String,
        amount: Double,
        accountNumber: String,
        referenceNumber: String,
        creditedAt: Date
    ) {
        self.id = id
        self.applicationId = applicationId
        self.applicationNumber = applicationNumber
        self.borrowerEmail = borrowerEmail
        self.borrowerName = borrowerName
        self.amount = amount
        self.accountNumber = accountNumber
        self.referenceNumber = referenceNumber
        self.creditedAt = creditedAt
    }
}

/// Centralized repository serving as the single source of truth for all loan applications.
/// Bridges real-time state updates across the Customer, Loan Officer, and Manager portals.
@MainActor
final class CentralLoanRepository: ObservableObject {
    static let shared = CentralLoanRepository()
    
    @Published var applications: [BorrowerLoanApplication] = []
    @Published var disbursementEvents: [LoanDisbursementEvent] = []
    @Published var borrowerNotifications: [LMSNotification] = []
    @Published var globalRules = GlobalLoanRules(minCibilScore: 700, maxDTI: 50.0, maxLTV: 80.0)
    
    private init() {
        loadPersistedState()
        
        // Load fallback rules from cache
        if let data = UserDefaults.standard.data(forKey: "GlobalLoanRules"),
           let savedRules = try? JSONDecoder().decode(GlobalLoanRules.self, from: data) {
            self.globalRules = savedRules
        }
        
        Task {
            await fetchGlobalRules()
        }
    }
    
    func fetchGlobalRules() async {
        do {
            let rules = try await AdminDashboardService.shared.fetchGlobalRules()
            self.globalRules = rules
            if let encoded = try? JSONEncoder().encode(rules) {
                UserDefaults.standard.set(encoded, forKey: "GlobalLoanRules")
            }
        } catch {
            print("[CentralLoanRepository] Failed to fetch global rules from Supabase: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Core Operations
    
    func submitApplication(_ app: BorrowerLoanApplication) {
        var updatedApp = app
        if updatedApp.borrowerId == nil, let uidString = resolveCurrentBorrowerUID(), let uid = UUID(uuidString: uidString) {
            updatedApp.borrowerId = uid
        }
        
        if let index = applications.firstIndex(where: { $0.id == updatedApp.id }) {
            applications[index] = updatedApp
        } else {
            applications.insert(updatedApp, at: 0)
        }
        persistState()
        syncApplicationToSupabase(updatedApp)
    }
    
    func updateApplication(_ app: BorrowerLoanApplication) {
        var updatedApp = app
        if updatedApp.borrowerId == nil, let uidString = resolveCurrentBorrowerUID(), let uid = UUID(uuidString: uidString) {
            updatedApp.borrowerId = uid
        }
        
        if let index = applications.firstIndex(where: { $0.id == updatedApp.id }) {
            applications[index] = updatedApp
            persistState()
            syncApplicationToSupabase(updatedApp)
        }
    }

    func deleteApplication(id: UUID) {
        applications.removeAll { $0.id == id }
        persistState()
        
        Task {
            do {
                try await ApplicationService.shared.deleteApplication(id: id)
                print("[CentralLoanRepository] Successfully deleted application \(id) from Supabase.")
            } catch {
                print("[CentralLoanRepository] Failed to delete application \(id) from Supabase: \(error.localizedDescription)")
            }
        }
    }
    
    private func mapToDocumentItem(from db: DBDocument) -> BorrowerLoanDocumentItem {
        let friendlyName: String
        let category: BorrowerDocumentCategory
        switch db.docType {
        case "identity_proof":
            friendlyName = "Identity Proof"
            category = .identityVerification
        case "address_proof":
            friendlyName = "Address Proof"
            category = .addressVerification
        case "income_proof":
            friendlyName = "Income Proof"
            category = .incomeVerification
        case "bank_statement":
            friendlyName = "Bank Statement"
            category = .loanSpecific
        case "property_document":
            friendlyName = "Property Documents"
            category = .loanSpecific
        default:
            friendlyName = db.fileName
            category = .identityVerification
        }

        let docStatus: BorrowerDocumentStatus
        switch db.status {
        case "uploaded": docStatus = .uploaded
        case "verified": docStatus = .verified
        case "rejected": docStatus = .rejected
        default: docStatus = .pendingUpload
        }

        return BorrowerLoanDocumentItem(
            id: db.documentId,
            name: friendlyName,
            category: category,
            status: docStatus,
            fileName: db.fileName,
            fileUrl: db.fileUrl,
            uploadDate: db.uploadedAt,
            lastUpdated: db.uploadedAt,
            isLocked: db.status == "verified"
        )
    }

    func fetchApplicationsFromSupabase(borrowerId: UUID) async {
        do {
            let products = await ProductService.shared.fetchLoanProducts()
            let dbApps = try await ApplicationService.shared.fetchApplications(borrowerId: borrowerId)
            
            var mappedApps: [BorrowerLoanApplication] = []
            for dbApp in dbApps {
                let product = products.first(where: { $0.id == dbApp.productId })
                    ?? BorrowerLoanProduct.sampleProducts.first(where: { $0.id == dbApp.productId })
                    ?? BorrowerLoanProduct.sampleProducts[0]
                
                var docs: [BorrowerLoanDocumentItem] = []
                if let dbDocs = try? await DatabaseService.shared.fetchDocuments(applicationId: dbApp.applicationId) {
                    docs = dbDocs.map { self.mapToDocumentItem(from: $0) }
                }
                
                let app = dbApp.toBorrowerApplication(product: product, documents: docs)
                mappedApps.append(app)
            }
            
            var hasChanges = false
            
            // Update existing applications if their values changed, or append new ones.
            for remoteApp in mappedApps {
                if let index = self.applications.firstIndex(where: { $0.id == remoteApp.id }) {
                    var mergedApp = remoteApp
                    // If documents list is empty on remote, fallback to local cache
                    if mergedApp.documents.isEmpty {
                        mergedApp.documents = self.applications[index].documents
                    }
                    if self.applications[index] != mergedApp {
                        self.applications[index] = mergedApp
                        hasChanges = true
                    }
                } else {
                    self.applications.append(remoteApp)
                    hasChanges = true
                }
            }
            
            // Remove local applications belonging to this borrower that are no longer present on Supabase.
            let remoteIds = Set(mappedApps.map { $0.id })
            let initialCount = self.applications.count
            self.applications.removeAll { localApp in
                if let localBorrowerId = localApp.borrowerId, localBorrowerId == borrowerId {
                    return !remoteIds.contains(localApp.id)
                }
                return false
            }
            if self.applications.count != initialCount {
                hasChanges = true
            }
            
            if hasChanges {
                self.persistState()
            }
            
            print("[CentralLoanRepository] Successfully fetched and synchronized \(mappedApps.count) applications from Supabase.")
        } catch {
            print("[CentralLoanRepository] Failed to fetch applications from Supabase: \(error.localizedDescription)")
        }
    }
    
    /// Fetches ALL submitted (non-draft) applications from Supabase for the Loan Officer dashboard.
    func fetchAllSubmittedApplicationsFromSupabase() async {
        do {
            let products = await ProductService.shared.fetchLoanProducts()
            let dbApps = try await ApplicationService.shared.fetchAllSubmittedApplications()
            
            var mappedApps: [BorrowerLoanApplication] = []
            for dbApp in dbApps {
                let product = products.first(where: { $0.id == dbApp.productId })
                    ?? BorrowerLoanProduct.sampleProducts.first(where: { $0.id == dbApp.productId })
                    ?? BorrowerLoanProduct.sampleProducts[0]
                
                var docs: [BorrowerLoanDocumentItem] = []
                if let dbDocs = try? await DatabaseService.shared.fetchDocuments(applicationId: dbApp.applicationId) {
                    docs = dbDocs.map { self.mapToDocumentItem(from: $0) }
                }
                
                let app = dbApp.toBorrowerApplication(product: product, documents: docs)
                mappedApps.append(app)
            }
            
            var hasChanges = false
            
            // Merge with existing local applications, updating any modified data.
            for remoteApp in mappedApps {
                if let index = self.applications.firstIndex(where: { $0.id == remoteApp.id }) {
                    var mergedApp = remoteApp
                    if mergedApp.documents.isEmpty {
                        mergedApp.documents = self.applications[index].documents
                    }
                    if self.applications[index] != mergedApp {
                        self.applications[index] = mergedApp
                        hasChanges = true
                    }
                } else {
                    self.applications.append(remoteApp)
                    hasChanges = true
                }
            }
            
            // Clean up any non-draft applications locally that are no longer returned in the submitted fetch.
            let remoteIds = Set(mappedApps.map { $0.id })
            let initialCount = self.applications.count
            self.applications.removeAll { localApp in
                // Only clean up if it's not a draft, meaning it was submitted/in process but is no longer present.
                if localApp.currentStage != .draft {
                    return !remoteIds.contains(localApp.id)
                }
                return false
            }
            if self.applications.count != initialCount {
                hasChanges = true
            }
            
            if hasChanges {
                self.persistState()
            }
            
            print("[CentralLoanRepository] Successfully fetched and synchronized \(mappedApps.count) submitted applications from Supabase for officer view.")
        } catch {
            print("[CentralLoanRepository] Failed to fetch all submitted applications: \(error.localizedDescription)")
        }
    }
    
    private func syncApplicationToSupabase(_ app: BorrowerLoanApplication) {
        // Prefer the application's existing borrower ID (so Officers/Managers don't overwrite it with their own ID)
        // Fallback to the current user's ID for new applications created by the borrower
        let resolvedUUID: UUID
        if let existingId = app.borrowerId {
            resolvedUUID = existingId
        } else if let uidString = resolveCurrentBorrowerUID(), let uid = UUID(uuidString: uidString) {
            resolvedUUID = uid
        } else {
            print("[CentralLoanRepository] Cannot sync to Supabase: no borrower ID could be resolved.")
            return
        }
        
        var syncedApp = app
        syncedApp.borrowerId = resolvedUUID
        
        let dbApp = DBLoanApplication.from(borrowerApplication: syncedApp, borrowerId: resolvedUUID)
        Task {
            do {
                try await ApplicationService.shared.upsertApplication(dbApp)
                print("[CentralLoanRepository] Successfully synced application \(app.displayIdentifier) to Supabase.")
            } catch {
                print("[CentralLoanRepository] Failed to sync application \(app.displayIdentifier) to Supabase: \(error.localizedDescription)")
            }
        }
    }
    
    /// Resolves the current authenticated user's UID for use as a fallback borrower_id.
    private nonisolated func resolveCurrentBorrowerUID() -> String? {
        // Access AuthManager on MainActor since it's @MainActor
        return MainActor.assumeIsolated {
            // Try to get the UID from AuthManager first
            if let uid = AuthManager.shared.currentUser?.uid {
                return uid
            }
            // Try to get the UID from the Supabase session directly
            if let uid = SupabaseManager.shared.client.auth.currentSession?.user.id.uuidString {
                return uid
            }
            return nil
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
            persistState()
            
            // Sync updated document to Supabase database
            let borrowerUUID = app.borrowerId ?? UUID()
            let docType: String
            switch app.documents[docIndex].category {
            case .identityVerification: docType = "identity_proof"
            case .addressVerification: docType = "address_proof"
            case .incomeVerification: docType = "income_proof"
            case .loanSpecific:
                let n = app.documents[docIndex].name.lowercased()
                if n.contains("statement") { docType = "bank_statement" }
                else if n.contains("property") || n.contains("land") || n.contains("tax") { docType = "property_document" }
                else { docType = "identity_proof" }
            }
            
            let statusString: String
            switch borrowerDocStatus {
            case .verified: statusString = "verified"
            case .rejected, .requiresResubmission: statusString = "rejected"
            default: statusString = "uploaded"
            }
            
            let verifierUUID = SupabaseManager.shared.client.auth.currentSession?.user.id
            
            let dbDoc = DBDocument(
                documentId: docId,
                borrowerId: borrowerUUID,
                applicationId: app.id,
                docType: docType,
                fileUrl: app.documents[docIndex].fileUrl ?? "",
                fileName: app.documents[docIndex].fileName ?? "",
                status: statusString,
                uploadedAt: app.documents[docIndex].uploadDate ?? Date(),
                verifiedBy: verifierUUID
            )
            
            Task {
                do {
                    try await DatabaseService.shared.upsertDocument(dbDoc)
                    print("[CentralLoanRepository] Synced document status review update (\(statusString)) to Supabase DB.")
                } catch {
                    print("[CentralLoanRepository] Failed to sync reviewed document to Supabase: \(error.localizedDescription)")
                }
            }
            
            syncApplicationToSupabase(app)
        }
    }
    
    func sendForFinalApproval(applicationId: String, officerName: String = "Officer") {
        guard let index = applications.firstIndex(where: { $0.applicationId == applicationId }) else { return }
        var app = applications[index]
        app.currentStage = .bankManagerReview
        app.updatedAt = Date()
        app.stageHistory.append(
            BorrowerStageEntry(
                stage: .bankManagerReview,
                timestamp: Date(),
                note: "Documents verified by \(officerName). Forwarded to Manager for final approval."
            )
        )
        applications[index] = app
        persistState()
        syncApplicationToSupabase(app)
    }
    
    @discardableResult
    func approveApplication(id: UUID, remarks: String) -> Bool {
        guard let index = applicationIndex(for: id) else { return false }
        var app = applications[index]
        guard app.currentStage == .bankManagerReview else { return false }

        let approvedAmount = app.formData.requestedAmountValue
        guard approvedAmount > 0 else { return false }

        let referenceNumber = "DISB\(Int.random(in: 100000...999999))"
        let trimmedRemarks = remarks.trimmingCharacters(in: .whitespacesAndNewlines)
        let approvalNote = trimmedRemarks.isEmpty ? "Approved by Branch Manager." : trimmedRemarks

        app.currentStage = .approved
        app.updatedAt = Date()
        app.stageHistory.append(
            BorrowerStageEntry(
                stage: .approved,
                timestamp: Date(),
                note: "\(approvalNote) Loan amount \(CurrencyFormatter.shared.format(approvedAmount)) credited to OD account. Ref: \(referenceNumber)."
            )
        )
        applications[index] = app

        let borrowerEmail = app.formData.emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let applicationNumber = app.applicationId ?? app.displayIdentifier
        let odAccountNumber = BorrowerProfileStore.shared.provisionODAccountForApprovedLoan(
            email: borrowerEmail,
            applicationId: app.id,
            applicationNumber: applicationNumber,
            borrowerName: app.formData.fullName,
            sanctionedAmount: approvedAmount
        ) ?? creditedAccountNumber(for: app)

        app.stageHistory[app.stageHistory.count - 1].note += " OD account \(maskedAccountNumber(odAccountNumber)) opened for EMI deductions."
        applications[index] = app

        let event = LoanDisbursementEvent(
            applicationId: app.id,
            applicationNumber: applicationNumber,
            borrowerEmail: borrowerEmail,
            borrowerName: app.formData.fullName,
            amount: approvedAmount,
            accountNumber: odAccountNumber,
            referenceNumber: referenceNumber,
            creditedAt: Date()
        )

        if !disbursementEvents.contains(where: { $0.applicationId == event.applicationId }) {
            disbursementEvents.insert(event, at: 0)
        }

        let resolvedBorrowerId = app.borrowerId ?? {
            if let profileStringId = BorrowerProfileStore.shared.borrowerProfile(matchingEmail: borrowerEmail)?.id {
                return UUID(uuidString: profileStringId)
            }
            return nil
        }()

        if let borrowerId = resolvedBorrowerId {
            let dbTx = DBTransaction(
                id: UUID(),
                title: "Loan Amount Credited - \(event.applicationNumber)",
                date: event.creditedAt,
                amount: approvedAmount,
                type: "credit",
                referenceNo: referenceNumber,
                bankAccountId: nil,
                borrowerId: borrowerId
            )
            
            let accountId = UUID()
            let rate = app.product.baseInterestRate > 0 ? Double(app.product.baseInterestRate) : 10.5
            let dbAccount = DBLoanAccount(
                accountId: accountId,
                applicationId: app.id,
                borrowerId: borrowerId,
                principalAmount: approvedAmount,
                outstandingBalance: approvedAmount,
                interestRate: rate,
                disbursementDate: Date(),
                closureDate: nil,
                status: "active",
                nextEmiDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
                createdAt: Date()
            )
            
            let p = approvedAmount
            let r = rate / 12.0 / 100.0
            let n = Double(max(1, app.formData.preferredTenureMonths))
            let emiAmount: Double
            if r > 0 {
                let factor = pow(1 + r, n)
                emiAmount = (p * r * factor) / (factor - 1)
            } else {
                emiAmount = p / n
            }
            
            var currentBalance = p
            var scheduleItems: [DBEMISchedule] = []
            for i in 1...Int(n) {
                let interestComponent = currentBalance * r
                let principalComponent = min(currentBalance, emiAmount - interestComponent)
                let dueDate = Calendar.current.date(byAdding: .month, value: i, to: Date()) ?? Date()
                
                let item = DBEMISchedule(
                    emiId: UUID(),
                    accountId: accountId,
                    instalmentNo: i,
                    dueDate: dueDate,
                    emiAmount: emiAmount,
                    principalComponent: principalComponent,
                    interestComponent: interestComponent,
                    status: "pending",
                    paidDate: nil,
                    paidAmount: nil,
                    createdAt: Date()
                )
                scheduleItems.append(item)
                currentBalance = max(0, currentBalance - principalComponent)
            }
            
            Task {
                do {
                    try await SupabaseManager.shared.client
                        .from("transactions")
                        .insert(dbTx)
                        .execute()
                    print("[CentralLoanRepository] Successfully saved disbursement transaction to Supabase.")
                    
                    try await DatabaseService.shared.insertLoanAccount(dbAccount)
                    try await DatabaseService.shared.insertEMISchedule(scheduleItems)
                    print("[CentralLoanRepository] Successfully created and synced loan account & EMI schedule to Supabase.")
                } catch {
                    print("[CentralLoanRepository] Failed to save disbursement resources to Supabase: \(error.localizedDescription)")
                }
            }
        }

        borrowerNotifications.insert(
            LMSNotification(
                title: "Loan Approved",
                body: "Your loan \(event.applicationNumber) is approved. \(CurrencyFormatter.shared.format(approvedAmount)) has been credited to OD account \(maskedAccountNumber(odAccountNumber)) for EMI deductions.",
                timestamp: event.creditedAt,
                icon: "checkmark.seal.fill",
                tint: LMSColors.emerald
            ),
            at: 0
        )

        persistState()
        syncApplicationToSupabase(app)
        return true
    }
    
    func rejectApplication(id: UUID, remarks: String) {
        guard let index = applicationIndex(for: id) else { return }
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
        persistState()
        syncApplicationToSupabase(app)
    }
    
    func sendBackApplication(id: UUID, remarks: String) {
        guard let index = applicationIndex(for: id) else { return }
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
        persistState()
        syncApplicationToSupabase(app)
    }
    
    // MARK: - Private Helpers

    private func applicationIndex(for id: UUID) -> Int? {
        if let index = applications.firstIndex(where: { $0.id == id }) {
            return index
        }
        return nil
    }
    
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

    private func creditedAccountNumber(for app: BorrowerLoanApplication) -> String {
        let email = app.formData.emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let profile = BorrowerProfileStore.shared.borrowerProfile(matchingEmail: email)
            ?? BorrowerProfileStore.shared.profile

        if let linkedAccount = profile?.linkedAccounts?.first {
            return linkedAccount.accountNumber
        }

        if let accountNumber = profile?.bankDetails.accountNumber,
           !accountNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return accountNumber
        }

        return "0000000000"
    }

    private func maskedAccountNumber(_ accountNumber: String) -> String {
        let suffix = String(accountNumber.suffix(4))
        return "•••• \(suffix.isEmpty ? "0000" : suffix)"
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
            riskLevel: app.formData.creditScoreValue >= 750 ? .low : (app.formData.creditScoreValue >= self.globalRules.minCibilScore ? .medium : .high),
            assignedOfficer: assignedOfficerName,
            assignedOfficerId: assignedOfficerId,
            submissionDate: app.submittedAt ?? Date(),
            documents: app.documents.map { mapToManagerDocument(from: $0) },
            officerRemarks: app.stageHistory.last(where: { $0.stage == .bankManagerReview })?.note ?? "Forwarded for manager approval after officer review.",
            managerRemarks: app.stageHistory.last(where: { $0.stage == .approved })?.note ?? "",
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

    private func loadPersistedState() {
        let restoredApplications = LoanApplicationPersistence.loadApplications()
        if !restoredApplications.isEmpty {
            applications = restoredApplications
        }
        let restoredDisbursements = LoanApplicationPersistence.loadDisbursements()
        if !restoredDisbursements.isEmpty {
            disbursementEvents = restoredDisbursements
        }
    }

    private func persistState() {
        LoanApplicationPersistence.saveApplications(applications)
        LoanApplicationPersistence.saveDisbursements(disbursementEvents)
    }

    func clearState() {
        self.applications = []
        self.disbursementEvents = []
        self.borrowerNotifications = []
        UserDefaults.standard.removeObject(forKey: "lms.centralLoanRepository.applications")
        UserDefaults.standard.removeObject(forKey: "lms.centralLoanRepository.disbursements")
    }
}
