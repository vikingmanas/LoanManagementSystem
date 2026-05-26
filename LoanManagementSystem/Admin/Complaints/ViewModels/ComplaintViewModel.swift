import SwiftUI
import Combine

@MainActor
final class ComplaintViewModel: ObservableObject {
    @Published var tickets: [ComplaintTicket] = []
    
    // Filtering State
    @Published var searchText: String = ""
    @Published var selectedOrigin: TicketOrigin? = nil
    @Published var selectedStatus: ComplaintStatus? = nil
    @Published var selectedPriority: ComplaintPriority? = nil
    @Published var selectedManager: String? = nil
    @Published var selectedCategory: ComplaintCategory? = nil
    
    var availableManagers: [String] {
        Array(Set(tickets.compactMap { $0.assignedManager })).sorted()
    }
    
    init() {
        loadMockData()
    }
    
    // MARK: - Filtered Data
    var filteredTickets: [ComplaintTicket] {
        tickets.filter { t in
            let matchesSearch = searchText.isEmpty ||
                t.title.localizedCaseInsensitiveContains(searchText) ||
                t.ticketId.localizedCaseInsensitiveContains(searchText) ||
                (t.borrowerName?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (t.assignedManager?.localizedCaseInsensitiveContains(searchText) ?? false)
            
            let matchesOrigin = selectedOrigin == nil || t.origin == selectedOrigin
            let matchesStatus = selectedStatus == nil || t.status == selectedStatus
            let matchesPriority = selectedPriority == nil || t.priority == selectedPriority
            let matchesManager = selectedManager == nil || t.assignedManager == selectedManager
            let matchesCategory = selectedCategory == nil || t.category == selectedCategory
            
            return matchesSearch && matchesOrigin && matchesStatus && matchesPriority && matchesManager && matchesCategory
        }
        .sorted { $0.priority.weight > $1.priority.weight }
    }
    
    // MARK: - Dashboard Analytics
    var totalCount: Int { tickets.count }
    var complaintCount: Int { tickets.filter { $0.origin == .complaint }.count }
    var operationalCount: Int { tickets.filter { $0.origin == .operationalIssue }.count }
    var openCount: Int { tickets.filter { $0.status == .open || $0.status == .inProgress || $0.status == .inReview || $0.status == .pending }.count }
    var escalatedCount: Int { tickets.filter { $0.status == .escalated }.count }
    var resolvedCount: Int { tickets.filter { $0.status == .resolved || $0.status == .closed }.count }
    var criticalCount: Int { tickets.filter { $0.priority == .critical && $0.status != .resolved && $0.status != .closed }.count }
    
    var resolutionRate: Double {
        guard totalCount > 0 else { return 0 }
        return Double(resolvedCount) / Double(totalCount)
    }
    
    // Branch Analytics
    struct BranchStat: Identifiable {
        let id = UUID()
        let branchName: String
        let total: Int
        let resolved: Int
        let escalated: Int
    }
    
    var branchAnalytics: [BranchStat] {
        let grouped = Dictionary(grouping: tickets, by: { $0.branchName })
        return grouped.map { (branch, list) in
            BranchStat(
                branchName: branch,
                total: list.count,
                resolved: list.filter { $0.status == .resolved || $0.status == .closed }.count,
                escalated: list.filter { $0.status == .escalated }.count
            )
        }.sorted { $0.total > $1.total }
    }
    
    var criticalAndEscalated: [ComplaintTicket] {
        tickets.filter {
            ($0.priority == .critical || $0.priority == .high || $0.status == .escalated) &&
            $0.status != .resolved && $0.status != .closed
        }
        .sorted { $0.priority.weight > $1.priority.weight }
    }
    
    // MARK: - Actions
    func updateStatus(for id: UUID, to status: ComplaintStatus, user: String) {
        if let i = tickets.firstIndex(where: { $0.id == id }) {
            tickets[i].status = status
            tickets[i].timeline.insert(
                TicketTimelineEvent(date: Date(), action: "Status → \(status.rawValue)", note: nil, user: user), at: 0
            )
        }
    }
    
    func escalate(id: UUID, user: String) {
        if let i = tickets.firstIndex(where: { $0.id == id }) {
            tickets[i].status = .escalated
            tickets[i].priority = .critical
            tickets[i].timeline.insert(
                TicketTimelineEvent(date: Date(), action: "Escalated to Admin", note: "Priority raised to Critical.", user: user), at: 0
            )
        }
    }
    
    func assignTeam(id: UUID, teamName: String, assignedBy: String) {
        if let i = tickets.firstIndex(where: { $0.id == id }) {
            tickets[i].assignedTeam = teamName
            tickets[i].timeline.insert(
                TicketTimelineEvent(date: Date(), action: "Team Assigned", note: "Assigned to \(teamName).", user: assignedBy), at: 0
            )
        }
    }
    
    func assignManager(id: UUID, managerName: String, assignedBy: String) {
        if let i = tickets.firstIndex(where: { $0.id == id }) {
            tickets[i].assignedManager = managerName
            tickets[i].timeline.insert(
                TicketTimelineEvent(date: Date(), action: "Staff Assigned", note: "Assigned to \(managerName).", user: assignedBy), at: 0
            )
        }
    }
    
    func addNote(id: UUID, note: String, user: String, isAdmin: Bool = false) {
        if let i = tickets.firstIndex(where: { $0.id == id }) {
            if isAdmin {
                tickets[i].adminRemarks = note
            } else {
                tickets[i].managerNotes = note
            }
            tickets[i].timeline.insert(
                TicketTimelineEvent(date: Date(), action: isAdmin ? "Admin Remark" : "Manager Note", note: note, user: user), at: 0
            )
        }
    }
    
    func clearAllFilters() {
        selectedOrigin = nil
        selectedStatus = nil
        selectedPriority = nil
        selectedManager = nil
        selectedCategory = nil
    }
    
    // MARK: - Mock Data
    private func loadMockData() {
        let now = Date()
        let cal = Calendar.current
        
        tickets = [
            // ── Borrower Complaints ──
            ComplaintTicket(
                id: UUID(), ticketId: "CMP-9082", title: "Excess EMI Deduction",
                origin: .complaint, category: .financialDiscrepancy, branchName: "Mumbai Central",
                dateRaised: cal.date(byAdding: .day, value: -2, to: now)!,
                status: .open, priority: .high,
                description: "The EMI deducted for this month was ₹15,000 instead of ₹12,500. Need immediate refund of the excess amount.",
                borrowerName: "Arjun Mehta",
                assignedManager: "Suresh Pillai", assignedTeam: nil,
                managerNotes: "Verified transaction logs. Extra amount deducted due to system glitch.",
                adminRemarks: nil,
                timeline: [
                    TicketTimelineEvent(date: cal.date(byAdding: .day, value: -1, to: now)!, action: "Assigned", note: "Assigned to Suresh Pillai.", user: "Admin Desk"),
                    TicketTimelineEvent(date: cal.date(byAdding: .day, value: -2, to: now)!, action: "Complaint Logged", note: "Auto-assigned to finance desk.", user: "System")
                ]
            ),
            ComplaintTicket(
                id: UUID(), ticketId: "CMP-9084", title: "Rude Field Officer Behavior",
                origin: .complaint, category: .customerService, branchName: "Bangalore South",
                dateRaised: cal.date(byAdding: .day, value: -1, to: now)!,
                status: .inReview, priority: .medium,
                description: "The loan officer was very rude during the physical verification process at my residence.",
                borrowerName: "Rohan Desai",
                assignedManager: "Anita Desai", assignedTeam: nil,
                managerNotes: "Called borrower to apologize. Scheduling compliance training for the officer.",
                adminRemarks: nil,
                timeline: [
                    TicketTimelineEvent(date: now, action: "Under Review", note: "Manager contacting borrower.", user: "Anita Desai"),
                    TicketTimelineEvent(date: cal.date(byAdding: .day, value: -1, to: now)!, action: "Complaint Logged", note: nil, user: "System")
                ]
            ),
            ComplaintTicket(
                id: UUID(), ticketId: "CMP-9085", title: "Late Fee Despite On-Time Payment",
                origin: .complaint, category: .policyViolation, branchName: "Hyderabad Main",
                dateRaised: cal.date(byAdding: .day, value: -10, to: now)!,
                status: .closed, priority: .low,
                description: "Was charged a late fee despite paying on the due date. The payment gateway took 24 hours to process.",
                borrowerName: "Sneha Reddy",
                assignedManager: "Anita Desai", assignedTeam: nil,
                managerNotes: "Refund initiated.",
                adminRemarks: "Approved and closed.",
                timeline: [
                    TicketTimelineEvent(date: cal.date(byAdding: .day, value: -7, to: now)!, action: "Closed", note: "Issue fully resolved.", user: "Admin"),
                    TicketTimelineEvent(date: cal.date(byAdding: .day, value: -8, to: now)!, action: "Resolved", note: "Late fee reversed.", user: "Anita Desai"),
                    TicketTimelineEvent(date: cal.date(byAdding: .day, value: -10, to: now)!, action: "Complaint Logged", note: nil, user: "System")
                ]
            ),
            
            // ── Operational / Technical Issues ──
            ComplaintTicket(
                id: UUID(), ticketId: "ISS-4001", title: "Core Banking Server Unresponsive",
                origin: .operationalIssue, category: .serverDowntime, branchName: "Mumbai Central",
                dateRaised: cal.date(byAdding: .hour, value: -3, to: now)!,
                status: .escalated, priority: .critical,
                description: "The core banking middleware server has been unresponsive since 08:15 AM. All loan disbursement and EMI processing operations are halted. ~340 transactions queued.",
                borrowerName: nil,
                assignedManager: "Suresh Pillai", assignedTeam: "Infra Ops Level 2",
                managerNotes: "Attempted server restart — no recovery. Disk I/O at 100%.",
                adminRemarks: "Cloud hosting vendor contacted. ETA: 2 hours. INC-7892 raised.",
                timeline: [
                    TicketTimelineEvent(date: cal.date(byAdding: .hour, value: -1, to: now)!, action: "Escalated to Admin", note: "Server restart failed.", user: "Suresh Pillai"),
                    TicketTimelineEvent(date: cal.date(byAdding: .hour, value: -2, to: now)!, action: "Restart Attempted", note: "Disk I/O saturated at 100%.", user: "Infra Ops L1"),
                    TicketTimelineEvent(date: cal.date(byAdding: .hour, value: -3, to: now)!, action: "Issue Reported", note: "Server unresponsive since 08:15 AM.", user: "System Monitor")
                ]
            ),
            ComplaintTicket(
                id: UUID(), ticketId: "ISS-4002", title: "Payment Gateway UPI Timeout",
                origin: .operationalIssue, category: .paymentGateway, branchName: "Delhi NCR",
                dateRaised: cal.date(byAdding: .hour, value: -6, to: now)!,
                status: .inProgress, priority: .high,
                description: "UPI payment collections via Razorpay are intermittently timing out. Success rate dropped from 98% to 61%.",
                borrowerName: nil,
                assignedManager: "Ravi Kumar", assignedTeam: "Payment Integration Team",
                managerNotes: "Razorpay webhook latency spiked. Their status page shows degraded performance.",
                adminRemarks: nil,
                timeline: [
                    TicketTimelineEvent(date: cal.date(byAdding: .hour, value: -4, to: now)!, action: "Team Assigned", note: "Payment Integration Team investigating.", user: "Admin Desk"),
                    TicketTimelineEvent(date: cal.date(byAdding: .hour, value: -6, to: now)!, action: "Issue Reported", note: "UPI success rate dropped to 61%.", user: "Ravi Kumar")
                ]
            ),
            ComplaintTicket(
                id: UUID(), ticketId: "ISS-4003", title: "KYC Aadhaar API 503 Errors",
                origin: .operationalIssue, category: .kycVerification, branchName: "Bangalore South",
                dateRaised: cal.date(byAdding: .day, value: -1, to: now)!,
                status: .pending, priority: .medium,
                description: "UIDAI Aadhaar verification API returning 503 errors. All new e-KYC loan applications are blocked.",
                borrowerName: nil,
                assignedManager: "Anita Desai", assignedTeam: nil,
                managerNotes: "UIDAI maintenance confirmed until tomorrow. Manual KYC fallback activated.",
                adminRemarks: nil,
                timeline: [
                    TicketTimelineEvent(date: cal.date(byAdding: .hour, value: -18, to: now)!, action: "Fallback Activated", note: "Manual KYC process enabled.", user: "Anita Desai"),
                    TicketTimelineEvent(date: cal.date(byAdding: .day, value: -1, to: now)!, action: "Issue Reported", note: "UIDAI API returning 503.", user: "System Monitor")
                ]
            ),
            ComplaintTicket(
                id: UUID(), ticketId: "ISS-4004", title: "Database Replication Lag — 45 min",
                origin: .operationalIssue, category: .databaseSync, branchName: "Hyderabad Main",
                dateRaised: cal.date(byAdding: .day, value: -2, to: now)!,
                status: .resolved, priority: .high,
                description: "Read replica lagging by 45 minutes. Stale data on borrower portal for ~1200 borrowers.",
                borrowerName: nil,
                assignedManager: "Suresh Pillai", assignedTeam: "DBA Team",
                managerNotes: "Lag caused by long-running analytical query. Query killed.",
                adminRemarks: "Post-mortem scheduled. Query governance policy to be enforced.",
                timeline: [
                    TicketTimelineEvent(date: cal.date(byAdding: .day, value: -1, to: now)!, action: "Resolved", note: "Replication lag recovered to < 1 sec.", user: "DBA Team"),
                    TicketTimelineEvent(date: cal.date(byAdding: .day, value: -2, to: now)!, action: "Issue Reported", note: "45-min replication lag detected.", user: "System Monitor")
                ]
            ),
            ComplaintTicket(
                id: UUID(), ticketId: "ISS-4005", title: "Loan Disbursement Workflow Stuck",
                origin: .operationalIssue, category: .loanProcessingFailure, branchName: "Pune Hub",
                dateRaised: cal.date(byAdding: .hour, value: -8, to: now)!,
                status: .open, priority: .high,
                description: "12 loan disbursement requests stuck in 'Processing' state. Approval microservice not acknowledging queue messages.",
                borrowerName: nil,
                assignedManager: "Ravi Kumar", assignedTeam: nil,
                managerNotes: nil, adminRemarks: nil,
                timeline: [
                    TicketTimelineEvent(date: cal.date(byAdding: .hour, value: -8, to: now)!, action: "Issue Reported", note: "12 disbursements stuck.", user: "Ravi Kumar")
                ]
            )
        ]
    }
}
