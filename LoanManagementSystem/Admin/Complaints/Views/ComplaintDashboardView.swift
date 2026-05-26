import SwiftUI
import Charts

struct ComplaintDashboardView: View {
    @StateObject private var viewModel = ComplaintViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // Critical Alert Banner
                    if viewModel.criticalCount > 0 {
                        HStack(spacing: 12) {
                            Image(systemName: "bolt.trianglebadge.exclamationmark.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.white)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(viewModel.criticalCount) Critical Alert\(viewModel.criticalCount > 1 ? "s" : "")")
                                    .font(LMSFont.subheadline.weight(.bold))
                                    .foregroundStyle(.white)
                                Text("Immediate attention required")
                                    .font(LMSFont.caption)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .padding(16)
                        .background(
                            LinearGradient(colors: [LMSColors.coral, LMSColors.coral.opacity(0.85)], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                        .padding(.horizontal, LMSSpacing.screenHorizontal)
                        .padding(.top, 8)
                    }
                    
                    // KPI Grid — Row 1
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                        kpiCard(title: "Total Tickets", count: viewModel.totalCount, icon: "tray.fill", color: LMSColors.brandNavy)
                        kpiCard(title: "Open", count: viewModel.openCount, icon: "circle", color: LMSColors.amber)
                        kpiCard(title: "Escalated", count: viewModel.escalatedCount, icon: "exclamationmark.triangle.fill", color: LMSColors.coral)
                        kpiCard(title: "Resolved", count: viewModel.resolvedCount, icon: "checkmark.circle.fill", color: LMSColors.emerald)
                    }
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                    .padding(.top, viewModel.criticalCount > 0 ? 0 : 8)
                    
                    // Origin Split Cards
                    HStack(spacing: 16) {
                        originCard(title: "Complaints", count: viewModel.complaintCount, origin: .complaint)
                        originCard(title: "Operational", count: viewModel.operationalCount, origin: .operationalIssue)
                    }
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                    
                    // Resolution Rate
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("System Health")
                                .font(LMSFont.subheadline.weight(.medium))
                                .foregroundStyle(LMSColors.textSecondary)
                            Text("\(Int(viewModel.resolutionRate * 100))%")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(viewModel.resolutionRate >= 0.7 ? LMSColors.emerald : LMSColors.coral)
                            Text("Resolution Rate")
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.textTertiary)
                        }
                        
                        Spacer()
                        
                        ZStack {
                            Circle()
                                .stroke(LMSColors.separatorLight, lineWidth: 8)
                                .frame(width: 64, height: 64)
                            Circle()
                                .trim(from: 0, to: CGFloat(viewModel.resolutionRate))
                                .stroke(
                                    viewModel.resolutionRate >= 0.7 ? LMSColors.emerald : LMSColors.coral,
                                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                )
                                .frame(width: 64, height: 64)
                                .rotationEffect(.degrees(-90))
                                .animation(.easeInOut(duration: 0.8), value: viewModel.resolutionRate)
                        }
                    }
                    .padding(20)
                    .lmsCard()
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                    
                    // Branch Analytics Chart
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Branch Analytics")
                            .font(LMSFont.title3)
                            .foregroundStyle(LMSColors.textPrimary)
                            .padding(.horizontal, LMSSpacing.screenHorizontal)
                        
                        Chart(viewModel.branchAnalytics) { stat in
                            BarMark(x: .value("Branch", stat.branchName), y: .value("Total", stat.total))
                                .foregroundStyle(LMSColors.brandNavy.opacity(0.25))
                                .cornerRadius(4)
                            BarMark(x: .value("Branch", stat.branchName), y: .value("Resolved", stat.resolved))
                                .foregroundStyle(LMSColors.emerald)
                                .cornerRadius(4)
                            BarMark(x: .value("Branch", stat.branchName), y: .value("Escalated", stat.escalated))
                                .foregroundStyle(LMSColors.coral)
                                .cornerRadius(4)
                        }
                        .chartLegend(.hidden)
                        .chartYAxis { AxisMarks(position: .leading) }
                        .frame(height: 220)
                        .padding(16)
                        .lmsCardElevated()
                        .padding(.horizontal, LMSSpacing.screenHorizontal)
                    }
                    
                    // Needs Attention Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Needs Attention")
                                .font(LMSFont.title3)
                                .foregroundStyle(LMSColors.textPrimary)
                            
                            Spacer()
                            
                            NavigationLink(destination: ComplaintListView(viewModel: viewModel)) {
                                HStack(spacing: 4) {
                                    Text("View All")
                                        .font(LMSFont.subheadline.weight(.medium))
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                }
                                .foregroundStyle(LMSColors.brandNavy)
                            }
                        }
                        .padding(.horizontal, LMSSpacing.screenHorizontal)
                        
                        if viewModel.criticalAndEscalated.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(LMSColors.emerald)
                                Text("All caught up!")
                                    .font(LMSFont.headline)
                                    .foregroundStyle(LMSColors.textSecondary)
                                Text("No critical or escalated tickets.")
                                    .font(LMSFont.subheadline)
                                    .foregroundStyle(LMSColors.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .lmsCard()
                            .padding(.horizontal, LMSSpacing.screenHorizontal)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.criticalAndEscalated.prefix(4)) { ticket in
                                    NavigationLink(destination: ComplaintDetailView(viewModel: viewModel, ticketId: ticket.id)) {
                                        ComplaintCard(ticket: ticket)
                                    }
                                    .buttonStyle(LMSPressableStyle())
                                }
                            }
                            .padding(.horizontal, LMSSpacing.screenHorizontal)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .background(LMSColors.background.ignoresSafeArea())
            .navigationTitle("Complaint Management")
        }
    }
    
    // MARK: - Subviews
    private func kpiCard(title: String, count: Int, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(color)
                }
                Spacer()
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("\(count)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(LMSColors.textPrimary)
                Text(title)
                    .font(LMSFont.subheadline.weight(.medium))
                    .foregroundStyle(LMSColors.textSecondary)
            }
        }
        .padding(16)
        .lmsCard()
    }
    
    private func originCard(title: String, count: Int, origin: TicketOrigin) -> some View {
        HStack(spacing: 12) {
            Image(systemName: origin.iconName)
                .font(.system(size: 22))
                .foregroundStyle(origin.tint)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(count)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(LMSColors.textPrimary)
                Text(title)
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)
            }
            
            Spacer()
        }
        .padding(16)
        .lmsCard()
    }
}

#Preview {
    ComplaintDashboardView()
        .preferredColorScheme(.dark)
}
