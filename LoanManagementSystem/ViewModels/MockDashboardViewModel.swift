import Foundation
import Combine

struct MockDashboardTransaction: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let amount: Double
    let date: Date
    let status: MockTransactionStatus
    let type: MockTransactionType
}

enum MockTransactionStatus: String {
    case completed = "Completed"
    case pending = "Pending"
    case failed = "Failed"
}

enum MockTransactionType {
    case repayment
    case disbursement
    case processingFee
}

class MockDashboardViewModel: ObservableObject {
    @Published var activeLoanAmount: Double = 500000.0
    @Published var remainingBalance: Double = 450000.0
    @Published var emiAmount: Double = 15000.0
    @Published var nextEmiDate: Date = Calendar.current.date(byAdding: .day, value: 15, to: Date()) ?? Date()
    @Published var totalRepaid: Double = 50000.0
    @Published var creditScore: Int = 780
    @Published var activeLoansCount: Int = 1
    @Published var pendingApplicationsCount: Int = 0
    @Published var recentTransactions: [MockDashboardTransaction] = []
    @Published var isLoading: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadDashboardData()
        
        // Sync with central data store changes
        BorrowerProfileStore.shared.$profile
            .compactMap { $0 }
            .sink { [weak self] profile in
                self?.remainingBalance = profile.loanOverview.remainingBalance
                self?.emiAmount = profile.income.existingEMIs
                if let nextEmi = profile.loanOverview.nextEmiDueDate {
                    self?.nextEmiDate = nextEmi
                }
                self?.creditScore = profile.income.creditScore
                self?.activeLoansCount = profile.loanOverview.activeLoans
            }
            .store(in: &cancellables)
    }
    
    func loadDashboardData() {
        isLoading = true
        // Mock delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let self = self else { return }
            self.recentTransactions = [
                MockDashboardTransaction(
                    title: "EMI Repayment",
                    description: "Loan Account #L-890214",
                    amount: 15000.0,
                    date: Calendar.current.date(byAdding: .day, value: -15, to: Date()) ?? Date(),
                    status: .completed,
                    type: .repayment
                ),
                MockDashboardTransaction(
                    title: "Processing Fee",
                    description: "Personal Loan Application",
                    amount: 2500.0,
                    date: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
                    status: .completed,
                    type: .processingFee
                ),
                MockDashboardTransaction(
                    title: "Loan Disbursement",
                    description: "Loan Account #L-890214",
                    amount: 500000.0,
                    date: Calendar.current.date(byAdding: .day, value: -45, to: Date()) ?? Date(),
                    status: .completed,
                    type: .disbursement
                )
            ]
            self.isLoading = false
        }
    }
    
    var repaymentProgress: Double {
        guard activeLoanAmount > 0 else { return 0.0 }
        return totalRepaid / activeLoanAmount
    }
    
    func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_IN")
        return formatter.string(from: NSNumber(value: amount)) ?? "₹0.00"
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
