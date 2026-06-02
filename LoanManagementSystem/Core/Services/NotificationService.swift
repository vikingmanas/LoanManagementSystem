import Foundation
import Supabase
import SwiftUI

/// Swift representation of the `public.notifications` database table.
/// NOTE: No CodingKeys needed — SupabaseManager's decoder uses .convertFromSnakeCase
/// and encoder uses .convertToSnakeCase automatically.
public struct DBNotification: Codable, Identifiable, Sendable {
    public var id: UUID { notificationId }
    
    public let notificationId: UUID
    public let userId: UUID
    public let notifType: String
    public let title: String
    public let message: String
    public var isRead: Bool
    public let createdAt: Date
    
    /// Convert to the LMSNotification UI model used by LMSNotificationRow.
    public func toLMSNotification() -> LMSNotification {
        let icon: String
        let tint: Color
        
        let lowerTitle = title.lowercased()
        if lowerTitle.contains("approved") || lowerTitle.contains("credited") {
            icon = "checkmark.seal.fill"
            tint = LMSColors.emerald
        } else if lowerTitle.contains("rejected") {
            icon = "xmark.seal.fill"
            tint = LMSColors.coral
        } else if lowerTitle.contains("submitted") || lowerTitle.contains("received") {
            icon = "paperplane.fill"
            tint = LMSColors.actionBlue
        } else if lowerTitle.contains("review") || lowerTitle.contains("under") {
            icon = "doc.text.magnifyingglass"
            tint = LMSColors.amber
        } else if lowerTitle.contains("document") || lowerTitle.contains("resubmission") {
            icon = "doc.badge.plus"
            tint = LMSColors.coral
        } else if lowerTitle.contains("verification") || lowerTitle.contains("verified") {
            icon = "checkmark.shield.fill"
            tint = LMSColors.teal
        } else if lowerTitle.contains("forwarded") || lowerTitle.contains("approval") {
            icon = "arrow.right.circle.fill"
            tint = LMSColors.brandNavy
        } else if lowerTitle.contains("clarification") || lowerTitle.contains("sent back") {
            icon = "arrow.uturn.backward.circle.fill"
            tint = LMSColors.amber
        } else {
            icon = "bell.fill"
            tint = LMSColors.brandNavy
        }
        
        return LMSNotification(
            id: notificationId,
            title: title,
            body: message,
            timestamp: createdAt,
            icon: icon,
            tint: tint,
            isUnread: !isRead
        )
    }
}

// MARK: - Insert-Only DTO

/// Lightweight struct used only for INSERT operations.
private struct DBNotificationInsert: Codable {
    let notificationId: UUID
    let userId: UUID
    let notifType: String
    let title: String
    let message: String
    let isRead: Bool
    let createdAt: Date
}

