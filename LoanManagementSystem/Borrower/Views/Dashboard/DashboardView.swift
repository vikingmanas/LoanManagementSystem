import SwiftUI
import CoreImage.CIFilterBuiltins

// MARK: - Navigation Destinations
public enum DashboardRoute: Hashable {
    case loanDetails(DashboardLoanAccount)
    case bankDetails(BankAccount)
    case insuranceDetails
    case allPendingEMIs
    case schemeDetails(GovernmentScheme)
    case profile
    case linkedBankAccounts
    case profileInfo
    case notifications
}

// MARK: - Native Status Banner Section
struct StatusBannerSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var navigationPath: [DashboardRoute]

    var body: some View {
        VStack(spacing: 12) {
            // Profile Completion Row (Priority 1)
            if let profile = BorrowerProfileStore.shared.profile, profile.profileCompletionPercentage < 100 {
                Button {
                    navigationPath.append(.profile)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark.fill")
                            .font(.title3)
                            .foregroundStyle(LMSColors.brandNavy)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Complete Your Profile")
                                .font(.system(.subheadline, design: .rounded).bold())
                                .foregroundStyle(LMSColors.textPrimary)
                            
                            HStack(spacing: 8) {
                                ProgressView(value: Double(profile.profileCompletionPercentage), total: 100)
                                    .tint(LMSColors.brandNavy)
                                    .frame(width: 60)
                                
                                Text("\(profile.profileCompletionPercentage)% done")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(LMSColors.textSecondary)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(LMSColors.textTertiary)
                    }
                    .padding(.horizontal, LMSSpacing.lg)
                    .padding(.vertical, LMSSpacing.md)
                    .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                }
                .buttonStyle(DashboardPressableStyle())
            }
            
            // Account Health Status Row (High-Signal Urgent Alert)
            Button {
                handleAlertTap()
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: viewModel.isAccountHealthy ? "shield.checkered" : "exclamationmark.shield.fill")
                        .font(.title3)
                        .foregroundStyle(viewModel.isAccountHealthy ? LMSColors.emerald : LMSColors.coral) // Premium Coral Red
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(viewModel.isAccountHealthy ? "Account Secure" : "Action Required")
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundStyle(LMSColors.textPrimary)
                        
                        Text(viewModel.healthStatusMessage)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(LMSColors.textTertiary)
                }
                .padding(.horizontal, LMSSpacing.lg)
                .padding(.vertical, LMSSpacing.md)
                .background(
                    viewModel.isAccountHealthy ? LMSColors.surface : LMSColors.coral.opacity(0.12), 
                    in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                        .stroke(viewModel.isAccountHealthy ? Color.clear : LMSColors.coral.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(DashboardPressableStyle())
        }
        .padding(.horizontal, LMSSpacing.lg)
    }
    
    private func handleAlertTap() {
        if !viewModel.isAccountHealthy {
            navigationPath.append(.allPendingEMIs)
        }
    }
}

// MARK: - Native Quick Actions Section
struct QuickActionGridSection: View {
    var onPay: () -> Void
    var onStatement: () -> Void
    var onForeclosure: () -> Void
    var onSupport: () -> Void
    var onTopUp: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("QUICK ACTIONS")
                .font(.system(.caption, design: .rounded).bold())
                .foregroundStyle(LMSColors.textSecondary)
                .padding(.horizontal, LMSSpacing.lg)
            
            HStack(spacing: 12) {
                QuickActionButton(title: "Pay EMI", icon: "indianrupeesign.circle.fill", color: LMSColors.brandNavy, action: onPay)
                QuickActionButton(title: "Top Up", icon: "plus.circle.fill", color: LMSColors.emerald, action: onTopUp)
                QuickActionButton(title: "Statement", icon: "doc.text.fill", color: LMSColors.actionBlue, action: onStatement)
                QuickActionButton(title: "Support", icon: "headphones.circle.fill", color: LMSColors.amber, action: onSupport)
            }
            .padding(.horizontal, LMSSpacing.lg)
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundStyle(color)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous).stroke(LMSColors.separatorLight, lineWidth: 0.5))
                
                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(LMSColors.textPrimary)
            }
        }
        .buttonStyle(DashboardPressableStyle())
    }
}

