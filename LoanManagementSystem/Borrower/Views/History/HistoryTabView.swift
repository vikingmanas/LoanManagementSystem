import SwiftUI

struct HistoryTabView: View {
    @Bindable var viewModel: DashboardViewModel
    @State private var transactionFilter: TransactionType? = nil
    @State private var selectedBankAccountId: UUID? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                if !viewModel.bankAccounts.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {

                            let totalBalance = viewModel.bankAccounts.map(\.availableBalance).reduce(0, +)
                            let isAllSelected = selectedBankAccountId == nil

                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedBankAccountId = nil
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "square.stack.3d.up.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(isAllSelected ? .white : LMSColors.brandNavy)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("All Accounts")
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundStyle(isAllSelected ? .white.opacity(0.8) : LMSColors.brandNavy.opacity(0.6))

                                        Text(totalBalance.formattedAsINR())
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundStyle(isAllSelected ? .white : LMSColors.brandNavy)
                                    }
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(
                                    Group {
                                        if isAllSelected {
                                            LinearGradient(
                                                colors: [LMSColors.brandNavy, LMSColors.brandNavyLight],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        } else {
                                            LinearGradient(
                                                colors: [LMSColors.surface, LMSColors.surface],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        }
                                    }
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(isAllSelected ? Color.clear : LMSColors.separatorLight, lineWidth: 1)
                                )
                                .shadow(color: isAllSelected ? LMSColors.brandNavy.opacity(0.18) : Color.clear, radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)

                            ForEach(viewModel.bankAccounts) { account in
                                let isSelected = selectedBankAccountId == account.id
                                let signatureColor = getSignatureColor(for: account.accountType)

                                Button {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        selectedBankAccountId = account.id
                                    }
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: getAccountIconName(for: account.accountType))
                                            .font(.system(size: 16))
                                            .foregroundStyle(isSelected ? .white : signatureColor)

                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 4) {
                                                Text(account.bankName)
                                                    .font(.system(size: 11, weight: .bold))
                                                Text("••\(account.accountNumber.suffix(2))")
                                                    .font(.system(size: 9, design: .monospaced))
                                            }
                                            .foregroundStyle(isSelected ? .white.opacity(0.8) : LMSColors.brandNavy.opacity(0.6))

                                            Text(account.availableBalance.formattedAsINR())
                                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                                .foregroundStyle(isSelected ? .white : LMSColors.brandNavy)
                                        }
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(
                                        Group {
                                            if isSelected {
                                                LinearGradient(
                                                    colors: getGradientColors(for: account.accountType),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            } else {
                                                LinearGradient(
                                                    colors: [LMSColors.surface, LMSColors.surface],
                                                    startPoint: .top,
                                                    endPoint: .bottom
                                                )
                                            }
                                        }
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(isSelected ? Color.clear : LMSColors.separatorLight, lineWidth: 1)
                                    )
                                    .shadow(color: isSelected ? signatureColor.opacity(0.18) : Color.clear, radius: 8, x: 0, y: 4)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, LMSSpacing.screenHorizontal)
                        .padding(.vertical, 8)
                    }
                    .frame(height: 72)
                    .background(LMSColors.background)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                HStack(alignment: .center) {
                    Text("Recent Transactions")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.brandNavy)
                    Spacer()
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)
                .padding(.top, 16)
                .padding(.bottom, 8)
                .background(LMSColors.background)

                if let filter = transactionFilter {
                    HStack {
                        HStack(spacing: 6) {
                            Text(filter.rawValue)
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.blue)
                            
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                    transactionFilter = nil
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.blue.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.12), in: Capsule())
                        .padding(.horizontal, LMSSpacing.screenHorizontal)
                        .padding(.bottom, 8)
                        .transition(.scale.combined(with: .opacity))
                        
                        Spacer()
                    }
                    .background(LMSColors.background)
                }

                if viewModel.isLoading {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(0..<8) { _ in
                                TransactionRowSkeleton()
                                Divider().padding(.horizontal, 20)
                            }
                        }
                        .dashboardCardStyle()
                        .padding(.horizontal, LMSSpacing.screenHorizontal)
                        .padding(.bottom, 24)
                    }
                } else {
                    let filtered = viewModel.transactions.filter { tx in
                        if let selectedBankAccountId = selectedBankAccountId {
                            if tx.bankAccountId != selectedBankAccountId {
                                return false
                            }
                        }
                        if let filter = transactionFilter {
                            if tx.type != filter {
                                return false
                            }
                        }
                        return true
                    }

                    if filtered.isEmpty {
                        ContentUnavailableView(
                            "No transactions found",
                            systemImage: "list.bullet.rectangle.portrait",
                            description: Text("Try changing your filter settings to view other transaction types.")
                        )
                    } else {
                        ScrollView {
                            let dateGroups = groupTransactionsByDate(filtered)

                            LazyVStack(alignment: .leading, spacing: 16) {
                                ForEach(dateGroups) { group in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(formatDateHeader(group.id))
                                            .font(.system(size: 13, weight: .bold, design: .rounded))
                                            .foregroundStyle(LMSColors.brandNavy.opacity(0.45))
                                            .padding(.horizontal, LMSSpacing.screenHorizontal + 4)
                                            .padding(.top, 4)

                                        VStack(spacing: 0) {
                                            ForEach(group.transactions) { tx in
                                                TransactionRowView(transaction: tx)
                                                if tx.id != group.transactions.last?.id {
                                                    Divider().padding(.horizontal, 20)
                                                }
                                            }
                                        }
                                        .dashboardCardStyle()
                                        .padding(.horizontal, LMSSpacing.screenHorizontal)
                                    }
                                }
                            }
                            .padding(.bottom, 24)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .lmsScreenBackground()
            .refreshable {
                await viewModel.fetchDashboardData()
            }
            .task {
                if viewModel.isLoading {
                    await viewModel.fetchDashboardData()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("All Transactions") { transactionFilter = nil }
                        Divider()
                        Button("EMI Payments") { transactionFilter = .emiPayment }
                        Button("Credits") { transactionFilter = .credit }
                        Button("Penalties") { transactionFilter = .penalty }
                        Button("Refunds") { transactionFilter = .refund }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.system(size: 18, weight: .regular))
                            .foregroundStyle(LMSColors.brandNavy)
                            .padding(4)
                    }
                }
            }
        }
    }

    private func groupTransactionsByDate(_ txs: [Transaction]) -> [DateGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: txs) { tx in
            calendar.startOfDay(for: tx.date)
        }
        return grouped.map { (date, list) in
            let sortedTxs = list.sorted { $0.date > $1.date }
            return DateGroup(id: date, transactions: sortedTxs)
        }
        .sorted { $0.id > $1.id }
    }

    private func formatDateHeader(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMMM yyyy"
            return formatter.string(from: date)
        }
    }

    private func getGradientColors(for type: DashboardAccountType?) -> [Color] {
        guard let type = type else {
            return [LMSColors.brandNavy, LMSColors.brandNavyLight]
        }
        switch type {
        case .savings:
            return [LMSColors.emerald, LMSColors.emeraldDark]
        case .overdraft:
            return [LMSColors.amber, Color(hex: "F4511E")]
        case .current:
            return [LMSColors.actionBlue, Color(hex: "5E35B1")]
        }
    }

    private func getSignatureColor(for type: DashboardAccountType?) -> Color {
        guard let type = type else {
            return LMSColors.brandNavy
        }
        switch type {
        case .savings:    return LMSColors.emerald
        case .overdraft:  return LMSColors.amber
        case .current:    return LMSColors.actionBlue
        }
    }

    private func getAccountIconName(for type: DashboardAccountType) -> String {
        switch type {
        case .savings:    return "building.columns.fill"
        case .overdraft:  return "creditcard.fill"
        case .current:    return "checkmark.circle.fill"
        }
    }
}

struct DateGroup: Identifiable {
    let id: Date
    let transactions: [Transaction]
}
