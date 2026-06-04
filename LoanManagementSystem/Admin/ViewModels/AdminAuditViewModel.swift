import Observation
import Foundation
import Combine
import SwiftUI
import OSLog
import Supabase

@MainActor
@Observable
final class AdminAuditViewModel {
    var auditEntries: [AuditLogEntry] = []
    var searchText: String = ""
    var selectedType: AuditLogType? = nil
    
    var isLoading = false
    var errorMessage: String?
    
    var filteredEntries: [AuditLogEntry] {
        var filtered = auditEntries
        
        if let type = selectedType {
            filtered = filtered.filter { $0.type == type }
        }
        
        if !searchText.isEmpty {
            let lowercasedSearch = searchText.lowercased()
            filtered = filtered.filter { 
                $0.userName.lowercased().contains(lowercasedSearch) ||
                $0.action.lowercased().contains(lowercasedSearch) ||
                $0.entityId.lowercased().contains(lowercasedSearch)
            }
        }
        
        return filtered.sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    func loadAuditLog() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let logs = try await AdminDashboardService.shared.fetchAllAuditLogs()
            // Filter out system actions from the main list as they are developer-only
            auditEntries = logs.filter { $0.type != .systemAction }
        } catch {
            logger.error("AdminAuditViewModel: Failed to load audit logs: \(error.localizedDescription)")
            errorMessage = "Failed to load audit logs."
        }
        
        isLoading = false
    }
    
    func exportCSV() -> URL? {
        return AuditReportExporter.shared.generateCSV(from: filteredEntries)
    }
    
    func exportPDF() -> URL? {
        return AuditReportExporter.shared.generatePDF(from: filteredEntries)
    }
    
    private let logger = Logger(subsystem: "galgotias.in.akash", category: "AdminAuditViewModel")
}
