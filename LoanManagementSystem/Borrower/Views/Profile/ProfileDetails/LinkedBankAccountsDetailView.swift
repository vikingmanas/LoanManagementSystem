import SwiftUI

struct LinkedBankAccountsDetailView: View {
    @ObservedObject var viewModel: BorrowerProfileViewModel
    @State private var showingEditSheet = false
    
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
            } else {
                Text("No linked bank account.")
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
    }
    
    private func maskAccountNumber(_ number: String) -> String {
        guard number.count > 4 else { return number }
        let suffix = number.suffix(4)
        return String(repeating: "•", count: number.count - 4) + suffix
    }
}

#Preview {
    NavigationStack {
        LinkedBankAccountsDetailView(viewModel: PreviewSupport.borrowerProfileViewModel)
    }
}
