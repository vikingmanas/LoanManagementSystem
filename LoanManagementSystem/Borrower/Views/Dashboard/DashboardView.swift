import SwiftUI

// MARK: - Navigation Destinations
public enum DashboardRoute: Hashable {
    case loanDetails(DashboardLoanAccount)
    case bankDetails(BankAccount)
    case insuranceDetails
    case allPendingEMIs
    case schemeDetails(GovernmentScheme)
}

public struct DashboardView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var appState: AppStateManager
    @EnvironmentObject private var tabRouter: BorrowerTabRouter
    @ObservedObject var viewModel: DashboardViewModel
    @State private var navigationPath = NavigationPath()
    
    // Quick Actions Sheets
    @State private var showingQuickPaySheet = false
    @State private var showingStatementSheet = false
    @State private var showingForeclosureSheet = false
    @State private var showingSupportSheet = false
    @State private var showingTopUpSheet = false
    @State private var showingProfileSheet = false
    
    private var greetingTitle: String {
        guard let profile = BorrowerProfileStore.shared.profile else {
            return "Dashboard"
        }
        let firstName = profile.fullName.components(separatedBy: " ").first ?? profile.fullName
        return "Hi, \(firstName)"
    }
    
    public var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                // 0. CUSTOM TOP BAR (HStack showing navigation title 'Dashboard' and notification/profile toolbar)
                HStack(alignment: .center) {
                    Text("Dashboard")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.brandNavy)
                    
                    Spacer()
                    
                    // Notification & Profile Toolbar Pill
                    HStack(spacing: 12) {
                        Button {
                            tabRouter.select(.history)
                        } label: {
                            Image(systemName: "bell.fill")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(LMSColors.brandNavy)
                                .frame(width: 36, height: 36)
                        }
                        .buttonStyle(LMSPressableStyle())
                        .accessibilityLabel("Notifications")

                        Button {
                            showingProfileSheet = true
                        } label: {
                            DashboardAvatar(
                                initials: dashboardInitials(
                                    viewModel: viewModel,
                                    authManager: authManager
                                )
                            )
                        }
                        .buttonStyle(LMSPressableStyle())
                        .accessibilityLabel("Profile")
                    }
                    .padding(.leading, 12)
                    .padding(.trailing, 6)
                    .padding(.vertical, 6)
                    .background(LMSColors.surface, in: Capsule())
                    .overlay(
                        Capsule()
                            .stroke(LMSColors.separatorLight, lineWidth: 0.5)
                    )
                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)
                .padding(.top, 12)
                .padding(.bottom, 12)
                .background(LMSColors.background) // match screen background

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: LMSSpacing.sectionGap) {

                        // 1. CUSTOMER INSIGHT & COMPLETION
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
                        
                        // 6. GOVERNMENT SCHEMES SECTION
                        GovernmentSchemesSection(viewModel: viewModel) { scheme in
                            navigationPath.append(DashboardRoute.schemeDetails(scheme))
                        }
                        
                    }
                    .padding(.top, LMSSpacing.sm)
                    .padding(.bottom, LMSSpacing.xxl)
                }
                .refreshable {
                    await viewModel.fetchDashboardData()
                }
            }
            .lmsScreenBackground()
            .hideNavigationBar()
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
                    .environmentObject(authManager)
                    .environmentObject(appState)
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

struct DashboardToolbarTitle: View {
    let firstName: String
    var customerID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.xs) {
            Text("Hello, \(firstName)")
                .font(LMSFont.subheadline.weight(.semibold))
                .foregroundStyle(LMSColors.textPrimary)
            if let customerID {
                Label(customerID, systemImage: "number")
                    .font(LMSFont.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(LMSColors.brandNavy)
                    .padding(.horizontal, LMSSpacing.sm)
                    .padding(.vertical, 3)
                    .background(LMSColors.brandNavy.opacity(0.10), in: Capsule())
            }
        }
    }
}

struct DashboardAvatar: View {
    let initials: String

