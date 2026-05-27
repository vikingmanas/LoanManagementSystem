import SwiftUI


struct ManagerReportsView: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @State private var showReportSheet = false
    @State private var showAuditLog = false
    @State private var showPerformanceSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("Reports & Insights")
                .font(.system(.footnote, design: .rounded).bold())
                .foregroundStyle(LMSColors.textSecondary)
                .padding(.horizontal, LMSSpacing.screenHorizontal)

            VStack(spacing: LMSSpacing.md) {

                HStack(spacing: LMSSpacing.md) {
                    ReportButton(
                        icon: "doc.text.fill",
                        title: "Monthly Report",
                        tint: LMSColors.brandNavy
                    ) {
                        showReportSheet = true
                    }

                    ReportButton(
                        icon: "list.bullet.clipboard.fill",
                        title: "Audit Logs",
                        tint: LMSColors.teal
                    ) {
                        showAuditLog = true
                    }
                }

                HStack(spacing: LMSSpacing.md) {
                    ReportButton(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Performance",
                        tint: LMSColors.emerald
                    ) {
                        showPerformanceSheet = true
                    }

                    ReportButton(
                        icon: "paperplane.fill",
                        title: "Publish",
                        tint: LMSColors.actionBlue
                    ) {
                        viewModel.publishMonthlyReport()
                    }
                }


                ManagerInsightCard(viewModel: viewModel)
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)
        }
        .sheet(isPresented: $showReportSheet) {
            ManagerReportSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showAuditLog) {
            ManagerAuditLogSheet(events: viewModel.auditEvents)
        }
        .sheet(isPresented: $showPerformanceSheet) {
            OfficerPerformanceReportSheet(viewModel: viewModel)
        }
    }
}


private struct ReportButton: View {
    let icon: String
    let title: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticsManager.triggerImpact(style: .medium)
            action()
        }) {
            HStack(spacing: LMSSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, LMSSpacing.md)
            .background(tint.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
        }
        .buttonStyle(LMSPressableStyle())
    }
}


private struct ManagerInsightCard: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel

    private var insightText: String {
        if let highRisk = viewModel.applicants.first(where: { $0.riskLevel == .high || $0.riskLevel == .critical }) {
            return "\(highRisk.applicationId) needs closer risk review before branch clearance."
        }
        if viewModel.pendingApplicants.isEmpty {
            return "Approval queue is clear for \(viewModel.branchOverview.name)."
        }
        return "\(viewModel.pendingApplicants.count) application\(viewModel.pendingApplicants.count == 1 ? "" : "s") awaiting manager decision."
    }

    var body: some View {
        HStack(alignment: .top, spacing: LMSSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.15), LMSColors.actionBlue.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Color.purple)
            }

            VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                Text("Branch Insight")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(Color.purple)

                Text(insightText)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(LMSSpacing.lg)
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


