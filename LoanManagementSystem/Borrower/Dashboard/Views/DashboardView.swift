//
//  DashboardView.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 19/05/26.
//

import SwiftUI

// MARK: - Navigation Destinations
public enum DashboardRoute: Hashable {
    case loanDetails(DashboardLoanAccount)
    case bankDetails(BankAccount)
    case insuranceDetails
    case allTransactions
    case allPendingEMIs
    case schemeDetails(GovernmentScheme)
}

public struct DashboardView: View {
    @EnvironmentObject private var authManager: AuthManager
    @StateObject private var viewModel = DashboardViewModel()
    @State private var navigationPath = NavigationPath()
    
    // Quick Actions Sheets
    @State private var showingQuickPaySheet = false
    @State private var showingStatementSheet = false
    @State private var showingForeclosureSheet = false
    @State private var showingSupportSheet = false
    @State private var showingTopUpSheet = false
    @State private var showingProfileSheet = false
    
    // Transaction Filter State
    @State private var transactionFilter: TransactionType? = nil
    @State private var showingFilterMenu = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: LMSSpacing.sectionGap) {

                    // 1. GREETING (below large navigation title)
                    DashboardGreetingSection(
                        viewModel: viewModel,
                        authManager: authManager,
                        onProfileTap: { showingProfileSheet = true }
                    )
                    
                    // 1b. CUSTOMER INSIGHT & COMPLETION
                    if let profile = BorrowerProfileStore.shared.profile {
                        VStack(spacing: 12) {
                            if profile.profileCompletionPercentage < 100 {
                                ProfileCompletionBanner(percentage: profile.profileCompletionPercentage) {
                                    showingProfileSheet = true
                                }
                                .padding(.horizontal, LMSSpacing.screenHorizontal)
                            }
                            
                            if profile.hasExistingBankAccount, profile.existingCustomerId != nil {
                                CustomerInsightCardView(profile: profile)
                                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                            }
                        }
                        .padding(.bottom, 4)
                    }
                    
                    // 2. PORTFOLIO CARDS
                    PortfolioCardsSection(viewModel: viewModel) { route in
                        navigationPath.append(route)
                    }
                    
                    // 2b. ACCOUNT HEALTH BANNER (Moved here below Portfolio)
                    AccountHealthBanner(viewModel: viewModel)
                    
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
                .padding(.top, 8)
                .padding(.bottom, LMSSpacing.sectionGap)
            }
            .lmsScreenBackground()
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        // Notifications tab — surfaced via tab bar
                    } label: {
                        Image(systemName: "bell.badge.fill")
                            .symbolRenderingMode(.multicolor)
                    }
                    .accessibilityLabel("Notifications")

                    Button {
                        showingProfileSheet = true
                    } label: {
                        DashboardAvatar(initials: dashboardInitials(viewModel: viewModel, authManager: authManager))
                    }
                    .accessibilityLabel("Profile")
                }
            }
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
            .sheet(isPresented: $showingProfileSheet) {
                ProfileView()
            }
        }
    }
}

// MARK: - Greeting

private func dashboardFirstName(profileStore: BorrowerProfileStore, authManager: AuthManager) -> String {
    if let profileName = profileStore.profile?.fullName,
       !profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        return profileName.components(separatedBy: " ").first ?? "User"
    }
    return authManager.userDisplayName.components(separatedBy: " ").first ?? "User"
}

private func dashboardInitials(viewModel: DashboardViewModel, authManager: AuthManager) -> String {
    let profileStore = BorrowerProfileStore.shared
    if let profileName = profileStore.profile?.fullName,
       !profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        let parts = profileName.components(separatedBy: " ").filter { !$0.isEmpty }
        if parts.count >= 2 {
            return String(parts[0].prefix(1) + parts[1].prefix(1)).uppercased()
        } else if let first = parts.first {
            return String(first.prefix(2)).uppercased()
        }
    }
    return authManager.userInitials
}

struct DashboardGreetingSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    @ObservedObject var authManager: AuthManager
    @ObservedObject var profileStore: BorrowerProfileStore = .shared
    let onProfileTap: () -> Void

    var body: some View {
        LMSDashboardGreeting(
            firstName: dashboardFirstName(profileStore: profileStore, authManager: authManager),
            customerID: profileStore.profile?.id
        )
    }
}

struct DashboardAvatar: View {
    let initials: String

    var body: some View {
        Text(initials)
            .font(LMSFont.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 32, height: 32)
            .background(LMSColors.brandNavy, in: Circle())
    }
}

// MARK: - Section 1b: Health Banner Component (Positioned below Portfolio)
struct AccountHealthBanner: View {
    @ObservedObject var viewModel: DashboardViewModel

