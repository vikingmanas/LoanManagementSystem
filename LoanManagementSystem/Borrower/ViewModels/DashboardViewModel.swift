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
    
    // Quick demonstration toggle state (e.g. to mock low balance vs normal)
    @Published public var forceLowBalanceMockState: Bool = false
    
    public init() {}
    
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
        
        // Simulate a 0.8s network latency delay
        do {
            try await Task.sleep(nanoseconds: 800_000_000)
            try Task.checkCancellation()
        } catch {
            return
        }
        
        // Load bank account from user profile
        if let profile = BorrowerProfileStore.shared.profile {
            let bank = profile.bankDetails
            let bankName = bank.bankName.isEmpty ? "My Main Bank" : bank.bankName
            let acctNum = bank.accountNumber.isEmpty ? "0000000000" : bank.accountNumber
            
            if self.bankAccount.bankName.isEmpty || self.bankAccount.accountNumber == "XXXX 7890" {
                self.bankAccount = BankAccount(
                    id: UUID(),
                    accountNumber: acctNum,
                    bankName: bankName,
                    accountType: .savings,
                    availableBalance: 0.0
                )
            } else {
                self.bankAccount.bankName = bankName
                self.bankAccount.accountNumber = acctNum
            }
            let additionalAccounts = (profile.linkedAccounts ?? []).map { linkedAccount in
                BankAccount(
                    id: linkedAccount.id,
                    accountNumber: linkedAccount.accountNumber,
                    bankName: linkedAccount.bankName,
                    accountType: .savings,
                    availableBalance: linkedAccount.balance
                )
            }
            self.bankAccounts = [self.bankAccount] + additionalAccounts
        } else {
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
        
        self.isLoading = false
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
        
        // Deduct balance if sufficient, and transition EMI status to paid
        if bankAccount.availableBalance >= emi.amount {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                bankAccount.availableBalance -= emi.amount

                if let accountIndex = bankAccounts.firstIndex(where: { $0.id == bankAccount.id }) {
                    bankAccounts[accountIndex].availableBalance = bankAccount.availableBalance
                }

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

        return false
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
