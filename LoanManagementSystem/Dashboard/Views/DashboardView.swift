//
//  DashboardView.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 19/05/26.
//

import SwiftUI

// MARK: - Navigation Destinations
public enum DashboardRoute: Hashable {
    case loanDetails(LoanAccount)
    case bankDetails(BankAccount)
    case insuranceDetails
    case allTransactions
    case allPendingEMIs
    case schemeDetails(GovernmentScheme)
}

public struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var navigationPath = NavigationPath()
    
    // Quick Actions Sheets
    @State private var showingQuickPaySheet = false
    @State private var showingStatementSheet = false
    @State private var showingForeclosureSheet = false
    @State private var showingSupportSheet = false
    @State private var showingTopUpSheet = false
    
    // Transaction Filter State
    @State private var transactionFilter: TransactionType? = nil
    @State private var showingFilterMenu = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // 1. TOP NAVIGATION BAR
                    TopNavigationBarSection(viewModel: viewModel)
                        .padding(.top, 8)
                    
                    // 2. PORTFOLIO CARDS
                    PortfolioCardsSection(viewModel: viewModel) { route in
                        navigationPath.append(route)
                    }
                    
                    // 2b. ACCOUNT HEALTH BANNER (Moved here below Portfolio)
                    AccountHealthBanner(viewModel: viewModel)
                        .padding(.vertical, 4)
                    
                    // 3. QUICK ACTION CHIPS
                    QuickActionChipsSection(
                        onPay: { showingQuickPaySheet = true },
                        onStatement: { showingStatementSheet = true },
                        onForeclosure: { showingForeclosureSheet = true },
                        onSupport: { showingSupportSheet = true },
                        onTopUp: { showingTopUpSheet = true }
                    )
                    
                    // 4. EMI TRACKER SECTION
                    EMITrackerView(viewModel: viewModel) {
                        viewModel.payNextEMI()
                    } onViewAllPendingTap: {
                        navigationPath.append(DashboardRoute.allPendingEMIs)
                    }
                    
                    // 5. TRANSACTION HISTORY SECTION
                    TransactionsHistorySection(viewModel: viewModel, filter: $transactionFilter) {
                        navigationPath.append(DashboardRoute.allTransactions)
                    }
                    
                    // 6. GOVERNMENT SCHEMES SECTION
                    GovernmentSchemesSection(viewModel: viewModel) { scheme in
                        navigationPath.append(DashboardRoute.schemeDetails(scheme))
                    }
                    
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemBackground))
            .refreshable {
                await viewModel.fetchDashboardData()
            }
            .task {
                await viewModel.fetchDashboardData()
            }
            .navigationDestination(for: DashboardRoute.self) { route in
                switch route {
                case .loanDetails(let loan):
                    LoanDetailsView(loan: loan)
                case .bankDetails(let bank):
                    BankDetailsView(bank: bank, viewModel: viewModel)
                case .insuranceDetails:
                    InsuranceDetailsView()
                case .allTransactions:
                    AllTransactionsView(viewModel: viewModel)
                case .allPendingEMIs:
                    AllPendingEMIsView(viewModel: viewModel)
                case .schemeDetails(let scheme):
                    SchemeDetailsView(scheme: scheme)
                }
            }
            // Sheets for Quick Actions
            .sheet(isPresented: $showingQuickPaySheet) {
                QuickPaySheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingStatementSheet) {
                StatementSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingForeclosureSheet) {
                ForeclosureSheet()
            }
            .sheet(isPresented: $showingSupportSheet) {
                SupportSheet()
            }
            .sheet(isPresented: $showingTopUpSheet) {
                TopUpSheet(viewModel: viewModel)
            }
        }
    }
}

