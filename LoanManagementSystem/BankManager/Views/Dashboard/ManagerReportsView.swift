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

                ScrollView(.horizontal, showsIndicators: false) {
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

                        ReportButton(
                            icon: "paperplane.fill",
                            title: "Publish",
                            tint: LMSColors.actionBlue
                        ) {
                            viewModel.publishMonthlyReport()
                        }
                    }
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                }

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
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticsManager.triggerImpact(style: .medium)
            action()
        }) {
            HStack(spacing: LMSSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                Text(title)
                    .font(.system(.body, design: .rounded).weight(.semibold))
            }
            .foregroundStyle(tint)
            .padding(.horizontal, LMSSpacing.lg)
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
