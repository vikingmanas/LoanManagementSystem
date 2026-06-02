import SwiftUI
import Combine
import Supabase

enum HistorySortOrder: String, CaseIterable {
    case newest = "Newest"
    case oldest = "Oldest"
    case amountAsc = "Amount ↑"
    case amountDesc = "Amount ↓"
}

@MainActor
class LoanOfficerDashboardViewModel: ObservableObject {
    typealias LoanApplication = OfficerLoanApplication
    typealias LoanType = OfficerLoanType
    typealias ApplicationStatus = OfficerApplicationStatus
    typealias DocumentStatus = OfficerDocumentStatus
    typealias DocumentType = OfficerDocumentType
    @Published var applications: [LoanApplication] = []
    @Published var activityFeed: [ActivityFeedItem] = []
    @Published var applicationMessages: [UUID: [DBMessage]] = [:]
    @Published var officerProfile: StaffMember? = nil
    @Published var isLoading: Bool = true
    @Published var hasError: Bool = false
    @Published var selectedTab: Int = 0              // 0=Dashboard, 1=History
    
    private var cancellables = Set<AnyCancellable>()
    private var isFetchingDashboardData = false
    
    init() {
        refreshFromRepository()
    }
    
    // Tab 2 History Filter parameters
    @Published var historyFilter: RegistryFilter = .all
    @Published var historyLoanTypeFilter: LoanType? = nil
    @Published var historySortOrder: HistorySortOrder = .newest
    @Published var historySearchQuery: String = ""
    
    // Date Range filters for history
    @Published var historyStartDate: Date = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
    @Published var historyEndDate: Date = Date()
    
    // Notifications Count
    @Published var unreadActivityCount: Int = 0
    
    // MARK: - KPI Computed Properties
    var totalApplications: Int {
        applications.count
    }
    
    var pendingCount: Int {
        applications.filter { $0.status == .pending }.count
    }
    
    var approvedCount: Int {
        applications.filter { $0.status == .approved }.count
    }
    
    var rejectedOrHoldCount: Int {
        applications.filter { $0.status == .rejected || $0.status == .onHold }.count
    }
    
    var totalPortfolioValue: Double {
        applications.reduce(0) { $0 + $1.requestedAmount }
    }
    
    var underProcessValue: Double {
        applications
            .filter { $0.status == .underReview || $0.status == .pending }
            .reduce(0) { $0 + $1.requestedAmount }
    }
    
    var underProcessCount: Int {
        applications.filter { $0.status == .underReview || $0.status == .pending }.count
    }
    
    var closedThisMonthValue: Double {
        let monthStart = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        return applications
            .filter { ($0.status == .disbursed || $0.status == .approved) && $0.submittedDate >= monthStart }
            .reduce(0) { $0 + $1.requestedAmount }
    }
    
    var closedThisMonthCount: Int {
        let monthStart = Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
        return applications.filter {
            ($0.status == .disbursed || $0.status == .approved) && $0.submittedDate >= monthStart
        }.count
    }
    
    var sentToManagerApps: [LoanApplication] {
        applications
            .filter { $0.sentToManagerDate != nil }
            .sorted { ($0.sentToManagerDate ?? Date()) > ($1.sentToManagerDate ?? Date()) }
    }
    
    var pendingDocumentCount: Int {
        // Sum all documents that are pending, uploaded, under review, or re-uploaded across all apps
        applications.reduce(0) { count, app in
            count + app.documents.filter { $0.status != .verified }.count
        }
    }
    
    var documentQueueList: [DocumentQueueItem] {
        var items: [DocumentQueueItem] = []
        for app in applications {
            for doc in app.documents {
                // Use application's submittedDate as a fallback for pending uploads so they appear in the "Missing" filter
                let date = doc.uploadedDate ?? app.submittedDate
                items.append(DocumentQueueItem(
                    id: doc.id,
                    borrowerName: app.borrowerName,
                    docType: doc.docType,
                    status: doc.status,
                    submittedDate: date,
                    applicationId: app.applicationId,
                    fileURL: doc.fileURL
                ))
            }
        }
        
        return items.sorted { a, b in
            let aScore = priorityScore(for: a.status)
            let bScore = priorityScore(for: b.status)
            if aScore != bScore {
                return aScore > bScore
            }
            return a.submittedDate > b.submittedDate
        }
    }
    