    var body: some View {
        Text(initials)
            .font(LMSFont.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 36, height: 36)
            .background(
                LinearGradient(
                    colors: [LMSColors.brandNavy, LMSColors.brandNavyLight],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: Circle()
            )
            .overlay(
                Circle()
                    .stroke(Color.white.opacity(0.25), lineWidth: 1)
            )
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
            HStack(spacing: LMSSpacing.lg) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: CGFloat(percentage) / 100.0)
                        .stroke(LMSColors.emerald, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(percentage)%")
                        .font(LMSFont.caption2.weight(.bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                    Text("Complete Your Profile")
                        .font(LMSFont.callout.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Unlock all features by finishing setup")
                        .font(LMSFont.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(LMSSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [LMSColors.brandNavy, LMSColors.brandNavyLight],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
            )
        }
        .buttonStyle(DashboardPressableStyle())
    }
}

// MARK: - Section 2: Portfolio
struct PortfolioCardsSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    let onNavigate: (DashboardRoute) -> Void
    @State private var showingPlaceholderAlert = false
    
    var body: some View {
        SectionContainer(title: "My Portfolio") {
//            FintechSectionLink(title: "See All") {
//                showingPlaceholderAlert = true
//            }
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
        SectionContainer(title: "Quick Actions", subtitle: "Pay, transfer, and manage your loan") {
            FintechQuickActionGrid(items: [
                FintechQuickActionItem(icon: "indianrupeesign.circle.fill", title: "Pay EMI", tint: LMSColors.brandNavy, action: onPay),
                FintechQuickActionItem(icon: "doc.text.fill", title: "Statement", tint: LMSColors.actionBlue, action: onStatement),
                FintechQuickActionItem(icon: "chart.line.downtrend.xyaxis", title: "Foreclose", tint: LMSColors.teal, action: onForeclosure),
                FintechQuickActionItem(icon: "headphones", title: "Support", tint: LMSColors.amber, action: onSupport),
                FintechQuickActionItem(icon: "plus.circle.fill", title: "Top-Up", tint: LMSColors.emerald, action: onTopUp)
            ])
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
            FintechSectionLink(title: "Explore All") {
                showingPlaceholderAlert = true
            }
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
                        .foregroundStyle(LMSColors.brandNavy)
                    
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
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    Button {
                        viewModel.payNextEMI()
                        dismiss()
                    } label: {
                        Text("Pay Now")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(LMSColors.brandNavy)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                        Text(tx.date.formattedAsDDMMMYYYY()).font(.subheadline).foregroundStyle(LMSColors.textSecondary)
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
                    .foregroundStyle(LMSColors.coral)
                
                Text("Request Foreclosure")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Foreclosing your home loan will trigger a 1% processing fee of the remaining outstanding amount. Do you wish to schedule a callback with our credit advisor?")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(LMSColors.textSecondary)
                    .padding()
                
                Button {
                    showingToast = true
                } label: {
                    Text("Schedule Callback")
                        .foregroundStyle(.white)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(LMSColors.brandNavy)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                    .foregroundStyle(.primary)
                    Button(action: { showingToast = true }) {
                        Label("Email: support@brandbank.com", systemImage: "envelope.fill")
                    }
                    .foregroundStyle(.primary)
                    Button(action: { showingToast = true }) {
                        Label("Live chat assistant", systemImage: "message.fill")
                    }
                    .foregroundStyle(.primary)
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
                    .foregroundStyle(LMSColors.emerald)
                
                Text("Top-Up Account Balance")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Slider(value: $topUpAmount, in: 5000...50000, step: 5000)
                
                Text("Amount to Add: \(topUpAmount.formattedAsINR())")
                    .font(.headline)
                    .foregroundStyle(LMSColors.emerald)
                
                Button {
                    viewModel.topUpAccount(amount: topUpAmount)
                    dismiss()
                } label: {
                    Text("Confirm Deposit")
                        .foregroundStyle(.white)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(LMSColors.emerald)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Text(loan.principalOutstanding.formattedAsINR())
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("Outstanding Principal")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.vertical, 32)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 20)
                
                // Detailed Stats Grid
                VStack(alignment: .leading, spacing: 16) {
                    Text("LOAN METRICS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(LMSColors.textSecondary)
                    
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
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Text(bank.availableBalance.formattedAsINR())
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("Available balance")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .padding(.vertical, 32)
                }
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 20)
                
                // Top-up Section inside details
                VStack(alignment: .leading, spacing: 16) {
                    Text("ADD FUNDS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(LMSColors.textSecondary)
                    
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
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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


struct AllPendingEMIsView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        List(viewModel.pendingEMIs.filter { $0.status != .paid }) { emi in
            HStack {
                VStack(alignment: .leading) {
                    Text(emi.loanType).font(.headline)
                    Text("Due Date: \(emi.dueDate.formattedAsDDMMMYYYY())").font(.caption).foregroundStyle(LMSColors.textSecondary)
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
                    .foregroundStyle(LMSColors.textSecondary)
                
                Text(scheme.description)
                    .font(.body)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Benefit Summary").font(.headline)
                    Text(scheme.benefitSummary).foregroundStyle(LMSColors.emerald).fontWeight(.bold)
                }
                
                Divider()
                
                if appSubmitted {
                    Text("🎉 Application Submitted Successfully! Our relationship manager will contact you in 24 hours.")
                        .foregroundStyle(LMSColors.emerald)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding()
                } else {
                    Button {
                        appSubmitted = true
                    } label: {
                        Text("Apply Now")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(LMSColors.brandNavy)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                .foregroundStyle(LMSColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .rounded))
                .fontWeight(.bold)
                .foregroundStyle(LMSColors.textPrimary)
        }
        .padding(.vertical, 4)
    }
}

#Preview("Dashboard") {
    NavigationStack {
        DashboardView(viewModel: PreviewSupport.dashboardViewModel)
    }
    .environmentObject(PreviewSupport.appState(role: .customer))
    .environmentObject(PreviewSupport.authManager)
    .environmentObject(PreviewSupport.borrowerTabRouter)
}

#Preview("Toolbar Title") {
    DashboardToolbarTitle(firstName: "Rahul", customerID: "C-109482")
        .padding()
}
