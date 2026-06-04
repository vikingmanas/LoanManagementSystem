import SwiftUI

struct AdminLoanProductDetailView: View {
    @State var product: AdminLoanProduct
    @Bindable var viewModel: AdminLoanRulesViewModel
    
    @Environment(\.dismiss) private var dismiss
    
    let allDocuments = ["Aadhaar", "PAN", "Salary Slip", "Bank Statement", "Property Documents", "GST Certificate", "ITR", "Business Bank Statement"]
    
    var body: some View {
        Form {
            Section("Status") {
                Toggle("Active Product", isOn: $product.isActive)
                    .tint(LMSColors.emerald)
            }
            
            Section("Interest Rate") {
                LabeledContent {
                    Stepper(value: $product.minRate, in: 0...24, step: 0.25) {
                        Text("\(product.minRate, specifier: "%.2f")%")
                            .font(LMSFont.body.monospacedDigit())
                    }
                } label: {
                    Text("Minimum Rate")
                }
                
                LabeledContent {
                    Stepper(value: $product.maxRate, in: 0...36, step: 0.25) {
                        Text("\(product.maxRate, specifier: "%.2f")%")
                            .font(LMSFont.body.monospacedDigit())
                    }
                } label: {
                    Text("Maximum Rate")
                }
            }
            
            Section("Parameters") {
                LabeledContent {
                    TextField("Min Amount", value: $product.minAmount, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Text("Min Amount (₹)")
                }
                
                LabeledContent {
                    TextField("Max Amount", value: $product.maxAmount, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Text("Max Amount (₹)")
                }
                
                LabeledContent {
                    TextField("Max Tenure (months)", value: $product.maxTenure, formatter: NumberFormatter())
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                } label: {
                    Text("Max Tenure (Months)")
                }
                
                LabeledContent {
                    Stepper(value: $product.processingFee, in: 0...10, step: 0.25) {
                        Text("\(product.processingFee, specifier: "%.2f")%")
                            .font(LMSFont.body.monospacedDigit())
                    }
                } label: {
                    Text("Processing Fee")
                }
            }
            
            Section("Required Documents") {
                ForEach(allDocuments, id: \.self) { doc in
                    let isRequired = product.requiredDocuments.contains(doc)
                    Button {
                        if isRequired {
                            product.requiredDocuments.removeAll { $0 == doc }
                        } else {
                            product.requiredDocuments.append(doc)
                        }
                    } label: {
                        HStack {
                            Text(doc)
                                .foregroundStyle(LMSColors.textPrimary)
                            Spacer()
                            if isRequired {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(LMSColors.actionBlue)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await viewModel.updateProduct(product)
                        dismiss()
                    }
                }
            }
        }
    }
}