struct TopNavigationBarSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Row
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Audit")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(Color(.label))
                    
                }
                
                Spacer()
                
                HStack(spacing: 14) {
                    // Notification Bell Button
                    Button {
                        // Action
                    } label: {
                        ZStack {
                            Image(systemName: "bell.badge.fill")
                                .font(.system(size: 20))
                                .foregroundColor(Color.brandNavy)
                                .symbolRenderingMode(.multicolor)
                        }
                    }
                    .frame(width: 44, height: 44) // HIG Target
                    .buttonStyle(.plain)
                    
                    // User Avatar placeholder
                    Button {
                        // Profile Action
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.brandNavy)
                                .frame(width: 40, height: 40)
                            
                            Text("RK")
                                .font(.system(.body, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

// MARK: - Section 1b: Health Banner Component (Positioned below Portfolio)
struct AccountHealthBanner: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var pulseBanner = false
    
    var body: some View {
        Button {
            // Interactive demonstration toggle
            viewModel.toggleBalanceMockMode()
        } label: {
            HStack {
                if viewModel.isLoading {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 48)
                        .shimmer(active: true)
                } else if viewModel.isLowBalance {
                    HStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Low Balance! Top up ₹\(Int(viewModel.balanceDeficit)) before 5 Jun to avoid penalty")
                            .font(.system(.callout, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                            .minimumScaleFactor(0.9)
                            .scaleEffect(pulseBanner ? 1.01 : 0.99)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.brandCoral)
                    .cornerRadius(14)
                    .shadow(color: Color.brandCoral.opacity(0.3), radius: 8, x: 0, y: 4)
                    .onAppear {
                        withAnimation(Animation.easeInOut(duration: 0.85).repeatForever(autoreverses: true)) {
                            pulseBanner = true
                        }
                    }
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Account balance is sufficient for your next EMI")
                            .font(.system(.callout, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.9)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.brandEmerald)
                    .cornerRadius(14)
                    .shadow(color: Color.brandEmerald.opacity(0.2), radius: 6, x: 0, y: 3)
                }
            }
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Account balance health notification banner. Tap to toggle mock balance state.")
    }
}

// MARK: - Section 2: Portfolio
struct PortfolioCardsSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    let onNavigate: (DashboardRoute) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("My Portfolio")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.label))
                
                Spacer()
                
                Button("See All") {
                    // Action
                }
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .frame(minWidth: 44, minHeight: 44) // HIG
            }
            .padding(.horizontal, 20)
            
            PortfolioCarouselView(
                viewModel: viewModel,
                onNavigateToLoan: { loan in
                    onNavigate(.loanDetails(loan))
                },
                onNavigateToBank: { bank in
                    onNavigate(.bankDetails(bank))
                },
                onNavigateToInsurance: {
                    onNavigate(.insuranceDetails)
                },
                onTransferTap: { bank in
                    onNavigate(.bankDetails(bank))
                }
            )
        }
    }
}

// MARK: - Section 3: Quick Action Chips
struct QuickActionChipsSection: View {
    let onPay: () -> Void
    let onStatement: () -> Void
    let onForeclosure: () -> Void
    let onSupport: () -> Void
    let onTopUp: () -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                QuickActionChip(icon: "arrow.up.circle.fill", title: "Pay EMI", action: onPay)
                QuickActionChip(icon: "doc.text.fill", title: "Statement", action: onStatement)
                QuickActionChip(icon: "waveform.path.ecg", title: "Foreclosure", action: onForeclosure)
                QuickActionChip(icon: "person.fill.questionmark", title: "Support", action: onSupport)
                QuickActionChip(icon: "plus.circle.fill", title: "Top-Up", action: onTopUp)
            }
            .padding(.horizontal, 20)
        }
    }
}

