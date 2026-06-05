import SwiftUI

struct LinkedBankAccountsDetailView: View {
    @Bindable var viewModel: BorrowerProfileViewModel

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

        }
        .navigationTitle("Loan Account")
        .navigationBarTitleDisplayMode(.inline)
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

    }

