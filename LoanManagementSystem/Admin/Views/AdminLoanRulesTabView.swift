import SwiftUI

struct AdminLoanRulesTabView: View {
    @StateObject private var viewModel = AdminLoanRulesViewModel()
    @State private var showingAddSheet = false
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                Section("Global Thresholds") {
                    LabeledContent {
                        Stepper(value: $viewModel.globalRules.minCibilScore, in: 300...900, step: 10) {
                            Text("\(viewModel.globalRules.minCibilScore)")
                                .font(LMSFont.body.monospacedDigit())
                        }
                    } label: {
                        Label("Min CIBIL Score", systemImage: "speedometer")
                            .font(LMSFont.body)
                    }
                    
                    LabeledContent {
                        HStack {
                            Slider(value: $viewModel.globalRules.maxDTI, in: 0...100, step: 5)
                            Text("\(Int(viewModel.globalRules.maxDTI))%")
                                .frame(width: 45, alignment: .trailing)
                                .font(LMSFont.body.monospacedDigit())
                        }
                    } label: {
                        Label("Max DTI Ratio", systemImage: "chart.pie.fill")
                            .font(LMSFont.body)
                    }
                    
                    LabeledContent {
                        HStack {
                            Slider(value: $viewModel.globalRules.maxLTV, in: 0...100, step: 5)
                            Text("\(Int(viewModel.globalRules.maxLTV))%")
                                .frame(width: 45, alignment: .trailing)
                                .font(LMSFont.body.monospacedDigit())
                        }
                    } label: {
                        Label("Max LTV Ratio", systemImage: "house.fill")
                            .font(LMSFont.body)
                    }
                    
                    Button(action: {
                        Task {
                            await viewModel.updateGlobalRules(viewModel.globalRules)
                            if let error = viewModel.errorMessage {
                                alertTitle = "Error"
                                alertMessage = error
                                showingAlert = true
                            } else {
                                alertTitle = "Success"
                                alertMessage = "Global thresholds updated successfully."
                                showingAlert = true
                            }
                        }
                    }) {
                        HStack {
                            Spacer()
                            Text("Save Global Thresholds")
                                .font(LMSFont.button)
                                .bold()
                            Spacer()
                        }
                    }
                    .foregroundColor(LMSColors.actionBlue)
                }
                
                Section("Loan Products") {
                    if viewModel.isLoading && viewModel.loanProducts.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        ForEach(viewModel.loanProducts) { product in
                            NavigationLink(destination: AdminLoanProductDetailView(product: product, viewModel: viewModel)) {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(product.name)
                                            .font(LMSFont.headline)
                                        Spacer()
                                        if !product.isActive {
                                            Text("Inactive")
                                                .font(LMSFont.caption2.weight(.bold))
                                                .foregroundStyle(LMSColors.coral)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(LMSColors.coral.opacity(0.1), in: Capsule())
                                        }
                                    }
                                    Text("\(product.minRate, specifier: "%.2f")% - \(product.maxRate, specifier: "%.2f")% Interest")
                                        .font(LMSFont.caption)
                                        .foregroundStyle(LMSColors.textSecondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("System Rules")
            .refreshable {
                await viewModel.loadRules()
            }
            .task {
                await viewModel.loadRules()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(LMSColors.brandNavy)
                    }
                }
            }
            .accessibleSheet(isPresented: $showingAddSheet) {
                AdminAddLoanProductSheet(viewModel: viewModel)
            }
            .alert(alertTitle, isPresented: $showingAlert) {
                Button("OK", role: .cancel) {
                    if alertTitle == "Error" {
                        Task {
                            await viewModel.loadRules()
                        }
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
    }
}
