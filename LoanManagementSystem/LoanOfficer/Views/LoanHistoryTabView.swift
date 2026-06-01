import SwiftUI

struct LoanHistoryTabView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @State private var activeDetailApp: OfficerLoanApplication?
    @State private var showingCallAlert = false
    @State private var showingFlagAlert = false
    @State private var alertMessage = ""

    var body: some View {
        List {
            Section {
                if viewModel.filteredApplications.isEmpty {
                    ContentUnavailableView(
                        "No \(viewModel.historyFilter.title) Applications",
                        systemImage: "tray.full",
                        description: Text("No records found matching this status.")
                    )
                } else {
                    ForEach(viewModel.filteredApplications) { app in
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
                Text("\(viewModel.filteredApplications.count) Total Applications")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(nil)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Registry")
        .searchable(text: $viewModel.historySearchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Borrower, ID, branch")
        .refreshable { await viewModel.fetchDashboardData() }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Picker("Filter by Status", selection: $viewModel.historyFilter) {
                        ForEach(RegistryFilter.allCases) { filter in
                            Label(filter.title, systemImage: icon(for: filter))
                                .tag(filter)
                        }
                    }
                    
                    Divider()
                    
                    Picker("Sort Order", selection: $viewModel.historySortOrder) {
                        ForEach(HistorySortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                } label: {
                    Label("Filter", systemImage: viewModel.historyFilter == .all ? "line.3.horizontal.decrease.circle" : "line.3.horizontal.decrease.circle.fill")
                }
            }
        }
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
    }

    private func icon(for filter: RegistryFilter) -> String {
        switch filter {
        case .all: return "tray.2"
        case .newCases: return "sparkles"
        case .underCheck: return "clock"
        case .approvalQueue: return "checkmark.seal"
        case .completed: return "checkmark.circle"
        }
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
