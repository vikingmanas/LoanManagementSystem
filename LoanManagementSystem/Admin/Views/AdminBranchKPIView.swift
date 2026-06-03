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
                // Branch List
                if filteredData.isEmpty {
                    ContentUnavailableView.search(text: searchText)
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
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search branch by name or code…")
        .background(LMSColors.background.ignoresSafeArea())
        .navigationTitle(kpi.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if branchData.isEmpty {
                branchData = viewModel.getBranchBreakdown(for: kpi)
            }
        }
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
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
