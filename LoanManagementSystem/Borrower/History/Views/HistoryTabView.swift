import SwiftUI

struct HistoryTabView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var transactionFilter: TransactionType? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                LMSColors.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if viewModel.isLoading {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(0..<8) { _ in
                                    TransactionRowSkeleton()
                                    Divider().padding(.horizontal, 20)
                                }
                            }
                            .dashboardCardStyle()
                            .padding()
                        }
                    } else {
                        let filtered = viewModel.transactions.filter { tx in
                            guard let filter = transactionFilter else { return true }
                            return tx.type == filter
                        }
                        
                        if filtered.isEmpty {
                            ContentUnavailableView(
                                "No transactions found",
                                systemImage: "list.bullet.rectangle.portrait",
                                description: Text("Try changing your filter settings to view other transaction types.")
                            )
                        } else {
                            ScrollView {
                                VStack(spacing: 0) {
                                    ForEach(filtered) { tx in
                                        TransactionRowView(transaction: tx)
                                        if tx.id != filtered.last?.id {
                                            Divider().padding(.horizontal, 20)
                                        }
                                    }
                                }
                                .dashboardCardStyle()
                                .padding()
                            }
                        }
                    }
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("All Transactions") { transactionFilter = nil }
                        Divider()
                        Button("EMI Payments") { transactionFilter = .emiPayment }
                        Button("Credits") { transactionFilter = .credit }
                        Button("Penalties") { transactionFilter = .penalty }
                        Button("Refunds") { transactionFilter = .refund }
                    } label: {
                        HStack(spacing: 4) {
                            Text(transactionFilter == nil ? "Filter" : transactionFilter!.rawValue)
                                .font(.subheadline.weight(.medium))
                            Image(systemName: "chevron.down")
                                .font(.caption2.weight(.bold))
                        }
                        .foregroundStyle(LMSColors.brandNavy)
                        .padding(.horizontal, LMSSpacing.md)
                        .padding(.vertical, LMSSpacing.sm)
                        .background(LMSColors.surface, in: Capsule())
                        .overlay(Capsule().stroke(LMSColors.separatorLight, lineWidth: 0.5))
                    }
                }
            }
            .refreshable {
                await viewModel.fetchDashboardData()
            }
        }
    }
}
