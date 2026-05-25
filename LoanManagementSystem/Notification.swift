import Foundation
import SwiftUI

enum NotificationType: String, CaseIterable {
    case alert
    case message
    case payment
    case update
    
    var iconName: String {
        switch self {
        case .alert:
            return "exclamationmark.triangle.fill"
        case .message:
            return "envelope.fill"
        case .payment:
            return "dollarsign.circle.fill"
        case .update:
            return "arrow.triangle.2.circlepath.circle.fill"
        }
    }
    
    var tintColor: Color {
        switch self {
        case .alert:
            return .red
        case .message:
            return .blue
        case .payment:
            return .green
        case .update:
            return .orange
        }
    }
}

struct Notification: Identifiable, Equatable {
    let id: UUID
    let title: String
    let description: String
    let timestamp: Date
    let type: NotificationType
    var isRead: Bool
    
    init(id: UUID = UUID(), title: String, description: String, timestamp: Date = Date(), type: NotificationType, isRead: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.timestamp = timestamp
        self.type = type
        self.isRead = isRead
    }
}
