import SwiftUI
import Combine

@MainActor
final class ManagerDashboardViewModel: ObservableObject {
    @Published var selectedTab: Int = 0

    @Published var isLoading: Bool = false
    @Published var isRefreshing: Bool = false

    @Published var applicants: [ManagerApplicant] = []
    @Published var officers: [ManagerOfficer] = []
    @Published var notifications: [ManagerNotificationItem] = []
    @Published var conversations: [ManagerChatConversation] = []
    @Published var branchOverview: BranchOverview = BranchOverview(
        name: "Assigned Branch",
        code: "BR",
        region: "Regional Office",
        staffCount: 0,
        activeLoanCount: 0,
        totalDisbursed: 0,
        totalRecovered: 0,
        nplRate: 0,
        auditRating: "Pending",
        monthlyTarget: 0
    )
    @Published var auditEvents: [ManagerAuditEvent] = []
    @Published var managerProfile: ManagerStaffProfile = .empty
    @Published var lastReportPublishedAt: Date?

    @Published var applicantSearchQuery: String = ""
    @Published var selectedStatusFilter: ManagerApplicantStatus? = nil
    @Published var selectedOfficerFilter: UUID? = nil
    @Published var selectedRiskFilter: ManagerRiskLevel? = nil
    @Published var selectedLoanTypeFilter: ManagerLoanType? = nil
    @Published var applicantSortOrder: ApplicantSortOrder = .dateDesc

    @Published var chatSearchQuery: String = ""
    @Published var selectedChatFilter: ChatFilterMode = .all

    private var cancellables = Set<AnyCancellable>()
    private var currentManagerUserId: UUID?
    private var databaseMessages: [DBMessage] = []
    private var allApplicants: [ManagerApplicant] = []

    enum ApplicantSortOrder: String, CaseIterable {
        case dateDesc = "Newest First"
        case dateAsc = "Oldest First"
        case amountDesc = "Highest Amount"
        case amountAsc = "Lowest Amount"
        case riskDesc = "Highest Risk"
    }

    enum ChatFilterMode: String, CaseIterable {
        case all = "All"
        case escalations = "Escalations"
        case announcements = "Announcements"
    }

    init() {
        CentralLoanRepository.shared.$applications
            .map { apps in
                apps.compactMap { CentralLoanRepository.shared.toManagerApplicant(from: $0) }
            }
            .sink { [weak self] mappedApplicants in
                guard let self else { return }
                self.allApplicants = mappedApplicants
                self.filterApplicantsByManagerBranch()
            }
            .store(in: &cancellables)
    }

    func filterApplicantsByManagerBranch() {
        let managerBranch = managerProfile.branchName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if managerBranch.isEmpty || managerBranch == "assigned branch" {
            self.applicants = allApplicants
        } else {
            self.applicants = allApplicants.filter { applicant in
                let applicantBranch = applicant.branchName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                return applicantBranch == managerBranch || applicantBranch.contains(managerBranch) || managerBranch.contains(applicantBranch)
            }
        }
        self.rebuildDerivedDashboardState()
    }

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

        if let status = selectedStatusFilter {
            result = result.filter { $0.status == status }
        }

        if let officerId = selectedOfficerFilter {
            result = result.filter { $0.assignedOfficerId == officerId }
        }

        if let risk = selectedRiskFilter {
            result = result.filter { $0.riskLevel == risk }
        }

        if let loanType = selectedLoanTypeFilter {
            result = result.filter { $0.loanType == loanType }
        }

