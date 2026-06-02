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
    case payEMI
    case repaymentSchedule(DashboardLoanAccount?)
    case emiCalculator
    case statement
    case topUp
    case foreclosure
    case support
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
    @AppStorage("dashboard.dismissedProfileCompletionPercentage") private var dismissedProfileCompletionPercentage = -1

    private var shouldShowProfileCompletionCard: Bool {
        viewModel.profileCompletionPercentage < 100 &&
        viewModel.profileCompletionPercentage > dismissedProfileCompletionPercentage
    }
    
    public var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: LMSSpacing.xxl) {
                    if shouldShowProfileCompletionCard {
                        ProfileCompletionCardSection(
                            percentage: viewModel.profileCompletionPercentage,
                            missingItems: viewModel.profileMissingRequirements
                        ) {
                            navigationPath.append(.profile)
                        } onDismiss: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                dismissedProfileCompletionPercentage = viewModel.profileCompletionPercentage
                            }
                        }
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity.combined(with: .move(edge: .top))
                        ))
                    }

                    LoanPortfolioSummarySection(viewModel: viewModel)

                    DashboardQuickActionsSection(
                        onApplyLoan: { tabRouter.select(.loans) },
                        onPayEMI: { navigationPath.append(.payEMI) },
                        onStatement: { navigationPath.append(.statement) },
                        onSupport: { navigationPath.append(.support) },
                        onCalculator: { navigationPath.append(.emiCalculator) },
                        onForeclosure: { navigationPath.append(.foreclosure) },
                        onTopUp: { navigationPath.append(.topUp) }
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
                        onPayNow: { navigationPath.append(.payEMI) },
                        onViewAll: { navigationPath.append(.allPendingEMIs) },
                        onSchedule: { navigationPath.append(.repaymentSchedule(nil)) }
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
                ToolbarItem(placement: .topBarTrailing) {
                    dashboardToolbarActions
                }
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
                    NotificationsDetailView(notificationViewModel: viewModel.notificationViewModel)
                case .transactionHistory:
                    TransactionHistoryFullScreen(viewModel: viewModel)
                case .payEMI:
                    PayEMIWorkflowView(viewModel: viewModel)
                case .repaymentSchedule(let loan):
                    RepaymentScheduleView(viewModel: viewModel, initialLoan: loan)
                case .emiCalculator:
                    EMICalculatorView()
                case .statement:
                    StatementWorkflowView(viewModel: viewModel)
                case .topUp:
                    TopUpWorkflowView(viewModel: viewModel) {
                        navigationPath.append(.linkedBankAccounts)
                    }
                case .foreclosure:
                    ForeclosureSheet(viewModel: viewModel)
                case .support:
                    HelpSupportDetailView()
                }
            }
        }
    }

    private var dashboardToolbarActions: some View {
        HStack(spacing: 4) {
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
                .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Profile")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.regularMaterial, in: Capsule())
        .frame(width: 104, height: 52)
    }
}

// MARK: - Repayment Schedule

private enum RepaymentScheduleStatus: String {
    case paid = "Paid"
    case due = "Due Soon"
    case upcoming = "Upcoming"
    case overdue = "Overdue"

    var tint: Color {
        switch self {
        case .paid: return LMSColors.emerald
        case .due: return LMSColors.amber
        case .upcoming: return LMSColors.actionBlue
        case .overdue: return LMSColors.coral
        }
    }

    var icon: String {
        switch self {
        case .paid: return "checkmark.circle.fill"
        case .due: return "clock.badge.exclamationmark.fill"
        case .upcoming: return "calendar.circle.fill"
        case .overdue: return "exclamationmark.circle.fill"
        }
    }
}

private struct RepaymentScheduleItem: Identifiable, Hashable {
    let id = UUID()
    let instalmentNo: Int
    let dueDate: Date
    let emiAmount: Double
    let principal: Double
    let interest: Double
    let outstandingAfterPayment: Double
    let status: RepaymentScheduleStatus
}

private struct RepaymentScheduleView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var selectedLoanID: UUID?

    init(viewModel: DashboardViewModel, initialLoan: DashboardLoanAccount?) {
        self.viewModel = viewModel
        _selectedLoanID = State(initialValue: initialLoan?.id)
    }

    private var selectedLoan: DashboardLoanAccount? {
        if let selectedLoanID,
           let loan = viewModel.loanAccounts.first(where: { $0.id == selectedLoanID }) {
            return loan
        }
        return viewModel.loanAccounts.first
    }

    private var scheduleItems: [RepaymentScheduleItem] {
        guard let loan = selectedLoan else { return [] }

        let totalMonths = max(1, loan.totalTenureMonths)
        let paidMonths = min(totalMonths, max(0, totalMonths - loan.tenureRemainingMonths))
        let principalPerMonth = loan.sanctionedAmount / Double(totalMonths)
        let interestPerMonth = max(0, loan.totalEMI - principalPerMonth)
        let firstDueDate = Calendar.current.date(
            byAdding: .month,
            value: -paidMonths,
            to: loan.nextEMIDate
        ) ?? loan.nextEMIDate

        return (1...totalMonths).map { month in
            let dueDate = Calendar.current.date(
                byAdding: .month,
                value: month - 1,
                to: firstDueDate
            ) ?? firstDueDate

            let status: RepaymentScheduleStatus
            if month <= paidMonths {
                status = .paid
            } else if month == paidMonths + 1 {
                status = dueDate < Calendar.current.startOfDay(for: Date()) ? .overdue : .due
            } else {
                status = .upcoming
            }

            return RepaymentScheduleItem(
                instalmentNo: month,
                dueDate: dueDate,
                emiAmount: loan.totalEMI,
                principal: principalPerMonth,
                interest: interestPerMonth,
                outstandingAfterPayment: max(0, loan.sanctionedAmount - principalPerMonth * Double(month)),
                status: status
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.loanAccounts.isEmpty {
                    DashboardEmptyState(
                        icon: "calendar.badge.clock",
                        title: "No Repayment Schedule",
                        message: "Approved or disbursed loans will show their full EMI timeline here."
                    )
                    .padding(.top, 80)
                } else if let loan = selectedLoan {
                    headerCard(for: loan)
                    accountFilter
                    timelineCard
                }
            }
            .padding(.horizontal, LMSSpacing.lg)
            .padding(.vertical, LMSSpacing.lg)
        }
        .background(LMSColors.background)
        .navigationTitle("Repayment Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if selectedLoanID == nil {
                selectedLoanID = viewModel.loanAccounts.first?.id
            }
        }
    }

    private func headerCard(for loan: DashboardLoanAccount) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(loan.loanType)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(LMSColors.textPrimary)

                    Text(loan.accountNumber)
                        .font(LMSFont.caption.monospaced())
                        .foregroundStyle(LMSColors.textSecondary)
                }

                Spacer()

                Text("\(loan.tenureRemainingMonths) left")
                    .font(LMSFont.caption.weight(.bold))
                    .foregroundStyle(LMSColors.brandNavy)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(LMSColors.brandNavy.opacity(0.10), in: Capsule())
            }

            HStack(spacing: 10) {
                scheduleMetric("EMI", value: loan.totalEMI.formattedAsINR())
                scheduleMetric("Outstanding", value: loan.principalOutstanding.formattedAsINR())
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Timeline Progress")
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textSecondary)
                    Spacer()
                    Text("\(Int(loan.repaidPercentage * 100))%")
                        .font(LMSFont.caption.weight(.bold))
                        .foregroundStyle(LMSColors.brandNavy)
                }

                ProgressView(value: loan.repaidPercentage)
                    .tint(LMSColors.emerald)
            }
        }
        .padding(16)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
        )
    }

    private var accountFilter: some View {
        Group {
            if viewModel.loanAccounts.count > 1 {
                Menu {
                    ForEach(viewModel.loanAccounts) { loan in
                        Button {
                            selectedLoanID = loan.id
                        } label: {
                            Label(
                                "\(loan.loanType) - \(loan.accountNumber)",
                                systemImage: selectedLoanID == loan.id ? "checkmark.circle.fill" : "circle"
                            )
                        }
                    }
                } label: {
                    HStack {
                        Label(selectedLoan?.accountNumber ?? "Select Account", systemImage: "line.3.horizontal.decrease.circle.fill")
                            .font(LMSFont.callout.weight(.semibold))
                            .foregroundStyle(LMSColors.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(LMSFont.caption.weight(.bold))
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                    .padding(14)
                    .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                            .stroke(LMSColors.separatorLight, lineWidth: 0.5)
                    )
                }
            }
        }
    }

    private var timelineCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Full Tenure Timeline")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(LMSColors.textPrimary)
                Spacer()
                Text("\(scheduleItems.count) EMIs")
                    .font(LMSFont.caption.weight(.semibold))
                    .foregroundStyle(LMSColors.textSecondary)
            }
            .padding(.bottom, 14)

            ForEach(Array(scheduleItems.enumerated()), id: \.element.id) { index, item in
                RepaymentScheduleRow(
                    item: item,
                    isLast: index == scheduleItems.count - 1
                )
            }
        }
        .padding(16)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
        )
    }

    private func scheduleMetric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(LMSFont.caption2)
                .foregroundStyle(LMSColors.textTertiary)
            Text(value)
                .font(LMSFont.callout.weight(.bold))
                .foregroundStyle(LMSColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(LMSColors.surfaceElevated, in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
    }
}

