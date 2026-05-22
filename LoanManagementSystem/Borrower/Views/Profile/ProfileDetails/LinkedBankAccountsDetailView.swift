import SwiftUI

struct LinkedBankAccountsDetailView: View {
    @ObservedObject var viewModel: BorrowerProfileViewModel
    @State private var showingEditSheet = false
    
    var body: some View {
        Form {
            if let bank = viewModel.profile?.bankDetails {
                Section(header: Text("Primary Account")) {
                    DataRowView(label: "Bank Name", value: bank.bankName)
                    DataRowView(label: "Account Holder", value: bank.accountHolderName)
                    DataRowView(label: "Account Number", value: maskAccountNumber(bank.accountNumber))
                    DataRowView(label: "IFSC Code", value: bank.ifscCode)
                    if let upi = bank.upiID {
                        DataRowView(label: "UPI ID", value: upi)
                    } else {
                        DataRowView(label: "UPI ID", value: "Not Linked", valueColor: .gray)
                    }
                    
                    HStack {
                        Text("Status")
                            .font(Font.AppTheme.body)
                            .foregroundStyle(Color.AppTheme.textSecondary)
                        Spacer()
                        if bank.isVerified {
                            StatusBadgeView(status: "Verified")
                        } else {
                            StatusBadgeView(status: "Pending")
                        }
                    }
                }
            } else {
                Text("No linked bank account.")
            }
        }
        .navigationTitle("Linked Bank Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
                .foregroundStyle(Color.AppTheme.primary)
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
