import Foundation
import Combine

enum NotificationFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case unread = "Unread"
    case read = "Read"
    
    var id: String { self.rawValue }
}

class NotificationViewModel: ObservableObject {
    @Published var notifications: [AppNotification] = []
    @Published var selectedFilter: NotificationFilter = .all
    
    var filteredNotifications: [AppNotification] {
        switch selectedFilter {
        case .all:
            return notifications
        case .unread:
            return notifications.filter { !$0.isRead }
        case .read:
            return notifications.filter { $0.isRead }
        }
    }
    
    init() {
        loadMockData()
    }
    
    func toggleReadStatus(for notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead.toggle()
        }
    }
    
    func markAsRead(_ notification: AppNotification) {
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            if !notifications[index].isRead {
                notifications[index].isRead = true
            }
        }
    }
    
    func markAllAsRead() {
        for index in notifications.indices {
            notifications[index].isRead = true
        }
    }
    
    private func loadMockData() {
        notifications = [
            AppNotification(
                title: "EMI Payment Successful",
                description: "Your EMI of $450.00 for Home Loan has been successfully processed.",
                timestamp: Date().addingTimeInterval(-3600),
                type: .payment,
                isRead: false
            ),
            AppNotification(
                title: "Document Verification Pending",
                description: "Please upload your recent bank statement to proceed with your personal loan application.",
                timestamp: Date().addingTimeInterval(-86400),
                type: .alert,
                isRead: false
            ),
            AppNotification(
                title: "Interest Rate Update",
                description: "Good news! The interest rate for your auto loan has been reduced by 0.5%.",
                timestamp: Date().addingTimeInterval(-172800),
                type: .update,
                isRead: true
            ),
            AppNotification(
                title: "Welcome to Premium Features",
                description: "You now have access to premium financial insights and dedicated support.",
                timestamp: Date().addingTimeInterval(-259200),
                type: .message,
                isRead: true
            ),
            AppNotification(
                title: "Upcoming Payment Reminder",
                description: "Your next EMI of $320.00 is due in 3 days. Ensure sufficient balance.",
                timestamp: Date().addingTimeInterval(-43200),
                type: .payment,
                isRead: false
            )
        ]
    }
}
