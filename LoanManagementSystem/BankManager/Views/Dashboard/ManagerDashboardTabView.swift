import SwiftUI


struct ManagerDashboardTabView: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    var onSelectApplicant: (ManagerApplicant) -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: LMSSpacing.xl) {


                BranchOverviewCard(overview: viewModel.branchOverview)
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                    .padding(.top, LMSSpacing.md)


                ManagerKPICardsView(kpis: viewModel.kpis)


                ManagerApprovalQueueView(
                    viewModel: viewModel,
                    onViewAll: {
                        viewModel.navigateToApplicantsWithPending()
                    },
                    onSelectApplicant: onSelectApplicant
                )


                VStack(alignment: .leading, spacing: LMSSpacing.md) {
                    Text("Loan Analytics")
                        .font(.system(.footnote, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textSecondary)
                        .padding(.horizontal, LMSSpacing.screenHorizontal)

                    ManagerAnalyticsView()
                }


                ManagerRiskPanelView(viewModel: viewModel)


                OfficerPerformanceSection(officers: viewModel.officers)


                ManagerReportsView()


                NotificationsSummarySection(
                    notifications: Array(viewModel.notifications.prefix(3)),
                    unreadCount: viewModel.unreadNotificationCount
                )

                Spacer()
                    .frame(height: LMSSpacing.xxxl)
            }
        }
        .background(LMSColors.background)
        .refreshable {
            await viewModel.refreshData()
        }
    }
}


private struct BranchOverviewCard: View {
    let overview: BranchOverview

    var body: some View {
        VStack(spacing: LMSSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(overview.name)
                        .font(.system(.headline, design: .rounded))
                        .foregroundStyle(LMSColors.textPrimary)
                    Text("\(overview.code) · \(overview.region)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                }
                Spacer()
                LMSStatusPill(text: overview.auditRating, style: .success, icon: "shield.checkmark.fill")
            }

            HStack(spacing: LMSSpacing.sm) {
                BranchMetricPill(icon: "person.2.fill", value: "\(overview.staffCount)", label: "Staff")
                BranchMetricPill(icon: "doc.text.fill", value: "\(overview.activeLoanCount)", label: "Active")
                BranchMetricPill(icon: "indianrupeesign.circle.fill", value: CurrencyFormatter.shared.format(overview.totalDisbursed), label: "Disbursed")
            }
        }
        .padding(LMSSpacing.lg)
        .background(LMSColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
}

private struct BranchMetricPill: View {
    let icon: String
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(LMSColors.brandNavy)
            Text(value)
                .font(.system(.caption2, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(LMSColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LMSSpacing.sm)
        .background(LMSColors.brandNavy.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous))
    }
}


private struct OfficerPerformanceSection: View {
    let officers: [ManagerOfficer]

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("Officer Performance")
                .font(.system(.footnote, design: .rounded).bold())
                .foregroundStyle(LMSColors.textSecondary)
                .padding(.horizontal, LMSSpacing.screenHorizontal)

            VStack(spacing: 0) {
                ForEach(officers.indices, id: \.self) { index in
                    OfficerPerformanceRow(officer: officers[index])
                    if index < officers.count - 1 {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(LMSColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
            .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
            .padding(.horizontal, LMSSpacing.screenHorizontal)
        }
    }
}

private struct OfficerPerformanceRow: View {
    let officer: ManagerOfficer

    var body: some View {
        HStack(spacing: LMSSpacing.md) {

            ZStack {
                Circle()
                    .fill(LMSColors.brandNavy.opacity(0.10))
                    .frame(width: 40, height: 40)
                Text(officer.initials)
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundStyle(LMSColors.brandNavy)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(officer.name)
                    .font(.system(.callout, design: .rounded).weight(.semibold))
                    .foregroundStyle(LMSColors.textPrimary)
                Text(officer.role)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundStyle(LMSColors.amber)
                        .font(.system(size: 10))
                    Text(String(format: "%.1f", officer.rating))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.textPrimary)
                }

                HStack(spacing: 6) {
                    Text("\(officer.activeCases)/\(officer.maxCapacity)")
                        .font(.system(.caption2, design: .rounded).weight(.medium))
                        .foregroundStyle(LMSColors.textSecondary)

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(officer.capacityColor.opacity(0.20))
                                .frame(height: 4)
                            Capsule()
                                .fill(officer.capacityColor)
                                .frame(width: geo.size.width * officer.capacityPercentage, height: 4)
                        }
                    }
                    .frame(width: 32, height: 4)
                }
            }
        }
        .padding(.vertical, LMSSpacing.md)
        .padding(.horizontal, LMSSpacing.lg)
    }
}


private struct NotificationsSummarySection: View {
    let notifications: [ManagerNotificationItem]
    let unreadCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            HStack {
                Text("Recent Notifications")
                    .font(.system(.footnote, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textSecondary)

                Spacer()

                if unreadCount > 0 {
                    Text("\(unreadCount) unread")
                        .font(.system(.caption2, design: .rounded).bold())
                        .foregroundStyle(LMSColors.coral)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(LMSColors.coral.opacity(0.10))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)

            VStack(spacing: 0) {
                ForEach(notifications) { notification in
                    HStack(alignment: .top, spacing: LMSSpacing.md) {
                        Image(systemName: notification.type.icon)
                            .foregroundStyle(notification.type.color)
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(notification.title)
                                .font(.system(.caption, design: .rounded).weight(notification.isRead ? .medium : .bold))
                                .foregroundStyle(LMSColors.textPrimary)
                            Text(notification.message)
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(LMSColors.textSecondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        if !notification.isRead {
                            Circle()
                                .fill(LMSColors.actionBlue)
                                .frame(width: 6, height: 6)
                                .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, LMSSpacing.sm)
                    .padding(.horizontal, LMSSpacing.lg)

                    if notification.id != notifications.last?.id {
                        Divider().padding(.leading, 54)
                    }
                }
            }
            .background(LMSColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
            .shadow(color: .black.opacity(0.03), radius: 6, x: 0, y: 2)
            .padding(.horizontal, LMSSpacing.screenHorizontal)
        }
    }
}

#Preview {
    ManagerDashboardTabView(
        viewModel: PreviewSupport.managerViewModel,
        onSelectApplicant: { _ in }
    )
    .previewManagerEnvironment()
}

