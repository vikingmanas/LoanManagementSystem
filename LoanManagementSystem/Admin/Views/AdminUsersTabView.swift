import SwiftUI

struct AdminUsersTabView: View {
    @ObservedObject var viewModel: AdminStaffViewModel
    @State private var isShowingAddSheet = false
    @State private var selectedMemberForDetail: StaffMember? = nil

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                VStack(spacing: LMSSpacing.md) {

                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(LMSColors.textSecondary)
                        TextField("Search name, email, employee code...", text: $viewModel.searchText)
                            .font(LMSFont.body)
                            .textFieldStyle(.plain)
                            .disableAutocapitalization()
                        if !viewModel.searchText.isEmpty {
                            Button(action: { viewModel.searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(LMSColors.textSecondary)
                            }
                        }
                    }
                    .padding(LMSSpacing.md)
                    .background(LMSColors.surfaceTertiary, in: RoundedRectangle(cornerRadius: LMSRadius.md))
                    .padding(.horizontal, LMSSpacing.screenHorizontal)


                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: LMSSpacing.sm) {
                            AdminFilterChip(
                                title: "All Roles",
                                isSelected: viewModel.selectedRoleFilter == nil,
                                action: { viewModel.selectedRoleFilter = nil }
                            )

                            AdminFilterChip(
                                title: "Loan Officer",
                                isSelected: viewModel.selectedRoleFilter == .loanOfficer,
                                action: { viewModel.selectedRoleFilter = .loanOfficer }
                            )

                            AdminFilterChip(
                                title: "Bank Manager",
                                isSelected: viewModel.selectedRoleFilter == .bankManager,
                                action: { viewModel.selectedRoleFilter = .bankManager }
                            )
                        }
                        .padding(.horizontal, LMSSpacing.screenHorizontal)
                    }
                }
                .padding(.vertical, LMSSpacing.md)
                .background(LMSColors.surface)


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
                    List {
                        ForEach(viewModel.filteredStaffMembers) { member in
                            StaffMemberRow(member: member)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                                .onTapGesture {
                                    selectedMemberForDetail = member
                                }
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
            .navigationTitle("Staff Directory")
            .lmsScreenBackground()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isShowingAddSheet = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(LMSColors.brandNavy)
                    }
                    .buttonStyle(LMSPressableStyle())
                }
            }
            .sheet(isPresented: $isShowingAddSheet) {
                AdminAddUserSheet(viewModel: viewModel)
            }
            .sheet(item: $selectedMemberForDetail) { member in
                AdminUserDetailSheet(viewModel: viewModel, member: member)
            }
            .task {
                await viewModel.loadData()
            }
        }
    }
}


private struct AdminFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(LMSFont.footnote.weight(.semibold))
                .padding(.horizontal, LMSSpacing.md)
                .padding(.vertical, 8)
                .background(
                    isSelected ? LMSColors.brandNavy : LMSColors.surfaceTertiary,
                    in: Capsule()
                )
                .foregroundStyle(isSelected ? .white : LMSColors.textSecondary)
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : LMSColors.separatorLight, lineWidth: 1)
                )
        }
        .buttonStyle(LMSPressableStyle())
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
                        .font(LMSFont.caption.weight(.medium))
                        .foregroundStyle(member.role.themeColor)
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