    /// Documents uploaded today — officer review queue for the current day.
    var todayDocumentQueueList: [DocumentQueueItem] {
        documentQueueList.filter { Calendar.current.isDateInToday($0.submittedDate) }
    }
    
    var todayDocumentReviewCount: Int {
        todayDocumentQueueList.filter { $0.status == .uploaded || $0.status == .reUploaded || $0.status == .underReview }.count
    }
    
    private func priorityScore(for status: DocumentStatus) -> Int {
        switch status {
        case .reUploaded: return 5
        case .uploaded: return 4
        case .underReview: return 3
        case .pending: return 2
        case .rejectFlag: return 1
        case .verified: return 0
        }
    }
    
    // MARK: - Filtered List for Tab 2 (History)
    var filteredApplications: [LoanApplication] {
        var list = applications
        
        // 1. Filter by Status (Registry Category)
        list = list.filter { app in
            switch historyFilter {
            case .all:
                return true
            case .newCases:
                return [.pending, .applied].contains(app.status)
            case .underCheck:
                return [.underReview, .verificationCompleted, .documentsPending, .documentsRejected, .onHold].contains(app.status)
            case .approvalQueue:
                return [.sentToManager, .finalApprovalPending].contains(app.status) || app.sentToManagerDate != nil
            case .completed:
                return [.approved, .disbursed, .rejected].contains(app.status)
            }
        }
        
        // 2. Filter by Loan Type
        if let typeFilter = historyLoanTypeFilter {
            list = list.filter { $0.loanType == typeFilter }
        }
        
        // 3. Filter by Search Query (Name, ID, Branch, or Notes)
        let query = historySearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            list = list.filter {
                $0.borrowerName.lowercased().contains(query) ||
                $0.applicationId.lowercased().contains(query) ||
                $0.branch.lowercased().contains(query) ||
                $0.notes.lowercased().contains(query)
            }
        }
        
        // 4. Date Range Filter
        list = list.filter {
            $0.submittedDate >= historyStartDate && $0.submittedDate <= historyEndDate
        }
        
        // 5. Sorting
        switch historySortOrder {
        case .newest:
            list.sort { $0.submittedDate > $1.submittedDate }
        case .oldest:
            list.sort { $0.submittedDate < $1.submittedDate }
        case .amountAsc:
            list.sort { $0.requestedAmount < $1.requestedAmount }
        case .amountDesc:
            list.sort { $0.requestedAmount > $1.requestedAmount }
        }
        
