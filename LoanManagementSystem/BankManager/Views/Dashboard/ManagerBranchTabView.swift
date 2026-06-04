import SwiftUI
import Charts

struct ManagerBranchTabView: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @State private var showBranchOverview = false
    @State private var showOfficerPerformance = false
    @State private var showReportSheet = false
    @State private var showAuditLog = false
    @State private var selectedAnalyticsTab: AnalyticsTab = .overview

    enum AnalyticsTab: String, CaseIterable, Identifiable {
        case overview = "Status"
        case products = "Products"
        var id: String { rawValue }
    }

    private var snapshot: BranchLoanReportSnapshot {
        BranchLoanReportSnapshot(applicants: viewModel.applicants, officers: viewModel.officers)
    }

    var body: some View {
        List {
            Section {
                branchHeaderCard
            }

            // MARK: - Consolidated Analytics Card
            Section {
                VStack(spacing: LMSSpacing.lg) {
                    Picker("Analytics View", selection: $selectedAnalyticsTab) {
                        ForEach(AnalyticsTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, LMSSpacing.sm)

                    unifiedChartView
                        .frame(height: 260)
                        .padding(.vertical, LMSSpacing.xs)
                    
                    analyticsLegend
                }
                .padding(.vertical, LMSSpacing.md)
            } header: {
                Text("Branch Performance")
            }

            Section("Key Performance Indicators") {
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
                    title: "NPL Rate",
                    value: String(format: "%.2f%%", viewModel.branchOverview.nplRate),
                    icon: "exclamationmark.triangle.fill",
                    tint: viewModel.branchOverview.nplRate < 1 ? LMSColors.emerald : LMSColors.coral
                )
            }

            Section("Team Performance") {
                Button {
                    HapticsManager.triggerImpact(style: .medium)
                    showOfficerPerformance = true
                } label: {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Detailed Officer Report")
                                .font(LMSFont.body.weight(.semibold))
                            Text("Manager reviews and historical ratings")
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                    } icon: {
                        Image(systemName: "person.3.fill")
                            .foregroundStyle(LMSColors.brandNavy)
                    }
                }

                if viewModel.officers.isEmpty {
                    Text("No loan officers assigned to this branch yet.")
                        .font(LMSFont.footnote)
                        .foregroundStyle(LMSColors.textSecondary)
                } else {
                    ForEach(viewModel.officerPerformanceSummaries.prefix(3)) { summary in
                        OfficerMiniRow(summary: summary, viewModel: viewModel, snapshot: snapshot)
                    }
                    
                    if viewModel.officerPerformanceSummaries.count > 3 {
                        NavigationLink {
                            OfficerPerformanceReportSheet(viewModel: viewModel)
                        } label: {
                            Text("View All \(viewModel.officers.count) Officers")
                                .font(LMSFont.footnote.weight(.semibold))
                                .foregroundStyle(LMSColors.brandNavy)
                        }
                    }
                }
            }

            Section("Operations & Reports") {
                Button {
                    HapticsManager.triggerImpact(style: .medium)
                    showReportSheet = true
                } label: {
                    Label("Generate Branch Report", systemImage: "chart.bar.doc.horizontal.fill")
                }

                Button {
                    HapticsManager.triggerImpact(style: .light)
                    showAuditLog = true
                } label: {
                    Label("Branch Audit Trail", systemImage: "list.bullet.clipboard.fill")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Branch")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Details") { showBranchOverview = true }
                    .font(LMSFont.subheadline.weight(.semibold))
            }
        }
        .refreshable { await viewModel.refreshData() }
        .sheet(isPresented: $showBranchOverview) { BranchOverviewDetailSheet(overview: viewModel.branchOverview) }
        .sheet(isPresented: $showOfficerPerformance) { OfficerPerformanceReportSheet(viewModel: viewModel) }
        .sheet(isPresented: $showReportSheet) { ManagerReportSheet(viewModel: viewModel) }
        .sheet(isPresented: $showAuditLog) { ManagerAuditLogSheet(events: viewModel.auditEvents) }
    }

    // MARK: - Chart Logic

    @ViewBuilder
    private var unifiedChartView: some View {
        switch selectedAnalyticsTab {
        case .overview:
            if statusChartData.isEmpty {
                emptyChartView(title: "No Status Data", message: "There are no applications to display status for.")
            } else {
                Chart(statusChartData) { item in
                    SectorMark(
                        angle: .value("Count", item.value),
                        innerRadius: .ratio(0.65),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color.gradient)
                    .cornerRadius(4)
                }
                .chartBackground { _ in
                    VStack(spacing: 2) {
                        Text("Total")
                            .font(LMSFont.caption2)
                            .foregroundStyle(LMSColors.textTertiary)
                        Text("\(Int(statusChartData.reduce(0) { $0 + $1.value }))")
                            .font(LMSFont.subheadline.bold())
                            .foregroundStyle(LMSColors.textPrimary)
                    }
                }
            }

        case .products:
            if loanTypeChartData.isEmpty {
                emptyChartView(title: "No Product Data", message: "There are no disbursed loans to display products for.")
            } else {
                Chart(loanTypeChartData) { item in
                    SectorMark(
                        angle: .value("Amount", item.value),
                        innerRadius: .ratio(0.65),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color.gradient)
                    .cornerRadius(4)
                }
                .chartBackground { _ in
                    VStack(spacing: 2) {
                        Text("Total")
                            .font(LMSFont.caption2)
                            .foregroundStyle(LMSColors.textTertiary)
                        Text(loanTypeChartData.reduce(0) { $0 + $1.value }.formattedAsCompactINR())
                            .font(LMSFont.subheadline.bold())
                            .foregroundStyle(LMSColors.textPrimary)
                    }
                }
            }
        }
    }

    private func emptyChartView(title: String, message: String) -> some View {
        VStack(spacing: LMSSpacing.sm) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 32))
                .foregroundStyle(LMSColors.textTertiary.opacity(0.5))
            Text(title)
                .font(LMSFont.subheadline.bold())
                .foregroundStyle(LMSColors.textSecondary)
            Text(message)
                .font(LMSFont.caption)
                .foregroundStyle(LMSColors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private var analyticsLegend: some View {
        switch selectedAnalyticsTab {
        case .overview:
            if !statusChartData.isEmpty {
                HStack(spacing: LMSSpacing.md) {
                    ForEach(statusChartData) { item in
                        LegendItem(color: item.color, label: item.label)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        case .products:
            if !loanTypeChartData.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: LMSSpacing.lg) {
                        ForEach(loanTypeChartData) { item in
                            LegendItem(color: item.color, label: item.label)
                        }
                    }
                    .padding(.horizontal, LMSSpacing.sm)
                }
            }
        }
    }

    // MARK: - Header & Components

    private var branchHeaderCard: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.branchOverview.name)
                        .font(LMSFont.title)
                    Text("\(viewModel.branchOverview.code) · \(viewModel.branchOverview.region)")
                        .font(LMSFont.subheadline)
                        .foregroundStyle(LMSColors.textSecondary)
                }
                Spacer()
                Text(viewModel.branchOverview.auditRating)
                    .font(LMSFont.caption.weight(.bold))
                    .foregroundStyle(LMSColors.emerald)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(LMSColors.emerald.opacity(0.12), in: Capsule())
            }

            HStack(spacing: LMSSpacing.sm) {
                headerStat(title: "Officers", value: "\(viewModel.officers.count)")
                headerStat(title: "Apps", value: "\(viewModel.applicants.count)")
                headerStat(title: "Volume", value: viewModel.branchOverview.totalDisbursed.formattedAsCompactINR())
            }
        }
        .padding(.vertical, LMSSpacing.sm)
    }

    private func headerStat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(LMSFont.caption2.weight(.medium))
                .foregroundStyle(LMSColors.textTertiary)
            Text(value)
                .font(LMSFont.subheadline.bold())
                .foregroundStyle(LMSColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LMSSpacing.sm)
        .background(LMSColors.background.opacity(0.5), in: RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous))
    }

    private func metricRow(title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: LMSSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(tint.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(tint)
            }
            Text(title)
                .font(LMSFont.body)
            Spacer()
            Text(value)
                .font(LMSFont.subheadline.bold())
                .foregroundStyle(LMSColors.textPrimary)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Data Preparation

    private var loanTypeChartData: [BranchChartSlice] {
        snapshot.loanTypeRows.map {
            BranchChartSlice(id: $0.loanType.rawValue, label: $0.loanType.rawValue, value: $0.disbursedAmount, color: $0.loanType.themeColor)
        }
        .filter { $0.value > 0 }
        .sorted { $0.value > $1.value }
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
}

// MARK: - Supporting Views

private struct OfficerMiniRow: View {
    let summary: ManagerOfficerPerformanceSummary
    let viewModel: ManagerDashboardViewModel
    let snapshot: BranchLoanReportSnapshot

    var body: some View {
        let assignedCount = viewModel.applicants(for: summary.officer).count
        let disbursedAmount = snapshot.officerRows.first { $0.officer.id == summary.officer.id }?.disbursedAmount ?? 0

        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(summary.officer.name)
                    .font(LMSFont.subheadline.bold())
                Spacer()
                RatingLabel(rating: summary.displayRating)
            }
            HStack {
                Label("\(assignedCount) Cases", systemImage: "briefcase")
                Text("·")
                Text(CurrencyFormatter.shared.format(disbursedAmount))
            }
            .font(LMSFont.caption)
            .foregroundStyle(LMSColors.textSecondary)
        }
        .padding(.vertical, 4)
    }
}

private struct RatingLabel: View {
    let rating: Double
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "star.fill")
                .font(.system(size: 8))
            Text(String(format: "%.1f", rating))
                .font(LMSFont.caption.bold())
        }
        .foregroundStyle(LMSColors.amber)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(LMSColors.amber.opacity(0.1), in: Capsule())
    }
}

private struct LegendItem: View {
    let color: Color
    let label: String
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label).font(LMSFont.caption2).foregroundStyle(LMSColors.textSecondary)
        }
    }
}

private struct BranchChartSlice: Identifiable {
    let id: String
    let label: String
    let value: Double
    let color: Color
}