/// Centralized service for all notification CRUD operations against the Supabase `notifications` table.
final class NotificationService {
    static let shared = NotificationService()
    private init() {}
    
    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }
    
    // MARK: - Insert
    
    /// Creates a new notification in Supabase for the given user.
    func insertNotification(userId: UUID, title: String, message: String, notifType: String = "push") async {
        let row = DBNotificationInsert(
            notificationId: UUID(),
            userId: userId,
            notifType: notifType,
            title: title,
            message: message,
            isRead: false,
            createdAt: Date()
        )
        
        do {
            try await client
                .from("notifications")
                .insert(row)
                .execute()
            print("[NotificationService] ✅ Notification sent to user \(userId.uuidString.prefix(8)): \(title)")
        } catch {
            print("[NotificationService] ❌ Failed to insert notification: \(error)")
        }
    }
    
    /// Sends the same notification to multiple users at once.
    func insertNotifications(userIds: [UUID], title: String, message: String, notifType: String = "push") async {
        let rows = userIds.map { userId in
            DBNotificationInsert(
                notificationId: UUID(),
                userId: userId,
                notifType: notifType,
                title: title,
                message: message,
                isRead: false,
                createdAt: Date()
            )
        }
        
        guard !rows.isEmpty else { return }
        
        do {
            try await client
                .from("notifications")
                .insert(rows)
                .execute()
            print("[NotificationService] ✅ Batch notification sent to \(userIds.count) users: \(title)")
        } catch {
            print("[NotificationService] ❌ Failed to insert batch notifications: \(error)")
        }
    }
    
    // MARK: - Fetch
    
    /// Fetches all notifications for the given user, ordered by most recent first.
    func fetchNotifications(userId: UUID) async throws -> [DBNotification] {
        let notifications: [DBNotification] = try await client
            .from("notifications")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(100)
            .execute()
            .value
        return notifications
    }
    
    /// Returns the count of unread notifications for the given user.
    func unreadCount(userId: UUID) async throws -> Int {
        let notifications: [DBNotification] = try await client
            .from("notifications")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("is_read", value: false)
            .execute()
            .value
        return notifications.count
    }
    
    // MARK: - Update
    
    /// Marks a single notification as read.
    func markAsRead(notificationId: UUID) async throws {
        struct ReadUpdate: Codable {
            let isRead: Bool
        }
        try await client
            .from("notifications")
            .update(ReadUpdate(isRead: true))
            .eq("notification_id", value: notificationId.uuidString)
            .execute()
    }
    
    /// Marks all notifications for a user as read.
    func markAllAsRead(userId: UUID) async throws {
        struct ReadUpdate: Codable {
            let isRead: Bool
        }
        try await client
            .from("notifications")
            .update(ReadUpdate(isRead: true))
            .eq("user_id", value: userId.uuidString)
            .eq("is_read", value: false)
            .execute()
    }
    
    // MARK: - Delete
    
    /// Deletes a single notification.
    func deleteNotification(notificationId: UUID) async throws {
        try await client
            .from("notifications")
            .delete()
            .eq("notification_id", value: notificationId.uuidString)
            .execute()
    }
    
    // MARK: - User Lookup Helpers
    
    /// Fetches all user IDs with a specific role (e.g., "loan_officer", "manager").
    /// For "manager", also matches "loan_manager" to handle role-naming inconsistencies.
    func fetchUserIds(byRole role: String) async -> [UUID] {
        struct UserIdRow: Codable {
            let id: UUID
        }
        do {
            let query = client
                .from("users")
                .select("id")
            
            // Handle both "manager" and "loan_manager" role variants
            let filteredQuery: PostgrestFilterBuilder
            if role == "manager" {
                filteredQuery = query.in("role", values: ["manager", "loan_manager"])
            } else {
                filteredQuery = query.eq("role", value: role)
            }
            
            let rows: [UserIdRow] = try await filteredQuery
                .execute()
                .value
            print("[NotificationService] Found \(rows.count) users with role '\(role)'")
            return rows.map(\.id)
        } catch {
            print("[NotificationService] ❌ Failed to fetch user IDs for role '\(role)': \(error)")
            return []
        }
    }
    
    /// Fetches the manager_id for the branch matching the given branch name.
    /// Falls back to all managers if the branch manager is not specified.
    func fetchManagerIds(forBranchName branchName: String) async -> [UUID] {
        struct DBBranch: Codable {
            let branchId: UUID
            let name: String
            let managerId: UUID?
            
            enum CodingKeys: String, CodingKey {
                case branchId = "branch_id"
                case name
                case managerId = "manager_id"
            }
        }
        
        do {
            let branches: [DBBranch] = try await client
                .from("branches")
                .select("branch_id, name, manager_id")
                .execute()
                .value
            
            let normalizedBranch = branchName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            let selectedBranch = branches.first { $0.name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) == normalizedBranch }
                ?? branches.first { $0.name.lowercased().contains(normalizedBranch) || normalizedBranch.contains($0.name.lowercased()) }
                ?? branches.first
            
            if let managerId = selectedBranch?.managerId {
                print("[NotificationService] Found branch manager ID \(managerId) for branch '\(branchName)'")
                return [managerId]
            }
        } catch {
            print("[NotificationService] ❌ Failed to fetch manager for branch '\(branchName)': \(error)")
        }
        
        // Fallback: notify all branch managers if branch manager is null or lookup failed
        return await fetchUserIds(byRole: "manager")
    }
}