        let query = applicantSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter {
                $0.borrowerName.localizedCaseInsensitiveContains(query) ||
                $0.applicationId.localizedCaseInsensitiveContains(query) ||
                $0.assignedOfficer.localizedCaseInsensitiveContains(query)
            }
        }

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
            result = result.filter { $0.messages.contains(where: { $0.isSystemMessage }) }
        }

        result.sort { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned }
            return lhs.timestamp > rhs.timestamp
        }

        return result
    }

    func fetchDashboardData(authManager: AuthManager? = nil) async {
        isLoading = true

        await CentralLoanRepository.shared.fetchAllSubmittedApplicationsFromSupabase()

            if let authManager {
                configureProfileFromAuth(authManager)
                await loadStaffContext(userId: authManager.currentUser?.uid)
                await loadMessageThreads()
            } else {
                rebuildDerivedDashboardState()
            }

        isLoading = false
    }

    func refreshData() async {
        isRefreshing = true
        await CentralLoanRepository.shared.fetchAllSubmittedApplicationsFromSupabase()
        await loadMessageThreads()
        rebuildDerivedDashboardState()
        isRefreshing = false
    }

    @discardableResult
    func approveApplicant(_ id: UUID, remarks: String) -> Bool {
        guard CentralLoanRepository.shared.approveApplication(id: id, remarks: remarks) else {
            return false
        }
        appendAudit(action: "Approved \(applicationLabel(for: id))", severity: .success)
        appendNotification(
            title: "Loan approved and credited",
            message: "\(applicationLabel(for: id)) was approved by \(managerProfile.name). The sanctioned amount has been credited to the borrower account.",
            type: .success,
            relatedApplicantId: id
        )
        HapticsManager.triggerNotification(type: .success)
        return true
    }

    func rejectApplicant(_ id: UUID, remarks: String) {
        CentralLoanRepository.shared.rejectApplication(id: id, remarks: remarks)
        appendAudit(action: "Rejected \(applicationLabel(for: id))", severity: .critical)
        appendNotification(
            title: "Loan rejected",
            message: "\(applicationLabel(for: id)) was rejected after manager review.",
            type: .alert,
            relatedApplicantId: id
        )
        HapticsManager.triggerNotification(type: .error)
    }

    func sendBackApplicant(_ id: UUID, remarks: String) {
        CentralLoanRepository.shared.sendBackApplication(id: id, remarks: remarks)
        appendAudit(action: "Requested clarification on \(applicationLabel(for: id))", severity: .warning)
        appendNotification(
            title: "Clarification requested",
            message: remarks.isEmpty ? "The application was returned to the loan officer." : remarks,
            type: .warning,
            relatedApplicantId: id
        )
        HapticsManager.triggerImpact(style: .medium)
    }

    func escalateApplicant(_ id: UUID) {
        guard let index = applicants.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            applicants[index].status = .escalated
            applicants[index].managerRemarks = "Escalated for senior review."
        }
        appendAudit(action: "Escalated \(applicationLabel(for: id))", severity: .critical)
        HapticsManager.triggerNotification(type: .warning)
    }

    func reassignApplicant(_ id: UUID, to officerId: UUID) {
        guard let index = applicants.firstIndex(where: { $0.id == id }),
              let officer = officers.first(where: { $0.id == officerId }) else { return }
        withAnimation {
            applicants[index].assignedOfficerId = officerId
            applicants[index].assignedOfficer = officer.name
        }
        appendAudit(action: "Reassigned \(applicationLabel(for: id)) to \(officer.name)", severity: .info)
        HapticsManager.triggerImpact(style: .medium)
    }

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

    func sendMessage(_ text: String, toConversation conversationId: UUID) {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let index = conversations.firstIndex(where: { $0.id == conversationId }),
              !cleanText.isEmpty else { return }

        let messageId = UUID()
        let timestamp = Date()
        let message = ManagerChatMessage(
            id: messageId,
            senderName: managerProfile.name,
            text: cleanText,
            timestamp: timestamp,
            isFromManager: true,
            isSystemMessage: false
        )

        let receiverId = conversations[index].officerUserId
        conversations[index].messages.append(message)
        conversations[index].lastMessage = cleanText
        conversations[index].timestamp = timestamp
        appendAudit(action: "Messaged \(conversations[index].officerName)", severity: .info)

        HapticsManager.triggerImpact(style: .light)

        guard let senderId = currentManagerUserId else { return }
        Task {
            let dbMessage = DBMessage(
                messageId: messageId,
                senderId: senderId,
                receiverId: receiverId,
                applicationId: nil,
                content: cleanText,
                sentAt: timestamp,
                isRead: false
            )
            do {
                try await DatabaseService.shared.sendMessage(dbMessage)
                try? await DatabaseService.shared.createNotification(
                    userId: receiverId,
                    title: "New message from \(managerProfile.name)",
                    message: cleanText
                )
                databaseMessages.append(dbMessage)
                rebuildConversations()
            } catch {
                appendNotification(
                    title: "Message not synced",
                    message: "Could not save message for \(conversations[index].officerName).",
                    type: .warning,
                    relatedApplicantId: nil
                )
            }
        }
    }

    func broadcastAnnouncement(subject: String, message: String) {
        let cleanSubject = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanSubject.isEmpty, !cleanMessage.isEmpty else { return }

        let body = "\(cleanSubject): \(cleanMessage)"
        let timestamp = Date()

        let senderId = currentManagerUserId
        var outgoing: [(receiverId: UUID, message: DBMessage)] = []

        for index in conversations.indices {
            let messageId = UUID()
            let announcement = ManagerChatMessage(
                id: messageId,
                senderName: managerProfile.name,
                text: body,
                timestamp: timestamp,
                isFromManager: true,
                isSystemMessage: true
            )
            conversations[index].messages.append(announcement)
            conversations[index].lastMessage = cleanSubject
            conversations[index].timestamp = timestamp
            conversations[index].isPinned = true

            if let senderId {
                outgoing.append((
                    receiverId: conversations[index].officerUserId,
                    message: DBMessage(
                        messageId: messageId,
                        senderId: senderId,
                        receiverId: conversations[index].officerUserId,
                        applicationId: nil,
                        content: body,
                        sentAt: timestamp,
                        isRead: false
                    )
                ))
            }
        }

        appendAudit(action: "Broadcast announcement to \(officers.count) officers", severity: .info)
        appendNotification(
            title: "Broadcast sent",
            message: cleanSubject,
            type: .info,
            relatedApplicantId: nil
        )
        HapticsManager.triggerNotification(type: .success)

        Task {
            for item in outgoing {
                try? await DatabaseService.shared.sendMessage(item.message)
                try? await DatabaseService.shared.createNotification(
                    userId: item.receiverId,
                    title: cleanSubject,
                    message: cleanMessage
                )
                databaseMessages.append(item.message)
            }
            rebuildConversations()
        }
    }

    func markConversationRead(_ conversationId: UUID) {
        guard let index = conversations.firstIndex(where: { $0.id == conversationId }) else { return }
        let unreadMessageIds = conversations[index].messages
            .filter { !$0.isFromManager }
            .map(\.id)
        conversations[index].unreadCount = 0

        guard !unreadMessageIds.isEmpty else { return }
        Task {
            try? await DatabaseService.shared.markMessagesRead(messageIds: unreadMessageIds)
            let ids = Set(unreadMessageIds)
            databaseMessages = databaseMessages.map { message in
                guard ids.contains(message.messageId) else { return message }
                return DBMessage(
                    messageId: message.messageId,
                    senderId: message.senderId,
                    receiverId: message.receiverId,
                    applicationId: message.applicationId,
                    content: message.content,
                    sentAt: message.sentAt,
                    isRead: true
                )
            }
            rebuildConversations()
        }
    }

    func publishMonthlyReport() {
        lastReportPublishedAt = Date()
        appendAudit(action: "Published monthly branch performance report", severity: .info)
        appendNotification(
            title: "Monthly report published",
            message: "Branch performance report is available for \(branchOverview.name).",
            type: .info,
            relatedApplicantId: nil
        )
        HapticsManager.triggerNotification(type: .success)
    }

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

    private func configureProfileFromAuth(_ authManager: AuthManager) {
        managerProfile.name = authManager.userDisplayName
        managerProfile.email = authManager.userEmail ?? ""
        if let uid = authManager.currentUser?.uid {
            currentManagerUserId = UUID(uuidString: uid)
        }
    }

    private func loadStaffContext(userId: String?) async {
        guard let staff = try? await AdminStaffService.shared.fetchStaffMembers() else {
            rebuildDerivedDashboardState()
            return
        }

        if let userId, let uuid = UUID(uuidString: userId),
           let manager = staff.first(where: { $0.id == uuid && $0.role == .bankManager }) {
            currentManagerUserId = uuid
            managerProfile = ManagerStaffProfile(
                name: manager.fullName,
                email: manager.email,
                phone: manager.phoneNumber,
                employeeCode: manager.employeeCode,
                branchName: manager.branchName ?? "Assigned Branch",
                branchCode: manager.employeeCode,
                region: manager.region ?? "Regional Office",
                roleTitle: manager.role.displayName,
                joinedAt: manager.createdAt
            )
        }

        let managerBranchId = staff.first(where: { $0.email == managerProfile.email && $0.role == .bankManager })?.branchId
        let branchOfficers = staff.filter { member in
            member.role == .loanOfficer && (managerBranchId == nil || member.branchId == managerBranchId)
        }

        officers = branchOfficers.map { member in
            let assignedCases = applicants.filter { $0.assignedOfficer.localizedCaseInsensitiveContains(member.fullName) }.count
            let completedCases = applicants.filter {
                $0.assignedOfficer.localizedCaseInsensitiveContains(member.fullName) &&
                ($0.status == .approved || $0.status == .disbursed)
            }.count
            let processed = applicants.filter { $0.assignedOfficer.localizedCaseInsensitiveContains(member.fullName) }.count
            let approvalRate = processed == 0 ? 0 : (Double(completedCases) / Double(processed)) * 100

            return ManagerOfficer(
                id: member.id,
                name: member.fullName,
                role: member.designation ?? member.role.displayName,
                activeCases: assignedCases,
                maxCapacity: 15,
                rating: processed == 0 ? 0 : min(5, 3.5 + approvalRate / 100),
                performance: processed == 0 ? 0 : min(1, approvalRate / 100),
                loansProcessedYTD: processed,
                approvalRate: approvalRate
            )
        }

        self.filterApplicantsByManagerBranch()
    }

    private func loadMessageThreads() async {
        guard let currentManagerUserId else { return }
        do {
            databaseMessages = try await DatabaseService.shared.fetchMessages(for: currentManagerUserId)
            rebuildConversations()
        } catch {
            appendNotification(
                title: "Messages unavailable",
                message: "Could not load branch conversations.",
                type: .warning,
                relatedApplicantId: nil
            )
        }
    }

    private func rebuildDerivedDashboardState(keepStaff: Bool = false) {
        if !keepStaff {
            rebuildOfficersFromApplicants()
        }
        rebuildBranchOverview()
        rebuildNotifications()
        rebuildConversations()
        rebuildAuditEvents()
    }

    private func rebuildOfficersFromApplicants() {
        let grouped = Dictionary(grouping: applicants, by: \.assignedOfficer)
        officers = grouped.map { name, apps in
            let completed = apps.filter { $0.status == .approved || $0.status == .disbursed }.count
            let approvalRate = apps.isEmpty ? 0 : (Double(completed) / Double(apps.count)) * 100
            return ManagerOfficer(
                id: apps.first?.assignedOfficerId ?? stableId(for: name),
                name: name,
                role: "Loan Officer",
                activeCases: apps.filter { $0.status == .sentToManager || $0.status == .needsClarification }.count,
                maxCapacity: 15,
                rating: apps.isEmpty ? 0 : min(5, 3.5 + approvalRate / 100),
                performance: apps.isEmpty ? 0 : min(1, approvalRate / 100),
                loansProcessedYTD: apps.count,
                approvalRate: approvalRate
            )
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func rebuildBranchOverview() {
        let totalDisbursed = applicants
            .filter { $0.status == .disbursed || $0.status == .approved }
            .reduce(0) { $0 + $1.requestedAmount }
        let activeLoans = applicants.filter { $0.status != .rejected }.count

        branchOverview = BranchOverview(
            name: managerProfile.branchName,
            code: managerProfile.branchCode,
            region: managerProfile.region,
            staffCount: officers.count,
            activeLoanCount: activeLoans,
            totalDisbursed: totalDisbursed,
            totalRecovered: 0,
            nplRate: 0,
            auditRating: auditRating(for: applicants),
            monthlyTarget: max(totalDisbursed, applicants.reduce(0) { $0 + $1.requestedAmount } * 1.2)
        )
    }


    private func rebuildNotifications() {
        let generated = pendingApplicants.prefix(5).map { applicant in
            ManagerNotificationItem(
                id: stableId(for: "notification-\(applicant.id.uuidString)"),
                title: "Approval pending",
                message: "\(applicant.borrowerName)'s \(applicant.loanType.rawValue.lowercased()) is ready for manager decision.",
                timestamp: applicant.submissionDate,
                type: applicant.riskLevel == .high || applicant.riskLevel == .critical ? .warning : .info,
                isRead: notifications.first(where: { $0.relatedApplicantId == applicant.id })?.isRead ?? false,
                relatedApplicantId: applicant.id
            )
        }

        let manual = notifications.filter { $0.relatedApplicantId == nil }
        notifications = (manual + generated).sorted { $0.timestamp > $1.timestamp }
    }

    private func rebuildConversations() {
        let existing = Dictionary(uniqueKeysWithValues: conversations.map { ($0.id, $0) })
        conversations = officers.map { officer in
            let id = stableId(for: "conversation-\(officer.id.uuidString)")
            let threadMessages = databaseMessages
                .filter { message in
                    guard let currentManagerUserId else { return false }
                    return (message.senderId == currentManagerUserId && message.receiverId == officer.id) ||
                           (message.senderId == officer.id && message.receiverId == currentManagerUserId)
                }
                .sorted { $0.sentAt < $1.sentAt }
            let mappedMessages = threadMessages.map { message in
                let fromManager = message.senderId == currentManagerUserId
                return ManagerChatMessage(
                    id: message.messageId,
                    senderName: fromManager ? managerProfile.name : officer.name,
                    text: message.content,
                    timestamp: message.sentAt,
                    isFromManager: fromManager,
                    isSystemMessage: message.applicationId == nil && message.content.contains(":")
                )
            }
            let unreadCount = threadMessages.filter { $0.receiverId == currentManagerUserId && !$0.isRead }.count
            let latest = mappedMessages.last
            let priority: ManagerChatConversation.ChatPriority = unreadCount >= 3 ? .urgent : (officer.activeCases > 10 || unreadCount > 0 ? .high : .normal)

            if let conversation = existing[id] {
                var updated = conversation
                updated.officerUserId = officer.id
                updated.officerName = officer.name
                updated.officerInitials = officer.initials
                updated.officerRole = officer.role
                updated.messages = mappedMessages.isEmpty ? conversation.messages : mappedMessages
                updated.lastMessage = latest?.text ?? conversation.lastMessage
                updated.timestamp = latest?.timestamp ?? conversation.timestamp
                updated.unreadCount = unreadCount
                updated.priority = priority
                return updated
            }
            return ManagerChatConversation(
                id: id,
                officerUserId: officer.id,
                officerName: officer.name,
                officerInitials: officer.initials,
                officerRole: officer.role,
                lastMessage: latest?.text ?? "No messages yet",
                timestamp: latest?.timestamp ?? Date.distantPast,
                unreadCount: unreadCount,
                isPinned: officer.activeCases > 0,
                priority: priority,
                messages: mappedMessages
            )
        }
    }

    private func rebuildAuditEvents() {
        let derived = applicants.flatMap { applicant -> [ManagerAuditEvent] in
            applicant.documents.compactMap { document in
                guard document.status == .rejected || document.status == .reUploaded else { return nil }
                return ManagerAuditEvent(
                    id: stableId(for: "audit-\(applicant.id.uuidString)-\(document.id.uuidString)-\(document.status.rawValue)"),
                    timestamp: applicant.submissionDate,
                    action: "\(document.name) marked \(document.status.rawValue.lowercased()) for \(applicant.applicationId)",
                    user: applicant.assignedOfficer,
                    severity: document.status == .rejected ? .warning : .info
                )
            }
        }

        let manual = auditEvents.filter { $0.user == managerProfile.name }
        auditEvents = (manual + derived).sorted { $0.timestamp > $1.timestamp }
    }

    private func appendAudit(action: String, severity: ManagerAuditEvent.Severity) {
        auditEvents.insert(
            ManagerAuditEvent(
                id: UUID(),
                timestamp: Date(),
                action: action,
                user: managerProfile.name,
                severity: severity
            ),
            at: 0
        )
    }

    private func appendNotification(title: String, message: String, type: ManagerNotificationItem.NotifType, relatedApplicantId: UUID?) {
        notifications.insert(
            ManagerNotificationItem(
                id: UUID(),
                title: title,
                message: message,
                timestamp: Date(),
                type: type,
                isRead: false,
                relatedApplicantId: relatedApplicantId
            ),
            at: 0
        )
    }

    private func applicationLabel(for id: UUID) -> String {
        guard let applicant = applicants.first(where: { $0.id == id }) else { return "application" }
        return "\(applicant.applicationId) (\(applicant.borrowerName))"
    }

    private func auditRating(for applicants: [ManagerApplicant]) -> String {
        guard !applicants.isEmpty else { return "Pending" }
        let highRiskShare = Double(applicants.filter { $0.riskLevel == .high || $0.riskLevel == .critical }.count) / Double(applicants.count)
        if highRiskShare < 0.10 { return "A" }
        if highRiskShare < 0.25 { return "B" }
        return "Review"
    }

    private func stableId(for value: String) -> UUID {
        var hash: UInt64 = 14_695_981_039_346_656_037
        for byte in value.utf8 {
            hash ^= UInt64(byte)
            hash &*= 1_099_511_628_211
        }
        let hex = String(format: "00000000-0000-0000-0000-%012llx", hash & 0x0000_FFFF_FFFF_FFFF)
        return UUID(uuidString: hex) ?? UUID()
    }
}