// MARK: - Dashboard View

public struct DashboardView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var tabRouter: BorrowerTabRouter
    @ObservedObject var viewModel: DashboardViewModel
    
    @State private var navigationPath = [DashboardRoute]()
    @State private var showingQuickPaySheet = false
    @State private var showingStatementSheet = false
    @State private var showingForeclosureSheet = false
    @State private var showingSupportSheet = false
    @State private var showingTopUpSheet = false
    @State private var navigateToLinkedBankAccountsAfterTopUp = false
    
    private var greetingSubtitle: String {
        if let profile = BorrowerProfileStore.shared.profile, !profile.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let firstName = profile.fullName.components(separatedBy: " ").first ?? profile.fullName
            return "Hi, \(firstName)"
        }
        let authName = authManager.userDisplayName.components(separatedBy: " ").first ?? "User"
        return "Hi, \(authName)"
    }
    
    public var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    
                    HStack {
                        Text(greetingSubtitle)
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundStyle(LMSColors.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, LMSSpacing.lg)
                    .padding(.top, 8)

                    StatusBannerSection(viewModel: viewModel, navigationPath: $navigationPath)
                    
                    VStack(alignment: .leading, spacing: 14) {
                        Text("FINANCIAL PORTFOLIO")
                            .font(.system(.caption, design: .rounded).bold())
                            .foregroundStyle(LMSColors.textSecondary)
                            .padding(.horizontal, LMSSpacing.lg)
                        
                        PortfolioCarouselView(
                            viewModel: viewModel,
                            onNavigateToLoan: { loan in
                                navigationPath.append(DashboardRoute.loanDetails(loan))
                            },
                            onNavigateToBank: { bank in
                                navigationPath.append(DashboardRoute.bankDetails(bank))
                            },
                            onNavigateToInsurance: {
                                navigationPath.append(DashboardRoute.insuranceDetails)
                            },
                            onTransferTap: { bank in
                                navigationPath.append(DashboardRoute.bankDetails(bank))
                            }
                        )
                    }
                    
                    QuickActionGridSection(
                        onPay: { showingQuickPaySheet = true },
                        onStatement: { showingStatementSheet = true },
                        onForeclosure: { showingForeclosureSheet = true },
                        onSupport: { showingSupportSheet = true },
                        onTopUp: { showingTopUpSheet = true }
                    )
                    
                    EMITrackerView(viewModel: viewModel) {
                        viewModel.payNextEMI()
                    } onViewAllPendingTap: {
                        navigationPath.append(DashboardRoute.allPendingEMIs)
                    }
                    
                    GovernmentSchemesSection(viewModel: viewModel) { scheme in
                        navigationPath.append(DashboardRoute.schemeDetails(scheme))
                    }
                }
                .padding(.bottom, LMSSpacing.xxxl)
            }
            .refreshable {
                await viewModel.fetchDashboardData()
            }
            .background(LMSColors.background)
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            navigationPath.append(.notifications)
                        } label: {
                            Image(systemName: "bell.badge")
                                .symbolRenderingMode(.hierarchical)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(LMSColors.brandNavy)
                        }
                        
                        Button {
                            navigationPath.append(.profile)
                        } label: {
                            DashboardAvatar(
                                initials: dashboardInitials(
                                    viewModel: viewModel,
                                    authManager: authManager
                                )
                            )
                        }
                    }
                }
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
                case .allPendingEMIs:
                    AllPendingEMIsView(viewModel: viewModel)
                case .schemeDetails(let scheme):
                    SchemeDetailsView(scheme: scheme)
                case .profile:
                    ProfileView()
                        .environmentObject(authManager)
                        .environmentObject(appState)
                case .linkedBankAccounts:
                    LinkedBankAccountsDetailView(viewModel: BorrowerProfileViewModel())
                case .profileInfo:
                    ProfileInfoDetailView(viewModel: BorrowerProfileViewModel())
                case .notifications:
                    NotificationsDetailView()
                }
            }
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
            .sheet(isPresented: $showingTopUpSheet, onDismiss: {
                if navigateToLinkedBankAccountsAfterTopUp {
                    navigateToLinkedBankAccountsAfterTopUp = false
                    navigationPath.append(.linkedBankAccounts)
                }
            }) {
                TopUpSheet(viewModel: viewModel) {
                    showingTopUpSheet = false
                    navigateToLinkedBankAccountsAfterTopUp = true
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
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("EXCLUSIVE OFFERS")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textSecondary)
                Spacer()
                Button("View All") {
                    showingPlaceholderAlert = true
                }
                .font(.system(.caption, design: .rounded).bold())
                .foregroundStyle(LMSColors.brandNavy)
            }
            .padding(.horizontal, LMSSpacing.lg)
            
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
                            .buttonStyle(DashboardPressableStyle())
                        }
                    }
                }
                .padding(.horizontal, LMSSpacing.lg)
            }
            .alert("Coming Soon", isPresented: $showingPlaceholderAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("This feature is currently under development.")
            }
        }
    }
}

