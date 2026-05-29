import SwiftUI

struct AdminBranchKPIView: View {
    let kpi: AdminKPI
    @ObservedObject var viewModel: AdminDashboardViewModel
    
    @State private var branchData: [KPIBranchData] = []
    @State private var searchText = ""
    
    var filteredData: [KPIBranchData] {
        if searchText.isEmpty {
            return branchData
        } else {
            return branchData.filter { $0.branchName.localizedCaseInsensitiveContains(searchText) || $0.branchCode.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: LMSSpacing.lg) {
                // Header Summary Card
                headerCard
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(LMSColors.textSecondary)
                    TextField("Search branch by name or code...", text: $searchText)
                        .font(LMSFont.body)
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(LMSColors.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.md))
                
                // Branch List
                if filteredData.isEmpty {
                    ContentUnavailableView(
                        "No Branches Found",
                        systemImage: "building.2.crop.circle.badge.xmark",
                        description: Text("Try adjusting your search terms.")
                    )
                    .padding(.top, 40)
                } else {
                    VStack(spacing: 0) {
                        ForEach(Array(filteredData.enumerated()), id: \.element.id) { index, data in
                            branchRow(for: data)
                            
                            if index < filteredData.count - 1 {
                                Divider().padding(.leading, 80)
                            }
                        }
                    }
                    .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
                }
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)
            .padding(.vertical, LMSSpacing.md)
        }
        .background(LMSColors.background.ignoresSafeArea())
        .navigationTitle(kpi.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if branchData.isEmpty {
                branchData = viewModel.getBranchBreakdown(for: kpi)
            }
        }
    }
    
    private var headerCard: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Total Overview")
                        .font(LMSFont.subheadline)
                        .foregroundStyle(LMSColors.textSecondary)
                    Text(kpi.value)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.textPrimary)
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(kpi.themeColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: kpi.icon)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(kpi.themeColor)
                }
            }
            
            Divider()
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: kpi.trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text("\(abs(kpi.trend), specifier: "%.1f")%")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(kpi.trend >= 0 ? LMSColors.emerald : LMSColors.coral)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background((kpi.trend >= 0 ? LMSColors.emerald : LMSColors.coral).opacity(0.15), in: Capsule())
                
                Text("vs last month")
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)
                
                Spacer()
            }
        }
        .padding(20)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
    }
    
    private func branchRow(for data: KPIBranchData) -> some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: LMSRadius.md)
                    .fill(LMSColors.brandNavy.opacity(0.1))
                    .frame(width: 48, height: 48)
                Image(systemName: "building.2.fill")
                    .font(.title3)
                    .foregroundStyle(LMSColors.brandNavy)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(data.branchName)
                    .font(LMSFont.callout.weight(.semibold))
                    .foregroundStyle(LMSColors.textPrimary)
                Text(data.branchCode)
                    .font(LMSFont.caption.monospaced())
                    .foregroundStyle(LMSColors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(data.value)
                    .font(LMSFont.headline)
                    .foregroundStyle(LMSColors.textPrimary)
                
                HStack(spacing: 2) {
                    Image(systemName: data.trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text("\(abs(data.trend), specifier: "%.1f")%")
                }
                .font(.caption2.weight(.bold))
                .foregroundStyle(data.trend >= 0 ? LMSColors.emerald : LMSColors.coral)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
