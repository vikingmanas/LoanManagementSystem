import SwiftUI

enum OfficerQuickActionID: String, Hashable, CaseIterable {
    case newApplication = "new_application"
    case verifyDocuments = "verify_documents"
    case complianceAudit = "compliance_audit"
    case branchReports = "branch_reports"
    case clientDirectory = "client_directory"
    case escalateCase = "escalate_case"

    var shortTitle: String {
        switch self {
        case .newApplication: return "New App"
        case .verifyDocuments: return "Verify Docs"
        case .complianceAudit: return "Compliance"
        case .branchReports: return "Reports"
        case .clientDirectory: return "Directory"
        case .escalateCase: return "Escalate"
        }
    }

    var symbol: String {
        switch self {
        case .newApplication: return "person.crop.circle.badge.plus"
        case .verifyDocuments: return "doc.text.magnifyingglass"
        case .complianceAudit: return "shield.checkerboard"
        case .branchReports: return "chart.bar.xaxis"
        case .clientDirectory: return "folder.badge.person.crop"
        case .escalateCase: return "arrow.up.circle.fill"
        }
    }

    var tint: Color {
        switch self {
        case .newApplication: return AppTheme.successGreen
        case .verifyDocuments: return AppTheme.actionBlue
        case .complianceAudit: return AppTheme.brandNavy
        case .branchReports: return .purple
        case .clientDirectory: return .teal
        case .escalateCase: return AppTheme.criticalRed
        }
    }
}

struct OfficerQuickActionsView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onSystemAction: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("Quick Actions")
                .font(LMSFont.title3)
                .foregroundStyle(LMSColors.textPrimary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LMSSpacing.md) {
                    ForEach(OfficerQuickActionID.allCases, id: \.self) { action in
                        NavigationLink(value: action) {
                            quickActionTile(action)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            }
        }
    }

    private func quickActionTile(_ action: OfficerQuickActionID) -> some View {
        VStack(spacing: LMSSpacing.sm) {
            ZStack {
                RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                    .fill(action.tint.opacity(0.14))
                    .frame(width: 52, height: 52)

                Image(systemName: action.symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(action.tint)
                    .symbolRenderingMode(.hierarchical)
            }

            Text(action.shortTitle)
                .font(LMSFont.caption2.weight(.semibold))
                .foregroundStyle(LMSColors.textPrimary)
                .lineLimit(1)
        }
        .frame(width: 80)
        .padding(.vertical, LMSSpacing.sm)
        .padding(.horizontal, LMSSpacing.xs)
        .background(LMSColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .accessibilityLabel("Quick action: \(action.shortTitle)")
    }
}



@ViewBuilder
func officerQuickActionDetail(
    for action: OfficerQuickActionID,
    viewModel: LoanOfficerDashboardViewModel,
    onSystemAction: @escaping (String) -> Void
) -> some View {
    switch action {
    case .newApplication:
        OfficerNewApplicationDetailView(viewModel: viewModel)
    case .verifyDocuments:
        OfficerVerifyDocumentsDetailView(viewModel: viewModel, onOpenQueue: { onSystemAction("verify_documents") })
    case .complianceAudit:
        OfficerComplianceAuditDetailView()
    case .branchReports:
        OfficerBranchReportsDetailView(onDownload: { onSystemAction("branch_reports") })
    case .clientDirectory:
        OfficerClientDirectoryDetailView(viewModel: viewModel)
    case .escalateCase:
        OfficerEscalateCaseDetailView(viewModel: viewModel, onSubmit: { onSystemAction("escalate_case") })
    }
}



struct OfficerNewApplicationDetailView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel

    private let steps = [
        ("person.text.rectangle", "Capture KYC", "Aadhaar, PAN, and address proof"),
        ("briefcase.fill", "Employment & Income", "Salary slips and bank statements"),
        ("house.fill", "Loan Selection", "Home, personal, or business product"),
        ("checkmark.seal.fill", "Submit for Review", "Officer verification queue")
    ]

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                    Text("Start Customer Onboarding")
                        .font(LMSFont.title3)
                    Text("Launch a guided flow to register a new borrower and initiate their loan application at your branch.")
                        .font(LMSFont.footnote)
                        .foregroundStyle(LMSColors.textSecondary)
                }
                .padding(.vertical, LMSSpacing.xs)
            }

            Section("Application Pipeline") {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(step.1)
                                .font(LMSFont.subheadline.weight(.semibold))
                            Text(step.2)
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                    } icon: {
                        ZStack {
                            Circle()
                                .fill(LMSColors.actionBlue.opacity(0.12))
                                .frame(width: 36, height: 36)
                            Image(systemName: step.0)
                                .foregroundStyle(LMSColors.actionBlue)
                        }
                    }
                    .badge(index + 1)
                }
            }

            Section {
                Button {
                    HapticsManager.triggerImpact(style: .medium)
                } label: {
                    Label("Begin New Application", systemImage: "plus.circle.fill")
                        .font(LMSFont.button)
                }
            }
        }
        .navigationTitle("New Application")
        .navigationBarTitleDisplayMode(.large)
    }
}



