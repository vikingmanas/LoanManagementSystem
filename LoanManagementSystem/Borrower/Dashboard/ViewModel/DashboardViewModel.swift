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
        
        // Simulate a 1.5s network latency delay
        do {
            try await Task.sleep(nanoseconds: 1_500_000_000)
            try Task.checkCancellation()
        } catch {
            return
        }
        
        // Prepopulate data
        self.loanAccounts = [
            MockData.home,
            MockData.business,
            MockData.car
        ]
        
        // Base bank account balance depends on mockup state
        let sbiBalance = forceLowBalanceMockState ? 12300.0 : 42300.0
        
        let sbiAcc = BankAccount(
            id: MockData.uuid1,
            accountNumber: "XXXXXX7890",
            bankName: "State Bank of India",
            accountType: .savings,
            availableBalance: sbiBalance,
            minBalance: 5000.0,
            linkedLoanIds: [MockData.loanId1]
        )
        
        let hdfcAcc = BankAccount(
            id: MockData.uuid2,
            accountNumber: "XXXXXX3421",
            bankName: "HDFC Bank",
            accountType: .overdraft,
            availableBalance: 15000.0,
            odLimit: 50000.0,
            linkedLoanIds: [MockData.loanId2]
        )
        
        let axisAcc = BankAccount(
            id: MockData.uuid3,
            accountNumber: "XXXXXX9910",
            bankName: "Axis Bank",
            accountType: .current,
            availableBalance: 2800.0,
            linkedLoanIds: [MockData.loanId3]
        )
        
        self.bankAccounts = [sbiAcc, hdfcAcc, axisAcc]
        self.bankAccount = sbiAcc
        
        self.pendingEMIs = MockData.samplePendingEMIs
        self.transactions = MockData.sampleTransactions
        self.schemes = MockData.sampleSchemes
        
        self.isLoading = false
    }
    
    // Quick-action methods
    public func payNextEMI() {
        guard let currentNextEMI = nextEMI else { return }
        
        // Trigger haptic feedback
        let feedback = UIImpactFeedbackGenerator(style: .medium)
        feedback.prepare()
        feedback.impactOccurred()
        
        // Deduct balance if sufficient, and transition EMI status to paid
        if bankAccount.availableBalance >= currentNextEMI.amount {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                bankAccount.availableBalance -= currentNextEMI.amount
                // Update the matching EMI to paid
                if let index = pendingEMIs.firstIndex(where: { $0.id == currentNextEMI.id }) {
                    pendingEMIs[index].status = .paid
                }
                
                // Add a new transaction row for the EMI paid
                let newTx = Transaction(
                    title: "EMI - \(currentNextEMI.loanType)",
                    date: Date(),
                    amount: currentNextEMI.amount,
                    type: .emiPayment,
                    referenceNo: "TXN\(Int.random(in: 1000000...9999999))"
                )
                transactions.insert(newTx, at: 0)
            }
        }
    }
    
    public func topUpAccount(amount: Double) {
        let feedback = UIImpactFeedbackGenerator(style: .light)
        feedback.impactOccurred()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            bankAccount.availableBalance += amount
            
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
