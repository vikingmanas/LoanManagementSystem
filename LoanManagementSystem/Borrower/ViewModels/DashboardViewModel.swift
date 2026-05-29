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
    @Published public var loanAccounts: [DashboardLoanAccount] = []
    @Published public var bankAccount: BankAccount = BankAccount(accountNumber: "", accountType: .savings, availableBalance: 0)
    @Published public var bankAccounts: [BankAccount] = []
    @Published public var pendingEMIs: [EMIRecord] = []
    @Published public var transactions: [Transaction] = []
    @Published public var schemes: [GovernmentScheme] = []
    @Published public var isLoading: Bool = true
    @Published public var profileName: String = ""
    @Published public var profileCompletionPercentage: Int = 0
    
    // Quick demonstration toggle state (e.g. to mock low balance vs normal)
    @Published public var forceLowBalanceMockState: Bool = false

    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        CentralLoanRepository.shared.$disbursementEvents
            .dropFirst()
            .sink { [weak self] _ in
                Task { await self?.fetchDashboardData() }
            }
            .store(in: &cancellables)

        CentralLoanRepository.shared.$applications
            .dropFirst()
            .sink { [weak self] _ in
                Task { await self?.fetchDashboardData() }
            }
            .store(in: &cancellables)

        BorrowerProfileStore.shared.$profile
            .receive(on: DispatchQueue.main)
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
    
    public var nextEMI: EMIRecord? {
        pendingEMIs.first { $0.status != .paid }
    }
    
    public var isLowBalance: Bool {
        guard !bankAccounts.isEmpty else { return false }
        guard let nextEMI = nextEMI else { return false }
        return bankAccount.availableBalance < nextEMI.amount
    }
    
    public var balanceDeficit: Double {
        guard let nextEMI = nextEMI else { return 0 }
        return max(0, nextEMI.amount - bankAccount.availableBalance)
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

    public var dashboardNotifications: [LMSNotification] {
        let live = CentralLoanRepository.shared.borrowerNotifications
        let merged = live + LMSMockNotifications.sample
        var seen = Set<UUID>()
        return merged.filter { seen.insert($0.id).inserted }
            .sorted { $0.timestamp > $1.timestamp }
    }

    public var profileMissingRequirements: [String] {
        guard let profile = BorrowerProfileStore.shared.profile else {
            return ["Complete personal details", "Verify contact information", "Link your bank account"]
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
        if profile.bankDetails.accountNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            missing.append("Link bank account")
        }
        if profile.kycVerification.aadhaarStatus != .verified {
            missing.append("Complete KYC verification")
        }
        if profile.profileImageData == nil {
            missing.append("Add profile photo")
        }
        return missing
    }
    
    public func isLowBalance(_ account: BankAccount) -> Bool {
        if account.id == MockData.uuid3 { // Axis Bank
            return account.availableBalance < 9200.0
        }
        if account.id == MockData.uuid1 { // SBI
            return forceLowBalanceMockState ? true : account.availableBalance < (account.minBalance ?? 5000.0)
        }
        return false
    }
    
    public func balanceDeficit(for account: BankAccount) -> Double {
        if account.id == MockData.uuid3 { // Axis Bank
            return max(0, 9200.0 - account.availableBalance)
        }
        if account.id == MockData.uuid1 { // SBI
            return max(0, 18500.0 - account.availableBalance)
        }
        return 0
    }
    
    public func fetchDashboardData() async {
        isLoading = true
        defer { isLoading = false }

        if let email = BorrowerProfileStore.shared.currentEmail ?? BorrowerProfileStore.shared.profile?.email,
           !email.isEmpty,
           BorrowerProfileStore.shared.profile == nil {
            _ = BorrowerProfileStore.shared.ensureProfile(email: email)
        }
        
        // Simulate a 0.8s network latency delay
        do {
            try await Task.sleep(nanoseconds: 800_000_000)
            try Task.checkCancellation()
        } catch {
            return
        }
        
        if let profile = BorrowerProfileStore.shared.profile {
            self.profileName = profile.fullName
            self.profileCompletionPercentage = profile.profileCompletionPercentage
            let disbursedCredits = disbursementCredits(for: profile)
            self.bankAccounts = buildBankAccounts(from: profile, disbursedCredits: disbursedCredits)
            self.bankAccount = bankAccounts.first(where: { $0.accountType == .savings })
                ?? bankAccounts.first
                ?? BankAccount(accountNumber: "", bankName: "", accountType: .savings, availableBalance: 0)
        } else {
            self.profileName = ""
            self.profileCompletionPercentage = 0
            self.bankAccount = BankAccount(accountNumber: "", bankName: "", accountType: .savings, availableBalance: 0.0)
            self.bankAccounts = []
        }
        
        // Load loan accounts from approved/disbursed applications in CentralLoanRepository
        let approvedApps = CentralLoanRepository.shared.applications.filter {
            $0.currentStage == .approved || $0.currentStage == .disbursed
        }
        
        self.loanAccounts = approvedApps.map { app in
            let totalEMI = app.formData.requestedAmountValue / Double(max(1, app.formData.preferredTenureMonths))
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
                linkedBankAccountId: bankAccount.id
            )
        }
        
        // Dynamically populate pending EMIs based on active loans
        self.pendingEMIs = self.loanAccounts.compactMap { loan in
            EMIRecord(
                dueDate: loan.nextEMIDate,
                amount: loan.totalEMI,
                loanType: loan.loanType,
                status: .dueSoon
            )
        }
        
        self.schemes = MockData.sampleSchemes

        // Fetch actual transactions from Supabase if borrower profile is available
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

        self.transactions = dbTransactionsList.sorted { $0.date > $1.date }
    }



    private func buildBankAccounts(from profile: BorrowerProfile, disbursedCredits: [String: Double]) -> [BankAccount] {
        var accounts: [BankAccount] = []
        let bank = profile.bankDetails
        let linked = profile.linkedAccounts ?? []
        let linkedNumbers = Set(linked.map(\.accountNumber))

        if !bank.accountNumber.isEmpty, !linkedNumbers.contains(bank.accountNumber) {
            accounts.append(
                BankAccount(
                    accountNumber: bank.accountNumber,
                    bankName: bank.bankName.isEmpty ? "My Main Bank" : bank.bankName,
                    accountType: .savings,
                    availableBalance: disbursedCredits[bank.accountNumber, default: 0]
                )
            )
        }

        for linkedAccount in linked {
            let isOD = linkedAccount.isOverdraftAccount
            let extraCredits = isOD ? 0 : disbursedCredits[linkedAccount.accountNumber, default: 0]
            accounts.append(
                BankAccount(
                    id: linkedAccount.id,
                    accountNumber: linkedAccount.accountNumber,
                    bankName: linkedAccount.bankName,
                    accountType: isOD ? .overdraft : .savings,
                    availableBalance: linkedAccount.balance + extraCredits,
                    odLimit: linkedAccount.odSanctionLimit,
                    linkedLoanIds: linkedAccount.linkedLoanApplicationId.map { [$0] } ?? []
                )
            )
        }

        if accounts.isEmpty, !bank.accountNumber.isEmpty {
            accounts.append(
                BankAccount(
                    accountNumber: bank.accountNumber,
                    bankName: bank.bankName.isEmpty ? "My Main Bank" : bank.bankName,
                    accountType: .savings,
                    availableBalance: disbursedCredits[bank.accountNumber, default: 0]
                )
            )
        }

        return accounts
    }

    private func emiRepaymentAccount() -> BankAccount? {
        bankAccounts.first(where: { $0.accountType == .overdraft }) ??
        bankAccounts.first(where: { $0.accountType == .savings })
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
        guard let currentNextEMI = nextEMI else { return }
        _ = payEMI(currentNextEMI)
    }

    @discardableResult
    public func payEMI(_ emi: EMIRecord) -> Bool {
        guard let index = pendingEMIs.firstIndex(where: { $0.id == emi.id }),
              pendingEMIs[index].status != .paid else {
            return false
        }
        
        // Trigger haptic feedback
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.prepare()
        feedback.impactOccurred()
        
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
    public func payEMI(for loan: DashboardLoanAccount, from account: BankAccount, scheduledDate: Date = Date()) -> Bool {
        guard account.availableBalance >= loan.totalEMI,
              loan.principalOutstanding > 0 else {
            return false
        }

        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.prepare()
        feedback.impactOccurred()

        let principalComponent = min(loan.principalOutstanding, loan.totalEMI * 0.73)
        let updatedAccountBalance = account.availableBalance - loan.totalEMI

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

            let refNo = "TXN\(Int.random(in: 1000000...9999999))"
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
        }
        return true
    }
    
    public func topUpAccount(amount: Double, to account: BankAccount? = nil) {
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            let destinationID = account?.id ?? bankAccount.id

            if let index = bankAccounts.firstIndex(where: { $0.id == destinationID }) {
                bankAccounts[index].availableBalance += amount
                bankAccount = bankAccounts[index]
            } else {
                bankAccount.availableBalance += amount
            }
            
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

    public func transferFunds(amount: Double, from source: BankAccount, to destination: BankAccount) {
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            if let sourceIndex = bankAccounts.firstIndex(where: { $0.id == source.id }) {
                bankAccounts[sourceIndex].availableBalance = max(0, bankAccounts[sourceIndex].availableBalance - amount)
            }

            if let destinationIndex = bankAccounts.firstIndex(where: { $0.id == destination.id }) {
                bankAccounts[destinationIndex].availableBalance += amount
                bankAccount = bankAccounts[destinationIndex]
            }

            let refNo = "TXN\(Int.random(in: 1000000...9999999))"
            let newTx = Transaction(
                title: "Transfer to \(destination.bankName.isEmpty ? "Linked Account" : destination.bankName)",
                date: Date(),
                amount: amount,
                type: .credit,
                referenceNo: refNo,
                bankAccountId: destination.id
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
                    bankAccountId: destination.id,
                    borrowerId: borrowerUUID
                )
                Task {
                    do {
                        try await SupabaseManager.shared.client
                            .from("transactions")
                            .insert(dbTx)
                            .execute()
                        print("[DashboardViewModel] Successfully saved transfer transaction to Supabase.")
                    } catch {
                        print("[DashboardViewModel] Error saving transfer transaction to Supabase: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    public func transferFundsToLoan(amount: Double, from source: BankAccount, to loan: DashboardLoanAccount) {
        guard source.availableBalance >= amount else { return }

        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.impactOccurred()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            let updatedBalance = source.availableBalance - amount
            if let sourceIndex = bankAccounts.firstIndex(where: { $0.id == source.id }) {
                bankAccounts[sourceIndex].availableBalance = updatedBalance
            }
            if bankAccount.id == source.id {
                bankAccount.availableBalance = updatedBalance
            }
            BorrowerProfileStore.shared.updateLinkedAccountBalance(accountId: source.id, balance: updatedBalance)

            if let loanIndex = loanAccounts.firstIndex(where: { $0.id == loan.id }) {
                loanAccounts[loanIndex].principalOutstanding = max(0, loanAccounts[loanIndex].principalOutstanding - amount)
                if loanAccounts[loanIndex].sanctionedAmount > 0 {
                    let paid = loanAccounts[loanIndex].sanctionedAmount - loanAccounts[loanIndex].principalOutstanding
                    loanAccounts[loanIndex].repaidPercentage = min(1, max(0, paid / loanAccounts[loanIndex].sanctionedAmount))
                }
            }

            let refNo = "TXN\(Int.random(in: 1000000...9999999))"
            let newTx = Transaction(
                title: "Top up to \(loan.loanType)",
                date: Date(),
                amount: amount,
                type: .emiPayment,
                referenceNo: refNo,
                bankAccountId: source.id
            )
            transactions.insert(newTx, at: 0)
            saveTransactionToRemote(newTx, type: "emi_payment", borrowerType: "emi_payment")
        }
    }

    public func transferToExternalReceiver(amount: Double, from source: BankAccount, receiverName: String) {
        guard source.availableBalance >= amount else { return }

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            let updatedBalance = source.availableBalance - amount
            if let sourceIndex = bankAccounts.firstIndex(where: { $0.id == source.id }) {
                bankAccounts[sourceIndex].availableBalance = updatedBalance
            }
            if bankAccount.id == source.id {
                bankAccount.availableBalance = updatedBalance
            }
            BorrowerProfileStore.shared.updateLinkedAccountBalance(accountId: source.id, balance: updatedBalance)

            let refNo = "TXN\(Int.random(in: 1000000...9999999))"
            let newTx = Transaction(
                title: "QR transfer to \(receiverName)",
                date: Date(),
                amount: amount,
                type: .failedDebit,
                referenceNo: refNo,
                bankAccountId: source.id
            )
            transactions.insert(newTx, at: 0)
            saveTransactionToRemote(newTx, type: "transfer", borrowerType: "transfer")
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
    
    public func toggleBalanceMockMode() {
        let feedback = UIImpactFeedbackGenerator(style: .rigid)
        feedback.impactOccurred()
        
        forceLowBalanceMockState.toggle()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            if forceLowBalanceMockState {
                bankAccount.availableBalance = 12300.0
            } else {
                bankAccount.availableBalance = 42300.0
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
