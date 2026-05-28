import SwiftUI

// MARK: - Applications Tab

struct BorrowerApplicationsTabView: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var tabRouter: BorrowerTabRouter
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            BorrowerApplicationsHub(
                viewModel: viewModel,
                onSelectApplication: { application in
                    navigationPath.append(LoanApplicationRoute.tracking(application))
                },
                onApplyForLoan: { tabRouter.select(.loans) }
            )
            .background(LMSColors.background)
            .navigationTitle("Applications")
            .navigationBarTitleDisplayMode(.large)
            .task(id: authManager.userEmail) {
                viewModel.setBorrowerAuthContext(
                    email: authManager.userEmail ?? "",
                    displayName: authManager.userDisplayName
                )
            }
            .navigationDestination(for: LoanApplicationRoute.self) { route in
                switch route {
                case .productDetail, .applicationWizard:
                    EmptyView()
                case .tracking(let application):
                    LoanApplicationTrackingScreen(
                        viewModel: viewModel,
                        application: application,
                        onResume: {
                            viewModel.resumeDraft(application)
                            navigationPath.append(LoanApplicationRoute.applicationWizard(application.product))
                        },
                        onDelete: {
                            if viewModel.deleteDraft(applicationID: application.id),
                               !navigationPath.isEmpty {
                                navigationPath.removeLast()
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Hub Content

struct BorrowerApplicationsHub: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let onSelectApplication: (BorrowerLoanApplication) -> Void
    let onApplyForLoan: () -> Void

    @State private var draftPendingDeletion: BorrowerLoanApplication?
    @State private var showDeleteDraftConfirmation = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: LMSSpacing.xl) {
                VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                    Text("Track every draft, review, approval, and decision in one place")
                        .font(LMSFont.subheadline)
                        .foregroundStyle(LMSColors.textSecondary)
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)

                ApplicationMetricsRow(metrics: viewModel.dashboardMetrics)

                ApplicationFilterChipRow(selection: $viewModel.selectedApplicationFilter)
                    .padding(.horizontal, LMSSpacing.screenHorizontal)

                if viewModel.filteredSubmittedApplications.isEmpty {
                    ApplicationsEmptyState(
                        filter: viewModel.selectedApplicationFilter,
                        onApply: onApplyForLoan
                    )
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                } else {
                    LazyVStack(spacing: LMSSpacing.md) {
                        ForEach(viewModel.filteredSubmittedApplications) { app in
                            ApplicationTrackingCard(
                                application: app,
                                progress: viewModel.progressValue(for: app)
                            )
                            .onTapGesture { onSelectApplication(app) }
                            .contextMenu {
                                if app.isDraft {
                                    Button(role: .destructive) {
                                        draftPendingDeletion = app
                                        showDeleteDraftConfirmation = true
                                    } label: {
                                        Label("Delete Draft", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                }
            }
            .padding(.vertical, LMSSpacing.md)
            .padding(.bottom, LMSSpacing.xxxl)
        }
        .alert("Delete Draft?", isPresented: $showDeleteDraftConfirmation, presenting: draftPendingDeletion) { app in
            Button("Delete", role: .destructive) {
                _ = viewModel.deleteDraft(applicationID: app.id)
                draftPendingDeletion = nil
            }
            Button("Cancel", role: .cancel) {
                draftPendingDeletion = nil
            }
        } message: { app in
            Text("This will permanently delete draft \(app.displayIdentifier).")
        }
    }
}

// MARK: - Metrics

private struct ApplicationMetricsRow: View {
    let metrics: BorrowerLoanDashboardMetrics

    var body: some View {
        HStack(spacing: LMSSpacing.md) {
            ApplicationMetricTile(title: "In Review", value: "\(metrics.activeApplications)", tint: LMSColors.actionBlue)
            ApplicationMetricTile(title: "Approved", value: "\(metrics.approvedLoans)", tint: LMSColors.emerald)
            ApplicationMetricTile(title: "Drafts", value: "\(metrics.draftApplications)", tint: LMSColors.textSecondary)
        }
        .padding(.horizontal, LMSSpacing.screenHorizontal)
    }
}

private struct ApplicationMetricTile: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(spacing: LMSSpacing.xs) {
            Text(value)
                .font(LMSFont.title3.weight(.bold))
                .foregroundStyle(tint)
            Text(title)
                .font(LMSFont.caption2.weight(.medium))
                .foregroundStyle(LMSColors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LMSSpacing.lg)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
        )
    }
}

// MARK: - Filter Chips

private struct ApplicationFilterChipRow: View {
    @Binding var selection: BorrowerApplicationFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LMSSpacing.sm) {
                ForEach(BorrowerApplicationFilter.allCases) { filter in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selection = filter
                        }
                    } label: {
                        Text(filter.rawValue)
                            .font(LMSFont.footnote.weight(.semibold))
                            .foregroundStyle(selection == filter ? .white : LMSColors.textPrimary)
                            .padding(.horizontal, LMSSpacing.lg)
                            .padding(.vertical, LMSSpacing.sm)
                            .background(
                                selection == filter ? LMSColors.brandNavy : LMSColors.surface,
                                in: Capsule()
                            )
                            .overlay(
                                Capsule()
                                    .stroke(selection == filter ? Color.clear : LMSColors.separatorLight, lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Application Card

struct ApplicationTrackingCard: View {
    let application: BorrowerLoanApplication
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            HStack(alignment: .top) {
                Image(systemName: application.product.type.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(LMSColors.brandNavy)
                    .frame(width: 44, height: 44)
                    .background(LMSColors.brandNavy.opacity(0.08), in: RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(application.product.type.title)
                        .font(LMSFont.headline)
                        .foregroundStyle(LMSColors.textPrimary)
                    Text(application.displayIdentifier)
                        .font(LMSFont.caption.monospaced())
                        .foregroundStyle(LMSColors.textSecondary)
                }

                Spacer(minLength: 0)

                Text(application.currentStage.rawValue)
                    .font(LMSFont.caption2.weight(.bold))
                    .foregroundStyle(application.currentStage.tintColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(application.currentStage.tintColor.opacity(0.12), in: Capsule())
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Submitted")
                        .font(LMSFont.caption2)
                        .foregroundStyle(LMSColors.textSecondary)
                    Text((application.submittedAt ?? application.updatedAt).formattedAsDDMMMYYYY())
                        .font(LMSFont.footnote.weight(.medium))
                        .foregroundStyle(LMSColors.textPrimary)
                }
                Spacer()
                if application.formData.requestedAmountValue > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Amount")
                            .font(LMSFont.caption2)
                            .foregroundStyle(LMSColors.textSecondary)
                        Text(application.formData.requestedAmountValue.formattedAsINR())
                            .font(LMSFont.headline)
                            .foregroundStyle(LMSColors.brandNavy)
                    }
                }
            }

            VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                HStack {
                    Text("Progress")
                        .font(LMSFont.caption2)
                        .foregroundStyle(LMSColors.textSecondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(LMSFont.caption2.weight(.bold))
                        .foregroundStyle(LMSColors.brandNavy)
                }
                ProgressView(value: progress)
                    .tint(LMSColors.brandNavy)
            }

            ApplicationTimelinePreview(application: application)
        }
        .padding(LMSSpacing.lg)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 3)
    }
}

private struct ApplicationTimelinePreview: View {
    let application: BorrowerLoanApplication

    private var stages: [BorrowerApplicationStage] {
        if application.currentStage == .rejected || application.stageHistory.contains(where: { $0.stage == .rejected }) {
            return [.draft, .submitted, .underReview, .documentVerification, .loanOfficerReview, .bankManagerReview, .rejected]
        }
        return [.draft, .submitted, .underReview, .documentVerification, .loanOfficerReview, .bankManagerReview, .approved]
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(stages.enumerated()), id: \.element) { index, stage in
                let completed = isCompleted(stage)
                HStack(spacing: 0) {
                    Circle()
                        .fill(completed ? stage.tintColor : LMSColors.separator)
                        .frame(width: stage == application.currentStage ? 10 : 7, height: stage == application.currentStage ? 10 : 7)

                    if index < stages.count - 1 {
                        Rectangle()
                            .fill(completed ? stage.tintColor.opacity(0.45) : LMSColors.separatorLight)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, LMSSpacing.xs)
        .accessibilityLabel("Application timeline status \(application.currentStage.rawValue)")
    }

    private func isCompleted(_ stage: BorrowerApplicationStage) -> Bool {
        application.stageHistory.contains(where: { $0.stage == stage }) || stage == application.currentStage
    }
}

private struct ApplicationsEmptyState: View {
    let filter: BorrowerApplicationFilter
    let onApply: () -> Void

    var body: some View {
        VStack(spacing: LMSSpacing.lg) {
            Image(systemName: "tray")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(LMSColors.brandNavy.opacity(0.7))
            Text(emptyTitle)
                .font(LMSFont.headline)
                .foregroundStyle(LMSColors.textPrimary)
            Text(emptyMessage)
                .font(LMSFont.footnote)
                .foregroundStyle(LMSColors.textSecondary)
                .multilineTextAlignment(.center)
            Button("Browse Loans", action: onApply)
                .font(LMSFont.footnote.weight(.semibold))
                .foregroundStyle(LMSColors.brandNavy)
        }
        .frame(maxWidth: .infinity)
        .padding(LMSSpacing.xxl)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
    }

    private var emptyTitle: String {
        switch filter {
        case .draft: return "No Draft Applications"
        case .underReview: return "Nothing Under Review"
        case .approved: return "No Approved Applications"
        case .rejected: return "No Rejected Applications"
        case .all: return "No Applications Yet"
        }
    }

    private var emptyMessage: String {
        switch filter {
        case .draft: return "Start a loan application from the Loans tab and save it as a draft."
        case .underReview: return "Submitted applications will appear here while being processed."
        case .approved: return "Approved applications will show up in this list."
        case .rejected: return "You have no rejected applications."
        case .all: return "Apply for a loan to track status, drafts, and approvals in one place."
        }
    }
}

// Shared with loan wizard summary
struct MetricBadge: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 0.5)
        )
    }
}
