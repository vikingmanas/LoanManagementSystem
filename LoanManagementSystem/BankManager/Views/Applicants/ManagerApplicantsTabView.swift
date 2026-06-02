import SwiftUI


struct ManagerApplicantsTabView: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    var onSelectApplicant: (ManagerApplicant) -> Void
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {                    let filtered = viewModel.filteredApplicants

                    if filtered.isEmpty {
                        ContentUnavailableView(
                            viewModel.applicants.isEmpty ? "No Applications Sent" : "No Applicants Found",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text(viewModel.applicants.isEmpty ? "Loan applications submitted by loan officers for manager approval will appear here." : "Try adjusting your filters or search query.")
                        )
                        .padding(.top, LMSSpacing.xxxl)
                    } else {
                        LazyVStack(spacing: LMSSpacing.sm) {
                            Text("\(filtered.count) applicant\(filtered.count == 1 ? "" : "s")")
                                .font(.system(.caption2, design: .rounded).bold())
                                .foregroundStyle(LMSColors.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, LMSSpacing.xs)
                                .padding(.top, LMSSpacing.sm)

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
                        .padding(.bottom, 100)
                    }
                }
            }
            .background(LMSColors.background)
            .searchable(text: $viewModel.applicantSearchQuery, prompt: "Search by name, ID, or officer…")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    filterToolbarMenu
                }
            }
    }

    private var filterToolbarMenu: some View {
        Menu {
            Menu {
                ForEach(ManagerDashboardViewModel.ApplicantSortOrder.allCases, id: \.self) { order in
                    Button(action: { viewModel.applicantSortOrder = order }) {
                        HStack {
                            Text(order.rawValue)
                            if viewModel.applicantSortOrder == order {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Sort By", systemImage: "arrow.up.arrow.down")
            }

            Divider()

            Menu {
                Button("All Statuses") { viewModel.selectedStatusFilter = nil }
                ForEach(ManagerApplicantStatus.allCases, id: \.self) { status in
                    Button(action: { viewModel.selectedStatusFilter = status }) {
                        HStack {
                            Text(status.displayName)
                            if viewModel.selectedStatusFilter == status {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Status", systemImage: "circle.grid.2x1")
            }

            Menu {
                Button("All Risks") { viewModel.selectedRiskFilter = nil }
                ForEach(ManagerRiskLevel.allCases, id: \.self) { risk in
                    Button(action: { viewModel.selectedRiskFilter = risk }) {
                        HStack {
                            Text(risk.rawValue)
                            if viewModel.selectedRiskFilter == risk {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Risk Level", systemImage: "shield")
            }

            Menu {
                Button("All Types") { viewModel.selectedLoanTypeFilter = nil }
                ForEach(ManagerLoanType.allCases, id: \.self) { type in
                    Button(action: { viewModel.selectedLoanTypeFilter = type }) {
                        HStack {
                            Text(type.rawValue)
                            if viewModel.selectedLoanTypeFilter == type {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Loan Type", systemImage: "tag")
            }

            Menu {
                Button("All Officers") { viewModel.selectedOfficerFilter = nil }
                ForEach(viewModel.officers) { officer in
                    Button(action: { viewModel.selectedOfficerFilter = officer.id }) {
                        HStack {
                            Text(officer.name)
                            if viewModel.selectedOfficerFilter == officer.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Officer", systemImage: "person")
            }

            if viewModel.selectedStatusFilter != nil || viewModel.selectedRiskFilter != nil || viewModel.selectedLoanTypeFilter != nil || viewModel.selectedOfficerFilter != nil {
                Divider()
                Button(role: .destructive, action: { viewModel.clearAllFilters() }) {
                    Label("Clear Filters", systemImage: "xmark.circle")
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 18))
                Text("Filters")
                    .font(.system(.body, design: .rounded))
            }
            .foregroundStyle(.black)
            .overlay(
                Group {
                    if viewModel.selectedStatusFilter != nil || viewModel.selectedRiskFilter != nil || viewModel.selectedLoanTypeFilter != nil || viewModel.selectedOfficerFilter != nil {
                        Circle()
                            .fill(LMSColors.coral)
                            .frame(width: 8, height: 8)
                            .offset(x: 6, y: -6)
                    }
                }
                , alignment: .topTrailing
            )
        }
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
        if score >= CentralLoanRepository.shared.globalRules.minCibilScore { return LMSColors.amber }
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