private struct RepaymentScheduleRow: View {
    let item: RepaymentScheduleItem
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Image(systemName: item.status.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(item.status.tint)
                    .frame(width: 28, height: 28)
                    .background(item.status.tint.opacity(0.12), in: Circle())

                if !isLast {
                    Rectangle()
                        .fill(LMSColors.separatorLight)
                        .frame(width: 2, height: 56)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("EMI \(item.instalmentNo)")
                            .font(LMSFont.callout.weight(.semibold))
                            .foregroundStyle(LMSColors.textPrimary)
                        Text(item.dueDate.formattedAsDDMMMYYYY())
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 3) {
                        Text(item.emiAmount.formattedAsINR())
                            .font(LMSFont.callout.weight(.bold))
                            .foregroundStyle(LMSColors.textPrimary)
                            .monospacedDigit()
                        Text(item.status.rawValue)
                            .font(LMSFont.caption2.weight(.bold))
                            .foregroundStyle(item.status.tint)
                    }
                }

                HStack(spacing: 8) {
                    miniBreakdown("Principal", value: item.principal.formattedAsINR())
                    miniBreakdown("Interest", value: item.interest.formattedAsINR())
                }

                Text("Balance after payment: \(item.outstandingAfterPayment.formattedAsINR())")
                    .font(LMSFont.caption2)
                    .foregroundStyle(LMSColors.textTertiary)
                    .padding(.bottom, isLast ? 0 : 14)
            }
        }
    }

    private func miniBreakdown(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(LMSFont.caption2)
                .foregroundStyle(LMSColors.textTertiary)
            Text(value)
                .font(LMSFont.caption.weight(.semibold))
                .foregroundStyle(LMSColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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

// MARK: - EMI Calculator

private enum EMICalculatorTenureUnit: String, CaseIterable, Identifiable {
    case months = "Months"
    case years = "Years"

    var id: String { rawValue }
}

private struct EMICalculatorResult {
    let monthlyEMI: Double
    let totalInterest: Double
    let totalPayable: Double
    let processingFee: Double
    let firstMonthInterest: Double
    let firstMonthPrincipal: Double
    let payoffMonth: Date
}

private struct EMICalculatorView: View {
    @State private var principalText = "500000"
    @State private var annualRateText = "10.5"
    @State private var tenureText = "60"
    @State private var tenureUnit: EMICalculatorTenureUnit = .months
    @State private var processingFeeText = "1.0"

    private var principal: Double { sanitizedDouble(principalText) }
    private var annualRate: Double { sanitizedDouble(annualRateText) }
    private var processingFeePercent: Double { sanitizedDouble(processingFeeText) }
    private var tenureMonths: Int {
        let rawTenure = max(1, Int(sanitizedDouble(tenureText)))
        return tenureUnit == .years ? rawTenure * 12 : rawTenure
    }

    private var result: EMICalculatorResult? {
        guard principal > 0, annualRate >= 0, tenureMonths > 0 else { return nil }

        let monthlyRate = annualRate / 12.0 / 100.0
        let months = Double(tenureMonths)
        let monthlyEMI: Double

        if monthlyRate == 0 {
            monthlyEMI = principal / months
        } else {
            let factor = pow(1 + monthlyRate, months)
            monthlyEMI = principal * monthlyRate * factor / (factor - 1)
        }

        let totalPayable = monthlyEMI * months
        let totalInterest = max(0, totalPayable - principal)
        let processingFee = principal * processingFeePercent / 100.0
        let firstMonthInterest = principal * monthlyRate
        let firstMonthPrincipal = max(0, monthlyEMI - firstMonthInterest)
        let payoffMonth = Calendar.current.date(byAdding: .month, value: tenureMonths, to: Date()) ?? Date()

        return EMICalculatorResult(
            monthlyEMI: monthlyEMI,
            totalInterest: totalInterest,
            totalPayable: totalPayable,
            processingFee: processingFee,
            firstMonthInterest: firstMonthInterest,
            firstMonthPrincipal: firstMonthPrincipal,
            payoffMonth: payoffMonth
        )
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                resultHeader
                inputSection
                breakdownSection
                amortizationPreview
            }
            .padding(.horizontal, LMSSpacing.lg)
            .padding(.vertical, LMSSpacing.lg)
        }
        .background(LMSColors.background)
        .navigationTitle("EMI Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var resultHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "function")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(LMSColors.brandNavy)
                    .frame(width: 46, height: 46)
                    .background(LMSColors.brandNavy.opacity(0.10), in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Estimated Monthly EMI")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(LMSColors.textSecondary)

                    Text(result?.monthlyEMI.formattedAsINR() ?? "-")
                        .font(.system(.title, design: .rounded).weight(.bold))
                        .foregroundStyle(LMSColors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                calculatorMetric("Interest", value: result?.totalInterest.formattedAsINR() ?? "-", tint: LMSColors.amber)
                calculatorMetric("Payable", value: result?.totalPayable.formattedAsINR() ?? "-", tint: LMSColors.emerald)
            }
        }
        .padding(16)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
        )
    }

    private var inputSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Loan Inputs")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(LMSColors.textPrimary)

            calculatorTextField(
                title: "Loan Amount",
                text: $principalText,
                prefix: "₹",
                keyboardType: .numberPad
            )

            calculatorTextField(
                title: "Annual Interest Rate",
                text: $annualRateText,
                suffix: "%",
                keyboardType: .decimalPad
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Tenure")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(LMSColors.textSecondary)

                HStack(spacing: 10) {
                    TextField("Tenure", text: $tenureText)
                        .keyboardType(.numberPad)
                        .textFieldStyle(.plain)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .padding(.horizontal, 12)
                        .frame(height: 46)
                        .background(LMSColors.background, in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))

                    Picker("Tenure Unit", selection: $tenureUnit) {
                        ForEach(EMICalculatorTenureUnit.allCases) { unit in
                            Text(unit.rawValue).tag(unit)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(maxWidth: 190)
                }
            }

            calculatorTextField(
                title: "Processing Fee",
                text: $processingFeeText,
                suffix: "%",
                keyboardType: .decimalPad
            )
        }
        .padding(16)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
        )
    }

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cost Breakdown")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(LMSColors.textPrimary)

            calculatorRow("Principal", value: principal.formattedAsINR())
            calculatorRow("Interest", value: result?.totalInterest.formattedAsINR() ?? "-")
            calculatorRow("Processing Fee", value: result?.processingFee.formattedAsINR() ?? "-")
            calculatorRow("Total Payable", value: result?.totalPayable.formattedAsINR() ?? "-", isEmphasized: true)
            calculatorRow("Loan Closure Month", value: result.map { monthFormatter.string(from: $0.payoffMonth) } ?? "-")
        }
        .padding(16)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
        )
    }

    private var amortizationPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("First EMI Split")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(LMSColors.textPrimary)

            calculatorRow("Principal Component", value: result?.firstMonthPrincipal.formattedAsINR() ?? "-")
            calculatorRow("Interest Component", value: result?.firstMonthInterest.formattedAsINR() ?? "-")

            if let result, result.monthlyEMI > 0 {
                let principalShare = min(1, max(0, result.firstMonthPrincipal / result.monthlyEMI))
                ProgressView(value: principalShare)
                    .tint(LMSColors.emerald)
                HStack {
                    Text("Principal \(Int(principalShare * 100))%")
                    Spacer()
                    Text("Interest \(Int((1 - principalShare) * 100))%")
                }
                .font(.system(.caption, design: .rounded).weight(.medium))
                .foregroundStyle(LMSColors.textSecondary)
            }
        }
        .padding(16)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
        )
    }

    private func calculatorMetric(_ title: String, value: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(.caption2, design: .rounded).weight(.semibold))
                .foregroundStyle(LMSColors.textSecondary)
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(LMSColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
    }

    private func calculatorTextField(
        title: String,
        text: Binding<String>,
        prefix: String = "",
        suffix: String = "",
        keyboardType: UIKeyboardType
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(LMSColors.textSecondary)

            HStack(spacing: 8) {
                if !prefix.isEmpty {
                    Text(prefix)
                        .font(.system(.body, design: .rounded).weight(.bold))
                        .foregroundStyle(LMSColors.textSecondary)
                }

                TextField(title, text: text)
                    .keyboardType(keyboardType)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .rounded).weight(.semibold))

                if !suffix.isEmpty {
                    Text(suffix)
                        .font(.system(.body, design: .rounded).weight(.bold))
                        .foregroundStyle(LMSColors.textSecondary)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 46)
            .background(LMSColors.background, in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
        }
    }

    private func calculatorRow(_ title: String, value: String, isEmphasized: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(isEmphasized ? .bold : .medium))
                .foregroundStyle(isEmphasized ? LMSColors.textPrimary : LMSColors.textSecondary)

            Spacer(minLength: 12)

            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(isEmphasized ? LMSColors.brandNavy : LMSColors.textPrimary)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
    }

    private func sanitizedDouble(_ value: String) -> Double {
        let allowed = value.filter { $0.isNumber || $0 == "." }
        return Double(allowed) ?? 0
    }

    private var monthFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }
}

