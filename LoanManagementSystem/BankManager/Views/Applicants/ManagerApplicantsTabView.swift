import SwiftUI


struct ManagerApplicantsTabView: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    var onSelectApplicant: (ManagerApplicant) -> Void

    var body: some View {
        VStack(spacing: 0) {

            VStack(spacing: LMSSpacing.md) {

                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(LMSColors.textSecondary)
                        .font(.system(size: 14))
                    TextField("Search by name, ID, or officer…", text: $viewModel.applicantSearchQuery)
                        .font(.system(.body, design: .rounded))
                    if !viewModel.applicantSearchQuery.isEmpty {
                        Button(action: { viewModel.applicantSearchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(LMSColors.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, LMSSpacing.lg)
                .padding(.vertical, 10)
                .background(LMSColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))


                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: LMSSpacing.sm) {
                        ManagerFilterChip(
                            title: "All",
                            isSelected: viewModel.selectedStatusFilter == nil,
                            action: { viewModel.selectedStatusFilter = nil }
                        )
                        ForEach(ManagerApplicantStatus.allCases, id: \.self) { status in
                            ManagerFilterChip(
                                title: status.displayName,
                                isSelected: viewModel.selectedStatusFilter == status,
                                tint: status.themeColor,
                                action: { viewModel.selectedStatusFilter = status }
                            )
                        }
                    }
                }


                HStack(spacing: LMSSpacing.sm) {

                    Menu {
                        Button("All Risks") { viewModel.selectedRiskFilter = nil }
                        ForEach(ManagerRiskLevel.allCases, id: \.self) { risk in
                            Button(risk.rawValue) { viewModel.selectedRiskFilter = risk }
                        }
                    } label: {
                        SecondaryFilterLabel(
                            icon: "shield.fill",
                            text: viewModel.selectedRiskFilter?.rawValue ?? "Risk",
                            isActive: viewModel.selectedRiskFilter != nil
                        )
                    }


                    Menu {
                        Button("All Types") { viewModel.selectedLoanTypeFilter = nil }
                        ForEach(ManagerLoanType.allCases, id: \.self) { type in
                            Button(type.rawValue) { viewModel.selectedLoanTypeFilter = type }
                        }
                    } label: {
                        SecondaryFilterLabel(
                            icon: "tag.fill",
                            text: viewModel.selectedLoanTypeFilter?.rawValue ?? "Loan Type",
                            isActive: viewModel.selectedLoanTypeFilter != nil
                        )
                    }


                    Menu {
                        Button("All Officers") { viewModel.selectedOfficerFilter = nil }
                        ForEach(viewModel.officers) { officer in
                            Button(officer.name) { viewModel.selectedOfficerFilter = officer.id }
                        }
                    } label: {
                        SecondaryFilterLabel(
                            icon: "person.fill",
                            text: viewModel.selectedOfficerFilter != nil
                                ? (viewModel.officers.first { $0.id == viewModel.selectedOfficerFilter }?.name.components(separatedBy: " ").first ?? "Officer")
                                : "Officer",
                            isActive: viewModel.selectedOfficerFilter != nil
                        )
                    }

                    Spacer()


                    Menu {
                        ForEach(ManagerDashboardViewModel.ApplicantSortOrder.allCases, id: \.self) { order in
                            Button(order.rawValue) {
                                viewModel.applicantSortOrder = order
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(LMSColors.actionBlue)
                            .frame(width: 32, height: 32)
                            .background(LMSColors.actionBlue.opacity(0.10))
                            .clipShape(Circle())
                    }
                }


                if viewModel.selectedStatusFilter != nil || viewModel.selectedRiskFilter != nil ||
                   viewModel.selectedLoanTypeFilter != nil || viewModel.selectedOfficerFilter != nil {
                    Button(action: {
                        HapticsManager.triggerImpact(style: .light)
                        viewModel.clearAllFilters()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                            Text("Clear All Filters")
                                .font(.system(.caption, design: .rounded).bold())
                        }
                        .foregroundStyle(LMSColors.coral)
                    }
                }
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)
            .padding(.vertical, LMSSpacing.md)
            .background(LMSColors.surface)

            Divider()


            let filtered = viewModel.filteredApplicants

            if filtered.isEmpty {
                ContentUnavailableView(
                    viewModel.applicants.isEmpty ? "No Applications Sent" : "No Applicants Found",
                    systemImage: "doc.text.magnifyingglass",
                    description: Text(viewModel.applicants.isEmpty ? "Loan applications submitted by loan officers for manager approval will appear here." : "Try adjusting your filters or search query.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVStack(spacing: LMSSpacing.sm) {

                        Text("\(filtered.count) applicant\(filtered.count == 1 ? "" : "s")")
                            .font(.system(.caption2, design: .rounded).bold())
                            .foregroundStyle(LMSColors.textTertiary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, LMSSpacing.xs)

                        ForEach(filtered) { applicant in
                            Button(action: {
                                HapticsManager.triggerImpact(style: .medium)
                                onSelectApplicant(applicant)
                            }) {
                                ApplicantListCard(applicant: applicant)
                            }
                            .buttonStyle(LMSPressableStyle())
                        }
                    }
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                    .padding(.vertical, LMSSpacing.md)
                }
            }
        }
        .background(LMSColors.background)
    }
}


private struct ManagerFilterChip: View {
    let title: String
    let isSelected: Bool
    var tint: Color = LMSColors.brandNavy
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticsManager.triggerImpact(style: .light)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { action() }
        }) {
            Text(title)
                .font(.system(.caption, design: .rounded).bold())
                .foregroundStyle(isSelected ? .white : LMSColors.textPrimary)
                .padding(.horizontal, LMSSpacing.md)
                .padding(.vertical, LMSSpacing.sm)
                .background(isSelected ? tint : LMSColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: LMSSpacing.xl, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: LMSSpacing.xl, style: .continuous)
                        .stroke(isSelected ? Color.clear : LMSColors.separatorLight, lineWidth: 0.5)
                )
        }
    }
}


