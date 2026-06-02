import SwiftUI

struct AdminAddLoanProductSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AdminLoanRulesViewModel
    
    @State private var product = AdminLoanProduct(
        id: UUID(),
        name: "",
        loanType: "",
        isActive: true,
        minRate: 8.0,
        maxRate: 15.0,
        minAmount: 10_000,
        maxAmount: 1_000_000,
        maxTenure: 60,
        processingFee: 1.0,
        requiredDocuments: []
    )
    
    let standardDocuments = [
        "Aadhaar Card", "PAN Card", "Salary Slip", "Bank Statement", 
        "ITR", "Property Papers", "GST Certificate", "Passport", "Driving License"
    ]
    
    let defaultLoanTypes = ["Personal Loan", "Home Loan", "Vehicle Loan", "Business Loan", "Education Loan"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Info") {
                    TextField("Product Name", text: $product.name)
                    
                    Picker("Loan Type", selection: $product.loanType) {
                        Text("Select Type").tag("")
                        ForEach(defaultLoanTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    
                    Toggle("Is Active", isOn: $product.isActive)
                }
                
                Section("Interest Rate (%)") {
                    HStack {
                        Text("Min:")
                        Spacer()
                        TextField("Min", value: $product.minRate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Max:")
                        Spacer()
                        TextField("Max", value: $product.maxRate, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Loan Limits") {
                    HStack {
                        Text("Min Amount:")
                        Spacer()
                        TextField("Min", value: $product.minAmount, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Max Amount:")
                        Spacer()
                        TextField("Max", value: $product.maxAmount, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Max Tenure (Months):")
                        Spacer()
                        TextField("Tenure", value: $product.maxTenure, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Processing Fee (%):")
                        Spacer()
                        TextField("Fee", value: $product.processingFee, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Required Documents") {
                    NavigationLink {
                        List(standardDocuments, id: \.self) { doc in
                            Button {
                                if product.requiredDocuments.contains(doc) {
                                    product.requiredDocuments.removeAll { $0 == doc }
                                } else {
                                    product.requiredDocuments.append(doc)
                                }
                            } label: {
                                HStack {
                                    Text(doc)
                                        .foregroundStyle(LMSColors.textPrimary)
                                    Spacer()
                                    if product.requiredDocuments.contains(doc) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(LMSColors.actionBlue)
                                            .fontWeight(.bold)
                                    }
                                }
                            }
                        }
                        .navigationTitle("Select Documents")
                        .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        HStack {
                            Text("Documents Required")
                            Spacer()
                            Text("\(product.requiredDocuments.count) selected")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("New Loan Type")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await viewModel.addLoanProduct(product)
                        }
                        dismiss()
                    }
                    .disabled(product.name.isEmpty || product.loanType.isEmpty)
                }
            }
        }
    }
}
