import SwiftUI
import CoreImage.CIFilterBuiltins
import UIKit

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
    case transactionHistory
}

// MARK: - Native Status Banner Section
struct StatusBannerSection: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Binding var navigationPath: [DashboardRoute]

    var body: some View {
        VStack(spacing: 12) {
            // Profile Completion Row (Priority 1)
            if viewModel.profileCompletionPercentage < 100 {
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
                                ProgressView(value: Double(viewModel.profileCompletionPercentage), total: 100)
                                    .tint(LMSColors.brandNavy)
                                    .frame(width: 60)
                                
                                Text("\(viewModel.profileCompletionPercentage)% done")
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
    
    @StateObject private var profileViewModel = BorrowerProfileViewModel()
    @State private var navigationPath = [DashboardRoute]()
    @State private var showingQuickPaySheet = false
    @State private var showingStatementSheet = false
    @State private var showingForeclosureSheet = false
    @State private var showingSupportSheet = false
    @State private var showingTopUpSheet = false
    @State private var navigateToLinkedBankAccountsAfterTopUp = false
    @State private var showingCalculatorAlert = false
    
    public var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: LMSSpacing.xxl) {
                    if viewModel.profileCompletionPercentage < 100 {
                        ProfileCompletionCardSection(
                            percentage: viewModel.profileCompletionPercentage,
                            missingItems: viewModel.profileMissingRequirements
                        ) {
                            navigationPath.append(.profile)
                        }
                    }

                    LoanPortfolioSummarySection(viewModel: viewModel)

                    DashboardQuickActionsSection(
                        onApplyLoan: { tabRouter.select(.loans) },
                        onPayEMI: { showingQuickPaySheet = true },
                        onStatement: { showingStatementSheet = true },
                        onSupport: { showingSupportSheet = true },
                        onCalculator: { showingCalculatorAlert = true },
                        onForeclosure: { showingForeclosureSheet = true }
                    )

                    ActiveLoanAccountsSection(
                        viewModel: viewModel,
                        onLoanTap: { loan in
                            navigationPath.append(.loanDetails(loan))
                        },
                        onApplyLoan: {
                            tabRouter.select(.loans)
                        }
                    )

                    TransactionHistorySection(
                        transactions: viewModel.recentTransactions,
                        accounts: viewModel.bankAccounts,
                        onViewAll: {
                            navigationPath.append(.transactionHistory)
                        }
                    )

                    UpcomingPaymentSection(
                        viewModel: viewModel,
                        onPayNow: { showingQuickPaySheet = true },
                        onViewAll: { navigationPath.append(.allPendingEMIs) }
                    )
                }
                .padding(.top, LMSSpacing.sm)
                .padding(.bottom, LMSSpacing.xxxl)
            }
            .refreshable {
                await viewModel.fetchDashboardData()
            }
            .background(LMSColors.background)
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        navigationPath.append(.notifications)
                    } label: {
                        Image(systemName: viewModel.dashboardNotifications.contains(where: \.isUnread)
                              ? "bell.badge.fill" : "bell")
                            .symbolRenderingMode(.hierarchical)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(LMSColors.brandNavy)
                            .frame(width: 44, height: 44)
                    }
                    .accessibilityLabel("Notifications")

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
                    .accessibilityLabel("Profile")
                }
            }
            .alert("Loan Calculator", isPresented: $showingCalculatorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("EMI calculator is coming soon. Use the Loans tab to explore products and apply.")
            }
            .task {
                await viewModel.fetchDashboardData()
            }
            .task(id: authManager.userEmail) {
                profileViewModel.loadProfile(
                    email: authManager.userEmail,
                    displayName: authManager.userDisplayName
                )
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
                    LinkedBankAccountsDetailView(viewModel: profileViewModel)
                case .profileInfo:
                    ProfileInfoDetailView(viewModel: profileViewModel)
                case .notifications:
                    NotificationsDetailView()
                case .transactionHistory:
                    TransactionHistoryFullScreen(viewModel: viewModel)
                }
            }
            .sheet(isPresented: $showingQuickPaySheet) {
                QuickPaySheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingStatementSheet) {
                StatementSheet(viewModel: viewModel)
            }
            .sheet(isPresented: $showingForeclosureSheet) {
                ForeclosureSheet(viewModel: viewModel)
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
    @State private var reminderMessage: String?

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

                if !unpaidEMIs.isEmpty {
                    Section {
                        Button {
                            Task { await scheduleAllReminders() }
                        } label: {
                            Label("Schedule EMI Reminders", systemImage: "bell.badge")
                        }
                    } footer: {
                        Text("Reminders are scheduled locally on this device one day before EMI due dates.")
                    }
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
            .alert("Reminder Status", isPresented: Binding(
                get: { reminderMessage != nil },
                set: { if !$0 { reminderMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(reminderMessage ?? "")
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

    private func scheduleAllReminders() async {
        for emi in unpaidEMIs {
            await LocalNotificationService.shared.scheduleEMIReminder(
                title: emi.loanType,
                amount: emi.amount,
                dueDate: emi.dueDate
            )
        }
        reminderMessage = "EMI reminders have been scheduled on this device."
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
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) var dismiss
    @State private var step: ForeclosureStep = .selectLoan
    @State private var selectedLoan: DashboardLoanAccount?
    @State private var reason: ForeclosureReason = .financiallyStable
    @State private var reasonDetails = ""
    @State private var documents = ForeclosureDocument.defaultDocuments
    @State private var signatureImage: UIImage?
    @State private var confirmedClosure = false
    @State private var acceptedCharges = false
    @State private var authorizedBank = false
    @State private var selectedUploadTarget: ForeclosureUploadTarget?
    @State private var showingUploadSource = false
    @State private var showingImagePicker = false
    @State private var showingSuccess = false
    @State private var isSubmitting = false
    @State private var requestID = ""

    private var activeLoans: [DashboardLoanAccount] {
        viewModel.loanAccounts.filter { $0.principalOutstanding > 0 }
    }

    private var selectedSummary: ForeclosureAmountSummary? {
        selectedLoan.map(ForeclosureAmountSummary.init)
    }

    private var canContinue: Bool {
        switch step {
        case .selectLoan:
            return selectedLoan != nil
        case .details:
            return selectedLoan != nil
        case .reason:
            return reasonDetails.trimmingCharacters(in: .whitespacesAndNewlines).count >= 20
        case .documents:
            return documents.filter(\.isRequired).allSatisfy { $0.status == .uploaded || $0.status == .pendingVerification }
        case .authorization:
            return signatureImage != nil && confirmedClosure && acceptedCharges && authorizedBank
        case .review:
            return true
        }
    }

    private var ctaTitle: String {
        switch step {
        case .review:
            return isSubmitting ? "Submitting..." : "Submit Foreclosure Request"
        case .authorization:
            return "Review Request"
        default:
            return "Continue"
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                foreclosureHeader
                stepContent
            }
            .scrollContentBackground(.hidden)
            .background(LMSColors.background)
            .navigationTitle("Foreclosure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                if step != .selectLoan && !showingSuccess {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Back") {
                            withAnimation(.smooth(duration: 0.22)) {
                                step = step.previous
                            }
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !showingSuccess {
                    bottomCTA
                }
            }
            .confirmationDialog("Upload Document", isPresented: $showingUploadSource, titleVisibility: .visible) {
                Button("Choose PNG, JPG or JPEG from Gallery") {
                    showingImagePicker = true
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Gallery upload only")
            }
            .sheet(isPresented: $showingImagePicker) {
                ForeclosureImagePicker { image in
                    showingImagePicker = false
                    handleUpload(image)
                } onCancel: {
                    showingImagePicker = false
                }
            }
            .fullScreenCover(isPresented: $showingSuccess) {
                ForeclosureSuccessView(requestID: requestID) {
                    showingSuccess = false
                    dismiss()
                }
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .selectLoan:
            loanSelectionSection
        case .details:
            foreclosureDetailsSection
        case .reason:
            reasonSection
        case .documents:
            requiredDocumentsSection
        case .authorization:
            authorizationSection
        case .review:
            reviewSection
        }
    }

    private var foreclosureHeader: some View {
        Section {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title)
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(LMSColors.textPrimary)
                        Text(step.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "lock.open.shield.fill")
                        .font(.title2)
                        .foregroundStyle(Color.orange)
                        .frame(width: 42, height: 42)
                        .background(Color.orange.opacity(0.12), in: Circle())
                }

                ProgressView(value: Double(step.rawValue + 1), total: Double(ForeclosureStep.allCases.count))
                    .tint(Color.orange)

                HStack(spacing: 6) {
                    ForEach(ForeclosureStep.allCases, id: \.self) { item in
                        Capsule()
                            .fill(item.rawValue <= step.rawValue ? Color.orange : LMSColors.separatorLight)
                            .frame(height: 5)
                    }
                }
            }
            .padding(.vertical, 6)
        }
        .listRowBackground(LMSColors.surface)
    }

    private var loanSelectionSection: some View {
        Section {
            if activeLoans.isEmpty {
                ContentUnavailableView("No active loan accounts", systemImage: "building.columns", description: Text("Foreclosure requests can be started after a loan is active."))
            } else {
                ForEach(activeLoans) { loan in
                    ForeclosureLoanCard(
                        loan: loan,
                        isSelected: selectedLoan?.id == loan.id
                    ) {
                        withAnimation(.smooth(duration: 0.2)) {
                            selectedLoan = loan
                        }
                        HapticsManager.triggerImpact(style: .light)
                    }
                    .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                    .listRowBackground(Color.clear)
                }
            }
        } header: {
            Text("Select Loan Account")
        }
    }

    private var foreclosureDetailsSection: some View {
        Group {
            if let summary = selectedSummary {
                Section {
                    LabeledContent("Outstanding Principal", value: summary.principal.formattedAsINR())
                    LabeledContent("Interest Due", value: summary.interestDue.formattedAsINR())
                    LabeledContent("Foreclosure Charges", value: summary.charges.formattedAsINR())
                    LabeledContent("GST", value: summary.gst.formattedAsINR())
                    LabeledContent("Total Payable", value: summary.total.formattedAsINR())
                        .font(.headline)
                } header: {
                    Text("Foreclosure Details")
                } footer: {
                    Text("Final amount may vary by payment date, loan product, and bank policy.")
                }

                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Things to Know Before Foreclosure", systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(Color.orange)
                        ForEach(ForeclosureAmountSummary.notices, id: \.self) { notice in
                            Label(notice, systemImage: "circle.fill")
                                .font(.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                    }
                    .padding(.vertical, 6)
                }
                .listRowBackground(Color.orange.opacity(0.10))
            }
        }
    }

    private var reasonSection: some View {
        Section {
            Picker("Reason", selection: $reason) {
                ForEach(ForeclosureReason.allCases) { reason in
                    Text(reason.rawValue).tag(reason)
                }
            }

            TextField("Please explain your foreclosure request briefly.", text: $reasonDetails, axis: .vertical)
                .lineLimit(5, reservesSpace: true)
                .textInputAutocapitalization(.sentences)

            HStack {
                Text("Minimum 20 characters")
                Spacer()
                Text("\(reasonDetails.trimmingCharacters(in: .whitespacesAndNewlines).count)/20")
            }
            .font(.caption)
            .foregroundStyle(canContinue ? LMSColors.emerald : LMSColors.textSecondary)
        } header: {
            Text("Reason for Closure")
        } footer: {
            Text("This helps the servicing team validate the closure request and prepare the correct foreclosure statement.")
        }
    }

    private var requiredDocumentsSection: some View {
        Section {
            ForEach(documents) { document in
                ForeclosureDocumentRow(document: document) {
                    selectedUploadTarget = .document(document.id)
                    showingUploadSource = true
                }
            }
        } header: {
            Text("Required Documents")
        } footer: {
            Text("Only PNG, JPG, and JPEG images are accepted. Camera and PDF upload are disabled for this request.")
        }
    }

    private var authorizationSection: some View {
        Group {
            Section {
                if let signatureImage {
                    VStack(alignment: .leading, spacing: 10) {
                        Image(uiImage: signatureImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, minHeight: 90, maxHeight: 120)
                            .padding(10)
                            .background(LMSColors.surfaceTertiary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        HStack {
                            Button("Replace") {
                                selectedUploadTarget = .signature
                                showingUploadSource = true
                            }
                            Spacer()
                            Button("Remove", role: .destructive) {
                                self.signatureImage = nil
                            }
                        }
                        .font(.caption.weight(.bold))
                    }
                } else {
                    Button {
                        selectedUploadTarget = .signature
                        showingUploadSource = true
                    } label: {
                        Label("Upload Signature Image", systemImage: "signature")
                    }
                }
            } header: {
                Text("Signature & Authorization")
            } footer: {
                Text("PNG with transparent background is preferred. JPG and JPEG are also accepted.")
            }

            Section {
                Toggle("I confirm I want to close this loan account.", isOn: $confirmedClosure)
                Toggle("I understand foreclosure charges may apply.", isOn: $acceptedCharges)
                Toggle("I authorize the bank to process this closure request.", isOn: $authorizedBank)
            } header: {
                Text("Legal Consent")
            }
        }
    }

    private var reviewSection: some View {
        Group {
            if let loan = selectedLoan, let summary = selectedSummary {
                Section {
                    LabeledContent("Loan", value: loan.loanType)
                    LabeledContent("Account", value: maskedAccount(loan.accountNumber))
                    LabeledContent("Total Payable", value: summary.total.formattedAsINR())
                    LabeledContent("Charges + GST", value: (summary.charges + summary.gst).formattedAsINR())
                } header: {
                    Text("Selected Loan")
                }

                Section {
                    Text(reason.rawValue)
                        .font(.subheadline.weight(.semibold))
                    Text(reasonDetails)
                        .font(.caption)
                        .foregroundStyle(LMSColors.textSecondary)
                } header: {
                    Text("Closure Reason")
                }

                Section {
                    ForEach(documents) { document in
                        Label(document.title, systemImage: document.status.icon)
                            .foregroundStyle(document.status.tint)
                    }
                } header: {
                    Text("Uploaded Documents")
                }

                Section {
                    if let signatureImage {
                        Image(uiImage: signatureImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 110)
                    }
                } header: {
                    Text("Signature Preview")
                }
            }
        }
    }

    private var bottomCTA: some View {
        VStack(spacing: 8) {
            Button {
                handleCTA()
            } label: {
                HStack {
                    Spacer()
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    }
                    Text(ctaTitle)
                        .font(.headline)
                    Spacer()
                }
                .foregroundStyle(.white)
                .padding(.vertical, 14)
                .background(canContinue && !isSubmitting ? LMSColors.brandNavy : LMSColors.textTertiary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(!canContinue || isSubmitting)
            .buttonStyle(LMSPressableStyle())
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(.ultraThinMaterial)
    }

    private func handleCTA() {
        HapticsManager.triggerImpact(style: .medium)
        if step == .review {
            submitRequest()
        } else {
            withAnimation(.smooth(duration: 0.24)) {
                step = step.next
            }
        }
    }

    private func submitRequest() {
        isSubmitting = true
        requestID = "FC-\(Int(Date().timeIntervalSince1970))"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            isSubmitting = false
            HapticsManager.triggerNotification(type: .success)
            showingSuccess = true
        }
    }

    private func handleUpload(_ image: UIImage) {
        guard validateUploadImage(image) else {
            if case .document(let id) = selectedUploadTarget,
               let index = documents.firstIndex(where: { $0.id == id }) {
                documents[index].status = .rejected
                documents[index].fileName = "Rejected image"
            }
            return
        }

        switch selectedUploadTarget {
        case .document(let id):
            if let index = documents.firstIndex(where: { $0.id == id }) {
                documents[index].status = .pendingVerification
                documents[index].thumbnail = image
                documents[index].fileName = "\(documents[index].filePrefix)-\(Int(Date().timeIntervalSince1970)).jpg"
                documents[index].fileSize = imageFileSize(image)
            }
        case .signature:
            signatureImage = image
        case .none:
            break
        }
        HapticsManager.triggerNotification(type: .success)
    }

    private func validateUploadImage(_ image: UIImage) -> Bool {
        let bytes = image.jpegData(compressionQuality: 0.86)?.count ?? 0
        return bytes > 20_000 && bytes < 5_000_000 && image.size.width >= 500 && image.size.height >= 250
    }

    private func imageFileSize(_ image: UIImage) -> String {
        let bytes = image.jpegData(compressionQuality: 0.86)?.count ?? 0
        if bytes >= 1_000_000 {
            return String(format: "%.1f MB", Double(bytes) / 1_000_000)
        }
        return "\(max(1, bytes / 1_000)) KB"
    }

    private func maskedAccount(_ number: String) -> String {
        "ACC ••\(number.suffix(4))"
    }
}

private enum ForeclosureStep: Int, CaseIterable {
    case selectLoan
    case details
    case reason
    case documents
    case authorization
    case review

    var title: String {
        switch self {
        case .selectLoan: return "Select Loan Account"
        case .details: return "Foreclosure Details"
        case .reason: return "Reason for Closure"
        case .documents: return "Required Documents"
        case .authorization: return "Signature & Authorization"
        case .review: return "Review & Submit"
        }
    }

    var subtitle: String {
        switch self {
        case .selectLoan: return "Choose the active loan account you want to close."
        case .details: return "Review the estimated payable amount and closure impact."
        case .reason: return "Tell us why you are closing this loan."
        case .documents: return "Upload the required foreclosure images."
        case .authorization: return "Add your signature and legal consent."
        case .review: return "Confirm all details before submission."
        }
    }

    var next: ForeclosureStep {
        ForeclosureStep(rawValue: min(rawValue + 1, ForeclosureStep.allCases.count - 1)) ?? self
    }

    var previous: ForeclosureStep {
        ForeclosureStep(rawValue: max(rawValue - 1, 0)) ?? self
    }
}

private struct ForeclosureAmountSummary {
    let principal: Double
    let interestDue: Double
    let charges: Double
    let gst: Double

    init(loan: DashboardLoanAccount) {
        principal = loan.principalOutstanding
        interestDue = max(loan.totalEMI * 0.18, loan.principalOutstanding * 0.002)
        charges = loan.principalOutstanding * 0.015
        gst = charges * 0.18
    }

    var total: Double {
        principal + interestDue + charges + gst
    }

    static let notices = [
        "Loan account will be permanently closed",
        "Credit history may be updated",
        "Some foreclosure charges may apply",
        "Pre-approved offers linked to this loan may end",
        "Closure process may take 3-7 working days"
    ]
}

private enum ForeclosureReason: String, CaseIterable, Identifiable {
    case financiallyStable = "Financially stable now"
    case movingBank = "Moving to another bank"
    case highInterest = "High interest rate"
    case sellingAsset = "Selling property/asset"
    case businessClosure = "Business closure"
    case noLongerNeeded = "Loan no longer needed"
    case other = "Other"

    var id: String { rawValue }
}

private enum ForeclosureUploadTarget {
    case document(UUID)
    case signature
}

private enum ForeclosureDocumentStatus {
    case pending, pendingVerification, uploaded, rejected

    var title: String {
        switch self {
        case .pending: return "Pending Upload"
        case .pendingVerification: return "Pending Verification"
        case .uploaded: return "Uploaded"
        case .rejected: return "Rejected"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .pendingVerification: return "viewfinder"
        case .uploaded: return "checkmark.seal.fill"
        case .rejected: return "xmark.octagon.fill"
        }
    }

    var tint: Color {
        switch self {
        case .pending, .pendingVerification: return LMSColors.amber
        case .uploaded: return LMSColors.emerald
        case .rejected: return LMSColors.coral
        }
    }
}

private struct ForeclosureDocument: Identifiable {
    let id = UUID()
    let title: String
    let isRequired: Bool
    let filePrefix: String
    var status: ForeclosureDocumentStatus = .pending
    var fileName = "Not uploaded"
    var fileSize = "-"
    var thumbnail: UIImage?

    static let defaultDocuments = [
        ForeclosureDocument(title: "Identity proof", isRequired: true, filePrefix: "identity-proof"),
        ForeclosureDocument(title: "Foreclosure request letter", isRequired: true, filePrefix: "foreclosure-request-letter"),
        ForeclosureDocument(title: "Latest loan statement", isRequired: true, filePrefix: "latest-loan-statement"),
        ForeclosureDocument(title: "Supporting proof", isRequired: false, filePrefix: "supporting-proof")
    ]
}

private struct ForeclosureLoanCard: View {
    let loan: DashboardLoanAccount
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(loan.loanType)
                            .font(.headline)
                            .foregroundStyle(LMSColors.textPrimary)
                        Text("ACC ••\(loan.accountNumber.suffix(4))")
                            .font(.caption)
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? LMSColors.emerald : LMSColors.textTertiary)
                        .font(.title3)
                }

                VStack(spacing: 8) {
                    detailRow("Outstanding", loan.principalOutstanding.formattedAsINR())
                    detailRow("EMI", loan.totalEMI.formattedAsINR())
                    detailRow("Remaining", "\(loan.tenureRemainingMonths) months")
                    detailRow("Status", loan.principalOutstanding > 0 ? "Active" : "Closed")
                }
            }
            .padding(14)
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(isSelected ? Color.orange : LMSColors.separatorLight, lineWidth: isSelected ? 1.4 : 0.6)
            )
            .shadow(color: isSelected ? Color.orange.opacity(0.18) : .black.opacity(0.03), radius: isSelected ? 14 : 6, x: 0, y: 6)
        }
        .buttonStyle(LMSPressableStyle())
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(LMSColors.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(LMSColors.textPrimary)
                .fontWeight(.semibold)
        }
        .font(.caption)
    }
}

