import SwiftUI

/// Reusable full-screen notification list view used by all user roles.
/// Displays real notifications from Supabase via NotificationViewModel.
struct NotificationsListView: View {
    @Bindable var viewModel: NotificationViewModel
    @Environment(\.dismiss) private var dismiss
    
    /// Determines if the view is being pushed into a NavigationStack or presented as a sheet.
    /// If true, it omits its own NavigationStack and the 'Close' button.
    var isPushed: Bool = false
    
    var body: some View {
        if isPushed {
            notificationContent
        } else {
            NavigationStack {
                notificationContent
            }
        }
    }
    
    private var notificationContent: some View {
        Group {
            if viewModel.isLoading && viewModel.notifications.isEmpty {
                loadingView
            } else if viewModel.notifications.isEmpty {
                emptyView
            } else {
                notificationsList
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isPushed {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            
            if viewModel.unreadCount > 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticsManager.triggerImpact(style: .medium)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            viewModel.markAllRead()
                        }
                    } label: {
                        Text("Mark All Read")
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
        .refreshable {
            await viewModel.loadNotifications()
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Loading notifications…")
                .font(.system(.callout, design: .rounded))
                .foregroundStyle(LMSColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .lmsScreenBackground()
    }
    
    private var emptyView: some View {
        ContentUnavailableView(
            "No Notifications",
            systemImage: "bell.slash",
            description: Text("You're all caught up! Notifications about loan updates, approvals, and actions will appear here.")
        )
        .lmsScreenBackground()
    }
    
    private var notificationsList: some View {
        List {
            // Unread section
            let unread = viewModel.notifications.filter { !$0.isRead }
            if !unread.isEmpty {
                Section {
                    ForEach(unread, id: \.notificationId) { notification in
                        notificationRow(notification)
                    }
                } header: {
                    HStack {
                        Text("Unread")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundStyle(LMSColors.textPrimary)
                            .textCase(nil)
                        
                        Text("\(unread.count)")
                            .font(.system(.caption2, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(LMSColors.actionBlue, in: Capsule())
                    }
                    .padding(.vertical, 4)
                }
            }
            
            // Read section
            let read = viewModel.notifications.filter { $0.isRead }
            if !read.isEmpty {
                Section {
                    ForEach(read, id: \.notificationId) { notification in
                        notificationRow(notification)
                    }
                } header: {
                    Text("Earlier")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundStyle(LMSColors.textPrimary)
                        .textCase(nil)
                        .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.plain)
    }
    
    private func notificationRow(_ notification: DBNotification) -> some View {
        let lmsNotif = notification.toLMSNotification()
        
        return LMSNotificationRow(notification: lmsNotif)
            .listRowInsets(EdgeInsets())
            .listRowBackground(notification.isRead ? Color.clear : LMSColors.actionBlue.opacity(0.03))
            .contentShape(Rectangle())
            .onTapGesture {
                HapticsManager.triggerImpact(style: .light)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.markRead(id: notification.notificationId)
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    HapticsManager.triggerImpact(style: .medium)
                    withAnimation {
                        viewModel.deleteNotification(id: notification.notificationId)
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                
                if !notification.isRead {
                    Button {
                        HapticsManager.triggerImpact(style: .light)
                        withAnimation {
                            viewModel.markRead(id: notification.notificationId)
                        }
                    } label: {
                        Label("Mark Read", systemImage: "envelope.open")
                    }
                    .tint(LMSColors.actionBlue)
                }
            }
    }
}