private struct SecondaryFilterLabel: View {
    let icon: String
    let text: String
    let isActive: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text(text)
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .lineLimit(1)
        }
        .foregroundStyle(isActive ? LMSColors.brandNavy : LMSColors.textSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isActive ? LMSColors.brandNavy.opacity(0.10) : LMSColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous)
                .stroke(isActive ? LMSColors.brandNavy.opacity(0.20) : LMSColors.separatorLight, lineWidth: 0.5)
        )
    }
}


struct ApplicantListCard: View {
    let applicant: ManagerApplicant

    var body: some View {
        HStack(spacing: LMSSpacing.md) {

            ZStack {
                RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                    .fill(applicant.status.themeColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                Image(systemName: applicant.status.icon)
                    .foregroundStyle(applicant.status.themeColor)
                    .font(.system(size: 20, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 4) {

                HStack {
                    Text(applicant.borrowerName)
                        .font(.system(.callout, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                    Spacer()
                    Text(CurrencyFormatter.shared.format(applicant.requestedAmount))
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                }


                HStack {
                    Text(applicant.applicationId)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(LMSColors.textTertiary)
                    Spacer()
                    Text(applicant.loanType.rawValue)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                }


                HStack {
                    Text("CIBIL: \(applicant.cibilScore)")
                        .font(.system(.caption2, design: .rounded).bold())
                        .foregroundStyle(cibilColor(applicant.cibilScore))

                    Spacer()

                    HStack(spacing: 3) {
                        Circle()
                            .fill(applicant.riskLevel.themeColor)
                            .frame(width: 5, height: 5)
                        Text(applicant.riskLevel.rawValue)
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(applicant.riskLevel.themeColor)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(applicant.riskLevel.themeColor.opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                    Text(applicant.status.displayName)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(applicant.status.themeColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(applicant.status.themeColor.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
        }
        .padding(LMSSpacing.md)
        .background(LMSColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 2)
    }

    private func cibilColor(_ score: Int) -> Color {
        if score >= 750 { return LMSColors.emerald }
        if score >= 650 { return LMSColors.amber }
        return LMSColors.coral
    }
}

#Preview {
    ManagerApplicantsTabView(
        viewModel: PreviewSupport.managerViewModel,
        onSelectApplicant: { _ in }
    )
    .previewManagerEnvironment()
}
