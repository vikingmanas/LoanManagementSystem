//
//  DashboardViewModel.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 19/05/26.
//

import SwiftUI
import Combine
import Supabase

@MainActor
public final class DashboardViewModel: ObservableObject {
    public static let emiShortfallPenalty: Double = 500

    @Published public var loanAccounts: [DashboardLoanAccount] = []
    @Published public var bankAccount: BankAccount = BankAccount(accountNumber: "", accountType: .savings, availableBalance: 0)
    @Published public var bankAccounts: [BankAccount] = []
    @Published public var pendingEMIs: [EMIRecord] = []
    @Published public var transactions: [Transaction] = []
    @Published public var schemes: [GovernmentScheme] = []
    @Published public var foreclosureRequests: [ForeclosureRequest] = []
    @Published public var isLoading: Bool = true
    @Published public var profileName: String = ""
    @Published public var profileCompletionPercentage: Int = 0
    
    // Notification support
    public let notificationViewModel = NotificationViewModel()
    
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        CentralLoanRepository.shared.$disbursementEvents
            .dropFirst()
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { await self?.fetchDashboardData() }
            }
            .store(in: &cancellables)

        CentralLoanRepository.shared.$applications
            .dropFirst()
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { await self?.fetchDashboardData() }
            }
            .store(in: &cancellables)

        BorrowerProfileStore.shared.$profile
            .dropFirst()
            .debounce(for: .seconds(2), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { await self?.fetchDashboardData() }
            }
            .store(in: &cancellables)
    }
    
    public var totalOutstanding: Double { loanAccounts.map(\.principalOutstanding).reduce(0, +) }
    public var totalSanctioned:  Double { loanAccounts.map(\.sanctionedAmount).reduce(0, +) }
    public var totalRepaid:      Double { totalSanctioned - totalOutstanding }
    public var repaidFraction:   Double { totalSanctioned > 0 ? (totalRepaid / totalSanctioned) : 0 }
    
    public var loansClosedCount: Int {
        // Closed if outstanding principal has reached 0 (or below due to rounding).
        loanAccounts.filter { $0.principalOutstanding <= 0.0 }.count
    }
    
    public var unpaidEMIs: [EMIRecord] {
        pendingEMIs
            .filter { $0.status != .paid }
            .sorted { $0.dueDate < $1.dueDate }
    }

    public var nextEMI: EMIRecord? {
        nextDueEMIs.first
    }

    public var nextDueEMIs: [EMIRecord] {
        guard let nextDueDate = unpaidEMIs.first?.dueDate else { return [] }
        let calendar = Calendar.current
        return unpaidEMIs.filter {
            calendar.isDate($0.dueDate, inSameDayAs: nextDueDate)
        }
    }

    public var nextDueAmount: Double {
        nextDueEMIs.map(\.amount).reduce(0, +)
    }

    public var nextDueLoanLabel: String {
        let dueEMIs = nextDueEMIs
        guard let first = dueEMIs.first else { return "No active EMI" }
        return dueEMIs.count == 1 ? first.loanType : "\(dueEMIs.count) loans due"
    }

    public var nextDueStatus: DashboardEMIStatus {
        nextDueEMIs.contains { $0.status == .overdue } ? .overdue : .dueSoon
    }
    
    public var isLowBalance: Bool {
        guard !bankAccounts.isEmpty else { return false }
        guard nextDueAmount > 0 else { return false }
        return bankAccount.availableBalance < nextDueAmount
    }
    
    public var balanceDeficit: Double {
        max(0, nextDueAmount - bankAccount.availableBalance)
    }
    
    public var isAccountHealthy: Bool {
        !isLowBalance && !pendingEMIs.contains { $0.status == .overdue }
    }
    
    public var healthStatusMessage: String {
        if pendingEMIs.contains(where: { $0.status == .overdue }) {
            return "You have overdue payments. Please settle immediately."
        }
        if isLowBalance {
            return "Low balance. Top up to ensure next EMI payment."
        }
        return "All your loan accounts are in good standing."
    }

    public var timeBasedGreeting: String {
        let firstName = profileName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: " ")
            .first ?? "there"
        return Self.greetingPrefix + ", \(firstName)"
    }

    private static var greetingPrefix: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        default: return "Good Evening"
        }
    }

    public var recentTransactions: [Transaction] {
        transactions.sorted { $0.date > $1.date }
    }

    public func foreclosureRequest(for loan: DashboardLoanAccount) -> ForeclosureRequest? {
        foreclosureRequests
            .filter { $0.loanID == loan.id && $0.status != .closed && $0.status != .rejected }
            .sorted { $0.updatedAt > $1.updatedAt }
            .first
    }

    public var dashboardNotifications: [LMSNotification] {
        return notificationViewModel.lmsNotifications
    }

    public var profileMissingRequirements: [String] {
        guard let profile = BorrowerProfileStore.shared.profile else {
            return ["Complete personal details", "Verify contact information", "Add profile photo"]
        }
        var missing: [String] = []
        if profile.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append("Add your full name")
        }
        if !profile.isEmailVerified {
            missing.append("Verify email address")
        }
        if !profile.isPhoneVerified {
            missing.append("Verify mobile number")
        }
        if profile.profileImageData == nil {
            missing.append("Add profile photo")
        }
        return missing
    }
    
    public func isLowBalance(_ account: BankAccount) -> Bool {
        account.availableBalance < (account.minBalance ?? 0)
    }
    
    public func balanceDeficit(for account: BankAccount) -> Double {
        max(0, (account.minBalance ?? 0) - account.availableBalance)
    }
    
    public func fetchDashboardData() async {
        isLoading = true
        defer { isLoading = false }

        if let email = BorrowerProfileStore.shared.currentEmail ?? BorrowerProfileStore.shared.profile?.email,
           !email.isEmpty,
           BorrowerProfileStore.shared.profile == nil {
            if let session = try? await SupabaseManager.shared.client.auth.session {
                await BorrowerProfileStore.shared.fetchProfileFromSupabase(
                    uid: session.user.id.uuidString,
                    email: session.user.email ?? email
                )
            }
        }
        
        // Simulate a 0.8s network latency delay
        do {
            try await Task.sleep(nanoseconds: 800_000_000)
            try Task.checkCancellation()
        } catch {
            return
        }
        
        // Load loan accounts from approved/disbursed applications in CentralLoanRepository
        let approvedApps = CentralLoanRepository.shared.applications.filter {
            $0.currentStage == .approved || $0.currentStage == .disbursed
        }

        if let profile = BorrowerProfileStore.shared.profile {
            self.profileName = profile.fullName
            self.profileCompletionPercentage = profile.profileCompletionPercentage
            syncApprovedLoanODAccounts(approvedApps, profile: profile)
            let refreshedProfile = BorrowerProfileStore.shared.profile ?? profile
            let disbursedCredits = disbursementCredits(for: profile)
            self.bankAccounts = buildBankAccounts(from: refreshedProfile, disbursedCredits: disbursedCredits)
            self.bankAccount = bankAccounts.first(where: { $0.accountType == .overdraft })
                ?? bankAccounts.first
                ?? BankAccount(accountNumber: "", bankName: "", accountType: .overdraft, availableBalance: 0)
        } else {
            self.profileName = ""
            self.profileCompletionPercentage = 0
            self.bankAccount = BankAccount(accountNumber: "", bankName: "", accountType: .overdraft, availableBalance: 0.0)
            self.bankAccounts = []
        }

        self.loanAccounts = approvedApps.map { app in
            let totalEMI = app.formData.requestedAmountValue / Double(max(1, app.formData.preferredTenureMonths))
            let linkedAccountID = bankAccounts.first(where: { $0.linkedLoanIds.contains(app.id) })?.id ?? bankAccount.id
            return DashboardLoanAccount(
                id: app.id,
                accountNumber: app.applicationId ?? "L-\(app.id.uuidString.prefix(6).uppercased())",
                loanType: app.product.type.title,
                sanctionedAmount: app.formData.requestedAmountValue,
                principalOutstanding: app.formData.requestedAmountValue,
                totalEMI: totalEMI,
                nextEMIDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
                tenureRemainingMonths: app.formData.preferredTenureMonths,
                totalTenureMonths: app.formData.preferredTenureMonths,
                repaidPercentage: 0.0,
                linkedBankAccountId: linkedAccountID
            )
        }

        for closedRequest in foreclosureRequests where closedRequest.status == .closed {
            if let index = loanAccounts.firstIndex(where: { $0.id == closedRequest.loanID }) {
                loanAccounts[index].principalOutstanding = 0
                loanAccounts[index].tenureRemainingMonths = 0
                loanAccounts[index].repaidPercentage = 1
            }
        }
        
        refreshPendingEMIs()
        
        self.schemes = []

        // Fetch actual transactions from Supabase if borrower profile is available
        let localTransactions = transactions
        var dbTransactionsList: [Transaction] = []
        if let profile = BorrowerProfileStore.shared.profile {
            do {
                let dbTxs: [DBTransaction] = try await SupabaseManager.shared.client
                    .from("transactions")
                    .select()
                    .eq("borrower_id", value: profile.id)
                    .execute()
                    .value
                
                dbTransactionsList = dbTxs.map { db in
                    let txType: TransactionType
                    switch db.type.lowercased() {
                    case "emi_payment", "emipayment": txType = .emiPayment
                    case "credit": txType = .credit
                    case "penalty": txType = .penalty
                    case "refund": txType = .refund
                    case "failed_debit", "faileddebit": txType = .failedDebit
                    default: txType = .credit
                    }
                    return Transaction(
                        id: db.id,
                        title: db.title,
                        date: db.date,
                        amount: db.amount,
                        type: txType,
                        referenceNo: db.referenceNo,
                        bankAccountId: db.bankAccountId
                    )
                }
            } catch {
                print("[DashboardViewModel] Error fetching transactions from Supabase: \(error.localizedDescription)")
            }
        }

        let dbTransactionIds = Set(dbTransactionsList.map(\.id))
        let unsyncedLocalTransactions = localTransactions.filter { !dbTransactionIds.contains($0.id) }
        self.transactions = (dbTransactionsList + unsyncedLocalTransactions).sorted { $0.date > $1.date }
        applyEMIPaymentsToLoanOutstanding()
        refreshPendingEMIs()
        
        // Configure notifications from Supabase
        if let profile = BorrowerProfileStore.shared.profile,
           let userId = UUID(uuidString: profile.id) {
            notificationViewModel.configure(userId: userId)
        }
    }



    private func buildBankAccounts(from profile: BorrowerProfile, disbursedCredits: [String: Double]) -> [BankAccount] {
        var accounts: [BankAccount] = []
        let linked = profile.linkedAccounts ?? []

        for linkedAccount in linked {
            guard linkedAccount.isOverdraftAccount else { continue }
            accounts.append(
                BankAccount(
                    id: linkedAccount.id,
                    accountNumber: linkedAccount.accountNumber,
                    bankName: linkedAccount.bankName,
                    accountType: .overdraft,
                    availableBalance: linkedAccount.balance,
                    odLimit: linkedAccount.odSanctionLimit,
                    linkedLoanIds: linkedAccount.linkedLoanApplicationId.map { [$0] } ?? []
                )
            )
        }

        return accounts
    }

    private func applyEMIPaymentsToLoanOutstanding() {
        guard !transactions.isEmpty else { return }

        for loanIndex in loanAccounts.indices {
            let loan = loanAccounts[loanIndex]
            let paidAmount = transactions
                .filter { transaction in
                    transaction.type == .emiPayment &&
                    transaction.bankAccountId == loan.linkedBankAccountId
                }
                .map(\.amount)
                .reduce(0, +)

            guard paidAmount > 0 else { continue }

            loanAccounts[loanIndex].principalOutstanding = max(0, loan.sanctionedAmount - paidAmount)
            loanAccounts[loanIndex].tenureRemainingMonths = max(
                0,
                loan.totalTenureMonths - Int(paidAmount / max(1, loan.totalEMI))
            )
            if loan.sanctionedAmount > 0 {
                loanAccounts[loanIndex].repaidPercentage = min(1, paidAmount / loan.sanctionedAmount)
            }
        }
    }

    private func refreshPendingEMIs() {
        pendingEMIs = loanAccounts.filter { $0.principalOutstanding > 0 }.compactMap { loan in
            EMIRecord(
                dueDate: loan.nextEMIDate,
                amount: loan.totalEMI,
                loanType: loan.loanType,
                status: .dueSoon
            )
        }
        .sorted { $0.dueDate < $1.dueDate }
    }

    private func syncApprovedLoanODAccounts(_ approvedApps: [BorrowerLoanApplication], profile: BorrowerProfile) {
        let linkedAccounts = profile.linkedAccounts ?? []

        for app in approvedApps {
            let sanctionedAmount = app.formData.requestedAmountValue
            guard sanctionedAmount > 0 else { continue }

            let linkedODAccount = linkedAccounts.first {
                $0.linkedLoanApplicationId == app.id && $0.isOverdraftAccount
            }
            let needsProvisioning = linkedODAccount == nil || linkedODAccount?.balance == 0

            guard needsProvisioning else { continue }

            _ = BorrowerProfileStore.shared.provisionODAccountForApprovedLoan(
                email: app.formData.emailAddress,
                applicationId: app.id,
                applicationNumber: app.applicationId ?? app.displayIdentifier,
                borrowerName: app.formData.fullName,
                sanctionedAmount: sanctionedAmount
            )
        }
    }

    private func emiRepaymentAccount() -> BankAccount? {
        bankAccounts.first(where: { $0.accountType == .overdraft })
    }

    func linkedRepaymentAccount(for loan: DashboardLoanAccount) -> BankAccount? {
        bankAccounts.first(where: { $0.id == loan.linkedBankAccountId })
            ?? bankAccounts.first(where: { $0.linkedLoanIds.contains(loan.id) })
    }

    func currentAccountBalance(for loan: DashboardLoanAccount) -> Double {
        linkedRepaymentAccount(for: loan)?.availableBalance ?? 0
    }

    private func ensureRepaymentAccount(for loan: DashboardLoanAccount) -> BankAccount {
        if let account = linkedRepaymentAccount(for: loan) {
            return account
        }

        let account = BankAccount(
            id: loan.linkedBankAccountId,
            accountNumber: loan.accountNumber,
            bankName: "Loan OD Account",
            accountType: .overdraft,
            availableBalance: 0,
            odLimit: loan.sanctionedAmount,
            linkedLoanIds: [loan.id]
        )
        bankAccounts.append(account)
        if bankAccount.accountNumber.isEmpty {
            bankAccount = account
        }
        return account
    }

    private func disbursementCredits(for profile: BorrowerProfile) -> [String: Double] {
        let email = profile.email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        return CentralLoanRepository.shared.disbursementEvents
            .filter { event in
                event.borrowerEmail.isEmpty ||
                email.isEmpty ||
                event.borrowerEmail == email
            }
            .reduce(into: [:]) { credits, event in
                credits[event.accountNumber, default: 0] += event.amount
            }
    }

    
    // Quick-action methods
    public func payNextEMI() {
        let dueEMIs = nextDueEMIs
        guard !dueEMIs.isEmpty,
              let repaymentAccount = emiRepaymentAccount(),
              repaymentAccount.availableBalance >= nextDueAmount else {
            return
        }

        for emi in dueEMIs {
            _ = payEMI(emi)
        }
    }

    @discardableResult
    public func payEMI(_ emi: EMIRecord) -> Bool {
        guard let index = pendingEMIs.firstIndex(where: { $0.id == emi.id }),
              pendingEMIs[index].status != .paid else {
            return false
        }
        
        // Trigger haptic feedback
        HapticsManager.triggerImpact(style: .medium)
        
        guard let repaymentAccount = emiRepaymentAccount(),
              repaymentAccount.availableBalance >= emi.amount else {
            return false
        }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            let updatedBalance = repaymentAccount.availableBalance - emi.amount

            if let accountIndex = bankAccounts.firstIndex(where: { $0.id == repaymentAccount.id }) {
                bankAccounts[accountIndex].availableBalance = updatedBalance
            }
            if bankAccount.id == repaymentAccount.id {
                bankAccount.availableBalance = updatedBalance
            }

            BorrowerProfileStore.shared.updateLinkedAccountBalance(
                accountId: repaymentAccount.id,
                balance: updatedBalance
            )

            pendingEMIs[index].status = .paid
                
            // Add a new transaction row for the EMI paid
            let refNo = "TXN\(Int.random(in: 1000000...9999999))"
            let newTx = Transaction(
                title: "EMI paid for \(emi.loanType)",
                date: Date(),
                amount: emi.amount,
                type: .emiPayment,
                referenceNo: refNo,
                bankAccountId: repaymentAccount.id
            )
            transactions.insert(newTx, at: 0)

            if let profile = BorrowerProfileStore.shared.profile,
               let borrowerUUID = UUID(uuidString: profile.id) {
                let dbTx = DBTransaction(
                    id: newTx.id,
                    title: newTx.title,
                    date: newTx.date,
                    amount: newTx.amount,
                    type: "emi_payment",
                    referenceNo: refNo,
                    bankAccountId: repaymentAccount.id,
                    borrowerId: borrowerUUID
                )
                Task {
                    do {
                        try await SupabaseManager.shared.client
                            .from("transactions")
                            .insert(dbTx)
                            .execute()
                        print("[DashboardViewModel] Successfully saved EMI payment transaction to Supabase.")
                    } catch {
                        print("[DashboardViewModel] Error saving EMI payment transaction to Supabase: \(error.localizedDescription)")
                    }
                }
            }
        }
        return true
    }

    @discardableResult
    public func payEMI(for loan: DashboardLoanAccount, scheduledDate: Date = Date()) -> (success: Bool, reference: String?, totalDebited: Double, penalty: Double) {
        guard loan.principalOutstanding > 0 else {
            return (false, nil, 0, 0)
        }

        HapticsManager.triggerImpact(style: .medium)

        let account = ensureRepaymentAccount(for: loan)
        let principalComponent = min(loan.principalOutstanding, loan.totalEMI)
        let penalty = account.availableBalance < loan.totalEMI ? Self.emiShortfallPenalty : 0
        let totalDebited = loan.totalEMI + penalty
        let updatedAccountBalance = account.availableBalance - totalDebited
        let refNo = "TXN\(Int.random(in: 1000000...9999999))"

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            if let accountIndex = bankAccounts.firstIndex(where: { $0.id == account.id }) {
                bankAccounts[accountIndex].availableBalance = updatedAccountBalance
            }
            if bankAccount.id == account.id {
                bankAccount.availableBalance = updatedAccountBalance
            }

            BorrowerProfileStore.shared.updateLinkedAccountBalance(
                accountId: account.id,
                balance: updatedAccountBalance
            )

            if let loanIndex = loanAccounts.firstIndex(where: { $0.id == loan.id }) {
                loanAccounts[loanIndex].principalOutstanding = max(0, loanAccounts[loanIndex].principalOutstanding - principalComponent)
                loanAccounts[loanIndex].tenureRemainingMonths = max(0, loanAccounts[loanIndex].tenureRemainingMonths - 1)
                if loanAccounts[loanIndex].sanctionedAmount > 0 {
                    let paid = loanAccounts[loanIndex].sanctionedAmount - loanAccounts[loanIndex].principalOutstanding
                    loanAccounts[loanIndex].repaidPercentage = min(1, max(0, paid / loanAccounts[loanIndex].sanctionedAmount))
                }
                loanAccounts[loanIndex].nextEMIDate = Calendar.current.date(byAdding: .month, value: 1, to: loan.nextEMIDate) ?? loan.nextEMIDate
            }

            if let emiIndex = pendingEMIs.firstIndex(where: { $0.loanType == loan.loanType && $0.status != .paid }) {
                pendingEMIs[emiIndex].status = .paid
            }

            let newTx = Transaction(
                title: scheduledDate > Date() ? "Scheduled EMI for \(loan.loanType)" : "EMI paid for \(loan.loanType)",
                date: Date(),
                amount: loan.totalEMI,
                type: .emiPayment,
                referenceNo: refNo,
                bankAccountId: account.id
            )
            transactions.insert(newTx, at: 0)

            saveTransactionToRemote(newTx, type: "emi_payment", borrowerType: "emi_payment")

            if penalty > 0 {
                let penaltyTx = Transaction(
                    title: "Penalty for insufficient EMI balance",
                    date: Date(),
                    amount: penalty,
                    type: .penalty,
                    referenceNo: "PEN\(Int.random(in: 1000000...9999999))",
                    bankAccountId: account.id
                )
                transactions.insert(penaltyTx, at: 1)
                saveTransactionToRemote(penaltyTx, type: "penalty", borrowerType: "penalty")
            }
        }
        return (true, refNo, totalDebited, penalty)
    }
    
    public func topUpAccount(amount: Double, to account: BankAccount? = nil) {
        HapticsManager.triggerImpact(style: .light)
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            let destinationID = account?.id ?? bankAccount.id
            var updatedBalance = bankAccount.availableBalance + amount

            if let index = bankAccounts.firstIndex(where: { $0.id == destinationID }) {
                bankAccounts[index].availableBalance += amount
                updatedBalance = bankAccounts[index].availableBalance
                bankAccount = bankAccounts[index]
            } else {
                bankAccount.availableBalance += amount
                updatedBalance = bankAccount.availableBalance
            }

            BorrowerProfileStore.shared.updateLinkedAccountBalance(
                accountId: destinationID,
                balance: updatedBalance
            )
            
            // Add a credit transaction row
            let refNo = "TXN\(Int.random(in: 1000000...9999999))"
            let newTx = Transaction(
                title: "Account Top-Up",
                date: Date(),
                amount: amount,
                type: .credit,
                referenceNo: refNo,
                bankAccountId: destinationID
            )
            transactions.insert(newTx, at: 0)

            if let profile = BorrowerProfileStore.shared.profile,
               let borrowerUUID = UUID(uuidString: profile.id) {
                let dbTx = DBTransaction(
                    id: newTx.id,
                    title: newTx.title,
                    date: newTx.date,
                    amount: newTx.amount,
                    type: "credit",
                    referenceNo: refNo,
                    bankAccountId: destinationID,
                    borrowerId: borrowerUUID
                )
                Task {
                    do {
                        try await SupabaseManager.shared.client
                            .from("transactions")
                            .insert(dbTx)
                            .execute()
                        print("[DashboardViewModel] Successfully saved Account Top-Up transaction to Supabase.")
                    } catch {
                        print("[DashboardViewModel] Error saving Account Top-Up transaction to Supabase: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    public func submitForeclosureRequest(for loan: DashboardLoanAccount) -> ForeclosureRequest {
        if let existing = foreclosureRequest(for: loan) {
            return existing
        }

        let summary = Self.foreclosureAmountSummary(for: loan)
        let request = ForeclosureRequest(
            requestID: "FC-\(Int(Date().timeIntervalSince1970))",
            loanID: loan.id,
            loanType: loan.loanType,
            loanAccountNumber: loan.accountNumber,
            outstandingPrincipal: summary.principal,
            accruedInterest: summary.interest,
            foreclosureCharges: summary.charges,
            gst: summary.gst,
            totalPayable: summary.total
        )
        foreclosureRequests.insert(request, at: 0)
        transactions.insert(
            Transaction(
                title: "Foreclosure request submitted - \(loan.loanType)",
                date: Date(),
                amount: 0,
                type: .credit,
                referenceNo: request.requestID,
                bankAccountId: loan.linkedBankAccountId
            ),
            at: 0
        )
        simulateForeclosureReview(for: request.id)
        return request
    }

    public func payForeclosureAmount(requestID: UUID, from account: BankAccount) -> Bool {
        guard let requestIndex = foreclosureRequests.firstIndex(where: { $0.id == requestID }),
              foreclosureRequests[requestIndex].status.isPaymentReady,
              account.availableBalance >= foreclosureRequests[requestIndex].totalPayable else {
            return false
        }

        let request = foreclosureRequests[requestIndex]
        let updatedBalance = account.availableBalance - request.totalPayable
        let reference = "FCP\(Int.random(in: 1000000...9999999))"

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            if let accountIndex = bankAccounts.firstIndex(where: { $0.id == account.id }) {
                bankAccounts[accountIndex].availableBalance = updatedBalance
            }
            if bankAccount.id == account.id {
                bankAccount.availableBalance = updatedBalance
            }
            BorrowerProfileStore.shared.updateLinkedAccountBalance(accountId: account.id, balance: updatedBalance)

            if let loanIndex = loanAccounts.firstIndex(where: { $0.id == request.loanID }) {
                loanAccounts[loanIndex].principalOutstanding = 0
                loanAccounts[loanIndex].tenureRemainingMonths = 0
                loanAccounts[loanIndex].repaidPercentage = 1
            }
            pendingEMIs.removeAll { $0.loanType == request.loanType }

            foreclosureRequests[requestIndex].status = .closed
            foreclosureRequests[requestIndex].paymentReference = reference
            foreclosureRequests[requestIndex].updatedAt = Date()

            let payment = Transaction(
                title: "Foreclosure paid - \(request.loanType)",
                date: Date(),
                amount: request.totalPayable,
                type: .emiPayment,
                referenceNo: reference,
                bankAccountId: account.id
            )
            let certificate = Transaction(
                title: "Loan closure certificate generated",
                date: Date(),
                amount: 0,
                type: .credit,
                referenceNo: "LCC\(Int.random(in: 100000...999999))",
                bankAccountId: account.id
            )
            transactions.insert(contentsOf: [payment, certificate], at: 0)
            saveTransactionToRemote(payment, type: "foreclosure_payment", borrowerType: "emi_payment")
        }

        HapticsManager.triggerNotification(type: .success)
        return true
    }

    public static func foreclosureAmountSummary(for loan: DashboardLoanAccount) -> (principal: Double, interest: Double, charges: Double, gst: Double, total: Double) {
        let principal = loan.principalOutstanding
        let interest = max(loan.totalEMI * 0.18, principal * 0.002)
        let charges = min(max(2_000, principal * 0.002), principal * 0.015)
        let gst = charges * 0.18
        return (principal, interest, charges, gst, principal + interest + charges + gst)
    }

    private func simulateForeclosureReview(for id: UUID) {
        let statuses: [(ForeclosureRequestStatus, String?, String?, UInt64)] = [
            (.officerReview, nil, nil, 700_000_000),
            (.recommended, "Recommended after payment history and pending dues review.", nil, 900_000_000),
            (.managerApproval, "Recommended after payment history and pending dues review.", nil, 900_000_000),
            (.awaitingPayment, "Recommended after payment history and pending dues review.", "Approved. Final foreclosure amount generated.", 1_000_000_000)
        ]

        Task { @MainActor in
            for item in statuses {
                try? await Task.sleep(nanoseconds: item.3)
                guard let index = foreclosureRequests.firstIndex(where: { $0.id == id }),
                      foreclosureRequests[index].status != .closed,
                      foreclosureRequests[index].status != .rejected else {
                    return
                }
                foreclosureRequests[index].status = item.0
                foreclosureRequests[index].officerRecommendation = item.1
                foreclosureRequests[index].managerDecision = item.2
                foreclosureRequests[index].updatedAt = Date()
            }
        }
    }

    public func topUpLoanLinkedAccount(amount: Double, to loan: DashboardLoanAccount) {
        guard amount > 0 else { return }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            let account = ensureRepaymentAccount(for: loan)
            let updatedBalance = account.availableBalance + amount
            if let accountIndex = bankAccounts.firstIndex(where: { $0.id == account.id }) {
                bankAccounts[accountIndex].availableBalance = updatedBalance
            }
            if bankAccount.id == account.id {
                bankAccount.availableBalance = updatedBalance
            }
            BorrowerProfileStore.shared.updateLinkedAccountBalance(
                accountId: account.id,
                balance: updatedBalance
            )

            let refNo = "TXN\(Int.random(in: 1000000...9999999))"
            let newTx = Transaction(
                title: "Funds added to \(loan.loanType) linked account",
                date: Date(),
                amount: amount,
                type: .credit,
                referenceNo: refNo,
                bankAccountId: account.id
            )
            transactions.insert(newTx, at: 0)
            saveTransactionToRemote(newTx, type: "loan_linked_top_up", borrowerType: "credit")
        }
    }

    private func saveTransactionToRemote(_ transaction: Transaction, type: String, borrowerType: String) {
        guard let profile = BorrowerProfileStore.shared.profile,
              let borrowerUUID = UUID(uuidString: profile.id) else { return }

        let dbTx = DBTransaction(
            id: transaction.id,
            title: transaction.title,
            date: transaction.date,
            amount: transaction.amount,
            type: borrowerType,
            referenceNo: transaction.referenceNo,
            bankAccountId: transaction.bankAccountId,
            borrowerId: borrowerUUID
        )

        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("transactions")
                    .insert(dbTx)
                    .execute()
                print("[DashboardViewModel] Successfully saved \(type) transaction to Supabase.")
            } catch {
                print("[DashboardViewModel] Error saving \(type) transaction to Supabase: \(error.localizedDescription)")
            }
        }
    }
    
}

private extension Array where Element == Transaction {
    func uniquedByReference() -> [Transaction] {
        var seen = Set<String>()
        return filter { transaction in
            seen.insert(transaction.referenceNo).inserted
        }
    }
}
