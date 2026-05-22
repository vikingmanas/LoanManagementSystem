import SwiftUI
import Combine

// MARK: - Manager Dashboard ViewModel
@MainActor
final class ManagerDashboardViewModel: ObservableObject {

    // MARK: - Tab State
    @Published var selectedTab: Int = 0

    // MARK: - Loading
    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false

    // MARK: - Data
    @Published var applicants: [ManagerApplicant] = []
    @Published var officers: [ManagerOfficer] = []
    @Published var kpis: [ManagerKPI] = []
    @Published var notifications: [ManagerNotificationItem] = []
    @Published var conversations: [ManagerChatConversation] = []
    @Published var branchOverview: BranchOverview = ManagerMockData.branchOverview
    @Published var auditEvents: [ManagerAuditEvent] = []

    // MARK: - Filters (Applicants Tab)
    @Published var applicantSearchQuery: String = ""
    @Published var selectedStatusFilter: ManagerApplicantStatus? = nil
    @Published var selectedOfficerFilter: UUID? = nil
    @Published var selectedRiskFilter: ManagerRiskLevel? = nil
    @Published var selectedLoanTypeFilter: ManagerLoanType? = nil
    @Published var applicantSortOrder: ApplicantSortOrder = .dateDesc

    enum ApplicantSortOrder: String, CaseIterable {
        case dateDesc = "Newest First"
        case dateAsc = "Oldest First"
        case amountDesc = "Highest Amount"
        case amountAsc = "Lowest Amount"
        case riskDesc = "Highest Risk"
    }

    // MARK: - Communication
    @Published var chatSearchQuery: String = ""
    @Published var selectedChatFilter: ChatFilterMode = .all

    enum ChatFilterMode: String, CaseIterable {
        case all = "All"
        case escalations = "Escalations"
        case announcements = "Announcements"
    }

    // MARK: - Computed Properties