// MARK: - Quick Action Action Sheets

private enum EMIPaymentStep: Int, CaseIterable {
    case selectLoan, details, account, options, confirm
    var title: String {
        switch self {
        case .selectLoan: return "Select Loan"
        case .details: return "EMI Details"
        case .account: return "Deduction Account"
        case .options: return "Payment Options"
        case .confirm: return "Confirm Payment"
        }
    }
    var next: EMIPaymentStep { EMIPaymentStep(rawValue: min(rawValue + 1, EMIPaymentStep.allCases.count - 1)) ?? self }
    var previous: EMIPaymentStep { EMIPaymentStep(rawValue: max(rawValue - 1, 0)) ?? self }
}

private enum EMIPaymentOption: String, CaseIterable, Identifiable {
    case payNow = "Pay Now"
    case schedule = "Schedule Payment"
    case autoDebit = "Auto-debit on due date"
    var id: String { rawValue }
}

struct PayEMIWorkflowView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var step: EMIPaymentStep = .selectLoan
    @State private var selectedLoan: DashboardLoanAccount?
    @State private var selectedAccountID: UUID?
    @State private var paymentOption: EMIPaymentOption = .payNow
    @State private var scheduledDate = Date()
    @State private var isProcessing = false
    @State private var successTransactionID: String?

    private var selectedAccount: BankAccount? {
        viewModel.bankAccounts.first { $0.id == selectedAccountID } ?? viewModel.bankAccounts.first
    }

    private var canContinue: Bool {
        switch step {
        case .selectLoan: return selectedLoan != nil
        case .details: return selectedLoan != nil
        case .account: return selectedAccount.map { account in selectedLoan.map { account.availableBalance >= $0.totalEMI } ?? false } ?? false
        case .options: return true
        case .confirm: return selectedLoan != nil && selectedAccount != nil
        }
    }

    var body: some View {
        Form {
            workflowHeader
            stepContent
        }
        .scrollContentBackground(.hidden)
        .background(LMSColors.background)
        .navigationTitle("Pay EMI")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if step != .selectLoan && successTransactionID == nil {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") { withAnimation(.smooth(duration: 0.22)) { step = step.previous } }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if successTransactionID == nil {
                stickyCTA
            }
        }
        .fullScreenCover(item: Binding(
            get: { successTransactionID.map { EMISuccessItem(id: $0, loan: selectedLoan, amount: selectedLoan?.totalEMI ?? 0) } },
            set: { if $0 == nil { successTransactionID = nil } }
        )) { item in
            EMIPaymentSuccessView(item: item) {
                successTransactionID = nil
                dismiss()
            }
        }
        .onAppear {
            selectedAccountID = selectedAccountID ?? viewModel.bankAccounts.first?.id
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .selectLoan: loanSelection
        case .details: emiDetails
        case .account: accountSelection
        case .options: paymentOptions
        case .confirm: confirmation
        }
    }

    private var workflowHeader: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(step.title)
                            .font(.title3.bold())
                        Text("Complete EMI payment securely from a linked account.")
                            .font(.caption)
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "indianrupeesign.circle.fill")
                        .font(.title)
                        .foregroundStyle(LMSColors.emerald)
                }
                ProgressView(value: Double(step.rawValue + 1), total: Double(EMIPaymentStep.allCases.count))
                    .tint(LMSColors.emerald)
            }
        }
        .listRowBackground(LMSColors.surface)
    }

    private var loanSelection: some View {
        Section {
            ForEach(viewModel.loanAccounts.filter { $0.principalOutstanding > 0 }) { loan in
                SelectableLoanPaymentCard(loan: loan, isSelected: selectedLoan?.id == loan.id) {
                    selectedLoan = loan
                    HapticsManager.triggerImpact(style: .light)
                }
            }
        } header: {
            Text("All Active Loan Accounts")
        }
    }

    private var emiDetails: some View {
        Group {
            if let loan = selectedLoan {
                let principal = min(loan.principalOutstanding, loan.totalEMI * 0.73)
                let interest = max(0, loan.totalEMI - principal)
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(loan.totalEMI.formattedAsINR())
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                        Text("Due \(loan.nextEMIDate.formattedAsDDMMMYYYY())")
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                    LabeledContent("Penalty if overdue", value: "₹0")
                    LabeledContent("Remaining tenure", value: "\(loan.tenureRemainingMonths) months")
                } header: {
                    Text("EMI Details")
                }

                Section {
                    LabeledContent("Principal", value: principal.formattedAsINR())
                    LabeledContent("Interest", value: interest.formattedAsINR())
                } header: {
                    Text("Upcoming EMI Breakdown")
                }
            }
        }
    }

    private var accountSelection: some View {
        Section {
            if viewModel.bankAccounts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Label("No linked bank account", systemImage: "building.columns")
                        .font(.headline)
                    Text("Add a bank account to pay EMI from this app.")
                        .font(.subheadline)
                        .foregroundStyle(LMSColors.textSecondary)
                }
                .padding(.vertical, 8)
            } else {
                ForEach(viewModel.bankAccounts) { account in
                    SelectableBankAccountCard(
                        account: account,
                        isSelected: selectedAccountID == account.id,
                        warning: selectedLoan.map { account.availableBalance < $0.totalEMI } ?? false
                    ) {
                        selectedAccountID = account.id
                        HapticsManager.triggerImpact(style: .light)
                    }
                }
            }
        } header: {
            Text("Select Deduction Account")
        } footer: {
            if selectedAccount.map({ account in selectedLoan.map { account.availableBalance < $0.totalEMI } ?? false }) == true {
                Text("Insufficient balance. Select another account or use Top Up before paying.")
            }
        }
    }

    private var paymentOptions: some View {
        Section {
            Picker("Payment Option", selection: $paymentOption) {
                ForEach(EMIPaymentOption.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.inline)

            if paymentOption == .schedule {
                DatePicker("Payment Date", selection: $scheduledDate, in: Date()..., displayedComponents: .date)
            }
        } header: {
            Text("Payment Options")
        }
    }

    private var confirmation: some View {
        Group {
            if let loan = selectedLoan, let account = selectedAccount {
                Section {
                    LabeledContent("Loan account", value: "ACC ••\(loan.accountNumber.suffix(4))")
                    LabeledContent("EMI amount", value: loan.totalEMI.formattedAsINR())
                    LabeledContent("Deduction account", value: "••\(account.accountNumber.suffix(4))")
                    LabeledContent("Payment date", value: (paymentOption == .schedule ? scheduledDate : Date()).formattedAsDDMMMYYYY())
                    LabeledContent("Charges", value: "₹0")
                } header: {
                    Text("Confirm Payment")
                }
            }
        }
    }

    private var stickyCTA: some View {
        Button {
            if step == .confirm {
                confirmPayment()
            } else {
                withAnimation(.smooth(duration: 0.22)) { step = step.next }
            }
        } label: {
            HStack {
                Spacer()
                if isProcessing { ProgressView().tint(.white) }
                Text(step == .confirm ? "Confirm EMI Payment" : "Continue")
                    .font(.headline)
                Spacer()
            }
            .foregroundStyle(.white)
            .padding(.vertical, 14)
            .background(canContinue ? LMSColors.brandNavy : LMSColors.textTertiary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(!canContinue || isProcessing)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private func confirmPayment() {
        guard let selectedLoan, let selectedAccount else { return }
        isProcessing = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            if viewModel.payEMI(for: selectedLoan, from: selectedAccount, scheduledDate: paymentOption == .schedule ? scheduledDate : Date()) {
                successTransactionID = "TXN\(Int.random(in: 1000000...9999999))"
            }
            isProcessing = false
        }
    }
}

private struct EMISuccessItem: Identifiable {
    let id: String
    let loan: DashboardLoanAccount?
    let amount: Double
}

private struct EMIPaymentSuccessView: View {
    let item: EMISuccessItem
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 22) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 74))
                .foregroundStyle(LMSColors.emerald)
            Text("EMI Payment Successful")
                .font(.title2.bold())
            VStack(spacing: 12) {
                LabeledContent("Transaction ID", value: item.id)
                LabeledContent("Paid amount", value: item.amount.formattedAsINR())
                LabeledContent("Remaining balance", value: max(0, (item.loan?.principalOutstanding ?? 0) - item.amount * 0.73).formattedAsINR())
                LabeledContent("Next EMI date", value: Calendar.current.date(byAdding: .month, value: 1, to: item.loan?.nextEMIDate ?? Date())?.formattedAsDDMMMYYYY() ?? "-")
            }
            .padding()
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            Spacer()
            Button("Download Receipt") { HapticsManager.triggerImpact(style: .light) }
                .buttonStyle(.bordered)
            Button("View Loan Details", action: onDone)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(LMSColors.brandNavy, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(24)
        .background(LMSColors.background)
    }
}

