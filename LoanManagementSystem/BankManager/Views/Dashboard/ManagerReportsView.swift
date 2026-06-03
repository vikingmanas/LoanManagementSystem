import SwiftUI


struct ManagerReportsView: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @State private var showReportSheet = false
    @State private var showAuditLog = false

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("Reports & Insights")
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
                .padding(.horizontal, LMSSpacing.screenHorizontal)

            VStack(spacing: LMSSpacing.md) {
                VStack(spacing: LMSSpacing.sm) {
                    ReportButton(
                        icon: "chart.bar.doc.horizontal.fill",
                        title: "Branch Loan Report",
                        subtitle: "Officer-wise disbursal, recovery, and product mix",
                        tint: LMSColors.brandNavy,
                        prominence: .primary
                    ) {
                        showReportSheet = true
                    }

                    ReportButton(
                        icon: "list.bullet.clipboard.fill",
                        title: "Audit Logs",
                        subtitle: "Manager decisions and exception trail",
                        tint: LMSColors.teal,
                        prominence: .secondary
                    ) {
                        showAuditLog = true
                    }
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)

                ManagerInsightCard(viewModel: viewModel)
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
            }
        }
        .sheet(isPresented: $showReportSheet) {
            ManagerReportSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showAuditLog) {
            ManagerAuditLogSheet(events: viewModel.auditEvents)
        }
    }
}


private struct ReportButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let tint: Color
    let prominence: Prominence
    let action: () -> Void

    enum Prominence {
        case primary, secondary
    }

    var body: some View {
        Button(action: {
            HapticsManager.triggerImpact(style: .medium)
            action()
        }) {
            HStack(spacing: LMSSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous)
                        .fill(prominence == .primary ? Color.white.opacity(0.16) : tint.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }

                Spacer(minLength: LMSSpacing.sm)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(prominence == .primary ? .white : tint)
            .padding(.horizontal, LMSSpacing.lg)
            .padding(.vertical, LMSSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(prominence == .primary ? tint : tint.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
        }
        .buttonStyle(LMSPressableStyle())
    }
}


private struct ManagerInsightCard: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    private var snapshot: BranchLoanReportSnapshot {
        BranchLoanReportSnapshot(applicants: viewModel.applicants, officers: viewModel.officers)
    }

    private var insightText: String {
        if let leadingOfficer = snapshot.officerRows.max(by: { $0.disbursedAmount < $1.disbursedAmount }), leadingOfficer.disbursedAmount > 0 {
            return "\(leadingOfficer.officer.name) leads disbursal with \(CurrencyFormatter.shared.format(leadingOfficer.disbursedAmount)) across \(leadingOfficer.disbursedCount) approved loan\(leadingOfficer.disbursedCount == 1 ? "" : "s")."
        }
        if let highRisk = viewModel.applicants.first(where: { $0.riskLevel == .high || $0.riskLevel == .critical }) {
            return "\(highRisk.applicationId) needs closer risk review before branch clearance."
        }
        if viewModel.pendingApplicants.isEmpty {
            return "Approval request is clear for \(viewModel.branchOverview.name)."
        }
        return "\(viewModel.pendingApplicants.count) application\(viewModel.pendingApplicants.count == 1 ? "" : "s") awaiting manager decision."
    }

    var body: some View {
        HStack(spacing: LMSSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.15), LMSColors.actionBlue.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.purple)
            }

            VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                Text("Branch Insight")
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundStyle(Color.purple)

                Text(insightText)
                    .font(.system(.callout, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }

            Spacer(minLength: 0)
        }
        .padding(LMSSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.04), LMSColors.actionBlue.opacity(0.04)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                .stroke(Color.purple.opacity(0.12), lineWidth: 0.5)
        )
    }
}