    var unreadNotificationCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    var unreadChatCount: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }

    var pendingApplicants: [ManagerApplicant] {
        applicants.filter { $0.status == .sentToManager || $0.status == .needsClarification }
    }

    var filteredApplicants: [ManagerApplicant] {
        var result = applicants

        // Status filter
        if let status = selectedStatusFilter {
            result = result.filter { $0.status == status }
        }

        // Officer filter
        if let officerId = selectedOfficerFilter {
            result = result.filter { $0.assignedOfficerId == officerId }
        }

        // Risk filter
        if let risk = selectedRiskFilter {
            result = result.filter { $0.riskLevel == risk }
        }

        // Loan type filter
        if let loanType = selectedLoanTypeFilter {
            result = result.filter { $0.loanType == loanType }
        }

        // Search
        let query = applicantSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter {
                $0.borrowerName.localizedCaseInsensitiveContains(query) ||
                $0.applicationId.localizedCaseInsensitiveContains(query) ||
                $0.assignedOfficer.localizedCaseInsensitiveContains(query)
            }
        }

        // Sort
        switch applicantSortOrder {
        case .dateDesc:
            result.sort { $0.submissionDate > $1.submissionDate }
        case .dateAsc:
            result.sort { $0.submissionDate < $1.submissionDate }
        case .amountDesc:
            result.sort { $0.requestedAmount > $1.requestedAmount }
        case .amountAsc:
            result.sort { $0.requestedAmount < $1.requestedAmount }
        case .riskDesc:
            let order: [ManagerRiskLevel] = [.critical, .high, .medium, .low]
            result.sort { order.firstIndex(of: $0.riskLevel)! < order.firstIndex(of: $1.riskLevel)! }
        }

        return result
    }

    var filteredConversations: [ManagerChatConversation] {
        var result = conversations

        let query = chatSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter {
                $0.officerName.localizedCaseInsensitiveContains(query) ||
                $0.lastMessage.localizedCaseInsensitiveContains(query)
            }
        }

        switch selectedChatFilter {
        case .all:
            break
        case .escalations:
            result = result.filter { $0.priority == .urgent }
        case .announcements:
            // placeholder — no announcements filter yet
            break
        }

        // Pinned first, then by timestamp
        result.sort { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
            return lhs.timestamp > rhs.timestamp
        }

        return result
    }

    // MARK: - Data Fetching

    func fetchDashboardData() async {
        isLoading = true
        // Simulate API call
        try? await Task.sleep(nanoseconds: 600_000_000)

        applicants = ManagerMockData.applicants
        officers = ManagerMockData.officers
        kpis = ManagerMockData.kpis
        notifications = ManagerMockData.notifications
        conversations = ManagerMockData.conversations
        branchOverview = ManagerMockData.branchOverview

        isLoading = false
    }

    func refreshData() async {
        isRefreshing = true
        try? await Task.sleep(nanoseconds: 400_000_000)
        isRefreshing = false
    }

    // MARK: - Applicant Actions

    func approveApplicant(_ id: UUID, remarks: String) {
        guard let index = applicants.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            applicants[index].status = .approved
            applicants[index].managerRemarks = remarks.isEmpty ? "Approved by Branch Manager." : remarks
        }
        HapticsManager.triggerNotification(type: .success)
    }

    func rejectApplicant(_ id: UUID, remarks: String) {
        guard let index = applicants.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            applicants[index].status = .rejected
            applicants[index].managerRemarks = remarks.isEmpty ? "Rejected by Branch Manager." : remarks
        }
        HapticsManager.triggerNotification(type: .error)
    }

    func sendBackApplicant(_ id: UUID, remarks: String) {
        guard let index = applicants.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            applicants[index].status = .needsClarification
            applicants[index].managerRemarks = remarks
        }
        HapticsManager.triggerImpact(style: .medium)
    }

    func escalateApplicant(_ id: UUID) {
        guard let index = applicants.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            applicants[index].status = .escalated
            applicants[index].managerRemarks = "Escalated to Admin for review."
        }
        HapticsManager.triggerNotification(type: .warning)
    }

    func reassignApplicant(_ id: UUID, to officerId: UUID) {
        guard let index = applicants.firstIndex(where: { $0.id == id }),
              let officer = officers.first(where: { $0.id == officerId }) else { return }
        withAnimation {
            applicants[index].assignedOfficerId = officerId
            applicants[index].assignedOfficer = officer.name
        }
        HapticsManager.triggerImpact(style: .medium)
    }

    // MARK: - Notification Actions

    func markNotificationRead(_ id: UUID) {
        guard let index = notifications.firstIndex(where: { $0.id == id }) else { return }
        withAnimation {
            notifications[index].isRead = true
        }
    }

    func markAllNotificationsRead() {
        withAnimation {
            for i in notifications.indices {
                notifications[i].isRead = true
            }
        }
    }

    // MARK: - Chat Actions

    func sendMessage(_ text: String, toConversation conversationId: UUID) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationId }),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        let message = ManagerChatMessage(
            id: UUID(),
            senderName: ManagerMockData.managerName,
            text: text,
            timestamp: Date(),
            isFromManager: true,
            isSystemMessage: false
        )

        conversations[index].messages.append(message)
        conversations[index].lastMessage = text
        conversations[index].timestamp = Date()

        HapticsManager.triggerImpact(style: .light)

        // Simulate officer reply
        let convIdx = index
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            let reply = ManagerChatMessage(
                id: UUID(),
                senderName: self.conversations[convIdx].officerName,
                text: "Noted, sir. I'll take care of it right away.",
                timestamp: Date(),
                isFromManager: false,
                isSystemMessage: false
            )
            self.conversations[convIdx].messages.append(reply)
            self.conversations[convIdx].lastMessage = reply.text
            self.conversations[convIdx].timestamp = Date()
            HapticsManager.triggerImpact(style: .light)
        }
    }

    func markConversationRead(_ conversationId: UUID) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationId }) else { return }
        conversations[index].unreadCount = 0
    }

    // MARK: - Navigate to Applicants Tab with Filter

    func navigateToApplicantsWithPending() {
        selectedStatusFilter = .sentToManager
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            selectedTab = 1
        }
    }

    func clearAllFilters() {
        applicantSearchQuery = ""
        selectedStatusFilter = nil
        selectedOfficerFilter = nil
        selectedRiskFilter = nil
        selectedLoanTypeFilter = nil
        applicantSortOrder = .dateDesc
    }
}
