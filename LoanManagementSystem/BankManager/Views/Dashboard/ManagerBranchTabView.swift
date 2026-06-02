import SwiftUI
import Charts

struct ManagerBranchTabView: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @State private var showBranchOverview = false
    @State private var showOfficerPerformance = false
    @State private var showReportSheet = false
    @State private var showAuditLog = false

    private var snapshot: BranchLoanReportSnapshot {
        BranchLoanReportSnapshot(applicants: viewModel.applicants, officers: viewModel.officers)
    }

    private var loanTypeChartData: [BranchChartSlice] {
        snapshot.loanTypeRows.map {
            BranchChartSlice(
                id: $0.loanType.rawValue,
                label: $0.loanType.rawValue,
                value: $0.disbursedAmount,
                color: $0.loanType.themeColor
            )
        }
        .filter { $0.value > 0 }
    }

    private var officerChartData: [BranchOfficerChartItem] {
        snapshot.officerRows.map {
            BranchOfficerChartItem(
                id: $0.officer.id,
                name: $0.officer.name,
                amount: $0.disbursedAmount
            )
        }
        .filter { $0.amount > 0 }
    }

    private var statusChartData: [BranchChartSlice] {
        let approved = viewModel.applicants.filter { $0.status == .approved || $0.status == .disbursed }.count
        let pending = viewModel.pendingApplicants.count
        let rejected = viewModel.applicants.filter { $0.status == .rejected }.count
        let escalated = viewModel.officerEscalatedApplicants.count

        return [
            BranchChartSlice(id: "approved", label: "Approved", value: Double(approved), color: LMSColors.emerald),
            BranchChartSlice(id: "pending", label: "Pending", value: Double(pending), color: LMSColors.amber),
            BranchChartSlice(id: "rejected", label: "Rejected", value: Double(rejected), color: LMSColors.coral),
            BranchChartSlice(id: "escalated", label: "Escalated", value: Double(escalated), color: Color.purple)
        ]
        .filter { $0.value > 0 }
    }

    var body: some View {
        List {
            Section {
                branchHeaderCard
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            Section("Branch Metrics") {
                metricRow(
                    title: "Total Disbursed",
                    value: CurrencyFormatter.shared.format(viewModel.branchOverview.totalDisbursed),
                    icon: "indianrupeesign.circle.fill",
                    tint: LMSColors.brandNavy
                )
                metricRow(
                    title: "Estimated Recovered",
                    value: CurrencyFormatter.shared.format(viewModel.branchOverview.totalRecovered),
                    icon: "arrow.down.circle.fill",
                    tint: LMSColors.emerald
                )
                metricRow(
                    title: "Active Loans",
                    value: "\(viewModel.branchOverview.activeLoanCount)",
                    icon: "doc.text.fill",
                    tint: LMSColors.actionBlue
                )
                metricRow(
                    title: "Non-Performing Loan Rate",
                    value: String(format: "%.2f%%", viewModel.branchOverview.nplRate),
                    icon: "exclamationmark.triangle.fill",
                    tint: viewModel.branchOverview.nplRate < 1 ? LMSColors.emerald : LMSColors.coral
                )
            }

            if !statusChartData.isEmpty {
                Section("Application Status") {
                    Chart(statusChartData) { item in
                        BarMark(
                            x: .value("Status", item.label),
                            y: .value("Count", item.value)
                        )
                        .foregroundStyle(item.color.gradient)
                        .cornerRadius(6)
                    }
                    .frame(height: 200)
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }

                    ForEach(statusChartData) { item in
                        LabeledContent(item.label, value: "\(Int(item.value))")
                    }
                }
            }

            if !loanTypeChartData.isEmpty {
                Section("Loans by Product") {
                    Chart(loanTypeChartData) { item in
                        SectorMark(
                            angle: .value("Amount", item.value),
                            innerRadius: .ratio(0.58),
                            angularInset: 1.5
                        )
                        .foregroundStyle(item.color)
                    }
                    .frame(height: 220)

                    ForEach(loanTypeChartData) { item in
                        HStack {
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)
                            Text(item.label)
                            Spacer()
                            Text(CurrencyFormatter.shared.format(item.value))
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                        .font(.subheadline)
                    }
                }
            }

            if !officerChartData.isEmpty {
                Section("Disbursal by Loan Officer") {
                    Chart(officerChartData) { item in
                        BarMark(
                            x: .value("Amount", item.amount),
                            y: .value("Officer", item.name)
                        )
                        .foregroundStyle(LMSColors.brandNavy.gradient)
                        .cornerRadius(6)
                    }
                    .frame(height: max(180, CGFloat(officerChartData.count) * 44))
                    .chartXAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            if let amount = value.as(Double.self) {
                                AxisValueLabel(amount.formattedAsCompactINR())
                            }
                        }
                    }
                }
            }

            Section {
                Button {
                    HapticsManager.triggerImpact(style: .medium)
                    showOfficerPerformance = true
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Loan Officer Performance")
                                .font(.body.weight(.semibold))
                            Text("Escalations, ratings, and officer-wise loan book")
                                .font(.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                    } icon: {
                        Image(systemName: "person.3.fill")
                            .foregroundStyle(LMSColors.brandNavy)
                    }
                }

                if viewModel.officers.isEmpty {
                    Text("Loan officers will appear once staff or applications are assigned to this branch.")
                        .font(.footnote)
                        .foregroundStyle(LMSColors.textSecondary)
                } else {
                    ForEach(viewModel.officerPerformanceSummaries.prefix(5)) { summary in
                        let assignedCount = viewModel.applicants(for: summary.officer).count
                        let disbursedAmount = snapshot.officerRows.first(where: { $0.officer.id == summary.officer.id })?.disbursedAmount ?? 0
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(summary.officer.name)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill")
                                        .font(.caption2)
                                        .foregroundStyle(LMSColors.amber)
                                    Text(String(format: "%.1f", summary.displayRating))
                                        .font(.caption.weight(.bold))
                                }
                            }
                            HStack {
                                Text("\(assignedCount) assigned")
                                Text("·")
                                Text("\(summary.officerEscalationCount) escalated")
                                Text("·")
                                Text(CurrencyFormatter.shared.format(disbursedAmount))
                            }
                            .font(.caption)
                            .foregroundStyle(LMSColors.textSecondary)
                        }
                        .padding(.vertical, 2)
                    }

                    if !viewModel.unassignedApplicants.isEmpty {
                        LabeledContent("Unassigned Loans", value: "\(viewModel.unassignedApplicants.count)")
                    }
                }
            } header: {
                Text("Team")
            }

            Section("Reports") {
                Button {
                    HapticsManager.triggerImpact(style: .medium)
                    showReportSheet = true
                } label: {
                    Label("Branch Loan Report", systemImage: "chart.bar.doc.horizontal.fill")
                }

                Button {
                    HapticsManager.triggerImpact(style: .light)
                    showAuditLog = true
                } label: {
                    Label("Audit Logs", systemImage: "list.bullet.clipboard.fill")
                }

                if let lastReportPublishedAt = viewModel.lastReportPublishedAt {
                    LabeledContent("Last Stored Report", value: lastReportPublishedAt.formatted(date: .abbreviated, time: .shortened))
                }

                if !viewModel.storedReports.isEmpty {
                    ForEach(viewModel.storedReports.prefix(4)) { report in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(report.title)
                                .font(.subheadline.weight(.semibold))
                            Text(report.generatedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                            HStack {
                                Link("PDF", destination: report.pdfURL)
                                Spacer()
                                Link("CSV", destination: report.csvURL)
                            }
                            .font(.caption.weight(.semibold))
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Branch")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Details") {
                    showBranchOverview = true
                }
                .font(.subheadline.weight(.semibold))
            }
        }
        .refreshable {
            await viewModel.refreshData()
        }
        .sheet(isPresented: $showBranchOverview) {
            BranchOverviewDetailSheet(overview: viewModel.branchOverview)
        }
        .sheet(isPresented: $showOfficerPerformance) {
            OfficerPerformanceReportSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showReportSheet) {
            ManagerReportSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showAuditLog) {
            ManagerAuditLogSheet(events: viewModel.auditEvents)
        }
    }

    private var branchHeaderCard: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.branchOverview.name)
                        .font(.title2.weight(.bold))
                    Text("\(viewModel.branchOverview.code) · \(viewModel.branchOverview.region)")
                        .font(.subheadline)
                        .foregroundStyle(LMSColors.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(viewModel.branchOverview.auditRating)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(LMSColors.emerald)
                    Text("Audit")
                        .font(.caption2)
                        .foregroundStyle(LMSColors.textTertiary)
                }
            }

            HStack(spacing: LMSSpacing.sm) {
                headerStat(title: "Officers", value: "\(viewModel.officers.count)")
                headerStat(title: "Applications", value: "\(viewModel.applicants.count)")
                headerStat(
                    title: "Disbursed",
                    value: viewModel.branchOverview.totalDisbursed.formattedAsCompactINR()
                )
            }
        }
        .padding(LMSSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LMSColors.surfaceElevated, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .padding(.horizontal, LMSSpacing.screenHorizontal)
        .padding(.vertical, LMSSpacing.sm)
    }

    private func headerStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(LMSColors.textTertiary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(LMSColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LMSSpacing.sm)
        .background(LMSColors.background, in: RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous))
    }

    private func metricRow(title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: LMSSpacing.md) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 28)
            Text(title)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(LMSColors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}

private struct BranchChartSlice: Identifiable {
    let id: String
    let label: String
    let value: Double
    let color: Color
}

private struct BranchOfficerChartItem: Identifiable {
    let id: UUID
    let name: String
    let amount: Double
}

#Preview {
    NavigationStack {
        ManagerBranchTabView(viewModel: PreviewSupport.managerViewModel)
    }
}