struct ManagerReportSheet: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var exportError: String?
    @State private var selectedFrequency: ManagerReportFrequency = .monthly

    private var snapshot: BranchLoanReportSnapshot {
        BranchLoanReportSnapshot(applicants: viewModel.applicants, officers: viewModel.officers)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Branch Loan Book") {
                    LabeledContent("Name", value: viewModel.branchOverview.name)
                    LabeledContent("Region", value: viewModel.branchOverview.region)
                    LabeledContent("Applications", value: "\(snapshot.totalApplications)")
                    LabeledContent("Approved/Disbursed", value: "\(snapshot.disbursedCount)")
                    LabeledContent("Disbursed Amount", value: CurrencyFormatter.shared.format(snapshot.totalDisbursed))
                    LabeledContent("Recovered Estimate", value: CurrencyFormatter.shared.format(snapshot.totalRecovered))
                }

                Section("Approval Pipeline") {
                    LabeledContent("Pending Approvals", value: "\(viewModel.pendingApplicants.count)")
                    LabeledContent("Needs Clarification", value: "\(viewModel.applicants.filter { $0.status == .needsClarification }.count)")
                    LabeledContent("Rejected", value: "\(viewModel.applicants.filter { $0.status == .rejected }.count)")
                    LabeledContent("Officers Tracked", value: "\(viewModel.officers.count)")
                }

                Section("Loan Type Mix") {
                    if snapshot.loanTypeRows.isEmpty {
                        Text("No loan applications available.")
                            .foregroundStyle(LMSColors.textSecondary)
                    } else {
                        ForEach(snapshot.loanTypeRows) { row in
                            VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                                HStack {
                                    Label(row.loanType.rawValue, systemImage: row.loanType.symbol)
                                        .font(.system(.body, design: .rounded).weight(.semibold))
                                        .foregroundStyle(LMSColors.textPrimary)
                                    Spacer()
                                    Text(CurrencyFormatter.shared.format(row.disbursedAmount))
                                        .font(.system(.body, design: .rounded).bold())
                                        .foregroundStyle(row.loanType.themeColor)
                                }
                                Text("\(row.applicationCount) application\(row.applicationCount == 1 ? "" : "s") · \(row.disbursedCount) approved/disbursed · \(CurrencyFormatter.shared.format(row.recoveredAmount)) recovered")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(LMSColors.textSecondary)
                            }
                            .padding(.vertical, LMSSpacing.xs)
                        }
                    }
                }

                Section("Loan Officer Report") {
                    if snapshot.officerRows.isEmpty {
                        Text("No officer loan activity available.")
                            .foregroundStyle(LMSColors.textSecondary)
                    } else {
                        ForEach(snapshot.officerRows) { row in
                            VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                                HStack(alignment: .top) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(row.officer.name)
                                            .font(.system(.body, design: .rounded).bold())
                                            .foregroundStyle(LMSColors.textPrimary)
                                        Text(row.officer.role)
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundStyle(LMSColors.textSecondary)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(CurrencyFormatter.shared.format(row.disbursedAmount))
                                            .font(.system(.body, design: .rounded).bold())
                                            .foregroundStyle(LMSColors.brandNavy)
                                        Text("Recovered \(CurrencyFormatter.shared.format(row.recoveredAmount))")
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundStyle(LMSColors.emerald)
                                    }
                                }

                                Text("\(row.disbursedCount) approved/disbursed of \(row.applicationCount) total · \(row.primaryLoanTypeText)")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(LMSColors.textSecondary)

                                if !row.loanTypeRows.isEmpty {
                                    VStack(spacing: LMSSpacing.xs) {
                                        ForEach(row.loanTypeRows) { typeRow in
                                            HStack {
                                                Text(typeRow.loanType.rawValue)
                                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                                                    .foregroundStyle(typeRow.loanType.themeColor)
                                                Spacer()
                                                Text("\(typeRow.disbursedCount) · \(CurrencyFormatter.shared.format(typeRow.disbursedAmount))")
                                                    .font(.system(.caption, design: .rounded))
                                                    .foregroundStyle(LMSColors.textSecondary)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.vertical, LMSSpacing.xs)
                        }
                    }
                }

                Section("Recovery Note") {
                    Text("Recovered amount is estimated from approved and disbursed loans using tenure, interest rate, and elapsed time in the available application data. Connect the EMI ledger to replace this with actual collections.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                }

                Section("Scheduled Report Storage") {
                    Picker("Frequency", selection: $selectedFrequency) {
                        ForEach(ManagerReportFrequency.allCases) { frequency in
                            Text(frequency.displayName).tag(frequency)
                        }
                    }
                    .pickerStyle(.segmented)

                    Button(action: storeSelectedReport) {
                        HStack {
                            if viewModel.isGeneratingReports {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Text(viewModel.isGeneratingReports ? "Storing Report..." : "Generate & Store \(selectedFrequency.displayName)")
                                .font(.system(.body, design: .rounded).weight(.bold))
                        }
                        .foregroundStyle(LMSColors.brandNavy)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    .disabled(viewModel.isGeneratingReports)

                    if let lastReportPublishedAt = viewModel.lastReportPublishedAt {
                        LabeledContent("Last Stored", value: lastReportPublishedAt.formatted(date: .abbreviated, time: .shortened))
                    }
                }

                if !viewModel.storedReports.isEmpty {
                    Section("Stored Reports") {
                        ForEach(viewModel.storedReports.prefix(6)) { report in
                            VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                                Text(report.title)
                                    .font(.system(.body, design: .rounded).bold())
                                    .foregroundStyle(LMSColors.textPrimary)
                                Text(report.generatedAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(LMSColors.textSecondary)
                                HStack {
                                    Link("Open PDF", destination: report.pdfURL)
                                    Spacer()
                                    Link("Open CSV", destination: report.csvURL)
                                }
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                            }
                            .padding(.vertical, LMSSpacing.xs)
                        }
                    }
                }

                Section {
                    Button(action: {
                        HapticsManager.triggerImpact(style: .medium)
                        shareItems = [snapshot.plainTextReport(branchName: viewModel.branchOverview.name, region: viewModel.branchOverview.region)]
                        showShareSheet = true
                    }) {
                        Text("Share Report Summary")
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundStyle(LMSColors.actionBlue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }

                    Button(action: exportPDF) {
                        Text("Export as PDF")
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundStyle(LMSColors.brandNavy)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }

                    Button(action: exportCSV) {
                        Text("Export as CSV")
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundStyle(LMSColors.emerald)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Branch Loan Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(activityItems: shareItems)
            }
            .alert("Export Failed", isPresented: Binding(
                get: { exportError != nil },
                set: { if !$0 { exportError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(exportError ?? "")
            }
        }
    }

    private func storeSelectedReport() {
        Task {
            await viewModel.generateAndStoreReportNow(frequency: selectedFrequency)
        }
    }

    private func exportPDF() {
        do {
            let url = try ManagerReportGenerationService.shared.localPDFURL(
                frequency: selectedFrequency,
                branchOverview: viewModel.branchOverview,
                applicants: viewModel.applicants,
                officers: viewModel.officers
            )
            HapticsManager.triggerImpact(style: .medium)
            shareItems = [url]
            showShareSheet = true
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func exportCSV() {
        do {
            let url = try CSVExportService.managerReportURL(
                branchName: viewModel.branchOverview.name,
                applicants: viewModel.applicants,
                officers: viewModel.officers
            )
            HapticsManager.triggerImpact(style: .medium)
            shareItems = [url]
            showShareSheet = true
        } catch {
            exportError = error.localizedDescription
        }
    }
}

struct BranchLoanReportSnapshot {
    let applicants: [ManagerApplicant]
    let officers: [ManagerOfficer]

    var totalApplications: Int { applicants.count }

    var disbursedApplications: [ManagerApplicant] {
        applicants.filter { $0.status == .approved || $0.status == .disbursed }
    }

    var disbursedCount: Int { disbursedApplications.count }

    var totalDisbursed: Double {
        disbursedApplications.reduce(0) { $0 + $1.requestedAmount }
    }

    var totalRecovered: Double {
        disbursedApplications.reduce(0) { $0 + Self.estimatedRecoveredAmount(for: $1) }
    }

    var loanTypeRows: [LoanTypeReportRow] {
        ManagerLoanType.allCases.compactMap { loanType in
            let typeApps = applicants.filter { $0.loanType == loanType }
            guard !typeApps.isEmpty else { return nil }
            return LoanTypeReportRow(loanType: loanType, applications: typeApps)
        }
        .sorted { $0.disbursedAmount > $1.disbursedAmount }
    }

    var officerRows: [OfficerLoanReportRow] {
        officers.compactMap { officer in
            let officerApps = applicants.filter { $0.assignedOfficerId == officer.id || $0.assignedOfficer.localizedCaseInsensitiveContains(officer.name) }
            guard !officerApps.isEmpty else { return nil }
            return OfficerLoanReportRow(officer: officer, applications: officerApps)
        }
        .sorted { $0.disbursedAmount > $1.disbursedAmount }
    }

    func plainTextReport(branchName: String, region: String) -> String {
        var lines: [String] = [
            "Branch Loan Report",
            "Branch: \(branchName)",
            "Region: \(region)",
            "Applications: \(totalApplications)",
            "Approved/Disbursed: \(disbursedCount)",
            "Disbursed: \(CurrencyFormatter.shared.format(totalDisbursed))",
            "Recovered Estimate: \(CurrencyFormatter.shared.format(totalRecovered))",
            "",
            "Officer-wise Loan Report"
        ]

        lines += officerRows.map { row in
            "\(row.officer.name): \(row.disbursedCount) loans, \(CurrencyFormatter.shared.format(row.disbursedAmount)) disbursed, \(CurrencyFormatter.shared.format(row.recoveredAmount)) recovered, \(row.primaryLoanTypeText)"
        }

        lines.append("")
        lines.append("Loan Type Mix")
        lines += loanTypeRows.map { row in
            "\(row.loanType.rawValue): \(row.applicationCount) applications, \(CurrencyFormatter.shared.format(row.disbursedAmount)) disbursed, \(CurrencyFormatter.shared.format(row.recoveredAmount)) recovered"
        }

        return lines.joined(separator: "\n")
    }

    static func estimatedRecoveredAmount(for applicant: ManagerApplicant) -> Double {
        guard applicant.status == .approved || applicant.status == .disbursed else { return 0 }
        let monthsSinceSubmission = max(1, Calendar.current.dateComponents([.month], from: applicant.submissionDate, to: Date()).month ?? 1)
        let paidMonths = min(max(applicant.tenure, 1), monthsSinceSubmission)
        let monthlyRate = applicant.interestRate / 1200
        let emi: Double

        if monthlyRate == 0 {
            emi = applicant.requestedAmount / Double(max(applicant.tenure, 1))
        } else {
            let factor = pow(1 + monthlyRate, Double(max(applicant.tenure, 1)))
            emi = applicant.requestedAmount * monthlyRate * factor / (factor - 1)
        }

        return min(applicant.requestedAmount, emi * Double(paidMonths))
    }
}

struct LoanTypeReportRow: Identifiable {
    let id: ManagerLoanType
    let loanType: ManagerLoanType
    let applicationCount: Int
    let disbursedCount: Int
    let disbursedAmount: Double
    let recoveredAmount: Double

    init(loanType: ManagerLoanType, applications: [ManagerApplicant]) {
        self.id = loanType
        self.loanType = loanType
        self.applicationCount = applications.count
        let disbursed = applications.filter { $0.status == .approved || $0.status == .disbursed }
        self.disbursedCount = disbursed.count
        self.disbursedAmount = disbursed.reduce(0) { $0 + $1.requestedAmount }
        self.recoveredAmount = disbursed.reduce(0) { $0 + BranchLoanReportSnapshot.estimatedRecoveredAmount(for: $1) }
    }
}

struct OfficerLoanReportRow: Identifiable {
    let id: UUID
    let officer: ManagerOfficer
    let applicationCount: Int
    let disbursedCount: Int
    let disbursedAmount: Double
    let recoveredAmount: Double
    let loanTypeRows: [LoanTypeReportRow]

    var primaryLoanTypeText: String {
        guard let topType = loanTypeRows.first else { return "No approved loans yet" }
        return "Primary type: \(topType.loanType.rawValue)"
    }

    init(officer: ManagerOfficer, applications: [ManagerApplicant]) {
        self.id = officer.id
        self.officer = officer
        self.applicationCount = applications.count
        let disbursed = applications.filter { $0.status == .approved || $0.status == .disbursed }
        self.disbursedCount = disbursed.count
        self.disbursedAmount = disbursed.reduce(0) { $0 + $1.requestedAmount }
        self.recoveredAmount = disbursed.reduce(0) { $0 + BranchLoanReportSnapshot.estimatedRecoveredAmount(for: $1) }
        self.loanTypeRows = ManagerLoanType.allCases.compactMap { loanType in
            let typeApps = applications.filter { $0.loanType == loanType }
            guard !typeApps.isEmpty else { return nil }
            return LoanTypeReportRow(loanType: loanType, applications: typeApps)
        }
        .sorted { $0.disbursedAmount > $1.disbursedAmount }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]
    var applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}


struct ManagerAuditLogSheet: View {
    @Environment(\.dismiss) var dismiss
    let events: [ManagerAuditEvent]

    var body: some View {
        NavigationStack {
            Group {
                if events.isEmpty {
                    ContentUnavailableView("No audit events", systemImage: "list.bullet.clipboard", description: Text("Manager decisions and document exceptions will appear here."))
                } else {
                    List(events) { event in
                        HStack(alignment: .top, spacing: LMSSpacing.md) {
                            Image(systemName: event.severity.icon)
                                .foregroundStyle(event.severity.color)
                                .font(.system(size: 20))
                                .padding(.top, 2)

                            VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                                Text(event.action)
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                    .foregroundStyle(LMSColors.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)

                                HStack {
                                    Text(event.user)
                                        .font(.system(.subheadline, design: .rounded))
                                        .foregroundStyle(LMSColors.textSecondary)
                                    Spacer()
                                    Text(event.timestamp, style: .relative)
                                        .font(.system(.caption, design: .rounded).bold())
                                        .foregroundStyle(LMSColors.textTertiary)
                                }
                            }
                        }
                        .padding(.vertical, LMSSpacing.xs)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Branch Audit Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ScrollView {
        ManagerReportsView(viewModel: PreviewSupport.managerViewModel)
    }
    .padding()
    .previewManagerEnvironment()
}
