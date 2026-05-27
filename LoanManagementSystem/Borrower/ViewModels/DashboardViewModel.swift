//
//  DashboardViewModel.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 19/05/26.
//

import SwiftUI
import Combine

@MainActor
public final class DashboardViewModel: ObservableObject {
    @Published public var loanAccounts: [DashboardLoanAccount] = []
    @Published public var bankAccount: BankAccount = BankAccount(accountNumber: "XXXX 7890", accountType: .savings, availableBalance: 0)
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
    
    public var nextEMI: EMIRecord? {
        pendingEMIs.first { $0.status != .paid }
    }
    
    public var isLowBalance: Bool {
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
                ?? BankAccount(accountNumber: "0000000000", bankName: "Default Bank", accountType: .savings, availableBalance: 0)
        } else {
            self.profileName = ""
            self.profileCompletionPercentage = 0
            self.bankAccount = BankAccount(accountNumber: "XXXX 0000", bankName: "Default Bank", accountType: .savings, availableBalance: 0.0)
            self.bankAccounts = [self.bankAccount]
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
                repaidPercentage: 0.0
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

        let disbursementTransactions = CentralLoanRepository.shared.disbursementEvents.map { event in
            Transaction(
                title: "Loan Amount Credited - \(event.applicationNumber)",
                date: event.creditedAt,
                amount: event.amount,
                type: .credit,
                referenceNo: event.referenceNumber,
                bankAccountId: bankAccounts.first(where: { $0.accountNumber == event.accountNumber })?.id
            )
        }
        let existingReferences = Set(transactions.map(\.referenceNo))
        transactions.insert(contentsOf: disbursementTransactions.filter { !existingReferences.contains($0.referenceNo) }, at: 0)
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

        if accounts.isEmpty {
            accounts.append(
                BankAccount(accountNumber: "0000000000", bankName: "Default Bank", accountType: .savings, availableBalance: 0)
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
                let newTx = Transaction(
                    title: "EMI - \(emi.loanType)",
                    date: Date(),
                    amount: emi.amount,
                    type: .emiPayment,
                    referenceNo: "TXN\(Int.random(in: 1000000...9999999))"
                )
                transactions.insert(newTx, at: 0)
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
            let newTx = Transaction(
                title: "Account Top-Up",
                date: Date(),
                amount: amount,
                type: .credit,
                referenceNo: "TXN\(Int.random(in: 1000000...9999999))"
            )
            transactions.insert(newTx, at: 0)
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

            let newTx = Transaction(
                title: "Transfer to \(destination.bankName.isEmpty ? "Linked Account" : destination.bankName)",
                date: Date(),
                amount: amount,
                type: .credit,
                referenceNo: "TXN\(Int.random(in: 1000000...9999999))"
            )
            transactions.insert(newTx, at: 0)
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
