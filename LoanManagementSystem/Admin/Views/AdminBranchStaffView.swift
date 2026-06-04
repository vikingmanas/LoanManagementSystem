import SwiftUI

struct AdminBranchStaffView: View {
    let branch: BranchInfo
    @Bindable var viewModel: AdminStaffViewModel
    
    var branchStaff: [StaffMember] {
        viewModel.staff(for: branch.branchId)
    }
    
    var managers: [StaffMember] {
        branchStaff.filter { $0.role == .bankManager }
    }
    
    var loanOfficers: [StaffMember] {
        branchStaff.filter { $0.role == .loanOfficer }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: LMSSpacing.lg) {
                branchHeader
                
                if branchStaff.isEmpty {
                    ContentUnavailableView(
                        "No Staff Assigned",
                        systemImage: "person.2.slash",
                        description: Text("There are currently no staff members assigned to this branch.")
                    )
                    .padding(.top, 40)
                } else {
                    VStack(spacing: LMSSpacing.xl) {
                        if !managers.isEmpty {
                            staffSection(title: managers.count == 1 ? "Branch Manager" : "Branch Managers", members: managers)
                        }
                        
                        if !loanOfficers.isEmpty {
                            staffSection(title: "Loan Officers", members: loanOfficers)
                        }
                    }
                }
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)
            .padding(.vertical, LMSSpacing.md)
        }
        .background(LMSColors.background.ignoresSafeArea())
        .navigationTitle("Branch Staff")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var branchHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: LMSRadius.md)
                    .fill(LMSColors.brandNavy.opacity(0.1))
                    .frame(width: 56, height: 56)
                Image(systemName: "building.2.fill")
                    .font(.title)
                    .foregroundStyle(LMSColors.brandNavy)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(branch.name)
                    .font(LMSFont.title3)
                    .foregroundStyle(LMSColors.textPrimary)
                
                HStack(spacing: 8) {
                    Label(branch.code, systemImage: "number.square")
                        .font(LMSFont.subheadline)
                        .foregroundStyle(LMSColors.textSecondary)
                    Text("•")
                        .foregroundStyle(LMSColors.textTertiary)
                    Text(branch.region)
                        .font(LMSFont.subheadline)
                        .foregroundStyle(LMSColors.textSecondary)
                }
            }
            Spacer()
        }
        .padding(16)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
    }
    
    private func staffSection(title: String, members: [StaffMember]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(LMSFont.headline)
                .foregroundStyle(LMSColors.textPrimary)
            
            VStack(spacing: 0) {
                ForEach(Array(members.enumerated()), id: \.element.id) { index, member in
                    NavigationLink(destination: AdminUserDetailView(viewModel: viewModel, member: member)) {
                        StaffMemberRow(member: member)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if index < members.count - 1 {
                        Divider().padding(.leading, 78)
                    }
                }
            }
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg))
        }
    }
}