struct QuickActionChip: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.brandNavy)
                
                Text(title)
                    .font(.system(.callout, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.label))
            }
            .padding(.horizontal, 16)
            .frame(height: 44) // Tap target compliance
            .background(Color(.systemGray6).opacity(0.8))
            .cornerRadius(22)
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color(.separator), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section 5: Transactions
struct TransactionsHistorySection: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var filter: TransactionType?
    let onViewAll: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.label))
                
                Spacer()
                
                // Filter dropdown
                Menu {
                    Button("All Transactions") { filter = nil }
                    Divider()
                    Button("EMI Payments") { filter = .emiPayment }
                    Button("Credits") { filter = .credit }
                    Button("Penalties") { filter = .penalty }
                    Button("Refunds") { filter = .refund }
                } label: {
                    HStack(spacing: 4) {
                        Text(filter == nil ? "Filter" : filter!.rawValue)
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                if viewModel.isLoading {
                    ForEach(0..<4) { _ in
                        TransactionRowSkeleton()
                        Divider().padding(.horizontal, 20)
                    }
                } else {
                    let filtered = viewModel.transactions.filter { tx in
                        guard let filter = filter else { return true }
                        return tx.type == filter
                    }
                    
                    if filtered.isEmpty {
                        // iOS 17 Empty State
                        ContentUnavailableView("No transactions found", systemImage: "list.bullet.rectangle.portrait", description: Text("Try changing your filter settings to view other transaction types."))
                            .frame(height: 160)
                    } else {
                        ForEach(filtered.prefix(5)) { tx in
                            TransactionRowView(transaction: tx)
                            if tx.id != filtered.prefix(5).last?.id {
                                Divider()
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                }
            }
            .background(Color(.secondarySystemBackground).opacity(0.4))
            .cornerRadius(20)
            .padding(.horizontal, 20)
            
            if !viewModel.isLoading && viewModel.transactions.count > 5 {
                Button(action: onViewAll) {
                    HStack(spacing: 6) {
                        Spacer()
                        Image(systemName: "list.bullet.rectangle")
                            .font(.system(size: 14))
                        Text("View All Transactions")
                            .font(.system(.callout, design: .rounded))
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .foregroundColor(.blue)
                    .frame(height: 44)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Section 6: Govt Schemes
struct GovernmentSchemesSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    let onSchemeTap: (GovernmentScheme) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Active Schemes & Offers")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.label))
                
                Spacer()
                
                Button("Explore All") {
                    // Action
                }
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .frame(minWidth: 44, minHeight: 44)
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if viewModel.isLoading {
                        ForEach(0..<3) { _ in
                            SchemeCardSkeleton()
                        }
                    } else {
                        ForEach(viewModel.schemes) { scheme in
                            Button {
                                onSchemeTap(scheme)
                            } label: {
                                SchemeCardView(scheme: scheme) {
                                    onSchemeTap(scheme)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .contentMargins(.horizontal, 20, for: .scrollContent)
        }
    }
}

// MARK: - Quick Action Action Sheets & Details Views (Compilable Stubs)

struct QuickPaySheet: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let nextEMI = viewModel.nextEMI {
                    Image(systemName: "indianrupeesign.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.brandNavy)
                    
                    Text("Confirm EMI Payment")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(spacing: 12) {
                        HStack {
                            Text("EMI Amount")
                            Spacer()
                            Text(nextEMI.amount.formattedAsINR()).fontWeight(.bold)
                        }
                        HStack {
                            Text("Account Number")
                            Spacer()
                            Text(viewModel.bankAccount.accountNumber)
                        }
                        HStack {
                            Text("Current Balance")
                            Spacer()
                            Text(viewModel.bankAccount.availableBalance.formattedAsINR())
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    
                    Button {
                        viewModel.payNextEMI()
                        dismiss()
                    } label: {
                        Text("Pay Now")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.brandNavy)
                            .cornerRadius(14)
                    }
                    .disabled(viewModel.bankAccount.availableBalance < nextEMI.amount)
                    
                } else {
                    AllCaughtUpCard()
                }
            }
            .padding(24)
            .navigationTitle("Pay EMI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct StatementSheet: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List(viewModel.transactions) { tx in
                HStack {
                    VStack(alignment: .leading) {
                        Text(tx.title).font(.headline)
                        Text(tx.date.formattedAsDDMMMYYYY()).font(.subheadline).foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(tx.amount.formattedAsINR()).fontWeight(.bold)
                }
            }
            .navigationTitle("Account Statement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct ForeclosureSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.brandCoral)
                
                Text("Request Foreclosure")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Foreclosing your home loan will trigger a 1% processing fee of the remaining outstanding amount. Do you wish to schedule a callback with our credit advisor?")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding()
                
                Button {
                    dismiss()
                } label: {
                    Text("Schedule Callback")
                        .foregroundColor(.white)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.brandNavy)
                        .cornerRadius(14)
                }
            }
            .padding(24)
            .navigationTitle("Foreclosure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct SupportSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Contact Channels")) {
                    Label("Call Support: 1800-BANK-LOAN", systemImage: "phone.fill")
                    Label("Email: support@brandbank.com", systemImage: "envelope.fill")
                    Label("Live chat assistant", systemImage: "message.fill")
                }
                Section(header: Text("FAQs")) {
                    Text("How to reschedule EMIs?")
                    Text("What if an EMI auto-debit fails?")
                    Text("How to update bank accounts?")
                }
            }
            .navigationTitle("Support Desk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct TopUpSheet: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) var dismiss
    @State private var topUpAmount = 10000.0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.brandEmerald)
                
                Text("Top-Up Account Balance")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Slider(value: $topUpAmount, in: 5000...50000, step: 5000)
                
                Text("Amount to Add: \(topUpAmount.formattedAsINR())")
                    .font(.headline)
                    .foregroundColor(.brandEmerald)
                
                Button {
                    viewModel.topUpAccount(amount: topUpAmount)
                    dismiss()
                } label: {
                    Text("Confirm Deposit")
                        .foregroundColor(.white)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.brandEmerald)
                        .cornerRadius(14)
                }
            }
            .padding(24)
            .navigationTitle("Top-Up Balance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Premium Detail Views

struct LoanDetailsView: View {
    let loan: LoanAccount
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header block
                ZStack {
                    LinearGradient(colors: [Color.brandNavy, Color(hex: "#2E3B84")], startPoint: .topLeading, endPoint: .bottomTrailing)
                    
                    VStack(spacing: 12) {
                        Text(loan.loanType.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(loan.principalOutstanding.formattedAsINR())
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Outstanding Principal")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.vertical, 32)
                }
                .cornerRadius(20)
                .padding(.horizontal, 20)
                
                // Detailed Stats Grid
                VStack(alignment: .leading, spacing: 16) {
                    Text("LOAN METRICS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    Group {
                        DetailMetricRow(label: "Account Number", value: loan.accountNumber)
                        DetailMetricRow(label: "Monthly EMI", value: loan.totalEMI.formattedAsINR())
                        DetailMetricRow(label: "Next EMI Date", value: loan.nextEMIDate.formattedAsDDMMMYYYY())
                        DetailMetricRow(label: "Total Tenure", value: "\(loan.totalTenureMonths) Months")
                        DetailMetricRow(label: "Remaining Tenure", value: "\(loan.tenureRemainingMonths) Months")
                        DetailMetricRow(label: "Rate of Interest", value: "8.65% p.a. (Floating)")
                    }
                }
                .padding(20)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Home Loan Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BankDetailsView: View {
    let bank: BankAccount
    @ObservedObject var viewModel: DashboardViewModel
    @State private var depositAmountStr = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Card
                ZStack {
                    LinearGradient(colors: [Color.brandEmerald, Color(hex: "#009E86")], startPoint: .topLeading, endPoint: .bottomTrailing)
                    
                    VStack(spacing: 12) {
                        Text(bank.accountType.rawValue.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(bank.availableBalance.formattedAsINR())
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Available balance")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.vertical, 32)
                }
                .cornerRadius(20)
                .padding(.horizontal, 20)
                
                // Top-up Section inside details
                VStack(alignment: .leading, spacing: 16) {
                    Text("ADD FUNDS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 12) {
                        Button("+ ₹5,000") { viewModel.topUpAccount(amount: 5000) }
                            .buttonStyle(.borderedProminent)
                            .tint(.brandEmerald)
                        
                        Button("+ ₹10,000") { viewModel.topUpAccount(amount: 10000) }
                            .buttonStyle(.borderedProminent)
                            .tint(.brandEmerald)
                        
                        Button("+ ₹20,000") { viewModel.topUpAccount(amount: 20000) }
                            .buttonStyle(.borderedProminent)
                            .tint(.brandEmerald)
                    }
                }
                .padding(20)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
                .padding(.horizontal, 20)
            }
        }
        .navigationTitle("Bank Account")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InsuranceDetailsView: View {
    var body: some View {
        List {
            Section(header: Text("Coverage Overview")) {
                DetailMetricRow(label: "Policy Status", value: "Active")
                DetailMetricRow(label: "Coverage Amount", value: "₹ 15,00,000")
                DetailMetricRow(label: "Coverage Type", value: "Loan Protection Plan")
            }
            Section(header: Text("Premium details")) {
                DetailMetricRow(label: "Monthly Premium", value: "₹850")
                DetailMetricRow(label: "Renewal Date", value: "12 Jan 2026")
            }
        }
        .navigationTitle("Loan Protection Plan")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AllTransactionsView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        List(viewModel.transactions) { tx in
            HStack {
                VStack(alignment: .leading) {
                    Text(tx.title).font(.headline)
                    Text(tx.date.formattedAsDDMMMYYYY()).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Text(tx.amount.formattedAsINR())
                    .fontWeight(.bold)
                    .foregroundColor(tx.type == .credit || tx.type == .refund ? .brandEmerald : .brandCoral)
            }
        }
        .navigationTitle("All Transactions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AllPendingEMIsView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        List(viewModel.pendingEMIs.filter { $0.status != .paid }) { emi in
            HStack {
                VStack(alignment: .leading) {
                    Text(emi.loanType).font(.headline)
                    Text("Due Date: \(emi.dueDate.formattedAsDDMMMYYYY())").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                Text(emi.amount.formattedAsINR()).fontWeight(.bold)
            }
        }
        .navigationTitle("All Pending EMIs")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SchemeDetailsView: View {
    let scheme: GovernmentScheme
    @State private var appSubmitted = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(scheme.title)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Category: \(scheme.category.rawValue)")
                    .foregroundColor(.secondary)
                
                Text(scheme.description)
                    .font(.body)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Benefit Summary").font(.headline)
                    Text(scheme.benefitSummary).foregroundColor(.brandEmerald).fontWeight(.bold)
                }
                
                Divider()
                
                if appSubmitted {
                    Text("🎉 Application Submitted Successfully! Our relationship manager will contact you in 24 hours.")
                        .foregroundColor(.brandEmerald)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    Button {
                        appSubmitted = true
                    } label: {
                        Text("Apply Now")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.brandNavy)
                            .cornerRadius(14)
                    }
                }
            }
            .padding(24)
        }
        .navigationTitle("Scheme Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DetailMetricRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(.body, design: .rounded))
                .foregroundColor(Color(.secondaryLabel))
            Spacer()
            Text(value)
                .font(.system(.body, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(Color(.label))
        }
        .padding(.vertical, 4)
    }
}
