import Foundation
import Combine
import SwiftUI
import OSLog

@MainActor
final class AdminDashboardViewModel: ObservableObject {
    @Published var kpis: [AdminKPI] = []
    @Published var systemHealth = SystemHealth(serverUptime: 100.0, activeSessions: 0, lastBackupTime: Date())
    @Published var recentAuditLogs: [AuditLogEntry] = []
    @Published var approvalBreakdown: (approved: Int, rejected: Int, pending: Int) = (0, 0, 0)
    @Published var rawApplications: [DBLoanApplication] = []
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let data = try await AdminDashboardService.shared.fetchDashboardData()
            
            // Format currency in Indian notation (Lakhs / Crores)
            let formattedDisbursed = formatCurrency(data.totalDisbursed)
            
            kpis = [
                AdminKPI(title: "Total Applications", value: "\(data.totalApplications)", icon: "folder.fill", trend: data.totalApplicationsTrend, themeColor: LMSColors.brandNavy),
                AdminKPI(title: "Active Loans", value: "\(data.activeLoans)", icon: "banknote.fill", trend: data.activeLoansTrend, themeColor: LMSColors.emerald),
                AdminKPI(title: "Pending Approvals", value: "\(data.pendingApprovals)", icon: "clock.fill", trend: data.pendingApprovalsTrend, themeColor: LMSColors.amber),
                AdminKPI(title: "Total Disbursed", value: formattedDisbursed, icon: "indianrupesign.circle.fill", trend: data.totalDisbursedTrend, themeColor: LMSColors.actionBlue)
            ]
            
            systemHealth = SystemHealth(
                serverUptime: data.serverUptime,
                activeSessions: data.activeSessions,
                lastBackupTime: data.lastBackupTime
            )
            
            recentAuditLogs = Array(data.recentAuditLogs.prefix(3))
            rawApplications = data.rawApplications
            
        } catch {
            logger.error("AdminDashboardViewModel: Failed to load dashboard data: \(error.localizedDescription)")
            errorMessage = "Failed to load dashboard data."
        }
        
        isLoading = false
    }
    
    private let logger = Logger(subsystem: "galgotias.in.akash", category: "AdminDashboardViewModel")
    
    private func formatCurrency(_ value: Double) -> String {
        if value >= 10_000_000 { // 1 Crore
            let crVal = value / 10_000_000
            return String(format: "₹%.2f Cr", crVal)
        } else if value >= 100_000 { // 1 Lakh
            let lakhVal = value / 100_000
            return String(format: "₹%.2f Lakh", lakhVal)
        } else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = Locale(identifier: "en_IN")
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: value)) ?? "₹\(Int(value))"
        }
    }
}
