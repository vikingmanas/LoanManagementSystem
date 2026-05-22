import SwiftUI

// MARK: - Manager Reports & AI Insights View
struct ManagerReportsView: View {
    @State private var showExportSheet = false
    @State private var showAuditLog = false
    @State private var isExporting = false

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("Reports & Insights")
                .font(.system(.footnote, design: .rounded).bold())
                .foregroundStyle(LMSColors.textSecondary)
                .padding(.horizontal, LMSSpacing.screenHorizontal)

            VStack(spacing: LMSSpacing.md) {
                // Quick Action Buttons
                HStack(spacing: LMSSpacing.md) {
                    ReportButton(
                        icon: "doc.text.fill",
                        title: "Monthly Report",
                        tint: LMSColors.brandNavy
                    ) {
                        showExportSheet = true
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
                        HapticsManager.triggerImpact(style: .light)
                    }

                    ReportButton(
                        icon: "square.and.arrow.up.fill",
                        title: "Export CSV",
                        tint: LMSColors.actionBlue
                    ) {
                        HapticsManager.triggerImpact(style: .light)
                    }
                }

                // AI Insight Placeholder
                AIInsightCard()
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)
        }
        .sheet(isPresented: $showExportSheet) {
            ManagerReportExportSheet(isExporting: $isExporting)
        }
        .sheet(isPresented: $showAuditLog) {
            ManagerAuditLogSheet()
        }
        .overlay {
            if isExporting {
                ZStack {
                    Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                    VStack(spacing: LMSSpacing.xl) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Generating Report…")
                            .font(.system(.headline, design: .rounded))
                            .foregroundStyle(.white)
                    }
                    .padding(LMSSpacing.xxxl)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: LMSRadius.xl, style: .continuous))
                }
                .transition(.opacity)
            }
        }
    }
}

// MARK: - Report Button
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

// MARK: - AI Insight Card
private struct AIInsightCard: View {
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
                Text("AI Insight")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(Color.purple)

                Text("Your branch approval rate has increased by 2.1% this quarter. Consider redistributing Neha Singh's workload — she's at 93% capacity.")
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

// MARK: - Report Export Sheet
private struct ManagerReportExportSheet: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isExporting: Bool
    @State private var reportType = "Monthly Performance"
    @State private var format = "PDF Document"

    let reportTypes = ["Monthly Performance", "NPL Status", "Disbursement Log", "Supervisor Action Queue"]
    let formats = ["PDF Document", "CSV Spreadsheet"]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Report Details")) {
                    Picker("Report Type", selection: $reportType) {
                        ForEach(reportTypes, id: \.self) { Text($0) }
                    }
                    Picker("Export Format", selection: $format) {
                        ForEach(formats, id: \.self) { Text($0) }
                    }
                }

                Section {
                    Button(action: {
                        HapticsManager.triggerImpact(style: .medium)
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation { isExporting = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation { isExporting = false }
                                HapticsManager.triggerNotification(type: .success)
                            }
                        }
                    }) {
                        Text("Export Now")
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .listRowBackground(LMSColors.brandNavy)
                }
            }
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Audit Log Sheet
private struct ManagerAuditLogSheet: View {
    @Environment(\.dismiss) var dismiss

    private let events: [ManagerAuditEvent] = [
        ManagerAuditEvent(id: UUID(), timestamp: Date().addingTimeInterval(-600), action: "Approved APP-2026-0750 (Rohan Kapoor)", user: "Ramanathan Swamy", severity: .success),
        ManagerAuditEvent(id: UUID(), timestamp: Date().addingTimeInterval(-3600), action: "Branch config updated: Home Loan Limit → ₹5.0 Cr", user: "Ramanathan Swamy", severity: .info),
        ManagerAuditEvent(id: UUID(), timestamp: Date().addingTimeInterval(-7200), action: "Escalated APP-2026-0988 (Vikram Joshi) — Fraud Risk", user: "Priya Menon", severity: .critical),
        ManagerAuditEvent(id: UUID(), timestamp: Date().addingTimeInterval(-14400), action: "Requested clarification on APP-2026-0801", user: "Rohan Gupta", severity: .warning),
        ManagerAuditEvent(id: UUID(), timestamp: Date().addingTimeInterval(-86400), action: "Generated Monthly Performance PDF Report", user: "Ramanathan Swamy", severity: .info),
        ManagerAuditEvent(id: UUID(), timestamp: Date().addingTimeInterval(-90000), action: "Disbursed APP-2026-0944 (Kavitha Nair)", user: "Rohan Gupta", severity: .success)
    ]

    var body: some View {
        NavigationStack {
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
