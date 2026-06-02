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
                    if let errorMessage = viewModel.errorMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(LMSColors.coral)
                                Text("Failed to Load Dashboard Data")
                                    .font(LMSFont.subheadline.weight(.semibold))
                                    .foregroundStyle(LMSColors.textPrimary)
                            }
                            Text(errorMessage)
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                                .lineLimit(3)
                            
                            Button {
                                Task {
                                    await viewModel.loadDashboardData()
                                }
                            } label: {
                                Text("Retry")
                                    .font(LMSFont.caption.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(LMSColors.brandNavy, in: Capsule())
                                    .foregroundStyle(.white)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
                        .overlay(
                            RoundedRectangle(cornerRadius: LMSRadius.lg)
                                .stroke(LMSColors.coral.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    kpiSection
                    auditPreviewSection
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)
                .padding(.vertical, LMSSpacing.md)
            }
            .background(LMSColors.background.ignoresSafeArea())
            .navigationTitle("Dashboard")
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
    

    
    private var kpiSection: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(viewModel.kpis) { kpi in
                NavigationLink {
                    AdminBranchKPIView(kpi: kpi, viewModel: viewModel)
                } label: {
                    HStack(alignment: .center, spacing: 10) {
                        Image(systemName: kpi.icon)
                            .font(.title3)
                            .foregroundStyle(kpi.themeColor)
                            .frame(width: 28, height: 28)

                        VStack(alignment: .leading, spacing: 1) {
                            Text(kpi.value)
                                .font(LMSFont.headline)
                                .foregroundStyle(LMSColors.textPrimary)
                                .minimumScaleFactor(0.7)
                                .lineLimit(1)
                            Text(kpi.title)
                                .font(LMSFont.caption2)
                                .foregroundStyle(LMSColors.textSecondary)
                                .lineLimit(2)
                        }

                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.md))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
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
                    let visibleLogs = viewModel.recentAuditLogs.filter { $0.type != .systemAction }
                    ForEach(visibleLogs) { log in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(log.displayColor.opacity(0.1))
                                
                                Image(systemName: log.displayIcon)
                                    .font(.title3)
                                    .foregroundStyle(log.displayColor)
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
                        
                        if log.id != visibleLogs.last?.id {
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
