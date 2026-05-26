import SwiftUI

struct NotificationCardView: View {
    let notification: AppNotification
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(notification.type.tintColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: notification.type.iconName)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(notification.type.tintColor)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    Text(notification.title)
                        .font(.system(.subheadline, design: .default))
                        .fontWeight(notification.isRead ? .regular : .semibold)
                        .foregroundColor(notification.isRead ? .secondary : .primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(timeAgoDisplay(for: notification.timestamp))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                
                Text(notification.description)
                    .font(.subheadline)
                    .foregroundColor(notification.isRead ? .secondary : .primary)
                    .opacity(notification.isRead ? 0.8 : 1.0)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Unread Indicator
            if !notification.isRead {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 10, height: 10)
                    .padding(.top, 6)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(notification.isRead ? Color(UIColor.secondarySystemGroupedBackground) : Color(UIColor.systemGroupedBackground).opacity(0.8))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(notification.isRead ? Color.clear : Color.blue.opacity(0.3), lineWidth: 1)
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: notification.isRead)
    }
    
    // Helper to format date
    private func timeAgoDisplay(for date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    VStack(spacing: 16) {
        NotificationCardView(notification: AppNotification(
            title: "EMI Payment Successful",
            description: "Your EMI of $450.00 for Home Loan has been successfully processed.",
            timestamp: Date().addingTimeInterval(-3600),
            type: .payment,
            isRead: false
        ))
        
        NotificationCardView(notification: AppNotification(
            title: "Document Verification Pending",
            description: "Please upload your recent bank statement to proceed with your personal loan application.",
            timestamp: Date().addingTimeInterval(-86400),
            type: .alert,
            isRead: true
        ))
    }
    .padding()
    .background(Color(UIColor.systemBackground))
    .preferredColorScheme(.dark)
}
