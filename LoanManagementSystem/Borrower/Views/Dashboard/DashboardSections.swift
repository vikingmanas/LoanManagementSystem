import SwiftUI

// MARK: - Scroll Header (replaces "Dashboard" large title)

struct DashboardScrollHeader: View {
    let greeting: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.xs) {
            Text(greeting)
                .font(LMSFont.largeTitle)
                .foregroundStyle(LMSColors.textPrimary)
                .accessibilityAddTraits(.isHeader)

            Text(subtitle)
                .font(LMSFont.subheadline)
                .foregroundStyle(LMSColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LMSSpacing.screenHorizontal)
    }
}

// MARK: - Profile Completion

struct ProfileCompletionCardSection: View {
    let percentage: Int
    let missingItems: [String]
    let onContinue: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
            DashboardSectionHeader(
                title: "Profile",
                subtitle: "Complete verification to unlock all services"
            )

            DashboardSectionCard {
                VStack(alignment: .leading, spacing: LMSSpacing.lg) {
                    HStack(alignment: .center, spacing: LMSSpacing.md) {
                        ZStack {
                            Circle()
                                .stroke(LMSColors.separatorLight, lineWidth: 6)
                            Circle()
                                .trim(from: 0, to: CGFloat(percentage) / 100)
                                .stroke(LMSColors.brandNavy, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Text("\(percentage)%")
                                .font(LMSFont.footnote.weight(.bold))
                                .foregroundStyle(LMSColors.textPrimary)
                        }
                        .frame(width: 56, height: 56)

                        VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                            Text("Complete Your Profile")
                                .font(LMSFont.headline)
                                .foregroundStyle(LMSColors.textPrimary)
                            Text("\(percentage)% completed")
                                .font(LMSFont.footnote)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                        Spacer(minLength: 0)

                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(LMSColors.textSecondary)
                                .frame(width: 28, height: 28)
                                .background(LMSColors.surfaceElevated, in: Circle())
                                .overlay(
                                    Circle()
                                        .stroke(LMSColors.separatorLight.opacity(0.7), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Dismiss profile completion card")
                    }

                    if !missingItems.isEmpty {
                        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                            Text("Still needed")
                                .font(LMSFont.caption.weight(.semibold))
                                .foregroundStyle(LMSColors.textSecondary)
                            ForEach(missingItems.prefix(3), id: \.self) { item in
                                Label(item, systemImage: "circle")
                                    .font(LMSFont.caption)
                                    .foregroundStyle(LMSColors.textSecondary)
                                    .labelStyle(.titleAndIcon)
                            }
                        }
                    }

                    DashboardFilledButton(title: "Continue Verification", action: onContinue)
                }
            }
        }
        .padding(.horizontal, LMSSpacing.screenHorizontal)
    }
}

// MARK: - Loan Portfolio Summary

struct LoanPortfolioSummarySection: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            DashboardSectionHeader(
                title: "Loan Portfolio",
                subtitle: "Your financial overview"
            )

            if viewModel.isLoading {
                RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
                    .fill(LMSColors.surface)
                    .frame(height: 168)
                    .shimmer(active: true)
            } else {
                LoanPortfolioSummaryCard(viewModel: viewModel)
            }
        }
        .padding(.horizontal, LMSSpacing.screenHorizontal)
    }
}

struct LoanPortfolioSummaryCard: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [LMSColors.brandNavy, LMSColors.brandNavyLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: LMSSpacing.lg) {
                HStack {
                    Label("Portfolio Summary", systemImage: "chart.pie.fill")
                        .font(LMSFont.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    Text("\(viewModel.loanAccounts.count) active")
                        .font(LMSFont.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.white.opacity(0.16), in: Capsule())
                }

                HStack(spacing: LMSSpacing.md) {
                    portfolioMetric(title: "Outstanding", value: viewModel.totalOutstanding.formattedAsINR())
                    portfolioMetric(title: "Total Paid", value: viewModel.totalRepaid.formattedAsINR())
                }

                HStack(spacing: LMSSpacing.md) {
                    portfolioMetric(
                        title: "Next EMI",
                        value: viewModel.nextEMI.map { $0.dueDate.formattedAsDDMMMYYYY() } ?? "—"
                    )
                    portfolioMetric(
                        title: "EMI Amount",
                        value: viewModel.nextDueAmount > 0 ? viewModel.nextDueAmount.formattedAsINR() : "—"
                    )
                }

                ProgressView(value: viewModel.repaidFraction)
                    .tint(LMSColors.emerald)
                    .background(Color.white.opacity(0.2))
                    .clipShape(Capsule())
            }
            .padding(LMSSpacing.lg)
        }
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
        .shadow(color: LMSColors.brandNavy.opacity(0.22), radius: 12, x: 0, y: 6)
    }

    private func portfolioMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(LMSFont.caption2)
                .foregroundStyle(.white.opacity(0.65))
            Text(value)
                .font(LMSFont.footnote.weight(.bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Active Loan Accounts

struct ActiveLoanAccountsSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    let onLoanTap: (DashboardLoanAccount) -> Void
    let onApplyLoan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            DashboardSectionHeader(
                title: "Active Loan Accounts"
            )

            if viewModel.isLoading {
                RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
                    .fill(LMSColors.surface)
                    .frame(height: 200)
                    .shimmer(active: true)
            } else if viewModel.loanAccounts.isEmpty {
                DashboardSectionCard {
                    DashboardEmptyState(
                        icon: "building.columns.fill",
                        title: "No Active Loan Accounts",
                        message: "Your approved loans will appear here automatically.",
                        actionTitle: "Apply for a Loan",
                        action: onApplyLoan
                    )
                }
            } else {
                ActiveLoansCarousel(
                    viewModel: viewModel,
                    loans: viewModel.loanAccounts,
                    onLoanTap: onLoanTap
                )
            }
        }
        .padding(.horizontal, LMSSpacing.screenHorizontal)
    }
}

