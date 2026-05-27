import SwiftUI


struct ManagerApplicantsTabView: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    var onSelectApplicant: (ManagerApplicant) -> Void

    var body: some View {
        VStack(spacing: 0) {

            VStack(spacing: 12) {

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
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
                    .padding(.horizontal, 16)
                }
                .padding(.horizontal, -16)


                HStack(spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            SecondaryFilterChip(
                                icon: "shield.fill",
                                text: viewModel.selectedRiskFilter?.rawValue ?? "Risk",
                                isActive: viewModel.selectedRiskFilter != nil,
                                onClear: { viewModel.selectedRiskFilter = nil }
                            ) {
                                Button("All Risks") { viewModel.selectedRiskFilter = nil }
                                ForEach(ManagerRiskLevel.allCases, id: \.self) { risk in
                                    Button(risk.rawValue) { viewModel.selectedRiskFilter = risk }
                                }
                            }


                            SecondaryFilterChip(
                                icon: "tag.fill",
                                text: viewModel.selectedLoanTypeFilter?.rawValue ?? "Loan Type",
                                isActive: viewModel.selectedLoanTypeFilter != nil,
                                onClear: { viewModel.selectedLoanTypeFilter = nil }
                            ) {
                                Button("All Types") { viewModel.selectedLoanTypeFilter = nil }
                                ForEach(ManagerLoanType.allCases, id: \.self) { type in
                                    Button(type.rawValue) { viewModel.selectedLoanTypeFilter = type }
                                }
                            }


                            SecondaryFilterChip(
                                icon: "person.fill",
                                text: viewModel.selectedOfficerFilter != nil
                                    ? (viewModel.officers.first { $0.id == viewModel.selectedOfficerFilter }?.name.components(separatedBy: " ").first ?? "Officer")
                                    : "Officer",
                                isActive: viewModel.selectedOfficerFilter != nil,
                                onClear: { viewModel.selectedOfficerFilter = nil }
                            ) {
                                Button("All Officers") { viewModel.selectedOfficerFilter = nil }
                                ForEach(viewModel.officers) { officer in
                                    Button(officer.name) { viewModel.selectedOfficerFilter = officer.id }
                                }
                            }
                        }
                        .padding(.leading, 16)
                        .padding(.trailing, 8)
                    }
                    .padding(.leading, -16)


                    Menu {
                        ForEach(ManagerDashboardViewModel.ApplicantSortOrder.allCases, id: \.self) { order in
                            Button(order.rawValue) {
                                viewModel.applicantSortOrder = order
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(viewModel.applicantSortOrder != .dateDesc ? Color.blue : Color.primary)
                        .frame(width: 32, height: 32)
                        .background(viewModel.applicantSortOrder != .dateDesc ? Color.blue.opacity(0.12) : Color(.systemGray6))
                        .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))


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
                    LazyVStack(spacing: 12) {

                        Text("\(filtered.count) applicant\(filtered.count == 1 ? "" : "s")")
                            .font(.system(.caption, design: .default))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)

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
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .searchable(text: $viewModel.applicantSearchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search by name, ID, or officer...")
    }
}


private struct ManagerFilterChip: View {
    let title: String
    let isSelected: Bool
    var tint: Color = Color.blue
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticsManager.triggerImpact(style: .light)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { action() }
        }) {
            Text(title)
                .font(.system(.footnote, design: .default).weight(.semibold))
                .foregroundStyle(isSelected ? .white : Color.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .clipShape(Capsule())
        }
    }
}


private struct SecondaryFilterChip<Content: View>: View {
    let icon: String
    let text: String
    let isActive: Bool
    let onClear: () -> Void
    @ViewBuilder let menuContent: () -> Content

    var body: some View {
        if isActive {
            HStack(spacing: 6) {
                Menu {
                    menuContent()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: icon)
                            .font(.system(size: 11, weight: .semibold))
                        Text(text)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.plain)

                Button(action: {
                    HapticsManager.triggerImpact(style: .light)
                    withAnimation { onClear() }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.blue.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .foregroundStyle(Color.blue)
            .padding(.leading, 12)
            .padding(.trailing, 8)
            .padding(.vertical, 8)
            .background(Color.blue.opacity(0.12))
            .clipShape(Capsule())
        } else {
            Menu {
                menuContent()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .semibold))
                    Text(text)
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(Color.secondary)
                }
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(Capsule())
            }
        }
    }
}


struct ApplicantListCard: View {
    let applicant: ManagerApplicant

    var body: some View {
        HStack(spacing: 12) {

            ZStack {
                Circle()
                    .fill(applicant.status.themeColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: applicant.status.icon)
                    .foregroundStyle(applicant.status.themeColor)
                    .font(.system(size: 18, weight: .semibold))
            }

            VStack(alignment: .leading, spacing: 4) {

                HStack {
                    Text(applicant.borrowerName)
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                    Spacer()
                    Text(CurrencyFormatter.shared.format(applicant.requestedAmount))
                        .font(.headline)
                        .foregroundStyle(Color.primary)
                }


                HStack {
                    Text(applicant.applicationId)
                        .font(.footnote.monospaced())
                        .foregroundStyle(Color.secondary)
                    Spacer()
                    Text(applicant.loanType.rawValue)
                        .font(.subheadline)
                        .foregroundStyle(Color.secondary)
                }


                HStack(spacing: 8) {
                    Text("CIBIL: \(applicant.cibilScore)")
                        .font(.subheadline.bold())
                        .foregroundStyle(cibilColor(applicant.cibilScore))

                    Spacer()

                    HStack(spacing: 3) {
                        Circle()
                            .fill(applicant.riskLevel.themeColor)
                            .frame(width: 5, height: 5)
                        Text(applicant.riskLevel.rawValue)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(applicant.riskLevel.themeColor)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(applicant.riskLevel.themeColor.opacity(0.10))
                    .clipShape(Capsule())

                    Text(applicant.status.displayName)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(applicant.status.themeColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(applicant.status.themeColor.opacity(0.10))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func cibilColor(_ score: Int) -> Color {
        if score >= 750 { return Color(.systemGreen) }
        if score >= 650 { return Color(.systemOrange) }
        return Color(.systemRed)
    }
}

#Preview {
    ManagerApplicantsTabView(
        viewModel: PreviewSupport.managerViewModel,
        onSelectApplicant: { _ in }
    )
    .previewManagerEnvironment()
}