private struct SelectableLoanPaymentCard: View {
    let loan: DashboardLoanAccount
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(loan.loanType).font(.headline)
                        Text("ACC ••\(loan.accountNumber.suffix(4))").font(.caption).foregroundStyle(LMSColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isSelected ? LMSColors.emerald : LMSColors.textTertiary)
                }
                LabeledContent("Upcoming EMI", value: loan.totalEMI.formattedAsINR())
                LabeledContent("Due", value: loan.nextEMIDate.formattedAsDDMMMYYYY())
                LabeledContent("Outstanding", value: loan.principalOutstanding.formattedAsINR())
                LabeledContent("Status", value: "Upcoming")
            }
            .padding(14)
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(isSelected ? LMSColors.emerald : LMSColors.separatorLight, lineWidth: isSelected ? 1.4 : 0.6))
            .shadow(color: isSelected ? LMSColors.emerald.opacity(0.18) : .clear, radius: 12, x: 0, y: 6)
        }
        .buttonStyle(LMSPressableStyle())
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
    }
}

private struct SelectableBankAccountCard: View {
    let account: BankAccount
    let isSelected: Bool
    let warning: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(account.bankName.isEmpty ? account.accountType.rawValue : account.bankName)
                        .font(.headline)
                    Text("••\(account.accountNumber.suffix(4))")
                        .foregroundStyle(LMSColors.textSecondary)
                    Text("Available: \(account.availableBalance.formattedAsINR())")
                        .font(.caption)
                        .foregroundStyle(warning ? LMSColors.coral : LMSColors.textSecondary)
                    Text(account.accountType.rawValue)
                        .font(.caption2)
                        .foregroundStyle(LMSColors.textTertiary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? LMSColors.emerald : LMSColors.textTertiary)
            }
            .padding(.vertical, 6)
        }
    }
}

