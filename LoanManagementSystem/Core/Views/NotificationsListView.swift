import SwiftUI

/// Reusable full-screen notification list view used by all user roles.
/// Displays real notifications from Supabase via NotificationViewModel.
struct NotificationsListView: View {
    @ObservedObject var viewModel: NotificationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
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
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                if viewModel.unreadCount > 0 {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                viewModel.markAllRead()
                            }
                        } label: {
                            Text("Mark All Read")
                                .font(.caption.weight(.semibold))
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.loadNotifications()
            }
            .lmsScreenBackground()
        }
    }
    
    // MARK: - Subviews
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .controlSize(.large)
            Text("Loading notifications…")
                .font(LMSFont.callout)
                .foregroundStyle(LMSColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyView: some View {
        ContentUnavailableView(
            "No Notifications",
            systemImage: "bell.slash",
            description: Text("You're all caught up! Notifications about loan updates, approvals, and actions will appear here.")
        )
    }
    
    private var notificationsList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                
                // Unread section
                let unread = viewModel.notifications.filter { !$0.isRead }
                if !unread.isEmpty {
                    sectionHeader("Unread", count: unread.count)
                    
                    VStack(spacing: 0) {
                        ForEach(unread, id: \.notificationId) { notification in
                            notificationRow(notification)
                            
                            if notification.notificationId != unread.last?.notificationId {
                                Divider()
                                    .padding(.leading, 72)
                            }
                        }
                    }
                    .lmsInsetGroupedCard()
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                    .padding(.bottom, LMSSpacing.lg)
                }
                
                // Read section
                let read = viewModel.notifications.filter { $0.isRead }
                if !read.isEmpty {
                    sectionHeader("Earlier", count: nil)
                    
                    VStack(spacing: 0) {
                        ForEach(read, id: \.notificationId) { notification in
                            notificationRow(notification)
                            
                            if notification.notificationId != read.last?.notificationId {
                                Divider()
                                    .padding(.leading, 72)
                            }
                        }
                    }
                    .lmsInsetGroupedCard()
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                    .padding(.bottom, LMSSpacing.lg)
                }
            }
            .padding(.top, LMSSpacing.md)
        }
    }
    
    private func sectionHeader(_ title: String, count: Int?) -> some View {
        HStack {
            Text(title)
                .font(LMSFont.subheadline.weight(.semibold))
                .foregroundStyle(LMSColors.textSecondary)
            
            if let count {
                Text("\(count)")
                    .font(LMSFont.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(LMSColors.actionBlue, in: Capsule())
            }
            
            Spacer()
        }
        .padding(.horizontal, LMSSpacing.screenHorizontal)
        .padding(.bottom, LMSSpacing.sm)
    }
    
    private func notificationRow(_ notification: DBNotification) -> some View {
        let lmsNotif = notification.toLMSNotification()
        
        return LMSNotificationRow(notification: lmsNotif)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.markRead(id: notification.notificationId)
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    withAnimation {
                        viewModel.deleteNotification(id: notification.notificationId)
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                
                if !notification.isRead {
                    Button {
                        withAnimation {
                            viewModel.markRead(id: notification.notificationId)
                        }
                    } label: {
                        Label("Read", systemImage: "envelope.open")
                    }
                    .tint(LMSColors.actionBlue)
                }
            }
    }
}
