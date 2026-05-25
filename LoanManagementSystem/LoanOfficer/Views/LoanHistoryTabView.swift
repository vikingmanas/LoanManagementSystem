import SwiftUI
import UIKit

struct LoanHistoryTabView: View {
    typealias LoanApplication = OfficerLoanApplication
    typealias LoanType = OfficerLoanType
    typealias ApplicationStatus = OfficerApplicationStatus
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel

    @State private var selectedFilter: FilterOption = .all
    @State private var showingExportAlert = false
    @State private var activeDetailApp: LoanApplication? = nil
    @State private var alertMessage = ""

    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "All"
        case pendingVerification = "Pending Verification"
        case underReview = "Under Review"
        case approved = "Approved"
        case rejected = "Rejected"

        var id: String { self.rawValue }
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack(alignment: .leading, spacing: 16) {
                registryHeader

                searchAndFilterHeader

                HStack {
                    Text("Showing \(localFilteredApplications.count) of \(viewModel.totalApplications) loans")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding(.top, 2)

                if localFilteredApplications.isEmpty {
                    emptyState
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(localFilteredApplications) { app in
                            LoanHistoryRow(
                                app: app,
                                onView: {
                                    activeDetailApp = app
                                },
                                onCall: {
                                    alertMessage = "Calling borrower \(app.borrowerName) at verified registration number..."
                                    showingExportAlert = true
                                },
                                onFlag: {
                                    alertMessage = "Flagged application \(app.applicationId) for compliance audit."
                                    showingExportAlert = true
                                }
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 112)
        }
        .background(Color(.systemBackground))
        .refreshable {
            await viewModel.fetchDashboardData()
        }
        .sheet(item: $activeDetailApp) { app in
            LoanApplicationReviewDetailView(applicationId: app.applicationId, viewModel: viewModel)
        }
        .alert(isPresented: $showingExportAlert) {
            Alert(
                title: Text("System Alert"),
                message: Text(alertMessage.isEmpty ? "Export action triggered." : alertMessage),
                dismissButton: .default(Text("OK")) {
                    alertMessage = ""
                }
            )
        }

        .onChange(of: viewModel.historyFilter) { _, newStatus in
            if let status = newStatus {
                switch status {
                case .pending, .applied, .documentsPending:
                    selectedFilter = .pendingVerification
                case .underReview, .sentToManager, .finalApprovalPending, .verificationCompleted:
                    selectedFilter = .underReview
                case .approved, .disbursed:
                    selectedFilter = .approved
                case .rejected, .documentsRejected:
                    selectedFilter = .rejected
                default:
                    selectedFilter = .all
                }
            } else {
                selectedFilter = .all
            }
        }
    }

    private var registryHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Loan Registry")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }

    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 44))
                .foregroundColor(.secondary.opacity(0.6))
                .padding(.top, 32)

            Text("No Loans Found")
                .font(.system(size: 17, weight: .bold, design: .rounded))

            Text("Try adjusting your filters or search terms.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(AppTheme.neutralSurface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }


    private var localFilteredApplications: [OfficerLoanApplication] {
        var list = viewModel.filteredApplications

        switch selectedFilter {
        case .all:
            break
        case .pendingVerification:
            list = list.filter { $0.status == .pending || $0.status == .applied || $0.status == .documentsPending }
        case .underReview:
            list = list.filter { $0.status == .underReview || $0.status == .sentToManager || $0.status == .finalApprovalPending || $0.status == .verificationCompleted }
        case .approved:
            list = list.filter { $0.status == .approved || $0.status == .disbursed }
        case .rejected:
            list = list.filter { $0.status == .rejected || $0.status == .documentsRejected }
        }

        return list
    }


    private var searchAndFilterHeader: some View {
        VStack(spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary.opacity(0.8))
                    .font(.system(size: 16, weight: .semibold))

                TextField("Search loans, customers, application ID", text: $viewModel.historySearchQuery)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.primary)
                    .autocorrectionDisabled()

                if !viewModel.historySearchQuery.isEmpty {
                    Button(action: {
                        viewModel.historySearchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 15))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FilterOption.allCases, id: \.self) { option in
                        FilterChip(
                            title: option.rawValue,
                            isSelected: selectedFilter == option
                        ) {
                            HapticsManager.triggerImpact(style: .light)
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                selectedFilter = option
                            }
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            AppTheme.neutralSurface,
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.primary.opacity(0.05), lineWidth: 1)
        )
    }
}


struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                )
                .foregroundColor(isSelected ? .white : .secondary)
                .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    LoanHistoryTabView(viewModel: PreviewSupport.loanOfficerViewModel)
        .previewLoanOfficerEnvironment()
}