private enum StatementPeriod: String, CaseIterable, Identifiable {
    case days30 = "Last 30 Days"
    case months3 = "Last 3 Months"
    case months6 = "Last 6 Months"
    case year1 = "Last 1 Year"
    case custom = "Custom Range"
    var id: String { rawValue }
}

private enum StatementFormat: String, CaseIterable, Identifiable {
    case pdf = "PDF"
    case excel = "Excel"
    var id: String { rawValue }
}

struct StatementWorkflowView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var selectedAccountID: String?
    @State private var period: StatementPeriod = .days30
    @State private var format: StatementFormat = .pdf
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var isGenerating = false
    @State private var generatedURL: URL?
    @State private var showShare = false

    private var loanStatementAccounts: [StatementAccountOption] {
        viewModel.loanAccounts.map {
            StatementAccountOption(
                id: "loan-\($0.id.uuidString)",
                title: $0.loanType,
                subtitle: "****\($0.accountNumber.suffix(4))",
                detail: "Outstanding: \($0.principalOutstanding.formattedAsINR())",
                icon: "doc.text.fill",
                loan: $0,
                bank: nil
            )
        }
    }

    private var bankStatementAccounts: [StatementAccountOption] {
        viewModel.bankAccounts.map {
            StatementAccountOption(
                id: "bank-\($0.id.uuidString)",
                title: $0.bankName.isEmpty ? $0.accountType.rawValue : $0.bankName,
                subtitle: "****\($0.accountNumber.suffix(4))",
                detail: "Available: \($0.availableBalance.formattedAsINR())",
                icon: "building.columns.fill",
                loan: nil,
                bank: $0
            )
        }
    }

    private var allStatementAccounts: [StatementAccountOption] {
        loanStatementAccounts + bankStatementAccounts
    }

    private var selectedAccount: StatementAccountOption? {
        allStatementAccounts.first { $0.id == selectedAccountID } ?? allStatementAccounts.first
    }

    var body: some View {
        Form {
            if !loanStatementAccounts.isEmpty {
                Section {
                    ForEach(loanStatementAccounts) { account in
                        StatementAccountOptionRow(account: account, isSelected: selectedAccount?.id == account.id) {
                            selectedAccountID = account.id
                        }
                    }
                } header: {
                    Text("Loan Accounts")
                }
            } else {
                Section {
                    Text("No loan account")
                        .foregroundStyle(LMSColors.textSecondary)
                } header: {
                    Text("Loan Accounts")
                }
            }

            if !bankStatementAccounts.isEmpty {
                Section {
                    ForEach(bankStatementAccounts) { account in
                        StatementAccountOptionRow(account: account, isSelected: selectedAccount?.id == account.id) {
                            selectedAccountID = account.id
                        }
                    }
                } header: {
                    Text("Linked Bank Accounts")
                }
            } else {
                Section {
                    Text("No linked bank account")
                        .foregroundStyle(LMSColors.textSecondary)
                } header: {
                    Text("Linked Bank Accounts")
                }
            }

            Section {
                Picker("Period", selection: $period) {
                    ForEach(StatementPeriod.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.inline)
                if period == .custom {
                    DatePicker("From", selection: $startDate, displayedComponents: .date)
                    DatePicker("To", selection: $endDate, displayedComponents: .date)
                }
            } header: {
                Text("Select Period")
            }

            Section {
                Picker("Format", selection: $format) {
                    ForEach(StatementFormat.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Format")
            }

            Section {
                Button {
                    generateStatement()
                } label: {
                    HStack {
                        Spacer()
                        if isGenerating { ProgressView() }
                        Text(isGenerating ? "Preparing secure statement..." : "Generate Statement")
                            .fontWeight(.bold)
                        Spacer()
                    }
                }
                .disabled(isGenerating || selectedAccount == nil)

                if generatedURL != nil {
                    Button {
                        showShare = true
                    } label: {
                        Label("Download Statement", systemImage: "square.and.arrow.down")
                    }
                }
            }
        }
        .navigationTitle("Statements")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { selectedAccountID = selectedAccountID ?? selectedAccount?.id }
        .sheet(isPresented: $showShare) {
            if let generatedURL {
                DashboardShareSheet(items: [generatedURL])
            }
        }
    }

    private func generateStatement() {
        guard let selectedAccount else { return }
        isGenerating = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            let ext = format == .pdf ? "pdf" : "csv"
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("LoanManagementSystem-\(selectedAccount.subtitle.suffix(4))-statement.\(ext)")
            let rows = filteredTransactions(for: selectedAccount)
                .map { "\($0.date.formattedAsDDMMMYYYY()),\($0.title),\($0.amount),\($0.referenceNo)" }
                .joined(separator: "\n")
            let body = "LoanManagementSystem Secure Statement\nAccount,\(selectedAccount.title) \(selectedAccount.subtitle)\nPeriod,\(period.rawValue)\nFormat,\(format.rawValue)\n\nDate,Description,Amount,Reference\n\(rows)"
            try? body.data(using: .utf8)?.write(to: url, options: .atomic)
            generatedURL = url
            isGenerating = false
            HapticsManager.triggerNotification(type: .success)
        }
    }

    private func filteredTransactions(for account: StatementAccountOption) -> [Transaction] {
        if let bank = account.bank {
            return viewModel.transactions.filter { $0.bankAccountId == nil || $0.bankAccountId == bank.id }
        }
        if let loan = account.loan {
            return viewModel.transactions.filter { $0.title.localizedCaseInsensitiveContains(loan.loanType) }
        }
        return viewModel.transactions
    }
}

private struct StatementAccountOption: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let detail: String
    let icon: String
    let loan: DashboardLoanAccount?
    let bank: BankAccount?
}

private struct StatementAccountOptionRow: View {
    let account: StatementAccountOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: account.icon)
                    .foregroundStyle(LMSColors.brandNavy)
                    .frame(width: 34, height: 34)
                    .background(LMSColors.brandNavy.opacity(0.10), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.title)
                        .font(.headline)
                        .foregroundStyle(LMSColors.textPrimary)
                    Text(account.subtitle)
                        .foregroundStyle(LMSColors.textSecondary)
                    Text(account.detail)
                        .font(.caption)
                        .foregroundStyle(LMSColors.textTertiary)
                }
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? LMSColors.emerald : LMSColors.textTertiary)
            }
            .padding(.vertical, 6)
        }
    }
}

private struct DashboardShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private enum TopUpStep: Int, CaseIterable {
    case home, source, destination, amount, review, authorize
    var title: String {
        switch self {
        case .home: return "Top Up"
        case .source: return "Source Account"
        case .destination: return "Destination"
        case .amount: return "Amount"
        case .review: return "Review Transfer"
        case .authorize: return "Confirm"
        }
    }
    var next: TopUpStep { TopUpStep(rawValue: min(rawValue + 1, TopUpStep.allCases.count - 1)) ?? self }
    var previous: TopUpStep { TopUpStep(rawValue: max(rawValue - 1, 0)) ?? self }
}

private enum TopUpMode {
    case addMoney
    case transfer
}

