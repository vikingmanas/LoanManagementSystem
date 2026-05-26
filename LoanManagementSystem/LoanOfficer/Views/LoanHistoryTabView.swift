import SwiftUI

struct LoanHistoryTabView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @State private var selectedFilter: RegistryFilter = .all
    @State private var sortOrder: HistorySortOrder = .newest
    @State private var activeDetailApp: OfficerLoanApplication?
    @State private var showingCallAlert = false
    @State private var showingFlagAlert = false
    @State private var alertMessage = ""

    private var filteredApplications: [OfficerLoanApplication] {
        var list = viewModel.filteredApplications

        switch selectedFilter {
        case .all:
            break
        case .pending:
            list = list.filter { [.pending, .applied, .documentsPending, .documentsRejected].contains($0.status) }
        case .review:
            list = list.filter { [.underReview, .verificationCompleted].contains($0.status) }
        case .manager:
            list = list.filter { [.sentToManager, .finalApprovalPending].contains($0.status) || $0.sentToManagerDate != nil }
        case .closed:
            list = list.filter { [.approved, .disbursed, .rejected].contains($0.status) }
        }

        switch sortOrder {
        case .newest:
            list.sort { $0.submittedDate > $1.submittedDate }
        case .oldest:
            list.sort { $0.submittedDate < $1.submittedDate }
        case .amountAsc:
            list.sort { $0.requestedAmount < $1.requestedAmount }
        case .amountDesc:
            list.sort { $0.requestedAmount > $1.requestedAmount }
        }

        return list
    }

    var body: some View {
        List {
            Section {
                Picker("Stage", selection: $selectedFilter) {
                    ForEach(RegistryFilter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)

            Section {
                ForEach(filteredApplications) { app in
                    Button {
                        activeDetailApp = app
                    } label: {
                        RegistryApplicationRow(app: app)
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            alertMessage = "Calling \(app.borrowerName) at the verified phone number."
                            showingCallAlert = true
                        } label: {
                            Label("Call", systemImage: "phone")
                        }
                        .tint(.green)

                        Button {
                            alertMessage = "\(app.applicationId) is flagged for compliance review."
                            showingFlagAlert = true
                        } label: {
                            Label("Flag", systemImage: "flag")
                        }
                        .tint(.orange)
                    }
                }
            } header: {
                HStack {
                    Text("\(filteredApplications.count) Applications")
                    Spacer()
                    Menu {
                        Picker("Sort", selection: $sortOrder) {
                            ForEach(HistorySortOrder.allCases, id: \.self) { order in
                                Text(order.rawValue).tag(order)
                            }
                        }
                    } label: {
                        Label(sortOrder.rawValue, systemImage: "arrow.up.arrow.down")
                    }
                    .textCase(nil)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Registry")
        .searchable(text: $viewModel.historySearchQuery, prompt: "Borrower, ID, branch")
        .refreshable { await viewModel.fetchDashboardData() }
        .sheet(item: $activeDetailApp) { app in
            LoanApplicationReviewDetailView(applicationId: app.applicationId, viewModel: viewModel)
        }
        .alert("Call", isPresented: $showingCallAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Flagged", isPresented: $showingFlagAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            syncFilterFromViewModel()
        }
        .onChange(of: viewModel.historyFilter) { _, _ in syncFilterFromViewModel() }
    }

    private func syncFilterFromViewModel() {
        guard let status = viewModel.historyFilter else {
            selectedFilter = .all
            return
        }

        switch status {
        case .pending, .applied, .documentsPending, .documentsRejected:
            selectedFilter = .pending
        case .underReview, .verificationCompleted:
            selectedFilter = .review
        case .sentToManager, .finalApprovalPending:
            selectedFilter = .manager
        case .approved, .disbursed, .rejected:
            selectedFilter = .closed
        default:
            selectedFilter = .all
        }
    }
}

private enum RegistryFilter: String, CaseIterable, Identifiable {
    case all
    case pending
    case review
    case manager
    case closed

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .pending: return "Pending"
        case .review: return "Review"
        case .manager: return "Manager"
        case .closed: return "Closed"
        }
    }
}

private struct RegistryApplicationRow: View {
    let app: OfficerLoanApplication

    var body: some View {
        HStack(spacing: 12) {
            OfficerAvatar(name: app.borrowerName, tint: app.loanType.themeColor)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(app.borrowerName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(CurrencyFormatter.shared.format(app.requestedAmount))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                }

                Text("\(app.loanType.rawValue) · \(app.branch)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 8) {
                    Text(app.applicationId)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                    Text(app.status.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(app.status.themeColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(app.status.themeColor.opacity(0.12), in: Capsule())
                }
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(app.borrowerName), \(app.loanType.rawValue), \(app.status.rawValue), amount \(CurrencyFormatter.shared.format(app.requestedAmount))")
    }
}