        return list
    }
    
    // MARK: - Fetch Data
    func fetchDashboardData() async {
        guard !isFetchingDashboardData else { return }
        isFetchingDashboardData = true
        isLoading = true
        hasError = false
        defer { isFetchingDashboardData = false }
        
        do {
            if let user = try? await SupabaseManager.shared.client.auth.session.user {
                if let profile = try? await DatabaseService.shared.fetchLoanOfficerProfile(userId: user.id) {
                    self.officerProfile = profile
                }
            }
            
            // Fetch all submitted applications from Supabase for the officer view
            await CentralLoanRepository.shared.fetchAllSubmittedApplicationsFromSupabase()
            refreshFromRepository()
            await loadAssignedApplicationMessages()
            
            // Simulate brief loading delay for UI
            try await Task.sleep(nanoseconds: 400_000_000)
            
            // Starts empty to remove mock feed items
            self.activityFeed = []
            
            if let officerId = self.officerProfile?.id {
                if let dbMessages = try? await DatabaseService.shared.fetchMessages(for: officerId) {
                    var newActivityItems: [ActivityFeedItem] = []
                    let repoApps = CentralLoanRepository.shared.applications
                    for msg in dbMessages {
                        let matchedApp = repoApps.first(where: { $0.id == msg.applicationId })
                        let borrowerName = matchedApp?.formData.fullName.isEmpty == false ? matchedApp!.formData.fullName : "Borrower"
                        let appDisplayId = matchedApp?.applicationId ?? matchedApp?.displayIdentifier ?? "APP-\(msg.applicationId?.uuidString.prefix(6).uppercased() ?? "UNKNOWN")"
                        let loanType = matchedApp?.product.type.title ?? "Loan Clarification"
                        
                        let isRead = msg.receiverId == officerId ? msg.isRead : true
                        
                        let feedItem = ActivityFeedItem(
                            id: msg.messageId,
                            borrowerName: borrowerName,
                            applicationId: appDisplayId,
                            loanType: loanType,
                            eventType: .queryRaised,
                            eventDescription: msg.content,
                            timestamp: msg.sentAt,
                            isRead: isRead,
                            requiresAction: !isRead,
                            actionType: .replyQuery
                        )
                        newActivityItems.append(feedItem)
                    }
                    self.activityFeed = newActivityItems.sorted { $0.timestamp > $1.timestamp }
                }
            }
            
            updateUnreadCount()
            isLoading = false
        } catch {
            self.hasError = true
            self.isLoading = false
        }
    }

    func refreshFromRepository() {
        applications = CentralLoanRepository.shared.applications.compactMap { borrowerApplication in
            guard borrowerApplication.currentStage != .draft else { return nil }
            if let officerUserId = officerProfile?.id {
                guard borrowerApplication.assignedOfficer?.userId == officerUserId else { return nil }
            }
            return CentralLoanRepository.shared.toOfficerApplication(from: borrowerApplication)
        }
    }

    func loadAssignedApplicationMessages() async {
        var nextMessages: [UUID: [DBMessage]] = [:]
        for app in applications {
            do {
                nextMessages[app.id] = try await DatabaseService.shared.fetchMessagesForApplication(applicationId: app.id)
            } catch {
                nextMessages[app.id] = []
            }
        }
        applicationMessages = nextMessages
    }
    
    func updateUnreadCount() {
        self.unreadActivityCount = self.activityFeed.filter { !$0.isRead }.count
    }
    
    // MARK: - User Interactions
    func markActivityRead(_ id: UUID) {
        if let index = activityFeed.firstIndex(where: { $0.id == id }) {
            activityFeed[index].isRead = true
            updateUnreadCount()
        }
    }
    
    func markAllActivityRead() {
        for idx in 0..<activityFeed.count {
            activityFeed[idx].isRead = true
        }
        updateUnreadCount()
    }
    
    func dismissActivity(_ id: UUID) {
        activityFeed.removeAll(where: { $0.id == id })
        updateUnreadCount()
    }
    
    func performQuickAction(_ action: String) {
        HapticsManager.triggerImpact(style: .medium)
        print("Executing quick action: \(action)")
    }
    
    func updateDocumentStatus(applicationId: String, docId: UUID, newStatus: DocumentStatus, rejectionReason: String? = nil) {
        CentralLoanRepository.shared.updateDocumentStatus(applicationId: applicationId, docId: docId, status: newStatus, reason: rejectionReason)
        refreshFromRepository()
        
        if let idx = applications.firstIndex(where: { $0.applicationId == applicationId }),
           let doc = applications[idx].documents.first(where: { $0.id == docId }) {
            let docName = doc.docType.rawValue
            let officerName = officerProfile?.fullName ?? "Officer Arjun"
            logActivity(
                borrowerName: applications[idx].borrowerName,
                applicationId: applicationId,
                loanType: applications[idx].loanType.rawValue,
                eventType: newStatus == .verified ? .consentGiven : .queryRaised,
                description: newStatus == .verified ? "\(docName) verified successfully by \(officerName)." : "\(docName) rejected: \(rejectionReason ?? "Incorrect format.")"
            )
        }
    }

    func refreshDocuments(for applicationId: String) async {
        guard let app = applications.first(where: { $0.applicationId == applicationId }) else { return }
        await CentralLoanRepository.shared.refreshDocumentsForApplication(id: app.id)
        refreshFromRepository()
    }
    
    func updateApplicationStatus(applicationId: String, newStatus: ApplicationStatus) {
        if let idx = applications.firstIndex(where: { $0.applicationId == applicationId }) {
            applications[idx].status = newStatus
            applications[idx].lastUpdatedDate = Date()
            
            logActivity(
                borrowerName: applications[idx].borrowerName,
                applicationId: applicationId,
                loanType: applications[idx].loanType.rawValue,
                eventType: .profileUpdated,
                description: "Application status updated to \(newStatus.rawValue)."
            )
        }
    }
    
    func sendForFinalApproval(applicationId: String) {
        guard let app = applications.first(where: { $0.applicationId == applicationId }),
              !app.documents.isEmpty,
              app.documents.allSatisfy({ $0.status == .verified }) else {
            return
        }
        let officerName = officerProfile?.fullName ?? "Officer Arjun"
        CentralLoanRepository.shared.sendForFinalApproval(applicationId: applicationId, officerName: officerName)
        refreshFromRepository()
        if let idx = applications.firstIndex(where: { $0.applicationId == applicationId }) {
            logActivity(
                borrowerName: applications[idx].borrowerName,
                applicationId: applicationId,
                loanType: applications[idx].loanType.rawValue,
                eventType: .consentGiven,
                description: "Application verified & forwarded to Manager for final approval by \(officerName)."
            )
        }
    }

    var escalatableApplications: [LoanApplication] {
        applications.filter { app in
            ![.approved, .rejected, .disbursed, .escalated].contains(app.status)
        }
    }

    @discardableResult
    func escalateApplication(applicationId: String, reason: String) -> Bool {
        guard let app = applications.first(where: { $0.applicationId == applicationId }),
              let officerId = officerProfile?.id else { return false }
        let officerName = officerProfile?.fullName ?? "Loan Officer"
        let didEscalate = CentralLoanRepository.shared.escalateApplicationByOfficer(
            id: app.id,
            officerId: officerId,
            officerName: officerName,
            reason: reason
        )
        guard didEscalate else { return false }
        refreshFromRepository()
        logActivity(
            borrowerName: app.borrowerName,
            applicationId: applicationId,
            loanType: app.loanType.rawValue,
            eventType: .queryRaised,
            description: "Escalated to branch manager by \(officerName): \(reason)"
        )
        return true
    }
    
    func logActivity(borrowerName: String, applicationId: String, loanType: String, eventType: ActivityEventType, description: String) {
        let newFeed = ActivityFeedItem(
            id: UUID(),
            borrowerName: borrowerName,
            applicationId: applicationId,
            loanType: loanType,
            eventType: eventType,
            eventDescription: description,
            timestamp: Date(),
            isRead: false,
            requiresAction: false,
            actionType: nil
        )
        activityFeed.insert(newFeed, at: 0)
    }
    
    private func recomputeApplicationStatus(applicationId: String) {
        if let idx = applications.firstIndex(where: { $0.applicationId == applicationId }) {
            let docs = applications[idx].documents
            if docs.isEmpty { return }
            
            let hasRejected = docs.contains(where: { $0.status == .rejectFlag })
            let hasPending = docs.contains(where: { $0.status == .pending })
            let allVerified = docs.allSatisfy({ $0.status == .verified })
            
            if allVerified {
                applications[idx].status = .verificationCompleted
            } else if hasRejected {
                applications[idx].status = .documentsRejected
            } else if hasPending {
                applications[idx].status = .documentsPending
            } else {
                applications[idx].status = .underReview
            }
            applications[idx].lastUpdatedDate = Date()
        }
    }
}

// Wrapper for UI list handling
struct DocumentQueueItem: Identifiable, Hashable {
    typealias DocumentType = OfficerDocumentType
    typealias DocumentStatus = OfficerDocumentStatus
    let id: UUID
    var borrowerName: String
    var docType: DocumentType
    var status: DocumentStatus
    var submittedDate: Date
    var applicationId: String
    var fileURL: String?
}
