import SwiftUI

struct AdminDashboardTabView: View {
    @ObservedObject var viewModel: AdminDashboardViewModel
    @Binding var showingProfile: Bool
    
    @EnvironmentObject private var authManager: AuthManager
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: LMSSpacing.sectionGap) {
                    headerSection
                    kpiSection
                    healthSection
                    auditPreviewSection
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)
                .padding(.vertical, LMSSpacing.md)
            }
            .background(LMSColors.background.ignoresSafeArea())
            .navigationTitle("Admin Portal")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingProfile = true
                    } label: {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [LMSColors.brandNavy, LMSColors.brandNavyLight],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text(authManager.userInitials)
                                .font(LMSFont.caption2.weight(.bold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 34, height: 34)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
            }
            .task {
                if viewModel.kpis.isEmpty {
                    await viewModel.loadDashboardData()
                }
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good morning, \(authManager.userDisplayName.split(separator: " ").first ?? "Admin")")
                    .font(LMSFont.title3)
                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(LMSFont.subheadline)
                    .foregroundStyle(LMSColors.textSecondary)
            }
            Spacer()
        }
    }
    
    private var kpiSection: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(viewModel.kpis) { kpi in
                NavigationLink {
                    AdminBranchKPIView(kpi: kpi, viewModel: viewModel)
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            Image(systemName: kpi.icon)
                                .font(.title2)
                                .foregroundStyle(kpi.themeColor)
                            Spacer()
                            HStack(spacing: 2) {
                                Image(systemName: kpi.trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                                Text("\(abs(kpi.trend), specifier: "%.1f")%")
                            }
                            .font(.caption.weight(.bold))
                            .foregroundStyle(kpi.trend >= 0 ? LMSColors.emerald : LMSColors.coral)
                        }
                        
                        Spacer(minLength: 0)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(kpi.value)
                                .font(LMSFont.title)
                                .foregroundStyle(LMSColors.textPrimary)
                                .minimumScaleFactor(0.8)
                                .lineLimit(1)
                            Text(kpi.title)
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, minHeight: 115, alignment: .leading)
                    .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var healthSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("System Health")
                .font(LMSFont.headline)
            
            VStack(spacing: 0) {
                healthMetricRow(title: "Server Uptime", value: "\(viewModel.systemHealth.serverUptime)%", icon: "server.rack")
                Divider().padding(.leading, 48)
                healthMetricRow(title: "Active Sessions", value: "\(viewModel.systemHealth.activeSessions)", icon: "person.3")
                Divider().padding(.leading, 48)
                healthMetricRow(title: "Last Backup", value: viewModel.systemHealth.lastBackupTime.formatted(date: .abbreviated, time: .shortened), icon: "externaldrive.badge.checkmark")
            }
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
        }
    }
    
    private func healthMetricRow(title: String, value: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(LMSColors.actionBlue)
                .frame(width: 24)
            Text(title)
                .font(LMSFont.body)
            Spacer()
            Text(value)
                .font(LMSFont.subheadline.weight(.medium))
                .foregroundStyle(LMSColors.textSecondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var auditPreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Audit Trail")
                    .font(LMSFont.headline)
                Spacer()
                NavigationLink(destination: AdminAuditTrailView()) {
                    Text("View All")
                        .font(LMSFont.subheadline.weight(.semibold))
                        .foregroundStyle(LMSColors.actionBlue)
                }
            }
            
            VStack(spacing: 0) {
                if viewModel.isLoading && viewModel.recentAuditLogs.isEmpty {
                    ProgressView()
                        .padding()
                        .frame(maxWidth: .infinity)
                } else if viewModel.recentAuditLogs.isEmpty {
                    Text("No recent activity.")
                        .font(LMSFont.subheadline)
                        .foregroundStyle(LMSColors.textSecondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                } else {
                    ForEach(viewModel.recentAuditLogs) { log in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(log.type.color.opacity(0.1))
                                
                                Image(systemName: log.type.icon)
                                    .font(.title3)
                                    .foregroundStyle(log.type.color)
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(log.action)
                                    .font(LMSFont.subheadline.weight(.medium))
                                Text("\(log.userName) • \(log.entityId)")
                                    .font(LMSFont.caption)
                                    .foregroundStyle(LMSColors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Text(RelativeDateFormatter.shared.relativeString(from: log.timestamp))
                                .font(LMSFont.caption2)
                                .foregroundStyle(LMSColors.textTertiary)
                        }
                        .padding(.vertical, 12)
                        
                        if log.id != viewModel.recentAuditLogs.last?.id {
                            Divider()
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
        }
    }
}
