import SwiftUI
import Combine

enum HistorySortOrder: String, CaseIterable {
    case newest = "Newest"
    case oldest = "Oldest"
    case amountAsc = "Amount ↑"
    case amountDesc = "Amount ↓"
}

@MainActor
class LoanOfficerDashboardViewModel: ObservableObject {
    @Published var applications: [LoanApplication] = []
    @Published var activityFeed: [ActivityFeedItem] = []
    @Published var isLoading: Bool = true
    @Published var hasError: Bool = false
    @Published var selectedTab: Int = 0              // 0=Dashboard, 1=History
    
    // Tab 2 History Filter parameters
    @Published var historyFilter: ApplicationStatus? = nil
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
        // Mock closed value: disbursed or approved within last 30 days
        applications
            .filter { ($0.status == .disbursed || $0.status == .approved) }
            .reduce(0) { $0 + $1.requestedAmount * 0.4 } // Simulating monthly fraction
    }
    
    var closedThisMonthCount: Int {
        applications.filter { $0.status == .disbursed || $0.status == .approved }.count
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
                items.append(DocumentQueueItem(
                    id: doc.id,
                    borrowerName: app.borrowerName,
                    docType: doc.docType,
                    status: doc.status,
                    submittedDate: doc.uploadedDate ?? app.lastUpdatedDate,
                    applicationId: app.applicationId
                ))
            }
        }
        
        // Sort items by status priority: reUploaded/uploaded first, then underReview, then pending
        return items.sorted { a, b in
            let aScore = priorityScore(for: a.status)
            let bScore = priorityScore(for: b.status)
            if aScore != bScore {
                return aScore > bScore
            }
            return a.submittedDate > b.submittedDate
        }
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
        
        // 1. Filter by Status
        if let filter = historyFilter {
            list = list.filter { $0.status == filter }
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
        isLoading = true
        hasError = false
        
        // Simulate 1.5s network delay
        do {
            try await Task.sleep(nanoseconds: 1_500_000_000)
            
            // Set mock dataset
            self.applications = LoanOfficerMockData.createApplications()
            self.activityFeed = LoanOfficerMockData.createActivityFeed()
            
            updateUnreadCount()
            isLoading = false
        } catch {
            self.hasError = true
            self.isLoading = false
        }
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
        if let appIndex = applications.firstIndex(where: { $0.applicationId == applicationId }) {
            let app = applications[appIndex]
            if let docIndex = app.documents.firstIndex(where: { $0.id == docId }) {
                applications[appIndex].documents[docIndex].status = newStatus
                applications[appIndex].documents[docIndex].rejectionReason = rejectionReason
                
                // Add timeline activity log
                let docName = app.documents[docIndex].docType.rawValue
                let logMsg: String
                let logType: ActivityEventType
                
                switch newStatus {
                case .verified:
                    logMsg = "\(docName) verified successfully by Officer Arjun."
                    logType = .consentGiven
                case .rejectFlag:
                    logMsg = "\(docName) rejected: \(rejectionReason ?? "Incorrect format.")"
                    logType = .queryRaised
                case .pending:
                    logMsg = "\(docName) marked as missing. Correction requested."
                    logType = .queryRaised
                default:
                    logMsg = "\(docName) status updated to \(newStatus.rawValue)."
                    logType = .profileUpdated
                }
                
                logActivity(
                    borrowerName: app.borrowerName,
                    applicationId: app.applicationId,
                    loanType: app.loanType.rawValue,
                    eventType: logType,
                    description: logMsg
                )
                
                // Automatically recompute application status based on doc statuses
                recomputeApplicationStatus(applicationId: applicationId)
                updateUnreadCount()
            }
        }
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
        if let idx = applications.firstIndex(where: { $0.applicationId == applicationId }) {
            applications[idx].status = .finalApprovalPending
            applications[idx].managerStatus = .underReview
            applications[idx].sentToManagerDate = Date()
            applications[idx].lastUpdatedDate = Date()
            
            logActivity(
                borrowerName: applications[idx].borrowerName,
                applicationId: applicationId,
                loanType: applications[idx].loanType.rawValue,
                eventType: .consentGiven,
                description: "Application verified & forwarded to Manager for final approval."
            )
        }
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
    let id: UUID
    var borrowerName: String
    var docType: DocumentType
    var status: DocumentStatus
    var submittedDate: Date
    var applicationId: String
}
