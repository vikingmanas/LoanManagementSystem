import SwiftUI
import Combine
import Supabase

/// Shared ViewModel for in-app notifications, usable by all user roles.
/// Fetches notifications from Supabase and auto-polls for new ones.
@MainActor
public final class NotificationViewModel: ObservableObject {
    
    @Published public var notifications: [DBNotification] = []
    @Published public var unreadCount: Int = 0
    @Published public var isLoading: Bool = false
    
    private var realtimeChannel: RealtimeChannelV2?
    private var userId: UUID?
    
    public init() {}
    
    /// The notifications converted to LMSNotification for UI rendering.
    public var lmsNotifications: [LMSNotification] {
        notifications.map { $0.toLMSNotification() }
    }
    
    deinit {
        let channel = realtimeChannel
        Task {
            await channel?.unsubscribe()
        }
    }
    
    
    /// Configures the view model with the current user's ID and starts realtime listener.
    public func configure(userId: UUID) {
        guard self.userId != userId else { return } // already configured for this user
        self.userId = userId
        print("[NotificationVM] ✅ Configured for user: \(userId.uuidString.prefix(8))")
        Task {
            await loadNotifications()
            await setupRealtime(for: userId)
        }
    }
    
    private func setupRealtime(for userId: UUID) async {
        if let channel = realtimeChannel {
            await channel.unsubscribe()
        }
        
        realtimeChannel = await NotificationService.shared.subscribeToNotifications(forUserId: userId) { [weak self] newNotification in
            Task { @MainActor in
                self?.handleNewRealtimeNotification(newNotification)
            }
        }
    }
    
    private func handleNewRealtimeNotification(_ notif: DBNotification) {
        if !notifications.contains(where: { $0.notificationId == notif.notificationId }) {
            notifications.insert(notif, at: 0) // Most recent first
            if !notif.isRead {
                unreadCount += 1
            }
        }
    }
    
    /// Stops listening.
    public func stopPolling() {
        let channel = realtimeChannel
        Task {
            await channel?.unsubscribe()
        }
        realtimeChannel = nil
    }
    
    
    /// Fetches all notifications from Supabase for the current user.
    public func loadNotifications() async {
        guard let userId else { return }
        
        isLoading = notifications.isEmpty
        
        do {
            let fetched = try await NotificationService.shared.fetchNotifications(userId: userId)
            self.notifications = fetched
            self.unreadCount = fetched.filter { !$0.isRead }.count
            print("[NotificationVM] Loaded \(fetched.count) notifications (\(unreadCount) unread)")
        } catch {
            print("[NotificationVM] ❌ Failed to load notifications: \(error)")
        }
        
        isLoading = false
    }
    
    
    /// Marks a single notification as read.
    public func markRead(id: UUID) {
        guard let index = notifications.firstIndex(where: { $0.notificationId == id }) else { return }
        guard !notifications[index].isRead else { return }
        
        notifications[index].isRead = true
        unreadCount = max(0, unreadCount - 1)
        
        Task {
            do {
                try await NotificationService.shared.markAsRead(notificationId: id)
            } catch {
                print("[NotificationVM] ❌ Failed to mark notification as read: \(error.localizedDescription)")
            }
        }
    }
    
    /// Marks all notifications as read.
    public func markAllRead() {
        guard let userId else { return }
        
        for i in notifications.indices {
            notifications[i].isRead = true
        }
        unreadCount = 0
        
        Task {
            do {
                try await NotificationService.shared.markAllAsRead(userId: userId)
            } catch {
                print("[NotificationVM] ❌ Failed to mark all as read: \(error.localizedDescription)")
            }
        }
    }
    
    /// Deletes a notification.
    public func deleteNotification(id: UUID) {
        notifications.removeAll { $0.notificationId == id }
        unreadCount = notifications.filter { !$0.isRead }.count
        
        Task {
            do {
                try await NotificationService.shared.deleteNotification(notificationId: id)
            } catch {
                print("[NotificationVM] ❌ Failed to delete notification: \(error.localizedDescription)")
            }
        }
    }
    

}