    var body: some View {
        Button {
            viewModel.toggleBalanceMockMode()
        } label: {
            Group {
                if viewModel.isLoading {
                    RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                        .fill(LMSColors.surfaceElevated)
                        .frame(height: 56)
                        .shimmer(active: true)
                } else if viewModel.isLowBalance {
                    LMSBanner(
                        message: "Low balance — top up ₹\(Int(viewModel.balanceDeficit)) before 5 Jun to avoid penalty",
                        style: .error,
                        icon: "exclamationmark.triangle.fill"
                    )
                } else {
                    LMSBanner(
                        message: "Account balance is sufficient for your next EMI",
                        style: .success,
                        icon: "checkmark.circle.fill"
                    )
                }
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)
        }
        .buttonStyle(DashboardPressableStyle())
        .accessibilityLabel("Account balance health. Tap to toggle demo state.")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Section 1c: Profile Completion Banner
struct ProfileCompletionBanner: View {
    let percentage: Int
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: CGFloat(percentage) / 100.0)
                        .stroke(LMSColors.emerald, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(percentage)%")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Complete Your Profile")
                        .font(.system(.subheadline, weight: .bold))
                        .foregroundColor(.white)
                    Text("Unlock all features by finishing setup")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding()
            .background(LMSColors.brandNavy)
            .cornerRadius(16)
            .padding(.horizontal, 20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section 2: Portfolio
struct PortfolioCardsSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    let onNavigate: (DashboardRoute) -> Void
    @State private var showingPlaceholderAlert = false
    
    var body: some View {
        SectionContainer(title: "My Portfolio", subtitle: "Loans, linked bank accounts, and protection cover") {
            Button("See All") {
                showingPlaceholderAlert = true
            }
            .font(.footnote.weight(.semibold))
            .foregroundColor(LMSColors.brandNavy)
            .frame(minWidth: 44, minHeight: 44)
            .alert("Coming Soon", isPresented: $showingPlaceholderAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This feature is currently under development.")
            }
        } content: {
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
        SectionContainer(title: "Quick Actions", subtitle: "Most-used account actions") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    QuickActionChip(icon: "arrow.up.circle.fill", title: "Pay EMI", action: onPay)
                    QuickActionChip(icon: "doc.text.fill", title: "Statement", action: onStatement)
                    QuickActionChip(icon: "waveform.path.ecg", title: "Foreclosure", action: onForeclosure)
                    QuickActionChip(icon: "person.fill.questionmark", title: "Support", action: onSupport)
                    QuickActionChip(icon: "plus.circle.fill", title: "Top-Up", action: onTopUp)
                }
                .padding(.horizontal, 1)
            }
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
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(LMSColors.brandNavy)
                
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(LMSColors.textPrimary)
            }
            .padding(.horizontal, 14)
            .frame(height: 42)
            .background(LMSColors.surfaceElevated, in: Capsule())
            .overlay(
                Capsule()
                    .stroke(Color(.separator).opacity(0.25), lineWidth: 0.5)
            )
        }
        .buttonStyle(DashboardPressableStyle())
    }
}

// MARK: - Section 5: Transactions
struct TransactionsHistorySection: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var filter: TransactionType?
    let onViewAll: () -> Void
    
    var body: some View {
        SectionContainer(title: "Recent Transactions", subtitle: "Repayments, penalties, credits and refunds") {
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
                        .font(.subheadline.weight(.medium))
                    Image(systemName: "chevron.down")
                        .font(.caption2.weight(.bold))
                }
                .foregroundColor(LMSColors.brandNavy)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(LMSColors.surfaceElevated, in: Capsule())
            }
        } content: {
            VStack(spacing: 12) {
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
                .padding(.horizontal, 1)
                .dashboardCardStyle()
                
                if !viewModel.isLoading && viewModel.transactions.count > 5 {
                    Button("View All Transactions", action: onViewAll)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(LMSColors.brandNavy)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .background(LMSColors.surfaceElevated, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .buttonStyle(DashboardPressableStyle())
                }
            }
        }
    }
}

