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
        case .newCases:
            list = list.filter { [.pending, .applied].contains($0.status) }
        case .underCheck:
            list = list.filter { [.underReview, .verificationCompleted, .documentsPending, .documentsRejected, .onHold].contains($0.status) }
        case .approvalQueue:
            list = list.filter { [.sentToManager, .finalApprovalPending].contains($0.status) || $0.sentToManagerDate != nil }
        case .completed:
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
                if filteredApplications.isEmpty {
                    ContentUnavailableView(
                        "No \(selectedFilter.title) Applications",
                        systemImage: "tray.full",
                        description: Text("No records found matching this status.")
                    )
                } else {
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
                }
            } header: {
                Text("\(filteredApplications.count) Total Applications")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(nil)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Registry")
        .searchable(text: $viewModel.historySearchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Borrower, ID, branch")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                RegistryFilterMenu(selectedFilter: $selectedFilter)
            }
        }
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
        if let filter = viewModel.historyFilter {
            selectedFilter = filter
        }
    }
}

private struct RegistryFilterMenu: View {
    @Binding var selectedFilter: RegistryFilter

    var body: some View {
        Menu {
            Picker("Status", selection: $selectedFilter) {
                ForEach(RegistryFilter.allCases) { filter in
                    Text(filter.title).tag(filter)
                }
            }
        } label: {
            Image(systemName: selectedFilter == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                .imageScale(.large)
                .symbolRenderingMode(.hierarchical)
        }
        .accessibilityLabel("Registry status filter")
        .accessibilityValue(selectedFilter.title)
    }
}

private struct RegistryApplicationRow: View {
    let app: OfficerLoanApplication

    var body: some View {
        HStack(spacing: 12) {
            OfficerAvatar(name: app.borrowerName, tint: app.loanType.themeColor)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(app.borrowerName)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(CurrencyFormatter.shared.format(app.requestedAmount))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.8)
                }

                Text("\(app.loanType.rawValue) · \(app.branch)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)

                HStack(spacing: 8) {
                    Text(app.applicationId)
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(app.status.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(app.status.themeColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(app.status.themeColor.opacity(0.12), in: Capsule())
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(app.borrowerName), \(app.loanType.rawValue), \(app.status.rawValue), amount \(CurrencyFormatter.shared.format(app.requestedAmount))")
    }
}
