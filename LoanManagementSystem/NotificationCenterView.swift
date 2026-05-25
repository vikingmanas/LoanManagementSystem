import SwiftUI

struct NotificationCenterView: View {
    @StateObject private var viewModel = NotificationViewModel()
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(UIColor.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filter Tabs
                    filterTabs
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(Color(UIColor.secondarySystemGroupedBackground))
                    
                    Divider()
                    
                    if viewModel.filteredNotifications.isEmpty {
                        emptyStateView
                    } else {
                        notificationList
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            viewModel.markAllAsRead()
                        }
                    }) {
                        Text("Mark all read")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    .disabled(viewModel.notifications.allSatisfy { $0.isRead })
                }
            }
        }
    }
    
    // MARK: - Components
    
    private var filterTabs: some View {
        HStack(spacing: 12) {
            ForEach(NotificationFilter.allCases) { filter in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.selectedFilter = filter
                    }
                }) {
                    Text(filter.rawValue)
                        .font(.subheadline)
                        .fontWeight(viewModel.selectedFilter == filter ? .semibold : .regular)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(viewModel.selectedFilter == filter ? Color.blue : Color.clear)
                        )
                        .foregroundColor(viewModel.selectedFilter == filter ? .white : .secondary)
                        .overlay(
                            Capsule()
                                .stroke(viewModel.selectedFilter == filter ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            Spacer()
        }
    }
    
    private var notificationList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredNotifications) { notification in
                    NotificationCardView(notification: notification)
                        .onTapGesture {
                            withAnimation {
                                viewModel.markAsRead(notification)
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                withAnimation {
                                    viewModel.toggleReadStatus(for: notification)
                                }
                            } label: {
                                Label(
                                    notification.isRead ? "Mark Unread" : "Mark Read",
                                    systemImage: notification.isRead ? "envelope.badge" : "envelope.open"
                                )
                            }
                            .tint(notification.isRead ? .blue : .gray)
                        }
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity),
                            removal: .scale(scale: 0.95).combined(with: .opacity)
                        ))
                }
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "bell.slash")
                .font(.system(size: 64))
                .foregroundColor(.secondary.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("All Caught Up!")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(viewModel.selectedFilter == .all ? "You don't have any notifications right now." : "You have no \(viewModel.selectedFilter.rawValue.lowercased()) notifications.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
    }
}

#Preview {
    NotificationCenterView()
        .preferredColorScheme(.dark)
}