struct OfficerVerifyDocumentsDetailView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onOpenQueue: () -> Void

    var body: some View {
        List {
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(viewModel.todayDocumentReviewCount)")
                            .font(LMSFont.largeTitle)
                            .foregroundStyle(AppTheme.warningAmber)
                        Text("Documents uploaded today")
                            .font(LMSFont.footnote)
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(AppTheme.actionBlue.opacity(0.5))
                }
                .padding(.vertical, LMSSpacing.xs)
            }

            Section("Priority Queue") {
                if viewModel.todayDocumentQueueList.isEmpty {
                    ContentUnavailableView("All Clear", systemImage: "checkmark.circle", description: Text("No documents uploaded today."))
                } else {
                    ForEach(viewModel.todayDocumentQueueList) { item in
                        HStack(spacing: LMSSpacing.md) {
                            Image(systemName: item.docType.symbol)
                                .foregroundStyle(item.status.themeColor)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.borrowerName)
                                    .font(LMSFont.subheadline.weight(.semibold))
                                Text("\(item.docType.rawValue) · \(item.applicationId)")
                                    .font(LMSFont.caption)
                                    .foregroundStyle(LMSColors.textSecondary)
                            }
                            Spacer()
                            Text(item.status.rawValue)
                                .font(LMSFont.caption2.weight(.bold))
                                .foregroundStyle(item.status.themeColor)
                        }
                    }
                }
            }

            Section {
                Button(action: onOpenQueue) {
                    Label("Open Full Document Queue", systemImage: "arrow.down.doc")
                }
            }
        }
        .navigationTitle("Verify Documents")
        .navigationBarTitleDisplayMode(.large)
    }
}



struct OfficerComplianceAuditDetailView: View {
    private let checks: [(String, String, String, Bool)] = [
        ("KYC Validity", "Aadhaar & PAN within policy window", "person.badge.shield.checkmark", true),
        ("AML Screening", "Borrower not on restricted lists", "list.bullet.clipboard", true),
        ("RBI LTV Norms", "Loan-to-value within product limits", "percent", false),
        ("Income Verification", "Salary credits match declared income", "indianrupeesign.bank.building", true),
        ("Collateral Docs", "Property papers attested and indexed", "doc.richtext", false)
    ]

    var body: some View {
        List {
            Section {
                Text("RBI-aligned compliance checklist for applications in your Bengaluru branch queue.")
                    .font(LMSFont.footnote)
                    .foregroundStyle(LMSColors.textSecondary)
            }

            Section("Audit Items") {
                ForEach(Array(checks.enumerated()), id: \.offset) { _, check in
                    HStack(spacing: LMSSpacing.md) {
                        Image(systemName: check.2)
                            .foregroundStyle(check.3 ? LMSColors.emerald : LMSColors.amber)
                            .frame(width: 28)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(check.0)
                                .font(LMSFont.subheadline.weight(.semibold))
                            Text(check.1)
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: check.3 ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .foregroundStyle(check.3 ? LMSColors.emerald : LMSColors.amber)
                    }
                }
            }

            Section {
                Button {
                    HapticsManager.triggerNotification(type: .success)
                } label: {
                    Label("Run Full Branch Audit", systemImage: "shield.checkered")
                }
            }
        }
        .navigationTitle("Compliance Audit")
        .navigationBarTitleDisplayMode(.large)
    }
}



struct OfficerBranchReportsDetailView: View {
    var onDownload: () -> Void