private struct ManagerReportSheet: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Branch") {
                    LabeledContent("Name", value: viewModel.branchOverview.name)
                    LabeledContent("Region", value: viewModel.branchOverview.region)
                    LabeledContent("Active Loans", value: "\(viewModel.branchOverview.activeLoanCount)")
                    LabeledContent("Disbursed", value: CurrencyFormatter.shared.format(viewModel.branchOverview.totalDisbursed))
                }

                Section("Performance") {
                    LabeledContent("Pending Approvals", value: "\(viewModel.pendingApplicants.count)")
                    LabeledContent("Approved/Disbursed", value: "\(viewModel.applicants.filter { $0.status == .approved || $0.status == .disbursed }.count)")
                    LabeledContent("Rejected", value: "\(viewModel.applicants.filter { $0.status == .rejected }.count)")
                    LabeledContent("Officers Tracked", value: "\(viewModel.officers.count)")
                }

                if let lastReportPublishedAt = viewModel.lastReportPublishedAt {
                    Section("Published") {
                        LabeledContent("Last Published", value: lastReportPublishedAt.formatted(date: .abbreviated, time: .shortened))
                    }
                }

                Section {
                    Button(action: {
                        HapticsManager.triggerImpact(style: .medium)
                        viewModel.publishMonthlyReport()
                        dismiss()
                    }) {
                        Text("Publish Monthly Report")
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .listRowBackground(LMSColors.brandNavy)
                }
            }
            .navigationTitle("Monthly Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}


private struct ManagerAuditLogSheet: View {
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
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(LMSColors.textSecondary)
                                    Spacer()
                                    Text(event.timestamp, style: .relative)
                                        .font(.system(.caption2, design: .rounded).bold())
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

struct OfficerPerformanceReportSheet: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @Environment(\.dismiss) var dismiss

    private var totalProcessed: Int {
        viewModel.officers.reduce(0) { $0 + $1.loansProcessedYTD }
    }

    private var avgApprovalRate: Double {
        let rates = viewModel.officers.map(\.approvalRate)
        return rates.isEmpty ? 0 : rates.reduce(0, +) / Double(rates.count)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.officers.isEmpty {
                    ContentUnavailableView(
                        "No Officers Tracked",
                        systemImage: "person.2.slash",
                        description: Text("Officer performance data will appear once staff are assigned to this branch.")
                    )
                } else {
                    List {
                        Section("Branch Summary") {
                            LabeledContent("Officers Tracked", value: "\(viewModel.officers.count)")
                            LabeledContent("Total Loans Processed (YTD)", value: "\(totalProcessed)")
                            LabeledContent("Avg. Approval Rate", value: String(format: "%.1f%%", avgApprovalRate))
                        }

                        Section("Individual Performance") {
                            ForEach(viewModel.officers.sorted(by: { $0.approvalRate > $1.approvalRate })) { officer in
                                VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                                    HStack {
                                        ZStack {
                                            Circle()
                                                .fill(LMSColors.brandNavy.opacity(0.10))
                                                .frame(width: 36, height: 36)
                                            Text(officer.initials)
                                                .font(.system(.caption2, design: .rounded).bold())
                                                .foregroundStyle(LMSColors.brandNavy)
                                        }

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(officer.name)
                                                .font(.system(.callout, design: .rounded).bold())
                                                .foregroundStyle(LMSColors.textPrimary)
                                            Text(officer.role)
                                                .font(.system(.caption2, design: .rounded))
                                                .foregroundStyle(LMSColors.textSecondary)
                                        }

                                        Spacer()

                                        HStack(spacing: 3) {
                                            Image(systemName: "star.fill")
                                                .foregroundStyle(LMSColors.amber)
                                                .font(.system(size: 10))
                                            Text(String(format: "%.1f", officer.rating))
                                                .font(.system(.caption, design: .rounded).bold())
                                                .foregroundStyle(LMSColors.textPrimary)
                                        }
                                    }

                                    HStack(spacing: LMSSpacing.lg) {
                                        PerformanceMetric(label: "Processed", value: "\(officer.loansProcessedYTD)")
                                        PerformanceMetric(label: "Approval", value: String(format: "%.1f%%", officer.approvalRate))
                                        PerformanceMetric(label: "Capacity", value: "\(officer.activeCases)/\(officer.maxCapacity)")
                                    }

                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(officer.capacityColor.opacity(0.15))
                                                .frame(height: 5)
                                            Capsule()
                                                .fill(officer.capacityColor)
                                                .frame(width: geo.size.width * officer.capacityPercentage, height: 5)
                                        }
                                    }
                                    .frame(height: 5)
                                }
                                .padding(.vertical, LMSSpacing.xs)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Officer Performance")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

private struct PerformanceMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.caption, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
                .monospacedDigit()
            Text(label)
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundStyle(LMSColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ScrollView {
        ManagerReportsView(viewModel: PreviewSupport.managerViewModel)
    }
    .padding()
    .previewManagerEnvironment()
}