private enum TopUpDestinationType: String, CaseIterable, Identifiable {
    case loan = "Own Loan Account"
    case savings = "Own Savings Account"
    case linked = "Another Linked Account"
    case qr = "QR Transfer"
    var id: String { rawValue }
}

struct TopUpWorkflowView: View {
    @ObservedObject var viewModel: DashboardViewModel
    let onAddAccount: () -> Void
    @State private var step: TopUpStep = .home
    @State private var mode: TopUpMode?
    @State private var sourceAccountID: UUID?
    @State private var destinationType: TopUpDestinationType = .loan
    @State private var destinationAccountID: UUID?
    @State private var destinationLoanID: UUID?
    @State private var amountText = "5000"
    @State private var mpin = ""
    @State private var scannedReceiver: QRReceiver?
    @State private var showQRScanner = false
    @State private var showSuccess = false

    private var amount: Double { Double(amountText.filter { $0.isNumber }) ?? 0 }
    private var sourceAccount: BankAccount? { viewModel.bankAccounts.first { $0.id == sourceAccountID } ?? viewModel.bankAccounts.first }
    private var destinationAccount: BankAccount? {
        if mode == .addMoney {
            if destinationLoanID != nil && destinationAccountID == nil { return nil }
            return viewModel.bankAccounts.first { $0.id == destinationAccountID } ?? viewModel.bankAccounts.first
        }
        return viewModel.bankAccounts.first { $0.id == destinationAccountID }
    }
    private var destinationLoan: DashboardLoanAccount? { viewModel.loanAccounts.first { $0.id == destinationLoanID } ?? viewModel.loanAccounts.first }

    private var canContinue: Bool {
        switch step {
        case .home: return mode != nil
        case .source: return mode == .addMoney || sourceAccount != nil
        case .destination:
            if mode == .addMoney { return destinationAccount != nil || destinationLoan != nil }
            if destinationType == .qr { return scannedReceiver != nil }
            if destinationType == .loan { return destinationLoan != nil }
            return destinationAccount != nil
        case .amount:
            if mode == .addMoney { return amount > 0 }
            return amount > 0 && (sourceAccount?.availableBalance ?? 0) >= amount
        case .review: return true
        case .authorize: return mpin.count >= 4
        }
    }

