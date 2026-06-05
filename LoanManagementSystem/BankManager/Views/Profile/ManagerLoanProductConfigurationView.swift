import SwiftUI

struct ManagerLoanProductConfigurationView: View {
    @State private var viewModel = ManagerLoanProductConfigurationViewModel()

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.products.isEmpty {
                ProgressView("Loading loan products…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.products.isEmpty {
                ContentUnavailableView(
                    "No Loan Products",
                    systemImage: "building.columns",
                    description: Text("Active loan products will appear here once configured by the bank.")
                )
            } else {
                List {
                    Section {
                        Text("Set the base interest rate and processing fee for each product offered at your branch. Borrowers and officers see these terms in the application flow.")
                            .font(.footnote)
                            .foregroundStyle(LMSColors.textSecondary)
                    }

                    Section("Products") {
                        ForEach(viewModel.products) { product in
                            NavigationLink {
                                ManagerLoanProductPricingDetailView(
                                    product: product,
                                    viewModel: viewModel
                                )
                            } label: {
                                ManagerLoanProductRow(product: product)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Loan Product Pricing")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            await viewModel.loadProducts()
        }
        .task {
            await viewModel.loadProducts()
        }
        .alert("Could Not Save", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .alert("Saved", isPresented: Binding(
            get: { viewModel.successMessage != nil },
            set: { if !$0 { viewModel.successMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.successMessage ?? "")
        }
    }
}

private struct ManagerLoanProductRow: View {
    let product: AdminLoanProduct

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(product.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(LMSColors.textPrimary)
                Spacer()
                if !product.isActive {
                    Text("Inactive")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(LMSColors.coral)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(LMSColors.coral.opacity(0.12), in: Capsule())
                }
            }
            Text(product.loanType)
                .font(.caption)
                .foregroundStyle(LMSColors.textSecondary)
            HStack(spacing: LMSSpacing.md) {
                Label(String(format: "%.2f%% p.a.", product.minRate), systemImage: "percent")
                Label(String(format: "%.2f%% fee", product.processingFee), systemImage: "indianrupeesign.circle")
            }
            .font(.caption.weight(.medium))
            .foregroundStyle(LMSColors.brandNavy)
        }
        .padding(.vertical, 4)
    }
}

struct ManagerLoanProductPricingDetailView: View {
    @State var product: AdminLoanProduct
    @Bindable var viewModel: ManagerLoanProductConfigurationViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Form {
            Section("Product") {
                LabeledContent("Name", value: product.name)
                LabeledContent("Type", value: product.loanType)
                LabeledContent("Status", value: product.isActive ? "Active" : "Inactive")
            }

            Section("Eligibility Criteria") {
                LabeledContent {
                    Stepper(value: $product.minAmount, in: 10000...10000000, step: 10000) {
                        Text(product.minAmount.formattedAsCompactINR())
                            .font(.body.monospacedDigit().weight(.semibold))
                    }
                } label: {
                    Text("Min Amount")
                }

                LabeledContent {
                    Stepper(value: $product.maxAmount, in: 50000...50000000, step: 50000) {
                        Text(product.maxAmount.formattedAsCompactINR())
                            .font(.body.monospacedDigit().weight(.semibold))
                    }
                } label: {
                    Text("Max Amount")
                }

                LabeledContent {
                    Stepper(value: $product.maxTenure, in: 6...360, step: 6) {
                        Text("\(product.maxTenure) months")
                            .font(.body.monospacedDigit().weight(.semibold))
                    }
                } label: {
                    Text("Max Tenure")
                }
            }

            Section {
                LabeledContent {
                    Stepper(value: $product.minRate, in: 5...30, step: 0.05) {
                        Text(String(format: "%.2f%%", product.minRate))
                            .font(.body.monospacedDigit().weight(.semibold))
                    }
                } label: {
                    Text("Base Interest Rate")
                }

                LabeledContent {
                    Stepper(value: $product.processingFee, in: 0...5, step: 0.05) {
                        Text(String(format: "%.2f%%", product.processingFee))
                            .font(.body.monospacedDigit().weight(.semibold))
                    }
                } label: {
                    Text("Processing Fee")
                }
            } header: {
                Text("Branch Pricing")
            } footer: {
                Text("These values are stored in the loan product catalog. Pricing and eligibility criteria can be customized for your branch.")
            }

            Section("Borrower Preview") {
                LabeledContent("Interest Display", value: String(format: "%.2f%% p.a.", product.minRate))
                LabeledContent("Fee Display", value: String(format: "%.2f%% of loan amount", product.processingFee))
            }
        }
        .navigationTitle(product.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(viewModel.isSaving ? "Saving…" : "Save") {
                    Task {
                        product.maxRate = max(product.minRate, product.maxRate)
                        await viewModel.saveProduct(product)
                        if viewModel.errorMessage == nil {
                            dismiss()
                        }
                    }
                }
                .disabled(viewModel.isSaving)
            }
        }
    }
}
