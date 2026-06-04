import SwiftUI

struct EditLoanOverviewView: View {
    @Environment(\.presentationMode) var presentationMode
    @Bindable var viewModel: BorrowerProfileViewModel

    @State private var requestType: String = "Tenure Extension"
    @State private var reason: String = "Temporary financial hardship"

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Active Loan Details")) {
                    if let loan = viewModel.profile?.loanOverview {
                        DataRowView(label: "Current Balance", value: viewModel.formatCurrency(loan.remainingBalance))
                        DataRowView(label: "Next EMI Due", value: loan.nextEmiDueDate != nil ? viewModel.formatDate(loan.nextEmiDueDate!) : "N/A")
                        DataRowView(label: "Status", value: loan.currentLoanStatus)
                    }
                }

                Section(header: Text("Request Modification"), footer: Text("You cannot directly edit an active loan. Please submit a modification request to your loan officer.")) {
                    TextField("Request Type (e.g. Pre-closure)", text: $requestType)
                    TextField("Reason", text: $reason)
                }
            }
            .navigationTitle("Loan Overview")
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
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "checkmark")
                            .fontWeight(.bold)
                            .foregroundStyle(Color.AppTheme.primary)
                    }
                }
            }
        }
    }
}