struct ActiveLoansCarousel: View {
    @ObservedObject var viewModel: DashboardViewModel
    let loans: [DashboardLoanAccount]
    let onLoanTap: (DashboardLoanAccount) -> Void
    @State private var selectedIndex = 0

    var body: some View {
        VStack(spacing: LMSSpacing.sm) {
            TabView(selection: $selectedIndex) {
                ForEach(Array(loans.enumerated()), id: \.element.id) { index, loan in
                    ActiveLoanAccountCard(
                        loan: loan,
                        currentBalance: viewModel.currentAccountBalance(for: loan)
                    ) {
                        onLoanTap(loan)
                    }
                    .tag(index)
                    .padding(.horizontal, 2)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(height: 142)

            if loans.count > 1 {
                HStack(spacing: 6) {
                    ForEach(0..<loans.count, id: \.self) { index in
                        Capsule()
                            .fill(index == selectedIndex ? LMSColors.brandNavy : LMSColors.separator)
                            .frame(width: index == selectedIndex ? 18 : 6, height: 6)
                            .animation(.easeInOut(duration: 0.2), value: selectedIndex)
                    }
                }
            }
        }
    }
}

struct ActiveLoanAccountCard: View {
    let loan: DashboardLoanAccount
    let currentBalance: Double
    let onTap: () -> Void

    private var statusText: String { loan.principalOutstanding <= 0 ? "Closed" : "Active" }
    private var statusColor: Color { loan.principalOutstanding <= 0 ? LMSColors.textTertiary : LMSColors.emerald }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: LMSSpacing.md) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(loan.loanType)
                            .font(LMSFont.headline)
                            .foregroundStyle(LMSColors.textPrimary)
                        Text(maskAccount(loan.accountNumber))
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                    Spacer()
                    Text(statusText)
                        .font(LMSFont.caption2.weight(.bold))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(statusColor.opacity(0.12), in: Capsule())
                }

                HStack {
                    loanDetailColumn(title: "Current Balance", value: currentBalance.formattedAsINR())
                    Spacer()
                    loanDetailColumn(title: "EMI", value: loan.totalEMI.formattedAsINR())
                    Spacer()
                    loanDetailColumn(title: "Next Due", value: loan.nextEMIDate.formattedAsDDMMMYYYY())
                }
            }
            .padding(LMSSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
                    .stroke(LMSColors.separatorLight, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(DashboardPressableStyle())
    }

    private func loanDetailColumn(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(LMSFont.caption2)
                .foregroundStyle(LMSColors.textSecondary)
            Text(value)
                .font(LMSFont.footnote.weight(.semibold))
                .foregroundStyle(LMSColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }

    private func maskAccount(_ number: String) -> String {
        let suffix = number.suffix(4)
        return "Account •••• \(suffix.isEmpty ? "0000" : suffix)"
    }
}

// MARK: - Upcoming Payment

struct UpcomingPaymentSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    var onPayNow: () -> Void
    var onViewAll: () -> Void
    var onSchedule: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            DashboardSectionHeader(
                title: "Upcoming Payment",
                subtitle: "Your next repayment",
                actionTitle: viewModel.pendingEMIs.count > 1 ? "View All" : nil,
                action: viewModel.pendingEMIs.count > 1 ? onViewAll : nil
            )

            if viewModel.isLoading {
                RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
                    .fill(LMSColors.surface)
                    .frame(height: 180)
                    .shimmer(active: true)
            } else if let nextEMI = viewModel.nextEMI {
                DashboardSectionCard {
                    VStack(alignment: .leading, spacing: LMSSpacing.lg) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                                Text(viewModel.nextDueStatus == .overdue ? "Overdue" : "Due Soon")
                                    .font(LMSFont.caption.weight(.bold))
                                    .foregroundStyle(viewModel.nextDueStatus == .overdue ? LMSColors.coral : LMSColors.amber)
                                Text(viewModel.nextDueAmount.formattedAsINR())
                                    .font(.system(.title, design: .rounded).weight(.bold))
                                    .foregroundStyle(LMSColors.textPrimary)
                                    .monospacedDigit()
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Due Date")
                                    .font(LMSFont.caption2)
                                    .foregroundStyle(LMSColors.textSecondary)
                                Text(nextEMI.dueDate.formattedAsDDMMMYYYY())
                                    .font(LMSFont.footnote.weight(.semibold))
                                    .foregroundStyle(LMSColors.textPrimary)
                            }
                        }

                        Label(viewModel.nextDueLoanLabel, systemImage: "doc.text.fill")
                            .font(LMSFont.footnote)
                            .foregroundStyle(LMSColors.textSecondary)

                        if viewModel.isLowBalance {
                            Label("Low balance — top up before due date", systemImage: "exclamationmark.triangle.fill")
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.coral)
                        }

                        DashboardFilledButton(
                            title: "Pay Now",
                            tint: viewModel.nextDueStatus == .overdue ? LMSColors.coral : LMSColors.brandNavy,
                            action: onPayNow
                        )
                    }
                    .contentShape(RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
                    .onTapGesture {
                        onSchedule()
                    }
                }
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("Opens repayment schedule")
            } else {
                DashboardSectionCard {
                    DashboardEmptyState(
                        icon: "checkmark.seal.fill",
                        title: "No Upcoming Payments",
                        message: "You're all caught up for this billing cycle."
                    )
                }
            }
        }
        .padding(.horizontal, LMSSpacing.screenHorizontal)
    }
}