// MARK: - Section 6: Govt Schemes
struct GovernmentSchemesSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    let onSchemeTap: (GovernmentScheme) -> Void
    @State private var showingPlaceholderAlert = false
    
    var body: some View {
        SectionContainer(title: "Active Schemes & Offers", subtitle: "Government + partner-backed opportunities") {
            Button("Explore All") {
                showingPlaceholderAlert = true
            }
            .font(.footnote.weight(.semibold))
            .foregroundColor(LMSColors.brandNavy)
            .frame(minWidth: 44, minHeight: 44)
            .alert("Coming Soon", isPresented: $showingPlaceholderAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This feature is currently under development.")
            }
        } content: {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
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
                            .buttonStyle(DashboardPressableStyle())
                        }
                    }
                }
            }
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
                        .foregroundColor(LMSColors.brandNavy)
                    
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
                    .background(LMSColors.surfaceElevated)
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
                            .background(LMSColors.brandNavy)
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
                        Text(tx.date.formattedAsDDMMMYYYY()).font(.subheadline).foregroundColor(LMSColors.textSecondary)
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
    @State private var showingToast = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(LMSColors.coral)
                
                Text("Request Foreclosure")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Foreclosing your home loan will trigger a 1% processing fee of the remaining outstanding amount. Do you wish to schedule a callback with our credit advisor?")
                    .multilineTextAlignment(.center)
                    .foregroundColor(LMSColors.textSecondary)
                    .padding()
                
                Button {
                    showingToast = true
                } label: {
                    Text("Schedule Callback")
                        .foregroundColor(.white)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(LMSColors.brandNavy)
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
            .alert("Callback Scheduled", isPresented: $showingToast) {
                Button("OK", role: .cancel) { dismiss() }
            } message: {
                Text("A credit advisor will call you within 24 hours.")
            }
        }
    }
}

struct SupportSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingToast = false
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Contact Channels")) {
                    Button(action: { showingToast = true }) {
                        Label("Call Support: 1800-BANK-LOAN", systemImage: "phone.fill")
                    }
                    .foregroundColor(.primary)
                    Button(action: { showingToast = true }) {
                        Label("Email: support@brandbank.com", systemImage: "envelope.fill")
                    }
                    .foregroundColor(.primary)
                    Button(action: { showingToast = true }) {
                        Label("Live chat assistant", systemImage: "message.fill")
                    }
                    .foregroundColor(.primary)
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
            .alert("Connecting...", isPresented: $showingToast) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Support services are currently offline in this mock environment.")
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
                    .foregroundColor(LMSColors.emerald)
                
                Text("Top-Up Account Balance")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Slider(value: $topUpAmount, in: 5000...50000, step: 5000)
                
                Text("Amount to Add: \(topUpAmount.formattedAsINR())")
                    .font(.headline)
                    .foregroundColor(LMSColors.emerald)
                
                Button {
                    viewModel.topUpAccount(amount: topUpAmount)
                    dismiss()
                } label: {
                    Text("Confirm Deposit")
                        .foregroundColor(.white)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(LMSColors.emerald)
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
    let loan: DashboardLoanAccount
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header block
                ZStack {
                    LinearGradient(colors: [LMSColors.brandNavy, LMSColors.brandNavy], startPoint: .topLeading, endPoint: .bottomTrailing)
                    
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
                        .foregroundColor(LMSColors.textSecondary)
                    
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
                .background(LMSColors.surfaceElevated)
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
                    LinearGradient(colors: [LMSColors.emerald, LMSColors.emeraldDark], startPoint: .topLeading, endPoint: .bottomTrailing)
                    
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
                        .foregroundColor(LMSColors.textSecondary)
                    
                    HStack(spacing: 12) {
                        Button("+ ₹5,000") { viewModel.topUpAccount(amount: 5000) }
                            .buttonStyle(.borderedProminent)
                            .tint(LMSColors.emerald)
                        
                        Button("+ ₹10,000") { viewModel.topUpAccount(amount: 10000) }
                            .buttonStyle(.borderedProminent)
                            .tint(LMSColors.emerald)
                        
                        Button("+ ₹20,000") { viewModel.topUpAccount(amount: 20000) }
                            .buttonStyle(.borderedProminent)
                            .tint(LMSColors.emerald)
                    }
                }
                .padding(20)
                .background(LMSColors.surfaceElevated)
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
                    Text(tx.date.formattedAsDDMMMYYYY()).font(.caption).foregroundColor(LMSColors.textSecondary)
                }
                Spacer()
                Text(tx.amount.formattedAsINR())
                    .fontWeight(.bold)
                    .foregroundColor(tx.type == .credit || tx.type == .refund ? LMSColors.emerald : LMSColors.coral)
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
                    Text("Due Date: \(emi.dueDate.formattedAsDDMMMYYYY())").font(.caption).foregroundColor(LMSColors.textSecondary)
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
                    .foregroundColor(LMSColors.textSecondary)
                
                Text(scheme.description)
                    .font(.body)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Benefit Summary").font(.headline)
                    Text(scheme.benefitSummary).foregroundColor(LMSColors.emerald).fontWeight(.bold)
                }
                
                Divider()
                
                if appSubmitted {
                    Text("🎉 Application Submitted Successfully! Our relationship manager will contact you in 24 hours.")
                        .foregroundColor(LMSColors.emerald)
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
                            .background(LMSColors.brandNavy)
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
                .foregroundColor(LMSColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(LMSColors.textPrimary)
        }
        .padding(.vertical, 4)
    }
}