// MARK: - Quick Action Action Sheets

struct QuickPaySheet: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) var dismiss
    @State private var successMessage = ""
    @State private var showSuccessAlert = false

    private var payableEMIs: [EMIRecord] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let endDate = calendar.date(byAdding: .day, value: 4, to: today) ?? today

        return viewModel.pendingEMIs
            .filter { emi in
                let dueDate = calendar.startOfDay(for: emi.dueDate)
                return emi.status != .paid && dueDate >= today && dueDate <= endDate
            }
            .sorted { $0.dueDate < $1.dueDate }
    }

    private var unpaidEMIs: [EMIRecord] {
        viewModel.pendingEMIs.filter { $0.status != .paid }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 14) {
                        Image(systemName: payableEMIs.isEmpty ? "calendar.badge.clock" : "indianrupeesign.circle.fill")
                            .font(.system(size: 58))
                            .foregroundStyle(payableEMIs.isEmpty ? LMSColors.textTertiary : LMSColors.brandNavy)

                        VStack(spacing: 4) {
                            Text(payableEMIs.isEmpty ? "No Payable EMI" : "Pay Upcoming EMI")
                                .font(.headline)
                                .foregroundStyle(LMSColors.textPrimary)

                            Text(headerMessage)
                                .font(.subheadline)
                                .foregroundStyle(LMSColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 16)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 22)
                }
                .listRowBackground(Color.clear)

                Section {
                    LabeledContent("Deduction Account", value: "•••• \(viewModel.bankAccount.accountNumber.suffix(4))")
                    LabeledContent("Bank Name", value: viewModel.bankAccount.bankName)
                    LabeledContent("Available Balance", value: viewModel.bankAccount.availableBalance.formattedAsINR())
                } header: {
                    Text("Payment Source")
                }

                if !payableEMIs.isEmpty {
                    Section {
                        ForEach(payableEMIs) { emi in
                            payableEMIRow(emi)
                        }
                    } header: {
                        Text("EMIs Due Soon")
                    } footer: {
                        Text("You can manually pay EMIs due in the next 4 days. Other EMIs will auto-debit on the fixed due date; failed debit may attract penalty.")
                    }
                } else {
                    Section {
                        Text(emptyStateMessage)
                            .font(.subheadline)
                            .foregroundStyle(LMSColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 10)
                    } footer: {
                        if !unpaidEMIs.isEmpty {
                            Text("EMIs outside this window will auto-debit on the fixed due date. If auto-debit fails, penalty may be applied.")
                        }
                    }
                }
            }
            .navigationTitle("Pay EMI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Payment Successful", isPresented: $showSuccessAlert) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text(successMessage)
            }
        }
    }

    private var headerMessage: String {
        if payableEMIs.isEmpty {
            return unpaidEMIs.isEmpty ? "There is no EMI yet." : "No EMI is due in the next 4 days."
        }

        return "\(payableEMIs.count) EMI\(payableEMIs.count == 1 ? "" : "s") available for early payment."
    }

    private var emptyStateMessage: String {
        unpaidEMIs.isEmpty ? "There is no EMI yet." : "No EMI is available for payment right now."
    }

    private func payableEMIRow(_ emi: EMIRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3)
                    .foregroundStyle(LMSColors.brandNavy)
                    .frame(width: 36, height: 36)
                    .background(LMSColors.brandNavy.opacity(0.10), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(emi.loanType)
                        .font(.headline)
                        .foregroundStyle(LMSColors.textPrimary)

                    Text("Due \(emi.dueDate.formattedAsDDMMMYYYY())")
                        .font(.caption)
                        .foregroundStyle(LMSColors.textSecondary)
                }

                Spacer()

                Text(emi.amount.formattedAsINR())
                    .font(.headline)
                    .foregroundStyle(LMSColors.textPrimary)
            }

            Button {
                if viewModel.payEMI(emi) {
                    successMessage = "Your EMI of \(emi.amount.formattedAsINR()) for \(emi.loanType) is payed successfully."
                    showSuccessAlert = true
                }
            } label: {
                HStack {
                    Spacer()
                    Text(viewModel.bankAccount.availableBalance < emi.amount ? "Insufficient Balance" : "Pay EMI")
                        .fontWeight(.bold)
                    Spacer()
                }
            }
            .disabled(viewModel.bankAccount.availableBalance < emi.amount)
            .buttonStyle(.borderedProminent)
            .tint(viewModel.bankAccount.availableBalance < emi.amount ? LMSColors.textTertiary : LMSColors.brandNavy)

            if viewModel.bankAccount.availableBalance < emi.amount {
                Text("Top up your account before paying this EMI.")
                    .font(.caption)
                    .foregroundStyle(LMSColors.coral)
            }
        }
        .padding(.vertical, 6)
    }
}

