import SwiftUI

struct ActivityFeedView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onActionTriggered: (ActivityActionType, ActivityFeedItem) -> Void
    var onViewAllPressed: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Row
            HStack {
                Text("Borrower Activity")
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundColor(.primary)
                
                Spacer()
                
                if viewModel.unreadActivityCount > 0 {
                    Button(action: {
                        HapticsManager.triggerImpact(style: .medium)
                        viewModel.markAllActivityRead()
                    }) {
                        Text("Mark All Read")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundColor(AppTheme.actionBlue)
                    }
                    .accessibilityLabel("Mark all notifications as read")
                }
            }
            .padding(.horizontal, 16)
            
            // Feed Card
            VStack(spacing: 0) {
                if viewModel.activityFeed.isEmpty {
                    ContentUnavailableView(
                        "No New Activities",
                        systemImage: "bell.slash.fill",
                        description: Text("All borrower queries and documents are processed.")
                    )
                    .frame(height: 180)
                    .background(AppTheme.neutralSurface)
                    .cornerRadius(16)
                } else {
                    // We render a standard list with scroll disabled, giving it the card layout.
                    // This enables SwiftUI native swipeActions to run beautifully!
                    List {
                        ForEach(viewModel.activityFeed.prefix(8)) { item in
                            ActivityFeedRow(
                                item: item,
                                onMarkRead: {
                                    withAnimation {
                                        viewModel.markActivityRead(item.id)
                                    }
                                },
                                onDismiss: {
                                    withAnimation {
                                        viewModel.dismissActivity(item.id)
                                    }
                                },
                                onActionTapped: { action in
                                    onActionTriggered(action, item)
                                }
                            )
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.visible, edges: .bottom)
                        }
                    }
                    .listStyle(.plain)
                    .scrollDisabled(true)
                    // Set height based on prefix count * approximate height of a feed row
                    .frame(height: CGFloat(min(viewModel.activityFeed.count, 8) * 88))
                    
                    // Bottom Button
                    Button(action: {
                        HapticsManager.triggerImpact(style: .light)
                        onViewAllPressed()
                    }) {
                        HStack {
                            Spacer()
                            Text("View All Activity (\(viewModel.activityFeed.count))")
                                .font(.system(.callout, design: .rounded).weight(.bold))
                                .foregroundColor(AppTheme.actionBlue)
                            Spacer()
                        }
                        .padding(.vertical, 14)
                        .background(Color.primary.opacity(0.02))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("View all activity feeds")
                }
            }
            .background(AppTheme.neutralSurface)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 3)
        }
    }
}
