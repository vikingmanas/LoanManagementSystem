import SwiftUI
import Combine

@MainActor
final class LoanReviewViewModel: ObservableObject {
    @Published var applicants: [LoanApplicantModel] = []
    
    // Filtering State
    @Published var searchText: String = ""
    @Published var selectedStatus: LoanApplicationStatus? = nil
    @Published var selectedLoanType: AdminLoanType? = nil
    
    // Sorting State
    enum SortOption {
        case dateDesc
        case dateAsc
        case amountDesc
        case amountAsc
    }
    @Published var currentSort: SortOption = .dateDesc
    
    init() {
        loadMockData()
    }
    
    // MARK: - Filtered & Sorted Data
    var filteredApplicants: [LoanApplicantModel] {
        var result = applicants.filter { a in
            let matchesSearch = searchText.isEmpty ||
                a.applicantName.localizedCaseInsensitiveContains(searchText) ||
                a.loanId.localizedCaseInsensitiveContains(searchText)
            
            let matchesStatus = selectedStatus == nil || a.status == selectedStatus
            let matchesType = selectedLoanType == nil || a.loanType == selectedLoanType
            
            return matchesSearch && matchesStatus && matchesType
        }
        
        switch currentSort {
        case .dateDesc:
            result.sort { $0.applicationDate > $1.applicationDate }
        case .dateAsc:
            result.sort { $0.applicationDate < $1.applicationDate }
        case .amountDesc:
            result.sort { $0.requestedAmount > $1.requestedAmount }
        case .amountAsc:
            result.sort { $0.requestedAmount < $1.requestedAmount }
        }
        
        return result
    }
    
    // MARK: - Dashboard Analytics
    var totalApplications: Int { applicants.count }
    var pendingCount: Int { applicants.filter { $0.status == .pending }.count }
    var underReviewCount: Int { applicants.filter { $0.status == .underReview }.count }
    var approvedCount: Int { applicants.filter { $0.status == .approved }.count }
    
    var actionableApplications: [LoanApplicantModel] {
        applicants.filter { $0.status == .pending || $0.status == .underReview }
            .sorted { $0.applicationDate > $1.applicationDate }
    }
    
    // MARK: - Actions
    func updateStatus(for id: UUID, to status: LoanApplicationStatus, user: String) {
        if let i = applicants.firstIndex(where: { $0.id == id }) {
            applicants[i].status = status
            applicants[i].timeline.insert(
                ApplicationTimelineEvent(date: Date(), action: "Status updated to \(status.rawValue)", user: user), at: 0
            )
        }
    }
    
    func addInternalNote(id: UUID, note: String, user: String) {
        if let i = applicants.firstIndex(where: { $0.id == id }) {
            applicants[i].internalNotes = note
            applicants[i].timeline.insert(
                ApplicationTimelineEvent(date: Date(), action: "Internal Note Added", user: user), at: 0
            )
        }
    }
    
    // MARK: - Mock Data
    private func loadMockData() {
        let now = Date()
        let cal = Calendar.current
        
        applicants = [
            LoanApplicantModel(
                id: UUID(), loanId: "APP-10928", applicantName: "Rahul Sharma",
                loanType: .personal, requestedAmount: 500000,
                applicationDate: cal.date(byAdding: .day, value: -2, to: now)!,
                status: .underReview, cibilScore: 780,
                recommendation: .eligible,
                employmentType: "Salaried", monthlyIncome: 85000, existingEMI: 12000,
                timeline: [
                    ApplicationTimelineEvent(date: cal.date(byAdding: .day, value: -1, to: now)!, action: "Documents Verified", user: "System"),
                    ApplicationTimelineEvent(date: cal.date(byAdding: .day, value: -2, to: now)!, action: "Application Submitted", user: "Rahul Sharma")
                ],
                internalNotes: nil
            ),
            LoanApplicantModel(
                id: UUID(), loanId: "APP-10929", applicantName: "Priya Singh",
                loanType: .home, requestedAmount: 4500000,
                applicationDate: cal.date(byAdding: .day, value: -4, to: now)!,
                status: .changesRequested, cibilScore: 690,
                recommendation: .additionalVerification,
                employmentType: "Self-Employed", monthlyIncome: 120000, existingEMI: 35000,
                timeline: [
                    ApplicationTimelineEvent(date: cal.date(byAdding: .day, value: -1, to: now)!, action: "Requested updated ITR", user: "Suresh Manager"),
                    ApplicationTimelineEvent(date: cal.date(byAdding: .day, value: -4, to: now)!, action: "Application Submitted", user: "Priya Singh")
                ],
                internalNotes: "ITR for FY22 is missing."
            ),
            LoanApplicantModel(
                id: UUID(), loanId: "APP-10930", applicantName: "Amit Patel",
                loanType: .business, requestedAmount: 1500000,
                applicationDate: cal.date(byAdding: .day, value: -1, to: now)!,
                status: .pending, cibilScore: 710,
                recommendation: .mediumRisk,
                employmentType: "Business Owner", monthlyIncome: 250000, existingEMI: 90000,
                timeline: [
                    ApplicationTimelineEvent(date: cal.date(byAdding: .day, value: -1, to: now)!, action: "Application Submitted", user: "Amit Patel")
                ],
                internalNotes: nil
            ),
            LoanApplicantModel(
                id: UUID(), loanId: "APP-10931", applicantName: "Neha Gupta",
                loanType: .auto, requestedAmount: 800000,
                applicationDate: cal.date(byAdding: .day, value: -10, to: now)!,
                status: .approved, cibilScore: 820,
                recommendation: .eligible,
                employmentType: "Salaried", monthlyIncome: 140000, existingEMI: 0,
                timeline: [
                    ApplicationTimelineEvent(date: cal.date(byAdding: .day, value: -2, to: now)!, action: "Loan Approved", user: "Admin"),
                    ApplicationTimelineEvent(date: cal.date(byAdding: .day, value: -10, to: now)!, action: "Application Submitted", user: "Neha Gupta")
                ],
                internalNotes: "Excellent profile. Fast-tracked."
            )
        ]
    }
}
