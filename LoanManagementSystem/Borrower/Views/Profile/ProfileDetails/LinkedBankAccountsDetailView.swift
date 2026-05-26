import SwiftUI

struct LinkedBankAccountsDetailView: View {
    @ObservedObject var viewModel: BorrowerProfileViewModel
    @State private var showingEditSheet = false
    @State private var showingAddSheet = false
    
    var body: some View {
        Form {
            if let bank = viewModel.profile?.bankDetails {
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

                if let linkedAccounts = viewModel.profile?.linkedAccounts, !linkedAccounts.isEmpty {
                    Section {
                        ForEach(linkedAccounts) { account in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Label(account.bankName, systemImage: "building.columns.fill")
                                        .font(.headline)
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    Text(maskAccountNumber(account.accountNumber))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                LabeledContent("IFSC Code", value: account.ifscCode)
                                if !account.branch.isEmpty {
                                    LabeledContent("Branch", value: account.branch)
                                }
                                if !account.customerId.isEmpty {
                                    LabeledContent("Customer ID", value: account.customerId)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    } header: {
                        Text("Additional Accounts")
                    }
                }

                Section {
                    Button {
                        showingAddSheet = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Add Another Account", systemImage: "plus.circle.fill")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .foregroundStyle(LMSColors.brandNavy)
                }
            } else {
                Section {
                    Text("No linked bank account.")

                    Button {
                        showingAddSheet = true
                    } label: {
                        HStack {
                            Spacer()
                            Label("Add Account", systemImage: "plus.circle.fill")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .foregroundStyle(LMSColors.brandNavy)
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
        .sheet(isPresented: $showingAddSheet) {
            AddLinkedBankAccountView(viewModel: viewModel)
        }
    }
    
    private func maskAccountNumber(_ number: String) -> String {
        guard number.count > 4 else { return number }
        let suffix = number.suffix(4)
        return String(repeating: "•", count: number.count - 4) + suffix
    }
}

private struct AddLinkedBankAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: BorrowerProfileViewModel

    @State private var bankName = ""
    @State private var accountNumber = ""
    @State private var ifscCode = ""
    @State private var branch = ""
    @State private var customerId = ""

    private var canSave: Bool {
        !bankName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !accountNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !ifscCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Bank Details")) {
                    TextField("Bank Name", text: $bankName)
                    TextField("Account Number", text: $accountNumber)
                        .keyboardType(.numberPad)
                    TextField("IFSC Code", text: $ifscCode)
                        .textInputAutocapitalization(.characters)
                    TextField("Branch (Optional)", text: $branch)
                    TextField("Customer ID (Optional)", text: $customerId)
                }
            }
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        viewModel.addLinkedBankAccount(
                            bank: bankName,
                            account: accountNumber,
                            ifsc: ifscCode,
                            branch: branch,
                            customerId: customerId
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        LinkedBankAccountsDetailView(viewModel: PreviewSupport.borrowerProfileViewModel)
    }
}