struct StatementSheet: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(viewModel.transactions) { tx in
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LMSColors.brandNavy.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                Image(systemName: "arrow.up.right.circle.fill")
                                    .foregroundStyle(LMSColors.brandNavy)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(tx.title)
                                    .font(.system(.body, design: .rounded).bold())
                                Text(tx.date.formattedAsDDMMMYYYY())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Text(tx.amount.formattedAsINR())
                                .font(.system(.body, design: .rounded).bold())
                                .foregroundStyle(LMSColors.textPrimary)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Recent Transactions")
                } footer: {
                    Text("Showing last 10 transactions.")
                }
            }
            .navigationTitle("E-Statement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
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
            Form {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(LMSColors.coral)
                        
                        Text("Loan Foreclosure")
                            .font(.title2.bold())
                        
                        Text("Securely close your active loan account before the tenure ends.")
                            .multilineTextAlignment(.center)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 24)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                }
                .listRowBackground(Color.clear)
                
                Section {
                    Text("Standard foreclosure charges (1-2%) apply on the outstanding principal. Our advisor will walk you through the final steps and calculation.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Information")
                }
                
                Section {
                    Button {
                        showingToast = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Schedule Advisor Call")
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                }
            }
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
                Text("An expert will call you within 24 business hours to assist with the closure.")
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
                Section {
                    Button(action: { showingToast = true }) {
                        Label("Phone Support", systemImage: "phone.fill")
                    }
                    Button(action: { showingToast = true }) {
                        Label("Email Support", systemImage: "envelope.fill")
                    }
                    Button(action: { showingToast = true }) {
                        Label("Live Chat Assistant", systemImage: "message.fill")
                    }
                } header: {
                    Text("Contact Us")
                }
                
                Section {
                    Text("Rescheduling EMIs")
                    Text("Updating Bank Credentials")
                    Text("Document Retrieval")
                    Text("Interest Certificate")
                } header: {
                    Text("Common Queries")
                }
            }
            .navigationTitle("Customer Care")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .alert("Feature Offline", isPresented: $showingToast) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Live support is currently being integrated.")
            }
        }
    }
}