    var body: some View {
        Form {
            topUpHeader
            topUpContent
        }
        .scrollContentBackground(.hidden)
        .background(LMSColors.background)
        .navigationTitle("Top Up")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if step != .home {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back") {
                        withAnimation(.smooth(duration: 0.22)) {
                            if mode == .addMoney && step == .destination {
                                step = .home
                                mode = nil
                            } else {
                                step = step.previous
                            }
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if step != .home {
                topUpCTA
            }
        }
        .onAppear {
            sourceAccountID = sourceAccountID ?? viewModel.bankAccounts.first?.id
            destinationAccountID = destinationAccountID ?? viewModel.bankAccounts.first?.id
            destinationLoanID = destinationLoanID ?? viewModel.loanAccounts.first?.id
        }
        .sheet(isPresented: $showQRScanner) {
            QRScannerMockView {
                scannedReceiver = QRReceiver(name: "Akash Kumar", handle: "akash@upi", bank: "HDFC Bank")
                showQRScanner = false
            }
        }
        .fullScreenCover(isPresented: $showSuccess) {
            TopUpSuccessView(amount: amount) {
                showSuccess = false
            }
        }
    }

    @ViewBuilder
    private var topUpContent: some View {
        switch step {
        case .home: topUpHomeSection
        case .source: sourceSection
        case .destination: destinationSection
        case .amount: amountSection
        case .review: reviewSection
        case .authorize: authSection
        }
    }

    private var topUpHeader: some View {
        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(step.title).font(.title3.bold())
                        Text(mode == .transfer ? "Move funds between active accounts." : "Add money or transfer between accounts.")
                            .font(.caption)
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundStyle(LMSColors.emerald)
                }
                ProgressView(value: Double(step.rawValue + 1), total: Double(TopUpStep.allCases.count))
                    .tint(LMSColors.emerald)
            }
        }
        .listRowBackground(LMSColors.surface)
    }

    private var topUpHomeSection: some View {
        Section {
            Button {
                mode = .addMoney
                withAnimation(.smooth(duration: 0.22)) { step = .destination }
            } label: {
                topUpModeCard(
                    title: "Add Money",
                    subtitle: "Add funds into your account.",
                    icon: "plus.circle.fill",
                    tint: LMSColors.emerald
                )
            }
            .buttonStyle(LMSPressableStyle())

            Button {
                mode = .transfer
                withAnimation(.smooth(duration: 0.22)) { step = .source }
            } label: {
                topUpModeCard(
                    title: "Transfer Money",
                    subtitle: "Move funds between linked accounts.",
                    icon: "arrow.left.arrow.right.circle.fill",
                    tint: LMSColors.brandNavy
                )
            }
            .buttonStyle(LMSPressableStyle())
        } header: {
            Text("Choose Action")
        }
    }

    private func topUpModeCard(title: String, subtitle: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 48, height: 48)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(LMSColors.textPrimary)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(LMSColors.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(LMSColors.textTertiary)
        }
        .padding(.vertical, 8)
    }

    private var sourceSection: some View {
        Section {
            if viewModel.bankAccounts.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Label("No linked bank account", systemImage: "building.columns")
                        .font(.headline)
                        .foregroundStyle(LMSColors.textPrimary)
                    Text("Add a bank account to transfer funds.")
                        .font(.subheadline)
                        .foregroundStyle(LMSColors.textSecondary)
                    Button {
                        onAddAccount()
                    } label: {
                        Label("Add Bank Account", systemImage: "plus.circle.fill")
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(LMSColors.brandNavy)
                }
                .padding(.vertical, 8)
            } else {
                ForEach(viewModel.bankAccounts) { account in
                    SelectableBankAccountCard(account: account, isSelected: sourceAccountID == account.id, warning: false) {
                        sourceAccountID = account.id
                    }
                }
            }
        } header: {
            Text("Select Source Account")
        }
    }

    private var destinationSection: some View {
        Section {
            if mode == .addMoney {
                if viewModel.bankAccounts.isEmpty && viewModel.loanAccounts.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("No destination account", systemImage: "building.columns")
                            .font(.headline)
                        Text("Add a bank account to receive funds.")
                            .font(.subheadline)
                            .foregroundStyle(LMSColors.textSecondary)
                        Button {
                            onAddAccount()
                        } label: {
                            Label("Add Bank Account", systemImage: "plus.circle.fill")
                        }
                    }
                    .padding(.vertical, 8)
                } else {
                    ForEach(viewModel.bankAccounts) { account in
                        SelectableBankAccountCard(account: account, isSelected: destinationAccountID == account.id, warning: false) {
                            destinationAccountID = account.id
                            destinationLoanID = nil
                        }
                    }
                    ForEach(viewModel.loanAccounts.filter { $0.principalOutstanding > 0 }) { loan in
                        SelectableLoanPaymentCard(loan: loan, isSelected: destinationLoanID == loan.id && destinationAccountID == nil) {
                            destinationLoanID = loan.id
                            destinationAccountID = nil
                        }
                    }
                }
            } else {
                Picker("Destination", selection: $destinationType) {
                    ForEach(TopUpDestinationType.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.inline)

                if destinationType == .loan {
                    ForEach(viewModel.loanAccounts.filter { $0.principalOutstanding > 0 }) { loan in
                        SelectableLoanPaymentCard(loan: loan, isSelected: destinationLoanID == loan.id) {
                            destinationLoanID = loan.id
                        }
                    }
                } else if destinationType == .savings || destinationType == .linked {
                    ForEach(viewModel.bankAccounts.filter { $0.id != sourceAccountID }) { account in
                        SelectableBankAccountCard(account: account, isSelected: destinationAccountID == account.id, warning: false) {
                            destinationAccountID = account.id
                        }
                    }
                    if viewModel.bankAccounts.filter({ $0.id != sourceAccountID }).isEmpty {
                        Text("Add another active account before transferring between accounts.")
                            .font(.subheadline)
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                } else {
                    Button {
                        showQRScanner = true
                    } label: {
                        Label(scannedReceiver == nil ? "Scan QR Code" : "QR Scanned", systemImage: "qrcode.viewfinder")
                    }
                    if let scannedReceiver {
                        LabeledContent("Receiver", value: scannedReceiver.name)
                        LabeledContent("UPI ID", value: scannedReceiver.handle)
                        LabeledContent("Bank", value: scannedReceiver.bank)
                    }
                }
            }
        } header: {
            Text(mode == .addMoney ? "Select Destination Account" : "Select Destination")
        }
    }

    private var amountSection: some View {
        Section {
            TextField("₹ Amount", text: $amountText)
                .keyboardType(.numberPad)
                .font(.title2.bold())
            HStack {
                ForEach([500, 1000, 5000, 10000], id: \.self) { chip in
                    Button("₹\(chip)") { amountText = "\(chip)" }
                        .buttonStyle(.bordered)
                }
            }
            if (sourceAccount?.availableBalance ?? 0) < amount {
                Label("Insufficient source balance", systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(LMSColors.coral)
            }
        } header: {
            Text(mode == .addMoney ? "Add Money" : "Enter Amount")
        }
    }

    private var reviewSection: some View {
        Section {
            if mode == .transfer {
                LabeledContent("From", value: sourceAccount.map { "\($0.bankName.isEmpty ? $0.accountType.rawValue : $0.bankName) ••\($0.accountNumber.suffix(4))" } ?? "-")
            }
            LabeledContent("To", value: destinationLabel)
            LabeledContent("Amount", value: amount.formattedAsINR())
            if mode == .transfer {
                LabeledContent("Balance after transfer", value: max(0, (sourceAccount?.availableBalance ?? 0) - amount).formattedAsINR())
            }
        } header: {
            Text(mode == .addMoney ? "Review Add Money" : "Review Transfer")
        }
    }

    private var authSection: some View {
        Section {
            SecureField("Enter MPIN", text: $mpin)
                .keyboardType(.numberPad)
            Label("Biometric authentication can be connected here for production builds.", systemImage: "faceid")
                .font(.caption)
                .foregroundStyle(LMSColors.textSecondary)
        } header: {
            Text("Biometric / MPIN")
        }
    }

    private var topUpCTA: some View {
        Button {
            if step == .authorize {
                confirmTopUp()
            } else {
                let nextStep: TopUpStep
                if mode == .addMoney && step == .destination {
                    nextStep = .amount
                } else if mode == .addMoney && step == .amount {
                    nextStep = .review
                } else if mode == .addMoney && step == .review {
                    nextStep = .authorize
                } else {
                    nextStep = step.next
                }
                withAnimation(.smooth(duration: 0.22)) { step = nextStep }
            }
        } label: {
            Text(step == .authorize ? (mode == .addMoney ? "Add Money" : "Transfer Now") : "Continue")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(canContinue ? LMSColors.brandNavy : LMSColors.textTertiary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(!canContinue)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    private var destinationLabel: String {
        if mode == .addMoney {
            if let destinationAccount {
                return "\(destinationAccount.bankName.isEmpty ? destinationAccount.accountType.rawValue : destinationAccount.bankName) ••\(destinationAccount.accountNumber.suffix(4))"
            }
            return destinationLoan.map { "\($0.loanType) Linked Account ••\($0.accountNumber.suffix(4))" } ?? "-"
        }

        switch destinationType {
        case .loan:
            return destinationLoan.map { "\($0.loanType) Linked Account ••\($0.accountNumber.suffix(4))" } ?? "-"
        case .savings, .linked:
            return destinationAccount.map { "\($0.bankName.isEmpty ? $0.accountType.rawValue : $0.bankName) ••\($0.accountNumber.suffix(4))" } ?? "-"
        case .qr:
            return scannedReceiver.map { "\($0.name) \($0.handle)" } ?? "-"
        }
    }

    private func confirmTopUp() {
        if mode == .addMoney {
            if let destinationAccount {
                viewModel.topUpAccount(amount: amount, to: destinationAccount)
            } else if let destinationLoan {
                viewModel.topUpLoanLinkedAccount(amount: amount, to: destinationLoan)
            }
            HapticsManager.triggerNotification(type: .success)
            showSuccess = true
            return
        }

        guard let sourceAccount else { return }
        switch destinationType {
        case .loan:
            if let destinationLoan { viewModel.transferFundsToLoan(amount: amount, from: sourceAccount, to: destinationLoan) }
        case .savings, .linked:
            if let destinationAccount { viewModel.transferFunds(amount: amount, from: sourceAccount, to: destinationAccount) }
        case .qr:
            viewModel.transferToExternalReceiver(amount: amount, from: sourceAccount, receiverName: scannedReceiver?.name ?? "QR Receiver")
        }
        HapticsManager.triggerNotification(type: .success)
        showSuccess = true
    }
}

private struct QRReceiver {
    let name: String
    let handle: String
    let bank: String
}

private struct QRScannerMockView: View {
    let onScan: () -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 84))
            Text("Scan QR")
                .font(.title2.bold())
            Text("Camera QR scanning placeholder. Tap below to simulate a secure QR scan.")
                .multilineTextAlignment(.center)
                .foregroundStyle(LMSColors.textSecondary)
            Button("Simulate Scan", action: onScan)
                .buttonStyle(.borderedProminent)
            Button("Cancel") { dismiss() }
        }
        .padding(24)
    }
}