    private let reports = [
        ("Monthly Performance", "May 2026 · Disbursements & targets", "chart.bar.doc.horizontal"),
        ("Portfolio Quality", "NPA, PAR-30, and recovery rates", "chart.pie"),
        ("Officer Productivity", "Approvals, TAT, and query resolution", "person.3.sequence"),
        ("Regulatory Filing", "RBI quarterly branch submission pack", "doc.zipper")
    ]

    var body: some View {
        List {
            Section("Bengaluru Branch") {
                ForEach(Array(reports.enumerated()), id: \.offset) { _, report in
                    HStack(spacing: LMSSpacing.md) {
                        Image(systemName: report.2)
                            .font(.title3)
                            .foregroundStyle(.purple)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(report.0)
                                .font(LMSFont.subheadline.weight(.semibold))
                            Text(report.1)
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.down.circle")
                            .foregroundStyle(LMSColors.actionBlue)
                    }
                }
            }

            Section {
                Button(action: onDownload) {
                    Label("Download All Reports (PDF)", systemImage: "square.and.arrow.down")
                }
            }
        }
        .navigationTitle("Branch Reports")
        .navigationBarTitleDisplayMode(.large)
    }
}



struct OfficerClientDirectoryDetailView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @State private var searchText = ""

    private var filteredApps: [OfficerLoanApplication] {
        guard !searchText.isEmpty else { return viewModel.applications }
        return viewModel.applications.filter {
            $0.borrowerName.localizedCaseInsensitiveContains(searchText) ||
            $0.applicationId.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    Text("\(viewModel.applications.count)")
                        .font(LMSFont.title)
                    Text("active borrowers in your portfolio")
                        .font(LMSFont.footnote)
                        .foregroundStyle(LMSColors.textSecondary)
                }
            }

            Section("Clients") {
                ForEach(filteredApps) { app in
                    HStack(spacing: LMSSpacing.md) {
                        Circle()
                            .fill(AppTheme.brandNavy.opacity(0.12))
                            .frame(width: 40, height: 40)
                            .overlay(
                                Text(String(app.borrowerName.prefix(2)).uppercased())
                                    .font(LMSFont.caption.weight(.bold))
                                    .foregroundStyle(AppTheme.brandNavy)
                            )
                        VStack(alignment: .leading, spacing: 2) {
                            Text(app.borrowerName)
                                .font(LMSFont.subheadline.weight(.semibold))
                            Text("\(app.loanType.rawValue) · \(app.applicationId)")
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                        Spacer()
                        Text(app.status.rawValue)
                            .font(LMSFont.caption2.weight(.bold))
                            .foregroundStyle(app.status.themeColor)
                    }
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search name or application ID")
        .navigationTitle("Client Directory")
        .navigationBarTitleDisplayMode(.large)
    }
}



struct OfficerEscalateCaseDetailView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onSubmit: () -> Void

    @State private var selectedAppId = ""
    @State private var escalationReason = ""
    @State private var priority = "High"
    private let priorities = ["High", "Medium", "Low"]

    var body: some View {
        Form {
            Section {
                Text("Submit a case to your branch manager when verification, compliance, or disbursement needs senior approval.")
                    .font(LMSFont.footnote)
                    .foregroundStyle(LMSColors.textSecondary)
            }

            Section("Case Details") {
                Picker("Application", selection: $selectedAppId) {
                    Text("Select application").tag("")
                    ForEach(viewModel.applications) { app in
                        Text("\(app.borrowerName) · \(app.applicationId)").tag(app.applicationId)
                    }
                }

                Picker("Priority", selection: $priority) {
                    ForEach(priorities, id: \.self) { Text($0).tag($0) }
                }

                TextField("Reason for escalation", text: $escalationReason, axis: .vertical)
                    .lineLimit(4...8)
            }

            Section {
                Button {
                    HapticsManager.triggerNotification(type: .warning)
                    onSubmit()
                } label: {
                    Label("Submit to Branch Manager", systemImage: "arrow.up.circle.fill")
                }
                .disabled(selectedAppId.isEmpty || escalationReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .navigationTitle("Escalate Case")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            if selectedAppId.isEmpty, let first = viewModel.applications.first {
                selectedAppId = first.applicationId
            }
        }
    }
}

#Preview {
    NavigationStack {
        OfficerQuickActionsView(
            viewModel: PreviewSupport.loanOfficerViewModel,
            onSystemAction: { _ in }
        )
        .padding()
    }
    .previewLoanOfficerEnvironment()
}

