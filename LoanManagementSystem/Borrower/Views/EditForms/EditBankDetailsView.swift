import SwiftUI

struct EditBankDetailsView: View {
    @Environment(\.presentationMode) var presentationMode
    @Bindable var viewModel: BorrowerProfileViewModel

    @State private var bankName: String
    @State private var accountHolder: String
    @State private var accountNumber: String
    @State private var ifscCode: String
    @State private var upiID: String
    @State private var showingDeleteConfirmation = false

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
                            .foregroundStyle(Color.AppTheme.textSecondary)
                        TextField("Enter Bank Name", text: $bankName)
                            .font(Font.AppTheme.input)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Account Holder Name")
                            .font(Font.AppTheme.caption)
                            .foregroundStyle(Color.AppTheme.textSecondary)
                        TextField("Enter Account Holder Name", text: $accountHolder)
                            .font(Font.AppTheme.input)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Account Number")
                            .font(Font.AppTheme.caption)
                            .foregroundStyle(Color.AppTheme.textSecondary)
                        TextField("Enter Account Number", text: $accountNumber)
                            .keyboardType(.numberPad)
                            .font(Font.AppTheme.input)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("IFSC Code")
                            .font(Font.AppTheme.caption)
                            .foregroundStyle(Color.AppTheme.textSecondary)
                        TextField("Enter IFSC Code", text: $ifscCode)
                            .autocapitalization(.allCharacters)
                            .font(Font.AppTheme.input)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("UPI ID (Optional)")
                            .font(Font.AppTheme.caption)
                            .foregroundStyle(Color.AppTheme.textSecondary)
                        TextField("Enter UPI ID (e.g. username@bank)", text: $upiID)
                            .autocapitalization(.none)
                            .font(Font.AppTheme.input)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Clear Bank Details")
                                .fontWeight(.semibold)
                            Spacer()
                        }
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
                            .foregroundStyle(Color.AppTheme.primary)
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
                            .foregroundStyle(Color.AppTheme.primary)
                    }
                }
            }
            .alert("Clear Bank Details?", isPresented: $showingDeleteConfirmation) {
                Button("Clear", role: .destructive) {
                    viewModel.deletePrimaryBankDetails()
                    presentationMode.wrappedValue.dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to clear your primary bank details? This will remove all primary account information.")
            }
        }
    }
}

#Preview {
    EditBankDetailsView(viewModel: BorrowerProfileViewModel())
}
