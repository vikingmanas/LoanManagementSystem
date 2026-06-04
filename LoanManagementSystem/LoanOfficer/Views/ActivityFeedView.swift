import SwiftUI

struct ActivityFeedView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onActionTriggered: (ActivityActionType, ActivityFeedItem) -> Void
    var onViewAllPressed: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Text("Borrower Activity")
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)

                Spacer()

                if viewModel.unreadActivityCount > 0 {
                    Button(action: {
                        HapticsManager.triggerImpact(style: .medium)
                        viewModel.markAllActivityRead()
                    }) {
                        Text("Mark All Read")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(LMSColors.actionBlue)
                    }
                    .accessibilityLabel("Mark all notifications as read")
                }
            }
            .padding(.horizontal, 16)


            VStack(spacing: 0) {
                if viewModel.activityFeed.isEmpty {
                    ContentUnavailableView(
                        "No New Activities",
                        systemImage: "bell.slash.fill",
                        description: Text("All borrower queries and documents are processed.")
                    )
                    .frame(height: 180)
                    .background(LMSColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {


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

                    .frame(height: CGFloat(min(viewModel.activityFeed.count, 8) * 88))


                    Button(action: {
                        HapticsManager.triggerImpact(style: .light)
                        onViewAllPressed()
                    }) {
                        HStack {
                            Spacer()
                            Text("View All Activity (\(viewModel.activityFeed.count))")
                                .font(.system(.callout, design: .rounded).weight(.bold))
                                .foregroundStyle(LMSColors.actionBlue)
                            Spacer()
                        }
                        .padding(.vertical, 14)
                        .background(LMSColors.textPrimary.opacity(0.02))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityLabel("View all activity feeds")
                }
            }
            .background(LMSColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 3)
        }
    }
}


