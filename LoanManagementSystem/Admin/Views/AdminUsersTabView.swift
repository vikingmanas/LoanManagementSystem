import SwiftUI

struct AdminUsersTabView: View {
    @ObservedObject var viewModel: AdminStaffViewModel
    @State private var isShowingAddSheet = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                if viewModel.isLoading && viewModel.staffMembers.isEmpty {
                    Spacer()
                    ProgressView("Loading staff directory...")
                        .font(LMSFont.footnote)
                    Spacer()
                } else if viewModel.filteredStaffMembers.isEmpty {
                    Spacer()
                    VStack(spacing: LMSSpacing.md) {
                        Image(systemName: "person.2.slash.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(LMSColors.textTertiary)
                        Text(viewModel.searchText.isEmpty ? "No staff members registered" : "No results match your search")
                            .font(LMSFont.headline)
                            .foregroundStyle(LMSColors.textPrimary)
                        Text(viewModel.searchText.isEmpty ? "Tap the '+' icon to add a staff account." : "Check spelling or adjust your filters.")
                            .font(LMSFont.subheadline)
                            .foregroundStyle(LMSColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    HStack {
                        Text("\(viewModel.filteredStaffMembers.count) Staff Members")
                            .font(LMSFont.subheadline.weight(.semibold))
                            .foregroundStyle(LMSColors.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                    .padding(.bottom, 8)
                    
                    List {
                        ForEach(viewModel.filteredStaffMembers) { member in
                            ZStack(alignment: .leading) {
                                StaffMemberRow(member: member)
                                
                                NavigationLink(destination: AdminUserDetailView(viewModel: viewModel, member: member)) {
                                    EmptyView()
                                }
                                .opacity(0)
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .padding(.horizontal, LMSSpacing.screenHorizontal)
                            .padding(.vertical, LMSSpacing.xs)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.loadData()
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Staff Directory")
            .searchable(text: $viewModel.searchText, prompt: "Search staff...")
            .disableAutocorrection(true)
            .lmsScreenBackground()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 8) {
                        Menu {
                            Section("Role") {
                                Button("All Roles") { viewModel.selectedRoleFilter = nil }
                                Button("Loan Officer") { viewModel.selectedRoleFilter = .loanOfficer }
                                Button("Bank Manager") { viewModel.selectedRoleFilter = .bankManager }
                            }
                            Section("Status") {
                                Button("All Status") { viewModel.selectedStatusFilter = nil }
                                ForEach(StaffStatus.allCases) { status in
                                    Button(status.displayName) { viewModel.selectedStatusFilter = status }
                                }
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                                .font(.title3)
                                .foregroundStyle(LMSColors.brandNavy)
                                .symbolVariant((viewModel.selectedRoleFilter != nil || viewModel.selectedStatusFilter != nil) ? .fill : .none)
                        }

                        Button(action: {
                            isShowingAddSheet = true
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundStyle(LMSColors.brandNavy)
                        }
                    }
                }
            }
            .sheet(isPresented: $isShowingAddSheet) {
                AdminAddUserSheet(viewModel: viewModel)
            }
            .task {
                await viewModel.loadData()
            }
        }
    }
}




private struct StaffMemberRow: View {
    let member: StaffMember

    var body: some View {
        HStack(spacing: LMSSpacing.md) {

            Text(member.initials)
                .font(LMSFont.headline)
                .foregroundStyle(.white)
                .frame(width: 46, height: 46)
                .background(member.role.themeColor, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: LMSSpacing.xs) {
                    Text(member.fullName)
                        .font(LMSFont.callout.weight(.semibold))
                        .foregroundStyle(LMSColors.textPrimary)

                    Spacer()


                    LMSStatusPill(
                        text: member.status.displayName,
                        style: statusStyle(member.status),
                        icon: statusIcon(member.status)
                    )
                }

                Text(member.email)
                    .font(LMSFont.footnote)
                    .foregroundStyle(LMSColors.textSecondary)

                HStack(spacing: 8) {
                    Label(member.employeeCode, systemImage: "number.square.fill")
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textSecondary)

                    Text("•")
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textTertiary)

                    Text(member.role.displayName)
                        .font(LMSFont.caption2.weight(.bold))
                        .foregroundStyle(member.role.themeColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(member.role.themeColor.opacity(0.1), in: Capsule())
                }
            }
        }
        .padding(LMSSpacing.md)
        .lmsInsetGroupedCard()
    }

    private func statusStyle(_ status: StaffStatus) -> LMSStatusPill.Style {
        switch status {
        case .active: return .success
        case .inactive: return .neutral
        case .suspended: return .error
        case .pending: return .warning
        }
    }

    private func statusIcon(_ status: StaffStatus) -> String {
        switch status {
        case .active: return "checkmark.circle.fill"
        case .inactive: return "minus.circle.fill"
        case .suspended: return "exclamationmark.octagon.fill"
        case .pending: return "clock.fill"
        }
    }
}