private struct ForeclosureDocumentRow: View {
    let document: ForeclosureDocument
    let onUpload: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let thumbnail = document.thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "doc.text.image.fill")
                        .font(.title3)
                        .foregroundStyle(document.status.tint)
                        .background(document.status.tint.opacity(0.10))
                }
            }
            .frame(width: 48, height: 56)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(document.title)
                        .font(.subheadline.weight(.semibold))
                    if !document.isRequired {
                        Text("Optional")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                }
                Text(document.fileName)
                    .font(.caption)
                    .foregroundStyle(LMSColors.textSecondary)
                    .lineLimit(1)
                Text(document.fileSize)
                    .font(.caption2)
                    .foregroundStyle(LMSColors.textTertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 8) {
                Label(document.status.title, systemImage: document.status.icon)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(document.status.tint)
                Button(document.status == .pending ? "Upload" : "Replace", action: onUpload)
                    .font(.caption.weight(.bold))
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ForeclosureSuccessView: View {
    let requestID: String
    let onTrack: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(LMSColors.emerald)

                VStack(spacing: 8) {
                    Text("Foreclosure Request Submitted")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)
                    Text("Your request has been queued for verification and closure processing.")
                        .font(.subheadline)
                        .foregroundStyle(LMSColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                VStack(spacing: 12) {
                    LabeledContent("Request ID", value: requestID)
                    LabeledContent("Timeline", value: "3-7 working days")
                    LabeledContent("Support", value: "1800-123-LOAN")
                    Button {
                        HapticsManager.triggerImpact(style: .light)
                    } label: {
                        Label("Download acknowledgement", systemImage: "square.and.arrow.down")
                    }
                    .font(.subheadline.weight(.bold))
                }
                .padding(16)
                .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                Spacer()

                Button("Track Request", action: onTrack)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(LMSColors.brandNavy, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .buttonStyle(LMSPressableStyle())
            }
            .padding(24)
            .background(LMSColors.background)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onTrack)
                }
            }
        }
    }
}

private struct ForeclosureImagePicker: UIViewControllerRepresentable {
    let onImagePicked: (UIImage) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.image"]
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImagePicked: (UIImage) -> Void
        let onCancel: () -> Void

        init(onImagePicked: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onImagePicked = onImagePicked
            self.onCancel = onCancel
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            } else {
                onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
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
