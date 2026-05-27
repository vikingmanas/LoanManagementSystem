import Foundation
import Combine
import SwiftUI
import SwiftUI

@MainActor
final class AdminAuditViewModel: ObservableObject {
    @Published var auditEntries: [AuditLogEntry] = []
    @Published var searchText: String = ""
    @Published var selectedType: AuditLogType? = nil
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
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
        
        // Simulating network fetch
        do {
            try await Task.sleep(nanoseconds: 800_000_000)
            
            // Generate some mock entries
            var mockEntries: [AuditLogEntry] = []
            let types: [AuditLogType] = [.userAction, .documentAction, .loanAction, .systemAction]
            let actions = ["Verified Document", "Rejected Application", "Created User", "System Update", "Downloaded Report"]
            let names = ["System", "Raj Kumar (LO)", "Priya Singh (BM)", "Amit Patel (LO)"]
            
            for i in 0..<20 {
                let entry = AuditLogEntry(
                    id: UUID(),
                    userId: UUID(),
                    userName: names.randomElement()!,
                    action: actions.randomElement()!,
                    entityType: "Entity \(i)",
                    entityId: "ID-\(Int.random(in: 1000...9999))",
                    timestamp: Date().addingTimeInterval(Double(-i * 3600)),
                    details: "Automated mock details for entry \(i)",
                    type: types.randomElement()!
                )
                mockEntries.append(entry)
            }
            
            auditEntries = mockEntries
            
        } catch {
            errorMessage = "Failed to load audit logs."
        }
        
        isLoading = false
    }
}