private struct TopUpSuccessView: View {
    let amount: Double
    let onDone: () -> Void
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 74))
                .foregroundStyle(LMSColors.emerald)
            Text("Money Added Successfully")
                .font(.title2.bold())
            Text(amount.formattedAsINR())
                .font(.system(size: 34, weight: .bold, design: .rounded))
            Spacer()
            Button("Done", action: onDone)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(LMSColors.brandNavy, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(24)
        .background(LMSColors.background)
    }
}

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
    @State private var selectedLoan: DashboardLoanAccount?
    @State private var acceptedClosure = false
    @State private var selectedPaymentAccountID: UUID?
    @State private var showingSubmissionSuccess = false
    @State private var showingPaymentSuccess = false

    private var loans: [DashboardLoanAccount] {
        viewModel.loanAccounts.sorted { $0.principalOutstanding > $1.principalOutstanding }
    }

    private var selectedRequest: ForeclosureRequest? {
        guard let selectedLoan else { return nil }
        return viewModel.foreclosureRequest(for: selectedLoan)
    }

    private var paymentAccount: BankAccount? {
        viewModel.bankAccounts.first { $0.id == selectedPaymentAccountID } ?? viewModel.bankAccounts.first
    }

    private var canPay: Bool {
        guard let request = selectedRequest,
              let account = paymentAccount else { return false }
        return request.status.isPaymentReady && account.availableBalance >= request.totalPayable
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: LMSSpacing.lg) {
                headerCard
                loanSelectionSection
                if let selectedLoan {
                    if let request = selectedRequest {
                        requestStatusSection(request)
                        if request.status.isPaymentReady {
                            paymentSection(request)
                        }
                        if request.status == .closed {
                            closureDocumentsSection(request)
                        }
                    } else {
                        requestSection(selectedLoan)
                    }
                }
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)
            .padding(.bottom, LMSSpacing.xxxl)
        }
        .background(LMSColors.background)
        .navigationTitle("Foreclosure")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            selectedLoan = selectedLoan ?? loans.first
            selectedPaymentAccountID = selectedPaymentAccountID ?? viewModel.bankAccounts.first?.id
        }
        .alert("Foreclosure Request Submitted", isPresented: $showingSubmissionSuccess) {
            Button("View Status", role: .cancel) {}
        } message: {
            Text("Your request is now visible for loan officer review and bank manager approval.")
        }
        .alert("Loan Closed", isPresented: $showingPaymentSuccess) {
            Button("Done", role: .cancel) {}
        } message: {
            Text("Foreclosure payment is complete. Future EMIs and auto-debit have been stopped.")
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Loan Foreclosure", systemImage: "lock.open.shield.fill")
                .font(.title3.bold())
                .foregroundStyle(LMSColors.textPrimary)
            Text("Request closure, track approval, pay the final amount, and receive closure documents.")
                .font(.subheadline)
                .foregroundStyle(LMSColors.textSecondary)
            HStack(spacing: 8) {
                ForEach(["Request", "Officer Review", "Manager Approval", "Payment", "Closed"], id: \.self) { item in
                    Text(item)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.orange.opacity(0.10), in: Capsule())
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var loanSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Loan Details")
                .font(.headline)
                .foregroundStyle(LMSColors.textPrimary)
            if loans.isEmpty {
                ContentUnavailableView("No loan accounts", systemImage: "building.columns", description: Text("Foreclosure can be requested after loan disbursement."))
            } else {
                ForEach(loans) { loan in
                    ForeclosureLoanCard(loan: loan, isSelected: selectedLoan?.id == loan.id) {
                        selectedLoan = loan
                    }
                }
            }
        }
    }

    private func requestSection(_ loan: DashboardLoanAccount) -> some View {
        let summary = DashboardViewModel.foreclosureAmountSummary(for: loan)
        return VStack(alignment: .leading, spacing: 14) {
            Text("Request Foreclosure")
                .font(.headline)
                .foregroundStyle(LMSColors.textPrimary)

            VStack(spacing: 10) {
                foreclosureAmountRow("Outstanding Principal", summary.principal)
                foreclosureAmountRow("Accrued Interest", summary.interest)
                foreclosureAmountRow("Estimated Foreclosure Charges", summary.charges)
                foreclosureAmountRow("Estimated Closure Amount", summary.total, isTotal: true)
            }
            .padding(16)
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            Toggle("I understand that foreclosure will permanently close this loan account.", isOn: $acceptedClosure)
                .font(.subheadline.weight(.semibold))

            Button {
                _ = viewModel.submitForeclosureRequest(for: loan)
                HapticsManager.triggerNotification(type: .success)
                showingSubmissionSuccess = true
            } label: {
                Text("Submit Foreclosure Request")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(acceptedClosure ? LMSColors.brandNavy : LMSColors.textTertiary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(!acceptedClosure)
            .buttonStyle(LMSPressableStyle())
        }
    }

    private func requestStatusSection(_ request: ForeclosureRequest) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("View Foreclosure Status")
                    .font(.headline)
                Spacer()
                Text(request.status.rawValue)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(statusTint(request.status))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(statusTint(request.status).opacity(0.12), in: Capsule())
            }
            VStack(spacing: 10) {
                LabeledContent("Request ID", value: request.requestID)
                LabeledContent("Submitted", value: request.submittedAt.formattedAsDDMMMYYYY())
                LabeledContent("Loan Officer", value: request.officerRecommendation ?? "Pending review")
                LabeledContent("Bank Manager", value: request.managerDecision ?? "Pending approval")
                LabeledContent("Final Amount", value: request.totalPayable.formattedAsINR())
            }
            .font(.subheadline)
        }
        .padding(16)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func paymentSection(_ request: ForeclosureRequest) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Pay Foreclosure Amount")
                .font(.headline)
            VStack(spacing: 10) {
                foreclosureAmountRow("Outstanding Principal", request.outstandingPrincipal)
                foreclosureAmountRow("Interest Due", request.accruedInterest)
                foreclosureAmountRow("Foreclosure Charges", request.foreclosureCharges)
                foreclosureAmountRow("Total Payable", request.totalPayable, isTotal: true)
            }
            .padding(16)
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

            if viewModel.bankAccounts.isEmpty {
                ContentUnavailableView("No payment source", systemImage: "building.columns", description: Text("Add a linked account to pay and close this loan."))
            } else {
                ForEach(viewModel.bankAccounts) { account in
                    SelectableBankAccountCard(account: account, isSelected: selectedPaymentAccountID == account.id, warning: account.availableBalance < request.totalPayable) {
                        selectedPaymentAccountID = account.id
                    }
                }
            }

            Button {
                if let account = paymentAccount,
                   viewModel.payForeclosureAmount(requestID: request.id, from: account) {
                    showingPaymentSuccess = true
                }
            } label: {
                Text("Pay & Close Loan")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(canPay ? LMSColors.brandNavy : LMSColors.textTertiary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(!canPay)
            .buttonStyle(LMSPressableStyle())
        }
    }

    private func closureDocumentsSection(_ request: ForeclosureRequest) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Closure Documents")
                .font(.headline)
            Label("Loan Closure Certificate", systemImage: "doc.badge.checkmark")
            Label("Foreclosure Receipt", systemImage: "receipt")
            Label("Final Account Statement", systemImage: "doc.text.magnifyingglass")
            Text("These documents are now available in Statements, Documents, and Loan Details.")
                .font(.caption)
                .foregroundStyle(LMSColors.textSecondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LMSColors.emerald.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func foreclosureAmountRow(_ title: String, _ amount: Double, isTotal: Bool = false) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(isTotal ? LMSColors.textPrimary : LMSColors.textSecondary)
            Spacer()
            Text(amount.formattedAsINR())
                .fontWeight(isTotal ? .bold : .semibold)
                .foregroundStyle(LMSColors.textPrimary)
        }
        .font(isTotal ? .headline : .subheadline)
    }

    private func statusTint(_ status: ForeclosureRequestStatus) -> Color {
        switch status {
        case .closed: return LMSColors.emerald
        case .rejected: return LMSColors.coral
        case .awaitingPayment, .approved: return Color.orange
        default: return LMSColors.brandNavy
        }
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
