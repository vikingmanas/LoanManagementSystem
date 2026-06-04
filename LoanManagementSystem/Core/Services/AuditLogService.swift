//
//  AuditLogService.swift
//  LoanManagementSystem
//

import Foundation
import Supabase
import OSLog

final class AuditLogService {
    static let shared = AuditLogService()
    private let client = SupabaseManager.shared.client
    private let logger = Logger(subsystem: "galgotias.in.akash", category: "AuditLogService")
    
    private init() {}
    
    func logAction(action: String, entityType: String, entityId: UUID, details: String? = nil) async {
        guard let userId = client.auth.currentSession?.user.id else {
            logger.warning("AuditLogService: No active user session, cannot log action.")
            return
        }
        
        var insertData: [String: String] = [
            "user_id": userId.uuidString,
            "action": action,
            "entity_type": entityType,
            "entity_id": entityId.uuidString,
            "ip_address": "Mobile App Client"
        ]
        
        do {
            try await client
                .from("audit_logs")
                .insert(insertData)
                .execute()
            logger.info("AuditLogService: Successfully logged action '\(action)' for entity '\(entityId)'")
        } catch {
            logger.error("AuditLogService: Failed to log action '\(action)': \(error.localizedDescription)")
        }
    }
}
