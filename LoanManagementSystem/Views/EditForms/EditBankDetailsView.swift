import SwiftUI

struct EditBankDetailsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: BorrowerProfileViewModel
    
    @State private var bankName: String
    @State private var accountHolder: String
    @State private var accountNumber: String
    @State private var ifscCode: String
    @State private var upiID: String
    
    init(viewModel: BorrowerProfileViewModel) {
        self.viewModel = viewModel
        _bankName = State(initialValue: viewModel.profile?.bankDetails.bankName ?? "")
        _accountHolder = State(initialValue: viewModel.profile?.bankDetails.accountHolderName ?? "")
        _accountNumber = State(initialValue: viewModel.profile?.bankDetails.accountNumber ?? "")
        _ifscCode = State(initialValue: viewModel.profile?.bankDetails.ifscCode ?? "")
        _upiID = State(initialValue: viewModel.profile?.bankDetails.upiID ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Bank Details")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bank Name")
                            .font(Font.AppTheme.caption)
                            .foregroundColor(Color.AppTheme.textSecondary)
                        TextField("Enter Bank Name", text: $bankName)
                            .font(Font.AppTheme.body)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Account Holder Name")
                            .font(Font.AppTheme.caption)
                            .foregroundColor(Color.AppTheme.textSecondary)
                        TextField("Enter Account Holder Name", text: $accountHolder)
                            .font(Font.AppTheme.body)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Account Number")
                            .font(Font.AppTheme.caption)
                            .foregroundColor(Color.AppTheme.textSecondary)
                        TextField("Enter Account Number", text: $accountNumber)
                            .keyboardType(.numberPad)
                            .font(Font.AppTheme.body)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("IFSC Code")
                            .font(Font.AppTheme.caption)
                            .foregroundColor(Color.AppTheme.textSecondary)
                        TextField("Enter IFSC Code", text: $ifscCode)
                            .autocapitalization(.allCharacters)
                            .font(Font.AppTheme.body)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("UPI ID (Optional)")
                            .font(Font.AppTheme.caption)
                            .foregroundColor(Color.AppTheme.textSecondary)
                        TextField("Enter UPI ID (e.g. username@bank)", text: $upiID)
                            .autocapitalization(.none)
                            .font(Font.AppTheme.body)
                    }
                }
            }
            .navigationTitle("Edit Bank Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color.AppTheme.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.updateBankDetails(
                            bank: bankName,
                            holder: accountHolder,
                            account: accountNumber,
                            ifsc: ifscCode,
                            upi: upiID
                        )
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "checkmark")
                            .fontWeight(.bold)
                            .foregroundColor(Color.AppTheme.primary)
                    }
                }
            }
        }
    }
}

#Preview {
    EditBankDetailsView(viewModel: BorrowerProfileViewModel())
}
