import SwiftUI

struct LoanReviewDashboardView: View {
    @StateObject private var viewModel = LoanReviewViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // KPI Overview
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                        kpiCard(title: "Total Application", count: viewModel.totalApplications, icon: "folder.fill", color: LMSColors.brandNavy, isSelected: viewModel.selectedStatus == nil) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { viewModel.selectedStatus = nil }
                        }
                        kpiCard(title: "Pending", count: viewModel.pendingCount, icon: "clock.fill", color: LMSColors.amber, isSelected: viewModel.selectedStatus == .pending) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { viewModel.selectedStatus = .pending }
                        }
                        kpiCard(title: "Under Review", count: viewModel.underReviewCount, icon: "eye.fill", color: LMSColors.actionBlue, isSelected: viewModel.selectedStatus == .underReview) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { viewModel.selectedStatus = .underReview }
                        }
                        kpiCard(title: "Approved", count: viewModel.approvedCount, icon: "checkmark.seal.fill", color: LMSColors.emerald, isSelected: viewModel.selectedStatus == .approved) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { viewModel.selectedStatus = .approved }
                        }
                    }
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                    .padding(.top, 16)
                    
                    // Filter & Sort Section
                    HStack {
                        Menu {
                            Section("Sort By") {
                                Button("Newest First") { viewModel.currentSort = .dateDesc }
                                Button("Oldest First") { viewModel.currentSort = .dateAsc }
                                Button("Amount (High to Low)") { viewModel.currentSort = .amountDesc }
                                Button("Amount (Low to High)") { viewModel.currentSort = .amountAsc }
                            }
                        } label: {
                            Label("Sort", systemImage: "arrow.up.arrow.down")
                                .font(LMSFont.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(LMSColors.surfaceElevated, in: Capsule())
                                .overlay(Capsule().stroke(LMSColors.separatorLight, lineWidth: 1))
                                .foregroundStyle(LMSColors.textPrimary)
                        }
                        
                        Menu {
                            Section("Status") {
                                Button("All") { viewModel.selectedStatus = nil }
                                ForEach(LoanApplicationStatus.allCases) { s in
                                    Button(s.rawValue) { viewModel.selectedStatus = s }
                                }
                            }
                            Section("Loan Type") {
                                Button("All") { viewModel.selectedLoanType = nil }
                                ForEach(AdminLoanType.allCases) { t in
                                    Button(t.rawValue) { viewModel.selectedLoanType = t }
                                }
                            }
                        } label: {
                            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                                .font(LMSFont.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(LMSColors.surfaceElevated, in: Capsule())
                                .overlay(Capsule().stroke(LMSColors.separatorLight, lineWidth: 1))
                                .foregroundStyle(LMSColors.textPrimary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                    
                    // Applications List
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Actionable Applications")
                            .font(LMSFont.title3)
                            .foregroundStyle(LMSColors.textPrimary)
                            .padding(.horizontal, LMSSpacing.screenHorizontal)
                        
                        if viewModel.filteredApplicants.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "folder.badge.questionmark")
                                    .font(.system(size: 40))
                                    .foregroundStyle(LMSColors.textTertiary)
                                Text("No Applications Found")
                                    .font(LMSFont.headline)
                                    .foregroundStyle(LMSColors.textSecondary)
                                Text("Try adjusting your search or filters.")
                                    .font(LMSFont.subheadline)
                                    .foregroundStyle(LMSColors.textTertiary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 60)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(viewModel.filteredApplicants) { applicant in
                                    NavigationLink(destination: ApplicantDetailView(viewModel: viewModel, applicantId: applicant.id)) {
                                        ApplicantCard(applicant: applicant)
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
            .navigationTitle("Loan Reviews")
            .searchable(text: $viewModel.searchText, prompt: "Search Applicant or ID")
        }
    }
    
    private func kpiCard(title: String, count: Int, icon: String, color: Color, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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
            .background(isSelected ? color.opacity(0.08) : Color.clear)
            .lmsCard()
            .overlay(
                RoundedRectangle(cornerRadius: LMSRadius.lg) // Assumes lmsCard uses lg or similar, adjust if needed
                    .stroke(isSelected ? color.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(LMSPressableStyle())
    }
}

#Preview {
    LoanReviewDashboardView()
        .preferredColorScheme(.dark)
}