struct TopUpSheet: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) var dismiss
    @State private var topUpAmount = 10000.0
    @State private var sourceAccountID: UUID?
    @State private var destinationAccountID: UUID?
    @State private var successMessage = ""
    @State private var showSuccessAlert = false
    let onAddAccount: () -> Void

    private var linkedAccounts: [BankAccount] {
        viewModel.bankAccounts.filter { account in
            !account.accountNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            account.accountNumber != "XXXX 0000" &&
            account.bankName != "Default Bank"
        }
    }

    private var sourceAccount: BankAccount? {
        linkedAccounts.first { $0.id == sourceAccountID }
    }

    private var destinationAccount: BankAccount? {
        linkedAccounts.first { $0.id == destinationAccountID }
    }

    private var canConfirmTransfer: Bool {
        if linkedAccounts.count == 1 { return true }
        guard linkedAccounts.count > 1,
              let sourceAccount,
              let destinationAccount else {
            return false
        }

        return sourceAccount.id != destinationAccount.id &&
               sourceAccount.availableBalance >= topUpAmount
    }
    
    var body: some View {
        NavigationStack {
            Form {
                amountSection

                if linkedAccounts.isEmpty {
                    noAccountSection
                } else if linkedAccounts.count == 1 {
                    qrReceiveSection(account: linkedAccounts[0])
                } else {
                    transferSection
                }

                if !linkedAccounts.isEmpty {
                    confirmSection
                }
            }
            .navigationTitle("Add Funds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                configureDefaultAccounts()
            }
            .alert("Funds Added", isPresented: $showSuccessAlert) {
                Button("Done") {
                    dismiss()
                }
            } message: {
                Text(successMessage)
            }
        }
    }

    private var amountSection: some View {
        Section {
            VStack(spacing: 18) {
                Image(systemName: linkedAccounts.isEmpty ? "building.columns.circle" : "plus.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(linkedAccounts.isEmpty ? LMSColors.brandNavy : LMSColors.emerald)

                VStack(spacing: 4) {
                    Text(linkedAccounts.count > 1 ? "Transfer Amount" : "Top-Up Amount")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(topUpAmount.formattedAsINR())
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.textPrimary)
                }

                Slider(value: $topUpAmount, in: 5000...100000, step: 5000)
                    .tint(LMSColors.emerald)
                    .padding(.horizontal, 24)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
        }
        .listRowBackground(Color.clear)
    }

    private var noAccountSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                Label("No linked bank account found", systemImage: "exclamationmark.circle.fill")
                    .font(.headline)
                    .foregroundStyle(LMSColors.textPrimary)

                Text("Add and verify a bank account before adding funds.")
                    .font(.subheadline)
                    .foregroundStyle(LMSColors.textSecondary)

                Button {
                    onAddAccount()
                } label: {
                    HStack {
                        Spacer()
                        Label("Add Account", systemImage: "building.columns.fill")
                            .fontWeight(.bold)
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(LMSColors.brandNavy)
            }
            .padding(.vertical, 8)
        }
    }

    private func qrReceiveSection(account: BankAccount) -> some View {
        Section {
            VStack(spacing: 16) {
                QRCodeView(payload: qrPayload(for: account))
                    .frame(width: 170, height: 170)
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(spacing: 4) {
                    Text("Scan to add funds")
                        .font(.headline)
                        .foregroundStyle(LMSColors.textPrimary)

                    Text("\(account.bankName.isEmpty ? "Linked Account" : account.bankName) \(maskedAccountNumber(account.accountNumber))")
                        .font(.subheadline)
                        .foregroundStyle(LMSColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        } header: {
            Text("Receive to Account")
        } footer: {
            Text("Scan this QR from any payment app, then confirm once the payment is completed.")
        }
    }

    private var transferSection: some View {
        Section {
            Picker("From Account", selection: Binding(
                get: { sourceAccountID ?? linkedAccounts.first?.id },
                set: { sourceAccountID = $0 }
            )) {
                ForEach(linkedAccounts) { account in
                    Text(accountPickerTitle(account)).tag(Optional(account.id))
                }
            }

            Picker("To Account", selection: Binding(
                get: { destinationAccountID ?? linkedAccounts.dropFirst().first?.id ?? linkedAccounts.first?.id },
                set: { destinationAccountID = $0 }
            )) {
                ForEach(linkedAccounts) { account in
                    Text(accountPickerTitle(account)).tag(Optional(account.id))
                }
            }

            if let sourceAccount, sourceAccount.availableBalance < topUpAmount {
                Label("Insufficient balance in source account", systemImage: "exclamationmark.triangle.fill")
                    .font(.footnote)
                    .foregroundStyle(LMSColors.coral)
            } else if sourceAccountID == destinationAccountID {
                Label("Choose a different destination account", systemImage: "arrow.left.arrow.right")
                    .font(.footnote)
                    .foregroundStyle(LMSColors.amber)
            }
        } header: {
            Text("Transfer Details")
        } footer: {
            Text("Move money from one linked account to another.")
        }
    }

    private var confirmSection: some View {
        Section {
            Button {
                confirmFunds()
            } label: {
                HStack {
                    Spacer()
                    Text(linkedAccounts.count > 1 ? "Confirm Transfer" : "Confirm Deposit")
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Spacer()
                }
            }
            .disabled(!canConfirmTransfer)
            .listRowBackground(canConfirmTransfer ? LMSColors.emerald : LMSColors.textTertiary.opacity(0.25))
        } footer: {
            if let destination = destinationAccount ?? linkedAccounts.first {
                Text("After confirmation, the amount will be credited to \(maskedAccountNumber(destination.accountNumber)).")
            }
        }
    }

    private func configureDefaultAccounts() {
        guard !linkedAccounts.isEmpty else { return }
        sourceAccountID = sourceAccountID ?? linkedAccounts.first?.id
        destinationAccountID = destinationAccountID ?? (linkedAccounts.dropFirst().first?.id ?? linkedAccounts.first?.id)
    }

    private func confirmFunds() {
        if linkedAccounts.count == 1, let account = linkedAccounts.first {
            viewModel.topUpAccount(amount: topUpAmount, to: account)
            successMessage = "Your amount \(topUpAmount.formattedAsINR()) is credited in the bank account \(maskedAccountNumber(account.accountNumber))."
            showSuccessAlert = true
            return
        }

        guard let sourceAccount, let destinationAccount else { return }
        viewModel.transferFunds(amount: topUpAmount, from: sourceAccount, to: destinationAccount)
        successMessage = "Your amount \(topUpAmount.formattedAsINR()) is credited in the bank account \(maskedAccountNumber(destinationAccount.accountNumber))."
        showSuccessAlert = true
    }

    private func maskedAccountNumber(_ number: String) -> String {
        let suffix = number.suffix(4)
        return "•••• \(suffix)"
    }

    private func accountPickerTitle(_ account: BankAccount) -> String {
        let name = account.bankName.isEmpty ? account.accountType.rawValue : account.bankName
        return "\(name) \(maskedAccountNumber(account.accountNumber))"
    }

    private func qrPayload(for account: BankAccount) -> String {
        "lms://add-funds?account=\(account.accountNumber)&amount=\(Int(topUpAmount))"
    }
}

private struct QRCodeView: View {
    let payload: String
    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        if let image = makeQRCode() {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
        } else {
            Image(systemName: "qrcode")
                .resizable()
                .scaledToFit()
                .foregroundStyle(LMSColors.textPrimary)
        }
    }

    private func makeQRCode() -> UIImage? {
        filter.message = Data(payload.utf8)
        guard let outputImage = filter.outputImage else { return nil }
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Premium Detail Views

struct LoanDetailsView: View {
    let loan: DashboardLoanAccount
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(LMSColors.brandNavy.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "house.fill")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(LMSColors.brandNavy)
                    }
                    
                    VStack(spacing: 4) {
                        Text(loan.principalOutstanding.formattedAsINR())
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("Outstanding Principal")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 40) {
                        VStack(spacing: 4) {
                            Text(loan.totalEMI.formattedAsINR())
                                .font(.headline)
                            Text("Monthly EMI")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(spacing: 4) {
                            Text("8.65%")
                                .font(.headline)
                            Text("Interest Rate")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
            .listRowBackground(Color.clear)
            
            Section {
                LabeledContent("Account Number", value: loan.accountNumber)
                LabeledContent("Next EMI Date", value: loan.nextEMIDate.formattedAsDDMMMYYYY())
                LabeledContent("Total Tenure", value: "\(loan.totalTenureMonths) Months")
                LabeledContent("Remaining", value: "\(loan.tenureRemainingMonths) Months")
            } header: {
                Text("Account Details")
            }
            
            Section {
                LabeledContent("Loan Type", value: loan.loanType)
                LabeledContent("Agreement Status", value: "Verified")
            } header: {
                Text("Legal")
            }
        }
        .navigationTitle("Loan Overview")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BankDetailsView: View {
    let bank: BankAccount
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        List {
            Section {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(LMSColors.emerald.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(LMSColors.emerald)
                    }
                    
                    VStack(spacing: 4) {
                        Text(bank.availableBalance.formattedAsINR())
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("Available Balance")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
            .listRowBackground(Color.clear)
            
            Section {
                LabeledContent("Bank Name", value: bank.bankName)
                LabeledContent("Account Type", value: bank.accountType.rawValue)
                LabeledContent("Account Number", value: "•••• \(bank.accountNumber.suffix(4))")
            } header: {
                Text("Account Details")
            }
            
            Section {
                Button("+ ₹10,000") { viewModel.topUpAccount(amount: 10000) }
                Button("+ ₹20,000") { viewModel.topUpAccount(amount: 20000) }
                Button("+ ₹50,000") { viewModel.topUpAccount(amount: 50000) }
            } header: {
                Text("Quick Deposit")
            }
        }
        .navigationTitle(bank.bankName)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InsuranceDetailsView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 20) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 64))
                        .foregroundStyle(LMSColors.actionBlue)
                    Text("Loan Protection Plan")
                        .font(.title2.bold())
                    Text("Active Policy")
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(LMSColors.emerald, in: Capsule())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
            .listRowBackground(Color.clear)
            
            Section {
                LabeledContent("Coverage Amount", value: "₹ 15,00,000")
                LabeledContent("Policy Number", value: "LMS-9982-AX")
                LabeledContent("Insurer", value: "Brand General Insurance")
            } header: {
                Text("Coverage Summary")
            }
            
            Section {
                LabeledContent("Monthly Premium", value: "₹ 850")
                LabeledContent("Renewal Date", value: "12 Jan 2026")
            } header: {
                Text("Premium Information")
            }
        }
        .navigationTitle("Insurance")
        .navigationBarTitleDisplayMode(.inline)
    }
}


struct AllPendingEMIsView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        List {
            Section {
                ForEach(viewModel.pendingEMIs.filter { $0.status != .paid }) { emi in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(emi.loanType)
                                .font(.system(.body, design: .rounded).bold())
                            Text("Due: \(emi.dueDate.formattedAsDDMMMYYYY())")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(emi.amount.formattedAsINR())
                            .font(.system(.body, design: .rounded).bold())
                    }
                    .padding(.vertical, 4)
                }
            } header: {
                Text("Upcoming Payments")
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
        List {
            Section {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(LMSColors.brandNavy.opacity(0.1))
                            .frame(width: 80, height: 80)
                        Image(systemName: "gift.fill")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(LMSColors.brandNavy)
                    }
                    
                    VStack(spacing: 8) {
                        Text(scheme.title)
                            .font(.title2.bold())
                            .multilineTextAlignment(.center)
                        Text(scheme.category.rawValue)
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.1), in: Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            }
            .listRowBackground(Color.clear)
            
            Section {
                Text(scheme.description)
                    .font(.body)
                    .foregroundStyle(LMSColors.textPrimary)
            } header: {
                Text("About Scheme")
            }
            
            Section {
                HStack {
                    Text("Benefit")
                        .font(.headline)
                    Spacer()
                    Text(scheme.benefitSummary)
                        .foregroundStyle(LMSColors.emerald)
                        .fontWeight(.bold)
                }
                LabeledContent("Valid Until", value: scheme.validTill.formattedAsDDMMMYYYY())
            } header: {
                Text("Benefits & Validity")
            }
            
            Section {
                if appSubmitted {
                    HStack {
                        Spacer()
                        Label("Application Submitted", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(LMSColors.emerald)
                            .font(.headline)
                        Spacer()
                    }
                    .padding()
                } else {
                    Button {
                        appSubmitted = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Apply for Benefit")
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                            Spacer()
                        }
                    }
                    .listRowBackground(LMSColors.brandNavy)
                }
            }
        }
        .navigationTitle("Scheme Details")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Helpers

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
