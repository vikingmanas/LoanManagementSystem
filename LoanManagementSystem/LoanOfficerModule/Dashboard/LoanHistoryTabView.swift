import SwiftUI

struct LoanHistoryTabView: View {
    typealias LoanApplication = OfficerLoanApplication
    typealias LoanType = OfficerLoanType
    typealias ApplicationStatus = OfficerApplicationStatus
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    
    @State private var isSearchExpanded = false
    @State private var showTypePicker = false
    @State private var showDatePicker = false
    @State private var showSortPicker = false
    @State private var showingExportAlert = false
    @State private var activeDetailApp: LoanApplication? = nil
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // FILTER BAR (Sticky Section)
            VStack(spacing: 10) {
                // 1. Status Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // "All" Pill
                        FilterPill(
                            title: "All",
                            isSelected: viewModel.historyFilter == nil
                        ) {
                            HapticsManager.triggerImpact(style: .light)
                            viewModel.historyFilter = nil
                        }
                        
                        // Dynamic ApplicationStatus Pills
                        ForEach(ApplicationStatus.allCases, id: \.self) { status in
                            FilterPill(
                                title: status.rawValue,
                                isSelected: viewModel.historyFilter == status
                            ) {
                                HapticsManager.triggerImpact(style: .light)
                                viewModel.historyFilter = status
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                }
                
                // 2. Sub-filters Row
                HStack(spacing: 8) {
                    // Loan Type Dropdown Chip
                    DropdownChip(
                        title: viewModel.historyLoanTypeFilter?.rawValue ?? "Loan Type",
                        isActive: viewModel.historyLoanTypeFilter != nil
                    ) {
                        showTypePicker = true
                    }
                    
                    // Date Range Chip
                    DropdownChip(
                        title: "Date Range",
                        isActive: true
                    ) {
                        showDatePicker = true
                    }
                    
                    // Sort Chip
                    DropdownChip(
                        title: "Sort: \(viewModel.historySortOrder.rawValue)",
                        isActive: true
                    ) {
                        showSortPicker = true
                    }
                    
                    Spacer()
                    
                    // Animated Search Chip/TextField
                    HStack {
                        if isSearchExpanded {
                            HStack(spacing: 4) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 14))
                                    .foregroundColor(LMSColors.textSecondary)
                                
                                TextField("Search name, ID...", text: $viewModel.historySearchQuery)
                                    .font(.system(.caption, design: .rounded))
                                    .frame(width: 110)
                                    .autocorrectionDisabled()
                                
                                Button(action: {
                                    withAnimation(.spring()) {
                                        viewModel.historySearchQuery = ""
                                        isSearchExpanded = false
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(LMSColors.textSecondary)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(LMSColors.textPrimary.opacity(0.06))
                            .cornerRadius(12)
                        } else {
                            Button(action: {
                                withAnimation(.spring()) {
                                    isSearchExpanded = true
                                }
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(LMSColors.textPrimary)
                                    .frame(width: 32, height: 32)
                                    .background(.ultraThinMaterial)
                                    .cornerRadius(16)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .background(LMSColors.surface)
            .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 3)
            
            // RESULTS HEADER
            HStack {
                Text("Showing \(viewModel.filteredApplications.count) of \(viewModel.totalApplications) loans")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(LMSColors.textSecondary)
                
                Spacer()
                
                Button(action: {
                    HapticsManager.triggerImpact(style: .medium)
                    showingExportAlert = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Export")
                            .font(.system(.caption, design: .rounded).bold())
                    }
                    .foregroundColor(AppTheme.actionBlue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 6)
            
            Divider()
            
            // LOAN LIST
            if viewModel.filteredApplications.isEmpty {
                Spacer()
                ContentUnavailableView(
                    "No Loans Found",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text("Try adjusting your filters or search terms.")
                )
                Spacer()
            } else {
                List {
                    let categorized = categorizedApplications()
                    ForEach(ApplicationCategory.allCases) { category in
                        if let apps = categorized[category], !apps.isEmpty {
                            Section(header: Text(category.rawValue)
                                .font(.system(.caption2, design: .rounded).bold())
                                .foregroundColor(AppTheme.brandNavy)
                                .padding(.vertical, 4)
                            ) {
                                ForEach(apps) { app in
                                    LoanHistoryRow(
                                        app: app,
                                        onView: {
                                            activeDetailApp = app
                                        },
                                        onCall: {
                                            alertMessage = "Calling borrower \(app.borrowerName) at verified registration number..."
                                            showingExportAlert = true // reuse alerts for mock responses
                                        },
                                        onFlag: {
                                            alertMessage = "Flagged application \(app.applicationId) for compliance audit."
                                            showingExportAlert = true
                                        }
                                    )
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(Color.clear)
                                    .listRowSeparator(.visible, edges: .bottom)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.fetchDashboardData()
                }
            }
        }
        // PICKER SHEETS & ALERTS
        .sheet(isPresented: $showTypePicker) {
            NavigationStack {
                List {
                    Button("All Types") {
                        viewModel.historyLoanTypeFilter = nil
                        showTypePicker = false
                    }
                    .foregroundColor(LMSColors.textPrimary)
                    
                    ForEach(LoanType.allCases, id: \.self) { type in
                        Button(type.rawValue) {
                            viewModel.historyLoanTypeFilter = type
                            showTypePicker = false
                        }
                        .foregroundColor(LMSColors.textPrimary)
                    }
                }
                .navigationTitle("Filter by Loan Type")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cancel") { showTypePicker = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                VStack(spacing: 20) {
                    DatePicker("Start Date", selection: $viewModel.historyStartDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                    
                    DatePicker("End Date", selection: $viewModel.historyEndDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                }
                .padding()
                .navigationTitle("Select Dates")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Done") { showDatePicker = false }
                    }
                }
            }
        }
        .sheet(isPresented: $showSortPicker) {
            NavigationStack {
                List {
                    ForEach(HistorySortOrder.allCases, id: \.self) { order in
                        Button(order.rawValue) {
                            viewModel.historySortOrder = order
                            showSortPicker = false
                        }
                        .foregroundColor(LMSColors.textPrimary)
                    }
                }
                .navigationTitle("Sort Orders")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Cancel") { showSortPicker = false }
                    }
                }
            }
            .presentationDetents([.medium])
        }
        .sheet(item: $activeDetailApp) { app in
            LoanApplicationReviewDetailView(applicationId: app.applicationId, viewModel: viewModel)
        }
        .alert(isPresented: $showingExportAlert) {
            Alert(
                title: Text("System Alert"),
                message: Text(alertMessage.isEmpty ? "Exporting \(viewModel.filteredApplications.count) records to CSV. File will be shared to your secure directory." : alertMessage),
                dismissButton: .default(Text("OK")) {
                    alertMessage = ""
                }
            )
        }
    }
    
    private func categorizedApplications() -> [ApplicationCategory: [LoanApplication]] {
        var groups: [ApplicationCategory: [LoanApplication]] = [:]
        let calendar = Calendar.current
        let now = Date()
        
        let filtered = viewModel.filteredApplications
        
        for app in filtered {
            // Check status-based categories first
            if app.status == .rejected || app.status == .documentsRejected {
                groups[.rejected, default: []].append(app)
                continue
            }
            
            if app.status == .finalApprovalPending || app.status == .sentToManager || app.status == .approved {
                groups[.forwarded, default: []].append(app)
                continue
            }
            
            // Check pending review / date based categories
            if app.status == .pending || app.status == .underReview || app.status == .documentsPending {
                if calendar.isDateInToday(app.submittedDate) {
                    groups[.todays, default: []].append(app)
                } else if calendar.isDateInYesterday(app.submittedDate) {
                    groups[.yesterdays, default: []].append(app)
                } else if calendar.isDate(app.submittedDate, equalTo: now, toGranularity: .weekOfYear) {
                    groups[.thisWeeks, default: []].append(app)
                } else {
                    groups[.pendingReviews, default: []].append(app)
                }
                continue
            }
            
            // Fallback
            if calendar.isDateInToday(app.submittedDate) {
                groups[.todays, default: []].append(app)
            } else if calendar.isDateInYesterday(app.submittedDate) {
                groups[.yesterdays, default: []].append(app)
            } else if calendar.isDate(app.submittedDate, equalTo: now, toGranularity: .weekOfYear) {
                groups[.thisWeeks, default: []].append(app)
            } else {
                groups[.pendingReviews, default: []].append(app)
            }
        }
        return groups
    }
}

enum ApplicationCategory: String, CaseIterable, Identifiable {
    case todays = "Today's Applications"
    case yesterdays = "Yesterday's Applications"
    case thisWeeks = "This Week's Applications"
    case pendingReviews = "Pending Reviews"
    case rejected = "Rejected Applications"
    case forwarded = "Forwarded to Manager"
    
    var id: String { self.rawValue }
}

// Mini filter pill styling
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.system(.caption, design: .rounded).bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.actionBlue : LMSColors.textPrimary.opacity(0.06))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(17)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Dropdown chip styling
struct DropdownChip: View {
    let title: String
    let isActive: Bool
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Text(title)
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundColor(isActive ? AppTheme.actionBlue : .primary)
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(isActive ? AppTheme.actionBlue : Color(.placeholderText))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background {
                if isActive {
                    AppTheme.actionBlue.opacity(0.08)
                } else {
                    Color.clear.background(.ultraThinMaterial)
                }
            }
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? AppTheme.actionBlue.opacity(0.3) : LMSColors.textPrimary.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Mock detailed loan view
struct LoanDetailMockView: View {
    typealias LoanApplication = OfficerLoanApplication
    let app: LoanApplication
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section("Borrower & ID") {
                    LabeledContent("Borrower Name", value: app.borrowerName)
                    LabeledContent("Application ID", value: app.applicationId)
                    LabeledContent("Assigned Branch", value: app.branch)
                    if let cibil = app.cibilScore {
                        LabeledContent("CIBIL Score", value: "\(cibil)")
                    }
                }
                
                Section("Financial Information") {
                    LabeledContent("Loan Type", value: app.loanType.rawValue)
                    LabeledContent("Requested Value", value: CurrencyFormatter.shared.format(app.requestedAmount))
                    LabeledContent("Status", value: app.status.rawValue)
                }
                
                Section("Documents Status") {
                    if app.documents.isEmpty {
                        Text("No verified documents in this simulation")
                    } else {
                        ForEach(app.documents) { doc in
                            HStack {
                                Image(systemName: doc.docType.symbol)
                                    .foregroundColor(doc.status.themeColor)
                                Text(doc.docType.rawValue)
                                Spacer()
                                Text(doc.status.rawValue)
                                    .font(LMSFont.caption)
                                    .foregroundColor(LMSColors.textSecondary)
                            }
                        }
                    }
                }
                
                Section("Officer Notes") {
                    Text(app.notes)
                        .font(LMSFont.body)
                }
            }
            .navigationTitle("Loan Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Dismiss") { dismiss() }
                }
            }
        }
    }
}
