import Foundation

struct AuditLog: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let action: String
    let entityType: String
    let entityId: UUID

    let oldValue: Data?
    let newValue: Data?
    let ipAddress: String
    let ts: Date

    enum CodingKeys: String, CodingKey {
        case id = "log_id"
        case userId = "user_id"
        case action
        case entityType = "entity_type"
        case entityId = "entity_id"
        case oldValue = "old_value"
        case newValue = "new_value"
        case ipAddress = "ip_address"
        case ts
    }
}
