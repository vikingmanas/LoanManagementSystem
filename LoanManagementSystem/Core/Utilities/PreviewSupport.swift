import SwiftUI

/// Shared mock data and environment objects for SwiftUI previews across the app.
@MainActor
enum PreviewSupport {
    
    // MARK: - Core
    
    static func appState(
        role: PortalRole = .customer,
        authenticated: Bool = true,
        showRoleSelection: Bool = false
    ) -> AppStateManager {
        let state = AppStateManager()
        state.selectedRole = role
        state.isAuthenticated = authenticated
        state.showRoleSelection = showRoleSelection
        return state
    }
    
    static var authManager: AuthManager { AuthManager() }
    
    // MARK: - Borrower
    
    static var borrowerProfileViewModel: BorrowerProfileViewModel {
        BorrowerProfileViewModel()
    }
    
    static var dashboardViewModel: DashboardViewModel {
        let vm = DashboardViewModel()
        vm.loanAccounts = [MockData.home, MockData.business, MockData.car]
        let sbiAcc = BankAccount(
            id: MockData.uuid1,
            accountNumber: "XXXXXX7890",
            bankName: "State Bank of India",
            accountType: .savings,
            availableBalance: 42300.0,
            minBalance: 5000.0,
            linkedLoanIds: [MockData.loanId1]
        )
        vm.bankAccounts = [sbiAcc]
        vm.bankAccount = sbiAcc
        vm.pendingEMIs = MockData.samplePendingEMIs
        vm.transactions = MockData.sampleTransactions
        vm.schemes = MockData.sampleSchemes
        vm.isLoading = false
        return vm
    }
    
    static var loanApplicationViewModel: LoanApplicationViewModel {
        LoanApplicationViewModel()
    }
    
    // MARK: - Loan Officer
    
    static var loanOfficerViewModel: LoanOfficerDashboardViewModel {
        let vm = LoanOfficerDashboardViewModel()
        vm.applications = LoanOfficerMockData.createApplications()
        vm.activityFeed = LoanOfficerMockData.createActivityFeed()
        vm.isLoading = false
        vm.updateUnreadCount()
        return vm
    }
    
    static var sampleDocumentQueueItem: DocumentQueueItem {
        let app = LoanOfficerMockData.createApplications()[0]
        let doc = app.documents.first(where: { $0.status == .reUploaded }) ?? app.documents[0]
        return DocumentQueueItem(
            id: doc.id,
            borrowerName: app.borrowerName,
            docType: doc.docType,
            status: doc.status,
            submittedDate: doc.uploadedDate ?? Date(),
            applicationId: app.applicationId
        )
    }
    
    static var sampleActivityFeedItem: ActivityFeedItem {
        LoanOfficerMockData.createActivityFeed()[0]
    }
    
    // MARK: - Bank Manager
    
    static var managerViewModel: ManagerDashboardViewModel {
        let vm = ManagerDashboardViewModel()
        vm.applicants = ManagerMockData.applicants
        vm.officers = ManagerMockData.officers
        vm.kpis = ManagerMockData.kpis
        vm.notifications = ManagerMockData.notifications
        vm.conversations = ManagerMockData.conversations
        vm.branchOverview = ManagerMockData.branchOverview
        vm.isLoading = false
        return vm
    }
    
    static var sampleManagerApplicant: ManagerApplicant {
        ManagerMockData.applicants[0]
    }
    
    static var sampleBorrowerProfile: BorrowerProfile {
        BorrowerProfileStore.shared.ensureProfile(
            email: "rahul.sharma@example.com",
            name: "Rahul Sharma"
        )
    }
    
    static var sampleLoanApplicationId: String {
        LoanOfficerMockData.createApplications().first?.applicationId ?? "APP-2024-0892"
    }
    
    static var borrowerTabRouter: BorrowerTabRouter { BorrowerTabRouter() }
}

// MARK: - View modifiers for previews

extension View {
    func previewBorrowerEnvironment() -> some View {
        self
            .environmentObject(PreviewSupport.appState(role: .customer))
            .environmentObject(PreviewSupport.authManager)
            .environmentObject(PreviewSupport.borrowerTabRouter)
    }
    
    func previewLoanOfficerEnvironment() -> some View {
        self
            .environmentObject(PreviewSupport.appState(role: .loanOfficer))
            .environmentObject(PreviewSupport.authManager)
    }
    
    func previewManagerEnvironment() -> some View {
        self
            .environmentObject(PreviewSupport.appState(role: .bankManager))
            .environmentObject(PreviewSupport.authManager)
    }
    
    func previewAdminEnvironment() -> some View {
        self
            .environmentObject(PreviewSupport.appState(role: .admin))
            .environmentObject(PreviewSupport.authManager)
    }
}