// MARK: - Quick Actions

struct DashboardQuickActionsSection: View {
    var onApplyLoan: () -> Void
    var onPayEMI: () -> Void
    var onStatement: () -> Void
    var onSupport: () -> Void
    var onCalculator: () -> Void
    var onForeclosure: () -> Void
    var onTopUp: () -> Void

    private var actions: [DashboardQuickAction] {
        [
            DashboardQuickAction(title: "Pay EMI", subtitle: "Due payments", icon: "indianrupeesign", tint: LMSColors.emerald, action: onPayEMI),
            DashboardQuickAction(title: "Top Up", subtitle: "Add funds", icon: "plus.circle.fill", tint: LMSColors.coral, action: onTopUp),
            DashboardQuickAction(title: "Calculator", subtitle: "Plan EMI", icon: "function", tint: LMSColors.brandNavy, action: onCalculator),
            DashboardQuickAction(title: "Apply Loan", subtitle: "New request", icon: "doc.badge.plus", tint: LMSColors.teal, action: onApplyLoan),
            DashboardQuickAction(title: "Statements", subtitle: "Download", icon: "doc.text.fill", tint: LMSColors.actionBlue, action: onStatement),
            DashboardQuickAction(title: "Support", subtitle: "Get help", icon: "headphones", tint: LMSColors.amber, action: onSupport),
            DashboardQuickAction(title: "Foreclosure", subtitle: "Close your loan early", icon: "lock.open.fill", tint: Color.orange, action: onForeclosure)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
            DashboardSectionHeader(title: "Quick Actions", subtitle: "Fast banking shortcuts")
                .padding(.horizontal, LMSSpacing.screenHorizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LMSSpacing.sm) {
                    ForEach(actions) { action in
                        DashboardQuickActionTile(action: action)
                    }
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)
                .padding(.vertical, 2)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
        }
    }
}

struct DashboardQuickAction: Identifiable {
    let title: String
    let subtitle: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var id: String { title }
}

struct DashboardQuickActionTile: View {
    let action: DashboardQuickAction

    var body: some View {
        Button {
            HapticsManager.triggerImpact(style: .light)
            action.action()
        } label: {
            VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(action.tint)
                    .frame(width: 42, height: 42)
                    .background(
                        action.tint.opacity(0.14),
                        in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                    )

                Spacer(minLength: 0)

                VStack(alignment: .leading, spacing: 3) {
                    Text(action.title)
                        .font(LMSFont.caption.weight(.bold))
                        .foregroundStyle(LMSColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)

                    Text(action.subtitle)
                        .font(LMSFont.caption2)
                        .foregroundStyle(LMSColors.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .padding(12)
            .frame(width: 124, height: 108, alignment: .leading)
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                    .stroke(LMSColors.separatorLight, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(DashboardPressableStyle())
    }

    private var icon: String {
        action.icon
    }
}

// MARK: - Notifications

struct DashboardNotificationsSection: View {
    let notifications: [LMSNotification]
    var onViewAll: () -> Void
    var onNotificationTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            DashboardSectionHeader(
                title: "Notifications",
                subtitle: "Important alerts",
                actionTitle: notifications.isEmpty ? nil : "View All",
                action: notifications.isEmpty ? nil : onViewAll
            )

            DashboardSectionCard {
                if notifications.isEmpty {
                    DashboardEmptyState(
                        icon: "bell.slash",
                        title: "No Notifications",
                        message: "EMI reminders and approval updates will appear here."
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(notifications.prefix(3).enumerated()), id: \.element.id) { index, notification in
                            Button(action: onNotificationTap) {
                                LMSNotificationRow(notification: notification)
                            }
                            .buttonStyle(.plain)
                            if index < min(2, notifications.count - 1) {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, LMSSpacing.screenHorizontal)
    }
}
