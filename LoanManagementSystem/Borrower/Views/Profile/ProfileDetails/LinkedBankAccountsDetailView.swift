import SwiftUI

struct LinkedBankAccountsDetailView: View {
    @ObservedObject var viewModel: BorrowerProfileViewModel
    @State private var showingEditSheet = false
    @State private var accountToDelete: LinkedBankAccount?
    @State private var showingDeleteAlert = false
    
    private var hasPrimaryBank: Bool {
        guard let bank = viewModel.profile?.bankDetails else { return false }
        return !bank.bankName.isEmpty && !bank.accountNumber.isEmpty
    }

    private var linkedAccounts: [LinkedBankAccount] {
        viewModel.profile?.linkedAccounts ?? []
    }

    private var loanAccounts: [DashboardLoanAccount] {
        CentralLoanRepository.shared.applications
            .filter { $0.currentStage == .approved || $0.currentStage == .disbursed }
            .map { app in
                let amount = app.formData.requestedAmountValue
                let months = max(1, app.formData.preferredTenureMonths)
                return DashboardLoanAccount(
                    id: app.id,
                    accountNumber: app.applicationId ?? "L-\(app.id.uuidString.prefix(6).uppercased())",
                    loanType: app.product.type.title,
                    sanctionedAmount: amount,
                    principalOutstanding: amount,
                    totalEMI: amount / Double(months),
                    nextEMIDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date(),
                    tenureRemainingMonths: months,
                    totalTenureMonths: months,
                    repaidPercentage: 0
                )
            }
    }

    var body: some View {
        Form {
            Section {
                if loanAccounts.isEmpty {
                    Text("No loan account")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(loanAccounts) { loan in
                        loanAccountDetails(loan)
                    }
                }
            } header: {
                Text("Loan Accounts")
            } footer: {
                Text("Loan accounts are created automatically after approval and disbursement.")
            }

            if let bank = viewModel.profile?.bankDetails, hasPrimaryBank {
                Section {
                    LabeledContent("Bank Name", value: bank.bankName)
                    LabeledContent("Account Holder", value: bank.accountHolderName)
                    LabeledContent("Account Number", value: maskAccountNumber(bank.accountNumber))
                    LabeledContent("IFSC Code", value: bank.ifscCode)
                    
                    if let upi = bank.upiID {
                        LabeledContent("UPI ID", value: upi)
                    } else {
                        LabeledContent("UPI ID", value: "Not Linked")
                    }
                    
                    LabeledContent("Status") {
                        if bank.isVerified {
                            Text("Verified")
                                .font(.caption.bold())
                                .foregroundStyle(.green)
                        } else {
                            Text("Pending")
                                .font(.caption.bold())
                                .foregroundStyle(.orange)
                        }
                    }
                } header: {
                    Text("Primary Account")
                }
            }

            let odAccounts = linkedAccounts.filter(\.isOverdraftAccount)
            let savingsAccounts = linkedAccounts.filter { !$0.isOverdraftAccount }

            if !odAccounts.isEmpty {
                Section {
                    ForEach(odAccounts) { account in
                        linkedAccountDetails(account, isOD: true)
                    }
                    .onDelete { indexSet in
                        if let index = indexSet.first {
                            accountToDelete = odAccounts[index]
                            showingDeleteAlert = true
                        }
                    }
                } header: {
                    Text("OD Accounts (EMI Deduction)")
                } footer: {
                    Text("Loan disbursement is credited here and monthly EMIs are deducted from this account.")
                }
            }

            if !savingsAccounts.isEmpty {
                Section {
                    ForEach(savingsAccounts) { account in
                        linkedAccountDetails(account, isOD: false)
                    }
                    .onDelete { indexSet in
                        if let index = indexSet.first {
                            accountToDelete = savingsAccounts[index]
                            showingDeleteAlert = true
                        }
                    }
                } header: {
                    Text("Additional Accounts")
                }
            }

        }
        .navigationTitle("Bank Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditBankDetailsView(viewModel: viewModel)
        }
        .alert("Delete Bank Account?", isPresented: $showingDeleteAlert, presenting: accountToDelete) { account in
            Button("Delete", role: .destructive) {
                viewModel.deleteLinkedBankAccount(withId: account.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: { account in
            Text("Are you sure you want to delete the account ending in \(String(account.accountNumber.suffix(4)))?")
        }
    }
    
    private func maskAccountNumber(_ number: String) -> String {
        guard number.count > 4 else { return number }
        let suffix = number.suffix(4)
        return String(repeating: "•", count: number.count - 4) + suffix
    }

    private func loanAccountDetails(_ loan: DashboardLoanAccount) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(loan.loanType, systemImage: "doc.text.fill")
                    .font(.headline)
                Spacer()
                Text("Active")
                    .font(.caption.bold())
                    .foregroundStyle(LMSColors.emerald)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(LMSColors.emerald.opacity(0.12), in: Capsule())
            }
            LabeledContent("Account", value: maskAccountNumber(loan.accountNumber))
            LabeledContent("Outstanding", value: loan.principalOutstanding.formattedAsINR())
            LabeledContent("EMI Amount", value: loan.totalEMI.formattedAsINR())
            LabeledContent("Next EMI", value: loan.nextEMIDate.formattedAsDDMMMYYYY())
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func linkedAccountDetails(_ account: LinkedBankAccount, isOD: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(account.bankName, systemImage: isOD ? "indianrupeesign.circle.fill" : "building.columns.fill")
                    .font(.headline)
                    .foregroundStyle(.primary)

                Spacer()

                HStack(spacing: 8) {
                    Text(maskAccountNumber(account.accountNumber))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Button(role: .destructive) {
                        accountToDelete = account
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.subheadline)
                            .foregroundStyle(.red)
                    }
                    .buttonStyle(.plain)
                }
            }

            if !account.accountHolderName.isEmpty {
                LabeledContent("Account Holder", value: account.accountHolderName)
            }
            LabeledContent("IFSC Code", value: account.ifscCode)
            if !account.branch.isEmpty {
                LabeledContent("Branch", value: account.branch)
            }
            if !account.customerId.isEmpty {
                LabeledContent("Customer ID", value: account.customerId)
            }
            LabeledContent("Available Balance", value: account.balance.formattedAsINR())
            if isOD, let limit = account.odSanctionLimit {
                LabeledContent("OD Sanction Limit", value: limit.formattedAsINR())
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        LinkedBankAccountsDetailView(viewModel: PreviewSupport.borrowerProfileViewModel)
    }
}
