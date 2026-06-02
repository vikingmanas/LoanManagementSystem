import SwiftUI


@MainActor
enum PreviewSupport {



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



    static var borrowerProfileViewModel: BorrowerProfileViewModel {
        BorrowerProfileViewModel()
    }

    static var dashboardViewModel: DashboardViewModel {
        let vm = DashboardViewModel()
        vm.isLoading = false
        return vm
    }

    static var loanApplicationViewModel: LoanApplicationViewModel {
        LoanApplicationViewModel()
    }



    static var loanOfficerViewModel: LoanOfficerDashboardViewModel {
        let vm = LoanOfficerDashboardViewModel()
        vm.isLoading = false
        vm.updateUnreadCount()
        return vm
    }

    static var sampleDocumentQueueItem: DocumentQueueItem {
        DocumentQueueItem(
            id: UUID(),
            borrowerName: "",
            docType: .aadhaar,
            status: .uploaded,
            submittedDate: Date(),
            applicationId: "",
            fileURL: nil
        )
    }

    static var sampleActivityFeedItem: ActivityFeedItem {
        ActivityFeedItem(
            id: UUID(),
            borrowerName: "",
            applicationId: "",
            loanType: "",
            eventType: .applicationSubmitted,
            eventDescription: "",
            timestamp: Date(),
            isRead: true,
            requiresAction: false,
            actionType: nil
        )
    }



    static var managerViewModel: ManagerDashboardViewModel {
        let vm = ManagerDashboardViewModel()
        vm.isLoading = false
        return vm
    }



    static var adminStaffViewModel: AdminStaffViewModel {
        let vm = AdminStaffViewModel()
        return vm
    }

    static var sampleManagerApplicant: ManagerApplicant {
        ManagerApplicant(
            id: UUID(),
            applicationId: "",
            borrowerName: "",
            borrowerInitials: "",
            loanType: .personal,
            requestedAmount: 0,
            cibilScore: 0,
            status: .sentToManager,
            riskLevel: .low,
            assignedOfficer: "",
            assignedOfficerId: UUID(),
            submissionDate: Date(),
            documents: [],
            officerRemarks: "",
            managerRemarks: "",
            verificationProgress: 0,
            tenure: 0,
            interestRate: 0,
            branchName: ""
        )
    }

    static var sampleBorrowerProfile: BorrowerProfile {
        BorrowerProfile.empty()
    }

    static var sampleLoanApplicationId: String {
        ""
    }

    static var borrowerTabRouter: BorrowerTabRouter { BorrowerTabRouter() }
}



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
