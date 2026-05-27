import Foundation
import Combine
import SwiftUI
import SwiftUI

@MainActor
final class AdminDashboardViewModel: ObservableObject {
    @Published var kpis: [AdminKPI] = []
    @Published var systemHealth = SystemHealth(serverUptime: 100.0, activeSessions: 0, lastBackupTime: Date())
    @Published var recentAuditLogs: [AuditLogEntry] = []
    @Published var approvalBreakdown: (approved: Int, rejected: Int, pending: Int) = (0, 0, 0)
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        // Simulating network fetch
        do {
            try await Task.sleep(nanoseconds: 800_000_000)
            
            // Mock Data
            kpis = [
                AdminKPI(title: "Total Applications", value: "3,482", icon: "folder.fill", trend: 5.2, themeColor: LMSColors.brandNavy),
                AdminKPI(title: "Active Loans", value: "1,204", icon: "banknote.fill", trend: 2.1, themeColor: LMSColors.emerald),
                AdminKPI(title: "Pending Approvals", value: "156", icon: "clock.fill", trend: -1.5, themeColor: LMSColors.amber),
                AdminKPI(title: "Total Disbursed", value: "₹42.5 Cr", icon: "indianrupesign.circle.fill", trend: 8.4, themeColor: LMSColors.actionBlue)
            ]
            
            approvalBreakdown = (approved: 2450, rejected: 876, pending: 156)
            
            systemHealth = SystemHealth(
                serverUptime: 99.98,
                activeSessions: 24,
                lastBackupTime: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date()
            )
            
            recentAuditLogs = [
                AuditLogEntry(id: UUID(), userId: UUID(), userName: "Raj Kumar (LO)", action: "Approved Application", entityType: "Loan", entityId: "APP-2024-0891", timestamp: Date().addingTimeInterval(-1200), details: "Verified all documents and approved personal loan.", type: .loanAction),
                AuditLogEntry(id: UUID(), userId: UUID(), userName: "System", action: "Daily Backup Completed", entityType: "Database", entityId: "DB-MAIN", timestamp: Date().addingTimeInterval(-7200), details: "Automated snapshot saved securely.", type: .systemAction),
                AuditLogEntry(id: UUID(), userId: UUID(), userName: "Priya Singh (BM)", action: "Suspended User", entityType: "User", entityId: "USR-0042", timestamp: Date().addingTimeInterval(-86400), details: "Suspended due to policy violation.", type: .userAction)
            ]
            
        } catch {
            errorMessage = "Failed to load dashboard data."
        }
        
        isLoading = false
    }
}
