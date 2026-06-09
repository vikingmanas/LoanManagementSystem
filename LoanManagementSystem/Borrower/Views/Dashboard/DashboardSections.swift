import SwiftUI

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

struct ProfileCompletionCardSection: View {
    let percentage: Int
    let missingItems: [String]
    let onContinue: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
            DashboardSectionHeader(
                title: "Profile"
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

struct LoanPortfolioSummarySection: View {
    @Bindable var viewModel: DashboardViewModel
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
            DashboardSectionHeader(
                title: "Loan Portfolio"
            )

            if viewModel.isLoading {
                RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
                    .fill(LMSColors.surface)
                    .frame(height: 168)
                    .shimmer(active: true)
            } else {
                Button(action: onTap) {
                    LoanPortfolioSummaryCard(viewModel: viewModel)
                }
                .buttonStyle(DashboardPressableStyle())
            }
        }
        .padding(.horizontal, LMSSpacing.screenHorizontal)
    }
}

struct LoanPortfolioSummaryCard: View {
    @Bindable var viewModel: DashboardViewModel

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

struct ActiveLoanAccountsSection: View {
    @Bindable var viewModel: DashboardViewModel
    let onLoanTap: (DashboardLoanAccount) -> Void
    let onApplyLoan: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
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
    @Bindable var viewModel: DashboardViewModel
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

struct UpcomingPaymentSection: View {
    @Bindable var viewModel: DashboardViewModel
    var onPayNow: () -> Void
    var onViewAll: () -> Void
    var onSchedule: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
            DashboardSectionHeader(
                title: "Upcoming Payment",
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

struct DashboardQuickActionsSection: View {
    var onPayEMI: () -> Void
    var onStatement: () -> Void
    var onSupport: () -> Void
    var onCalculator: () -> Void
    var onTopUp: () -> Void

    private var actions: [DashboardQuickAction] {
        [
            DashboardQuickAction(title: "Pay EMI", subtitle: "Due payments", icon: "indianrupeesign", tint: LMSColors.emerald, action: onPayEMI),
            DashboardQuickAction(title: "Calculator", subtitle: "Plan EMI", icon: "plus.forwardslash.minus", tint: LMSColors.brandNavy, action: onCalculator),
            DashboardQuickAction(title: "Statements", subtitle: "Download", icon: "doc.text.fill", tint: LMSColors.actionBlue, action: onStatement),
            DashboardQuickAction(title: "Support", subtitle: "Get help", icon: "headphones", tint: LMSColors.amber, action: onSupport)
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
            DashboardSectionHeader(title: "Quick Actions")
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

enum DashboardTransactionFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case credits = "Credits"
    case debits = "Debits"
    case penalties = "Penalties"
    case failed = "Failed"
    case emi = "EMI"
    case byAccount = "By Account"

    var id: String { rawValue }
}

enum DashboardTransactionSort: String, CaseIterable, Identifiable {
    case newest = "Newest"
    case oldest = "Oldest"
    case highestAmount = "Highest"

    var id: String { rawValue }
}

struct TransactionHistorySection: View {
    let transactions: [Transaction]
    let accounts: [BankAccount]
    let onViewAll: () -> Void

    private var recentTransactions: [Transaction] {
        transactions.sorted { $0.date > $1.date }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
            DashboardSectionHeader(
                title: "Transaction History",
                actionTitle: transactions.isEmpty ? nil : "View All",
                action: transactions.isEmpty ? nil : onViewAll
            )

            DashboardSectionCard {
                if recentTransactions.isEmpty {
                    DashboardEmptyState(
                        icon: "list.bullet.rectangle.portrait",
                        title: "No transactions yet",
                        message: "Your account activity will appear here."
                    )
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(recentTransactions.prefix(5).enumerated()), id: \.element.id) { index, transaction in
                            TransactionHistoryRow(
                                transaction: transaction,
                                account: account(for: transaction)
                            )
                                .padding(.vertical, LMSSpacing.sm)
                            if index < min(4, recentTransactions.count - 1) {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, LMSSpacing.screenHorizontal)
    }

    private func account(for transaction: Transaction) -> BankAccount? {
        guard let bankAccountId = transaction.bankAccountId else { return nil }
        return accounts.first(where: { $0.id == bankAccountId })
    }
}

private struct AccountFilterSheet: View {
    let accounts: [BankAccount]
    @Binding var selectedAccountID: UUID?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        selectedAccountID = nil
                        dismiss()
                    } label: {
                        accountRow(title: "All accounts", subtitle: "Show every transaction", isSelected: selectedAccountID == nil)
                    }

                    ForEach(accounts) { account in
                        Button {
                            selectedAccountID = account.id
                            dismiss()
                        } label: {
                            accountRow(
                                title: account.bankName.isEmpty ? account.accountType.rawValue : account.bankName,
                                subtitle: "\(account.accountType.rawValue) •••• \(account.accountNumber.suffix(4))",
                                isSelected: selectedAccountID == account.id
                            )
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Filter by Account")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func accountRow(title: String, subtitle: String, isSelected: Bool) -> some View {
        HStack(spacing: LMSSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(LMSFont.callout.weight(.semibold))
                    .foregroundStyle(LMSColors.textPrimary)
                Text(subtitle)
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(LMSColors.emerald)
            }
        }
    }
}

struct TransactionHistoryFullScreen: View {
    @Bindable var viewModel: DashboardViewModel
    @State private var searchText = ""
    @State private var selectedFilter: DashboardTransactionFilter = .all
    @State private var selectedSort: DashboardTransactionSort = .newest
    @State private var selectedAccountID: UUID?
    @State private var showingAccountSelector = false

    private var filteredTransactions: [Transaction] {
        var result = viewModel.recentTransactions

        switch selectedFilter {
        case .all:
            break
        case .credits:
            result = result.filter { !$0.type.isDebit }
        case .debits:
            result = result.filter { $0.type.isDebit }
        case .penalties:
            result = result.filter { $0.type == .penalty }
        case .failed:
            result = result.filter { $0.type == .failedDebit }
        case .emi:
            result = result.filter { $0.type == .emiPayment }
        case .byAccount:
            if let selectedAccountID {
                result = result.filter { $0.bankAccountId == selectedAccountID }
            }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter { transaction in
                transaction.displayTitle.localizedCaseInsensitiveContains(query) ||
                transaction.descriptionText.localizedCaseInsensitiveContains(query) ||
                transaction.referenceNo.localizedCaseInsensitiveContains(query)
            }
        }

        switch selectedSort {
        case .newest:
            return result.sorted { $0.date > $1.date }
        case .oldest:
            return result.sorted { $0.date < $1.date }
        case .highestAmount:
            return result.sorted { $0.amount > $1.amount }
        }
    }

    private var groupedTransactions: [(title: String, items: [Transaction])] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: Date())?.start ?? today

        let groups: [(String, (Transaction) -> Bool)] = [
            ("Today", { calendar.isDate($0.date, inSameDayAs: today) }),
            ("Yesterday", { calendar.isDate($0.date, inSameDayAs: yesterday) }),
            ("This Week", { $0.date >= weekStart && !calendar.isDate($0.date, inSameDayAs: today) && !calendar.isDate($0.date, inSameDayAs: yesterday) }),
            ("Older", { $0.date < weekStart })
        ]

        return groups.compactMap { title, matcher in
            let items = filteredTransactions.filter(matcher)
            return items.isEmpty ? nil : (title, items)
        }
    }

    var body: some View {
        List {
            Section {
                filterRow
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }

            if filteredTransactions.isEmpty {
                Section {
                    DashboardEmptyState(
                        icon: "list.bullet.rectangle.portrait",
                        title: "No transactions yet",
                        message: "Your account activity will appear here."
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            } else {
                ForEach(groupedTransactions, id: \.title) { group in
                    Section(group.title) {
                        ForEach(group.items) { transaction in
                            NavigationLink {
                                TransactionDetailScreen(
                                    transaction: transaction,
                                    account: account(for: transaction)
                                )
                            } label: {
                                TransactionHistoryRow(
                                    transaction: transaction,
                                    account: account(for: transaction)
                                )
                            }
                            .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Transaction History")
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .tabBar)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search transactions")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Picker("Sort", selection: $selectedSort) {
                        ForEach(DashboardTransactionSort.allCases) { sort in
                            Text(sort.rawValue).tag(sort)
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.arrow.down.circle")
                }
            }
        }
        .refreshable {
            await viewModel.fetchDashboardData()
        }
        .accessibleSheet(isPresented: $showingAccountSelector) {
            AccountFilterSheet(
                accounts: viewModel.bankAccounts,
                selectedAccountID: $selectedAccountID
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.visible)
        }
    }

    private var filterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LMSSpacing.sm) {
                ForEach(DashboardTransactionFilter.allCases) { filter in
                    Button {
                        if filter == .byAccount {
                            selectedFilter = filter
                            showingAccountSelector = true
                        } else {
                            selectedFilter = filter
                        }
                    } label: {
                        Text(filterTitle(filter))
                            .font(LMSFont.caption.weight(.semibold))
                            .foregroundStyle(selectedFilter == filter ? .white : LMSColors.textPrimary)
                            .padding(.horizontal, LMSSpacing.md)
                            .padding(.vertical, LMSSpacing.sm)
                            .background(selectedFilter == filter ? LMSColors.brandNavy : LMSColors.surface, in: Capsule())
                            .overlay(
                                Capsule()
                                    .stroke(selectedFilter == filter ? Color.clear : LMSColors.separatorLight, lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)
            .padding(.vertical, LMSSpacing.xs)
        }
    }

    private func filterTitle(_ filter: DashboardTransactionFilter) -> String {
        if filter == .byAccount,
           let selected = viewModel.bankAccounts.first(where: { $0.id == selectedAccountID }) {
            return "Account \(selected.accountNumber.suffix(4))"
        }
        return filter.rawValue
    }

    private func account(for transaction: Transaction) -> BankAccount? {
        guard let bankAccountId = transaction.bankAccountId else { return nil }
        return viewModel.bankAccounts.first(where: { $0.id == bankAccountId })
    }
}

private struct TransactionHistoryRow: View {
    let transaction: Transaction
    let account: BankAccount?

    private var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM • h:mm a"
        return formatter.string(from: transaction.date)
    }

    var body: some View {
        HStack(alignment: .top, spacing: LMSSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                    .fill(transaction.type.tint.opacity(0.12))
                    .frame(width: 46, height: 46)
                Image(systemName: transaction.type.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(transaction.type.tint)
                    .symbolRenderingMode(.hierarchical)
            }
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(transaction.type.tint)
                    .frame(width: 9, height: 9)
                    .overlay(Circle().stroke(LMSColors.surfaceElevated, lineWidth: 2))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.displayTitle)
                    .font(LMSFont.subheadline.weight(.semibold))
                    .foregroundStyle(LMSColors.textPrimary)
                    .lineLimit(1)

                Text(transaction.descriptionText)
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)
                    .lineLimit(2)

                Text(accountReference)
                    .font(LMSFont.caption2)
                    .foregroundStyle(LMSColors.textTertiary)

                Text(formattedDateTime)
                    .font(LMSFont.caption2)
                    .foregroundStyle(LMSColors.textTertiary)
            }

            Spacer(minLength: LMSSpacing.sm)

            VStack(alignment: .trailing, spacing: 5) {
                Text(transaction.signedAmountText)
                    .font(LMSFont.subheadline.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(transaction.type.amountColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(transaction.type.statusText)
                    .font(LMSFont.caption2.weight(.bold))
                    .foregroundStyle(transaction.type.tint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(transaction.type.tint.opacity(0.10), in: Capsule())
            }
        }
        .contentShape(Rectangle())
    }

    private var accountReference: String {
        guard let account else {
            return "Ref \(transaction.referenceNo)"
        }
        return "\(account.bankName.isEmpty ? account.accountType.rawValue : account.bankName) •••• \(account.accountNumber.suffix(4))"
    }
}

private struct TransactionDetailScreen: View {
    let transaction: Transaction
    let account: BankAccount?
    @State private var showReceiptAlert = false

    var body: some View {
        List {
            Section {
                VStack(spacing: LMSSpacing.md) {
                    Image(systemName: transaction.type.iconName)
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(transaction.type.tint)
                        .frame(width: 64, height: 64)
                        .background(transaction.type.tint.opacity(0.12), in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))

                    Text(transaction.signedAmountText)
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(transaction.type.amountColor)

                    Text(transaction.type.statusText)
                        .font(LMSFont.caption.weight(.bold))
                        .foregroundStyle(transaction.type.tint)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(transaction.type.tint.opacity(0.10), in: Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, LMSSpacing.lg)
            }

            Section("Transaction Details") {
                LabeledContent("Transaction ID", value: String(transaction.id.uuidString.prefix(8)).uppercased())
                LabeledContent("Status", value: transaction.type.statusText)
                LabeledContent("Date & Time", value: transaction.date.formatted(date: .abbreviated, time: .shortened))
                LabeledContent("Reference", value: transaction.referenceNo)
                LabeledContent("Account", value: accountReference)
                LabeledContent("Loan Association", value: transaction.descriptionText)
            }

            Section("Amount Breakdown") {
                LabeledContent(transaction.type.isDebit ? "Debit Amount" : "Credit Amount", value: transaction.amount.formattedAsINR())
                LabeledContent("Fees", value: transaction.type == .penalty ? "Included" : "₹0")
                LabeledContent("Net Amount", value: transaction.amount.formattedAsINR())
            }

            Section("Notes") {
                Text(transaction.descriptionText)
                    .font(LMSFont.footnote)
                    .foregroundStyle(LMSColors.textSecondary)
            }

            Section {
                Button {
                    showReceiptAlert = true
                } label: {
                    Label("Download Receipt", systemImage: "square.and.arrow.down")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Transaction")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .alert("Receipt Ready", isPresented: $showReceiptAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("Receipt download will be available once document export is connected.")
        }
    }

    private var accountReference: String {
        guard let account else { return "Linked account" }
        return "\(account.bankName.isEmpty ? account.accountType.rawValue : account.bankName) •••• \(account.accountNumber.suffix(4))"
    }
}

private extension Transaction {
    var displayTitle: String {
        switch type {
        case .emiPayment:
            return title.localizedCaseInsensitiveContains("failed") ? "Auto-debit failed" : "EMI paid"
        case .credit:
            return title.localizedCaseInsensitiveContains("top-up") ? "Loan account credited" : "Loan disbursed"
        case .penalty:
            return "Late penalty"
        case .refund:
            return "Refund processed"
        case .failedDebit:
            return "Auto-debit failed"
        }
    }

    var descriptionText: String {
        switch type {
        case .emiPayment:
            return title.localizedCaseInsensitiveContains("failed")
                ? "Auto-debit could not be completed. Please retry payment."
                : title
        case .credit:
            return title
        case .penalty:
            return title.isEmpty ? "Penalty charged on overdue EMI" : title
        case .refund:
            return title.isEmpty ? "Refund processed to linked account" : title
        case .failedDebit:
            return title.isEmpty ? "Auto-debit could not be completed. Please retry payment." : title
        }
    }

    var signedAmountText: String {
        "\(type.isDebit ? "-" : "+") \(amount.formattedAsINR())"
    }
}

private extension TransactionType {
    var iconName: String {
        switch self {
        case .emiPayment: return "indianrupeesign.circle.fill"
        case .credit: return "arrow.down.circle.fill"
        case .penalty: return "exclamationmark.triangle.fill"
        case .refund: return "arrow.uturn.left.circle.fill"
        case .failedDebit: return "exclamationmark.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .emiPayment: return LMSColors.brandNavy
        case .credit: return LMSColors.emerald
        case .penalty: return LMSColors.amber
        case .refund: return LMSColors.actionBlue
        case .failedDebit: return LMSColors.amber
        }
    }

    var amountColor: Color {
        isDebit ? LMSColors.coral : LMSColors.emerald
    }

    var statusText: String {
        switch self {
        case .emiPayment: return "Debited"
        case .credit: return "Credited"
        case .penalty: return "Charged"
        case .refund: return "Returned"
        case .failedDebit: return "Failed"
        }
    }
}

struct DashboardNotificationsSection: View {
    let notifications: [LMSNotification]
    var onViewAll: () -> Void
    var onNotificationTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
            DashboardSectionHeader(
                title: "Notifications",
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
