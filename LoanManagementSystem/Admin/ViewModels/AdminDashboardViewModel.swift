import Observation
import Foundation
import Combine
import SwiftUI
import Supabase

@MainActor
@Observable
final class AdminDashboardViewModel {
    var kpis: [AdminKPI] = []
    var systemHealth = SystemHealth(serverUptime: 100.0, activeSessions: 0, lastBackupTime: Date())
    var recentAuditLogs: [AuditLogEntry] = []
    var approvalBreakdown: (approved: Int, rejected: Int, pending: Int) = (0, 0, 0)

    var isLoading = false
    var errorMessage: String?
    
    private var branchBreakdowns: [String: [KPIBranchData]] = [:]
    
    private func normalizeBranchName(_ name: String) -> String {
        name.lowercased()
            .replacingOccurrences(of: "branch", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ",", with: "")
    }
    
    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let data = try await AdminDashboardService.shared.fetchDashboardData()
            
            let branches = try await AdminStaffService.shared.fetchBranches()
            
            let client = SupabaseManager.shared.client
            
            struct DBProfileMin: Codable {
                let id: UUID
                let preferredBranch: String?
            }
            
            let dbProfiles: [DBProfileMin] = (try? await client
                .from("profiles")
                .select("id, preferred_branch")
                .execute()
                .value) ?? []
            let userToBranchMap = Dictionary(uniqueKeysWithValues: dbProfiles.map { ($0.id, $0.preferredBranch ?? "") })
            
            struct DBLoanOfficerMin: Codable {
                let officerId: UUID
                let branchId: UUID
            }
            let dbOfficers: [DBLoanOfficerMin] = (try? await client
                .from("loan_officers")
                .select("officer_id, branch_id")
                .execute()
                .value) ?? []
            let officerToBranchMap = Dictionary(uniqueKeysWithValues: dbOfficers.map { ($0.officerId, $0.branchId) })
            
            var appsByBranchId: [UUID: [DBLoanApplication]] = [:]
            for app in data.rawApplications {
                var branchId: UUID? = nil
                
                if let offId = app.officerId, let bId = officerToBranchMap[offId] {
                    branchId = bId
                } else {
                    let prefBranchName = userToBranchMap[app.borrowerId] ?? ""
                    let normPref = normalizeBranchName(prefBranchName)
                    if !normPref.isEmpty {
                        if let matchedBranch = branches.first(where: { normalizeBranchName($0.name).contains(normPref) || normPref.contains(normalizeBranchName($0.name)) }) {
                            branchId = matchedBranch.branchId
                        }
                    }
                }
                
                let finalBranchId = branchId ?? branches.first?.branchId ?? UUID()
                appsByBranchId[finalBranchId, default: []].append(app)
            }
            
            let calculateTrend: (Int, Int) -> Double = { current, previous in
                if previous == 0 {
                    return current > 0 ? 100.0 : 0.0
                }
                let diff = Double(current - previous)
                let percent = (diff / Double(previous)) * 100.0
                return Double(String(format: "%.1f", percent)) ?? percent
            }
            
            let now = Date()
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
            let sixtyDaysAgo = Calendar.current.date(byAdding: .day, value: -60, to: now) ?? now
            
            let pendingStatuses = ["submitted", "under_review", "document_verification", "officer_review", "manager_review"]
            
            var breakdowns: [String: [KPIBranchData]] = [:]
            var totalAppsBranchData: [KPIBranchData] = []
            var activeLoansBranchData: [KPIBranchData] = []
            var pendingApprovalsBranchData: [KPIBranchData] = []
            var totalDisbursedBranchData: [KPIBranchData] = []
            
