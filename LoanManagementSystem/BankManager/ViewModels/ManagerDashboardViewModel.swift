import Observation
import SwiftUI
import Combine

@MainActor
@Observable
final class ManagerDashboardViewModel {
    var selectedTab: Int = 0

    var isLoading: Bool = false
    var isRefreshing: Bool = false

    var applicants: [ManagerApplicant] = []
    var officers: [ManagerOfficer] = []
    var notifications: [ManagerNotificationItem] = []
    var conversations: [ManagerChatConversation] = []
    var branchOverview: BranchOverview = BranchOverview(
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
    var auditEvents: [ManagerAuditEvent] = []
    var managerProfile: ManagerStaffProfile = .empty
    var lastReportPublishedAt: Date?
    var storedReports: [StoredManagerReport] = []
    var isGeneratingReports = false

    var applicantSearchQuery: String = ""
    var selectedStatusFilter: ManagerApplicantStatus? = nil
    var selectedOfficerFilter: UUID? = nil
    var selectedRiskFilter: ManagerRiskLevel? = nil
    var selectedLoanTypeFilter: ManagerLoanType? = nil
    var applicantSortOrder: ApplicantSortOrder = .dateDesc

    var chatSearchQuery: String = ""
    var selectedChatFilter: ChatFilterMode = .all

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

    var nonPerformingApplicants: [ManagerApplicant] {
        applicants.filter { isNonPerformingLoan($0) }
    }

    var officerEscalatedApplicants: [ManagerApplicant] {
        applicants.filter(isOfficerEscalation)
    }

    var officerPerformanceSummaries: [ManagerOfficerPerformanceSummary] {
        officers.map { officer in
            let escalations = officerEscalations(for: officer)
            return ManagerOfficerPerformanceSummary(
                officer: officer,
                escalations: escalations,
                managerRating: managerRating(for: officer.id),
                suggestedRating: suggestedRating(for: officer, escalationCount: escalations.count)
            )
        }
        .sorted { $0.officerEscalationCount > $1.officerEscalationCount }
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
            result.sort { 
                let index0 = order.firstIndex(of: $0.riskLevel) ?? order.count
                let index1 = order.firstIndex(of: $1.riskLevel) ?? order.count
                return index0 < index1 
            }
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
        self.allApplicants = CentralLoanRepository.shared.applications.compactMap { CentralLoanRepository.shared.toManagerApplicant(from: $0) }
        self.filterApplicantsByManagerBranch()

            if let authManager {
                configureProfileFromAuth(authManager)
                await loadStaffContext(userId: authManager.currentUser?.uid)
                await loadMessageThreads()
            } else {
                rebuildDerivedDashboardState()
            }

        isLoading = false

        Task {
            await generateDueReportsIfNeeded()
        }
    }

    func refreshData() async {
        isRefreshing = true

        await CentralLoanRepository.shared.fetchAllSubmittedApplicationsFromSupabase()
        self.allApplicants = CentralLoanRepository.shared.applications.compactMap { CentralLoanRepository.shared.toManagerApplicant(from: $0) }
        self.filterApplicantsByManagerBranch()
        if currentManagerUserId != nil {
            await loadStaffContext(userId: currentManagerUserId?.uuidString)
            await loadMessageThreads()
            rebuildDerivedDashboardState(keepStaff: !officers.isEmpty)
        } else {
            rebuildDerivedDashboardState(keepStaff: !officers.isEmpty)
        }
        isRefreshing = false

        Task {
            await generateDueReportsIfNeeded()
        }
    }

    @discardableResult
    func approveApplicant(_ id: UUID, remarks: String) -> Bool {
        guard CentralLoanRepository.shared.approveApplication(id: id, remarks: remarks) else {
            return false
        }
        appendAudit(action: "Approved \(applicationLabel(for: id))", severity: .success)
        
        Task {
            do {
                try await DatabaseService.shared.logAuditAction(
                    action: "Loan Approved",
                    entityType: "LoanApplication",
                    entityId: id
                )
            } catch {
                print("Failed to log audit action for manager approval: \(error)")
            }
        }
        
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
        
        Task {
            do {
                try await DatabaseService.shared.logAuditAction(
                    action: "Loan Rejected",
                    entityType: "LoanApplication",
                    entityId: id
                )
            } catch {
                print("Failed to log audit action for manager rejection: \(error)")
            }
        }
        
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
        CentralLoanRepository.shared.escalateApplication(id: id, managerName: managerProfile.name)
        appendAudit(action: "Escalated \(applicationLabel(for: id))", severity: .critical)
        HapticsManager.triggerNotification(type: .warning)
    }

    func applicants(for officer: ManagerOfficer) -> [ManagerApplicant] {
        applicants.filter { applicantBelongsToOfficer($0, officer: officer) }
    }

    var unassignedApplicants: [ManagerApplicant] {
        applicants.filter { !$0.isAssignedToOfficer }
    }

    func officerEscalations(for officer: ManagerOfficer) -> [ManagerOfficerEscalation] {
        officerEscalatedApplicants
            .filter { applicantBelongsToOfficer($0, officer: officer) }
            .map { applicant in
                let note = applicant.officerRemarks
                return ManagerOfficerEscalation(
                    id: applicant.id,
                    applicationId: applicant.applicationId,
                    borrowerName: applicant.borrowerName,
                    loanType: applicant.loanType,
                    requestedAmount: applicant.requestedAmount,
                    escalatedAt: applicant.escalatedAt ?? applicant.submissionDate,
                    reason: LoanEscalationNote.reason(from: note) ?? note,
                    riskLevel: applicant.riskLevel
                )
            }
            .sorted { $0.escalatedAt > $1.escalatedAt }
    }

    func managerRating(for officerId: UUID) -> Double? {
        guard let currentManagerUserId else { return nil }
        return ManagerOfficerRatingStorage.shared.rating(managerId: currentManagerUserId, officerId: officerId)
    }

    func setOfficerRating(_ rating: Double, for officerId: UUID) {
        guard let currentManagerUserId else { return }
        ManagerOfficerRatingStorage.shared.setRating(rating, managerId: currentManagerUserId, officerId: officerId)
        if let index = officers.firstIndex(where: { $0.id == officerId }) {
            officers[index].managerRating = rating
            officers[index].rating = rating
        }
        appendAudit(action: "Rated officer \(officers.first(where: { $0.id == officerId })?.name ?? "team member") \(String(format: "%.1f", rating))/5", severity: .info)
        HapticsManager.triggerNotification(type: .success)
    }

    func suggestedRating(for officer: ManagerOfficer, escalationCount: Int) -> Double {
        let escalationPenalty = Double(escalationCount) * 0.45
        let approvalBonus = officer.approvalRate / 40
        return min(5, max(1, 4.2 - escalationPenalty + approvalBonus))
    }

    func reassignApplicant(_ id: UUID, to officerId: UUID) {
        guard let officer = officers.first(where: { $0.id == officerId }) else { return }
        CentralLoanRepository.shared.reassignApplication(id: id, newOfficerId: officerId, newOfficerName: officer.name)
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

    func generateAndStoreReportNow(frequency: ManagerReportFrequency = .monthly) async {
        isGeneratingReports = true
        do {
            let report = try await ManagerReportGenerationService.shared.generateAndStoreReport(
                frequency: frequency,
                branchOverview: branchOverview,
                applicants: applicants,
                officers: officers
            )
            storedReports.insert(report, at: 0)
            lastReportPublishedAt = report.generatedAt
            appendAudit(action: "Stored \(report.title)", severity: .success)
            appendNotification(
                title: "\(report.frequency.displayName) report stored",
                message: "PDF and CSV reports were uploaded for \(branchOverview.name).",
                type: .success,
                relatedApplicantId: nil
            )
        } catch {
            appendAudit(action: "Report storage failed: \(error.localizedDescription)", severity: .warning)
            appendNotification(
                title: "Report storage failed",
                message: error.localizedDescription,
                type: .warning,
                relatedApplicantId: nil
            )
        }
        isGeneratingReports = false
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

        await CentralLoanRepository.shared.syncOfficerDirectory()
        CentralLoanRepository.shared.applyOfficerDirectory(from: staff)

        officers = branchOfficers.map { member in
            let officerApps = applicants.filter { $0.assignedOfficerId == member.id }
            let assignedCases = officerApps.filter { $0.status == .sentToManager || $0.status == .needsClarification }.count
            let completedCases = officerApps.filter { $0.status == .approved || $0.status == .disbursed }.count
            let processed = officerApps.count
            let approvalRate = processed == 0 ? 0 : (Double(completedCases) / Double(processed)) * 100

            let autoRating = processed == 0 ? 0 : min(5, 3.5 + approvalRate / 100)
            let storedRating = managerRating(for: member.id)
            return ManagerOfficer(
                id: member.id,
                name: member.fullName,
                role: member.designation ?? member.role.displayName,
                activeCases: assignedCases,
                maxCapacity: 15,
                rating: storedRating ?? autoRating,
                managerRating: storedRating,
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

    private func generateDueReportsIfNeeded() async {
        guard !applicants.isEmpty else { return }
        isGeneratingReports = true
        do {
            let reports = try await ManagerReportGenerationService.shared.generateAndStoreDueReports(
                branchOverview: branchOverview,
                applicants: applicants,
                officers: officers
            )
            if !reports.isEmpty {
                storedReports.insert(contentsOf: reports.reversed(), at: 0)
                lastReportPublishedAt = reports.last?.generatedAt
                appendAudit(action: "Stored \(reports.count) scheduled branch report\(reports.count == 1 ? "" : "s")", severity: .success)
                appendNotification(
                    title: "Scheduled reports stored",
                    message: "\(reports.map { $0.frequency.displayName }.joined(separator: ", ")) branch report\(reports.count == 1 ? "" : "s") uploaded as PDF and CSV.",
                    type: .success,
                    relatedApplicantId: nil
                )
            }
        } catch {
            appendAudit(action: "Scheduled report storage failed: \(error.localizedDescription)", severity: .warning)
            appendNotification(
                title: "Scheduled report storage failed",
                message: error.localizedDescription,
                type: .warning,
                relatedApplicantId: nil
            )
        }
        isGeneratingReports = false
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
            let officerId = apps.first?.assignedOfficerId ?? stableId(for: name)
            let autoRating = apps.isEmpty ? 0 : min(5, 3.5 + approvalRate / 100)
            let storedRating = managerRating(for: officerId)
            return ManagerOfficer(
                id: officerId,
                name: name,
                role: "Loan Officer",
                activeCases: apps.filter { $0.status == .sentToManager || $0.status == .needsClarification }.count,
                maxCapacity: 15,
                rating: storedRating ?? autoRating,
                managerRating: storedRating,
                performance: apps.isEmpty ? 0 : min(1, approvalRate / 100),
                loansProcessedYTD: completed,
                approvalRate: approvalRate
            )
        }
        .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private func isOfficerEscalation(_ applicant: ManagerApplicant) -> Bool {
        applicant.status == .escalated && LoanEscalationNote.isOfficerEscalation(applicant.officerRemarks)
    }

    private func applicantBelongsToOfficer(_ applicant: ManagerApplicant, officer: ManagerOfficer) -> Bool {
        applicant.assignedOfficerId == officer.id
    }

    private func rebuildBranchOverview() {
        let disbursedLoans = applicants
            .filter { $0.status == .disbursed || $0.status == .approved }
        let totalDisbursed = disbursedLoans
            .reduce(0) { $0 + $1.requestedAmount }
        let totalRecovered = disbursedLoans
            .reduce(0) { $0 + estimatedRecoveredAmount(for: $1) }
        let nplExposure = disbursedLoans
            .filter { isNonPerformingLoan($0) }
            .reduce(0) { $0 + max(0, $1.requestedAmount - estimatedRecoveredAmount(for: $1)) }
        let nplRate = totalDisbursed == 0 ? 0 : (nplExposure / totalDisbursed) * 100
        let activeLoans = disbursedLoans.count

        branchOverview = BranchOverview(
            name: managerProfile.branchName,
            code: managerProfile.branchCode,
            region: managerProfile.region,
            staffCount: officers.count,
            activeLoanCount: activeLoans,
            totalDisbursed: totalDisbursed,
            totalRecovered: totalRecovered,
            nplRate: nplRate,
            auditRating: auditRating(for: applicants),
            monthlyTarget: max(totalDisbursed, applicants.reduce(0) { $0 + $1.requestedAmount } * 1.2)
        )
    }

    private func estimatedRecoveredAmount(for applicant: ManagerApplicant) -> Double {
        guard applicant.status == .approved || applicant.status == .disbursed else { return 0 }
        let monthsSinceSubmission = max(1, Calendar.current.dateComponents([.month], from: applicant.submissionDate, to: Date()).month ?? 1)
        let paidMonths = min(max(applicant.tenure, 1), monthsSinceSubmission)
        let monthlyRate = applicant.interestRate / 1200
        let emi: Double

        if monthlyRate == 0 {
            emi = applicant.requestedAmount / Double(max(applicant.tenure, 1))
        } else {
            let factor = pow(1 + monthlyRate, Double(max(applicant.tenure, 1)))
            emi = applicant.requestedAmount * monthlyRate * factor / (factor - 1)
        }

        return min(applicant.requestedAmount, emi * Double(paidMonths))
    }

    private func isNonPerformingLoan(_ applicant: ManagerApplicant) -> Bool {
        guard applicant.status == .approved || applicant.status == .disbursed else { return false }
        return applicant.riskLevel == .critical || applicant.riskLevel == .high
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
        let existing = Dictionary(conversations.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
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