            for branch in branches {
                let branchApps = appsByBranchId[branch.branchId] ?? []
                
                let totalAppsCount = branchApps.count
                let last30Apps = branchApps.filter { ($0.submittedAt ?? $0.updatedAt) >= thirtyDaysAgo }
                let prev30Apps = branchApps.filter { ($0.submittedAt ?? $0.updatedAt) >= sixtyDaysAgo && ($0.submittedAt ?? $0.updatedAt) < thirtyDaysAgo }
                let totalAppsTrend = calculateTrend(last30Apps.count, prev30Apps.count)
                totalAppsBranchData.append(KPIBranchData(
                    branchName: branch.name,
                    branchCode: branch.code,
                    value: "\(totalAppsCount)",
                    trend: totalAppsTrend
                ))
                
                let activeApps = branchApps.filter { $0.status == "disbursed" || $0.status == "approved" }
                let activeCount = activeApps.count
                let last30Active = last30Apps.filter { $0.status == "disbursed" || $0.status == "approved" }.count
                let prev30Active = prev30Apps.filter { $0.status == "disbursed" || $0.status == "approved" }.count
                let activeTrend = calculateTrend(last30Active, prev30Active)
                activeLoansBranchData.append(KPIBranchData(
                    branchName: branch.name,
                    branchCode: branch.code,
                    value: "\(activeCount)",
                    trend: activeTrend
                ))
                
                let pendingApps = branchApps.filter { pendingStatuses.contains($0.status) }
                let pendingCount = pendingApps.count
                let last30Pending = last30Apps.filter { pendingStatuses.contains($0.status) }.count
                let prev30Pending = prev30Apps.filter { pendingStatuses.contains($0.status) }.count
                let pendingTrend = calculateTrend(last30Pending, prev30Pending)
                pendingApprovalsBranchData.append(KPIBranchData(
                    branchName: branch.name,
                    branchCode: branch.code,
                    value: "\(pendingCount)",
                    trend: pendingTrend
                ))
                
                let totalDisbursedAmt = activeApps.reduce(0.0) { $0 + Double($1.amountRequested) }
                let last30Disbursed = last30Apps.filter { $0.status == "disbursed" || $0.status == "approved" }.reduce(0.0) { $0 + Double($1.amountRequested) }
                let prev30Disbursed = prev30Apps.filter { $0.status == "disbursed" || $0.status == "approved" }.reduce(0.0) { $0 + Double($1.amountRequested) }
                let disbursedTrend = calculateTrend(Int(last30Disbursed), Int(prev30Disbursed))
                
                let formattedDisbursed: String
                if totalDisbursedAmt >= 10_000_000 {
                    formattedDisbursed = String(format: "₹%.2f Cr", totalDisbursedAmt / 10_000_000.0)
                } else if totalDisbursedAmt >= 100_000 {
                    formattedDisbursed = String(format: "₹%.2f L", totalDisbursedAmt / 100_000.0)
                } else {
                    formattedDisbursed = String(format: "₹%.0f", totalDisbursedAmt)
                }
                
                totalDisbursedBranchData.append(KPIBranchData(
                    branchName: branch.name,
                    branchCode: branch.code,
                    value: formattedDisbursed,
                    trend: disbursedTrend
                ))
            }
            
            breakdowns["Total Applications"] = totalAppsBranchData.sorted { $0.trend > $1.trend }
            breakdowns["Active Loans"] = activeLoansBranchData.sorted { $0.trend > $1.trend }
            breakdowns["Pending Approvals"] = pendingApprovalsBranchData.sorted { $0.trend > $1.trend }
            breakdowns["Total Disbursed"] = totalDisbursedBranchData.sorted { $0.trend > $1.trend }
            
            self.branchBreakdowns = breakdowns
            
            let formattedTotalApps = "\(data.totalApplications)"
            let formattedActiveLoans = "\(data.activeLoans)"
            let formattedPendingApprovals = "\(data.pendingApprovals)"
            
            let formattedTotalDisbursed: String
            if data.totalDisbursed >= 10_000_000 {
                formattedTotalDisbursed = String(format: "₹%.2f Cr", data.totalDisbursed / 10_000_000.0)
            } else if data.totalDisbursed >= 100_000 {
                formattedTotalDisbursed = String(format: "₹%.2f L", data.totalDisbursed / 100_000.0)
            } else {
                formattedTotalDisbursed = String(format: "₹%.0f", data.totalDisbursed)
            }
            
            kpis = [
                AdminKPI(title: "Total Applications", value: formattedTotalApps, icon: "square.stack.3d.up", trend: data.totalApplicationsTrend, themeColor: LMSColors.textPrimary),
                AdminKPI(title: "Active Loans", value: formattedActiveLoans, icon: "chart.line.uptrend.xyaxis", trend: data.activeLoansTrend, themeColor: LMSColors.textPrimary),
                AdminKPI(title: "Pending Approvals", value: formattedPendingApprovals, icon: "hourglass", trend: data.pendingApprovalsTrend, themeColor: LMSColors.amber),
                AdminKPI(title: "Total Disbursed", value: formattedTotalDisbursed, icon: "indianrupeesign.circle", trend: data.totalDisbursedTrend, themeColor: LMSColors.emerald)
            ]
            
            let approvedCount = data.rawApplications.filter { $0.status == "disbursed" || $0.status == "approved" }.count
            let rejectedCount = data.rawApplications.filter { $0.status == "rejected" }.count
            let pendingCount = data.rawApplications.filter { pendingStatuses.contains($0.status) }.count
            approvalBreakdown = (approved: approvedCount, rejected: rejectedCount, pending: pendingCount)
            
            systemHealth = SystemHealth(
                serverUptime: data.serverUptime,
                activeSessions: data.activeSessions,
                lastBackupTime: data.lastBackupTime
            )
            
            recentAuditLogs = data.recentAuditLogs
            
        } catch {
            print("❌ AdminDashboardViewModel: Error loading dashboard data: \(error)")
            errorMessage = "Failed to load dashboard data: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func getBranchBreakdown(for kpi: AdminKPI) -> [KPIBranchData] {
        return branchBreakdowns[kpi.title] ?? []
    }

}
