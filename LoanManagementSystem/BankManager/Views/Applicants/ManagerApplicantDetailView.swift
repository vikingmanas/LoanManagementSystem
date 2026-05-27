import SwiftUI


struct ManagerApplicantDetailView: View {
    let applicantId: UUID
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showActionSheet = false
    @State private var actionType: ActionType? = nil
    @State private var showReassignSheet = false
    @State private var managerRemarks = ""

    enum ActionType: Identifiable {
        case approve, reject, sendBack, escalate
        var id: String { String(describing: self) }
    }

    /// Always reads the freshest copy from the view model so assignment
    /// changes (reassign, approve, etc.) are reflected immediately.
    private var currentApplicant: ManagerApplicant? {
        viewModel.applicants.first { $0.id == applicantId }
    }

    /// Finds the full ManagerOfficer record for the current applicant (if any).
    private var assignedOfficerRecord: ManagerOfficer? {
        guard let applicant = currentApplicant else { return nil }
        return viewModel.officers.first { $0.id == applicant.assignedOfficerId }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let applicant = currentApplicant {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: LMSSpacing.xl) {

                            // ── Borrower Hero ──────────────────────────────────
                            VStack(spacing: LMSSpacing.md) {
                                ZStack {
                                    Circle()
                                        .fill(applicant.loanType.themeColor.opacity(0.15))
                                        .frame(width: 72, height: 72)
                                    Text(applicant.borrowerInitials)
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .foregroundStyle(applicant.loanType.themeColor)
                                }

                                Text(applicant.borrowerName)
                                    .font(.system(.title3, design: .rounded).bold())
                                    .foregroundStyle(LMSColors.textPrimary)

                                HStack(spacing: LMSSpacing.sm) {
                                    Text(applicant.applicationId)
                                        .font(.system(.caption, design: .monospaced).bold())
                                        .foregroundStyle(LMSColors.textSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 4)
                                        .background(LMSColors.textSecondary.opacity(0.12))
                                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                                    LMSStatusPill(
                                        text: applicant.status.displayName,
                                        style: statusPillStyle(applicant.status),
                                        icon: applicant.status.icon
                                    )
                                }

                                // Loan type badge
                                HStack(spacing: 5) {
                                    Image(systemName: applicant.loanType.symbol)
                                        .font(.system(size: 11, weight: .bold))
                                    Text(applicant.loanType.rawValue)
                                        .font(.system(.caption, design: .rounded).bold())
                                }
                                .foregroundStyle(applicant.loanType.themeColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(applicant.loanType.themeColor.opacity(0.12))
                                .clipShape(Capsule())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, LMSSpacing.xl)
                            .background(LMSColors.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.xl, style: .continuous))

                            // ── Assigned Loan Officer Card ────────────────────
                            AssignedOfficerCard(
                                applicant: applicant,
                                officerRecord: assignedOfficerRecord,
                                onReassign: { showReassignSheet = true }
                            )

                            // ── Loan Details ──────────────────────────────────
                            VStack(spacing: 0) {
                                DetailRow(label: "LOAN TYPE", value: applicant.loanType.rawValue, icon: applicant.loanType.symbol)
                                Divider()
                                DetailRow(label: "REQUESTED AMOUNT", value: CurrencyFormatter.shared.format(applicant.requestedAmount))
                                Divider()
                                DetailRow(label: "TENURE", value: "\(applicant.tenure) months")
                                Divider()
                                DetailRow(label: "INTEREST RATE", value: String(format: "%.2f%% p.a.", applicant.interestRate))
                                Divider()
                                DetailRow(label: "SUBMISSION DATE", value: RelativeDateFormatter.shared.absoluteString(from: applicant.submissionDate))
                            }
                            .background(LMSColors.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))

                            CIBILScoreCard(score: applicant.cibilScore)

                            VerificationProgressCard(progress: applicant.verificationProgress)

                            DocumentsSection(documents: applicant.documents)

                            OfficerRecommendationCard(
                                officerName: applicant.assignedOfficer,
                                remarks: applicant.officerRemarks
                            )

                            if !applicant.managerRemarks.isEmpty {
                                ManagerRemarksCard(remarks: applicant.managerRemarks)
                            }

                            // ── Action Buttons ────────────────────────────────
                            if applicant.status == .sentToManager || applicant.status == .needsClarification {
                                VStack(spacing: LMSSpacing.md) {

                                    Button(action: { actionType = .approve }) {
                                        Text("Approve & Disburse Clearance")
                                            .font(.system(.body, design: .rounded).weight(.bold))
                                            .foregroundStyle(.white)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 52)
                                            .background(LMSColors.emerald)
                                            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
                                    }

                                    HStack(spacing: LMSSpacing.md) {
                                        Button(action: { actionType = .reject }) {
                                            Text("Reject")
                                                .font(.system(.body, design: .rounded).weight(.semibold))
                                                .foregroundStyle(LMSColors.coral)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 52)
                                                .background(LMSColors.coral.opacity(0.12))
                                                .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
                                        }

                                        Button(action: { actionType = .escalate }) {
                                            Text("Escalate")
                                                .font(.system(.body, design: .rounded).weight(.semibold))
                                                .foregroundStyle(Color.purple)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 52)
                                                .background(Color.purple.opacity(0.12))
                                                .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
                                        }
                                    }

                                    Button(action: { actionType = .sendBack }) {
                                        Text("Request Officer Clarification")
                                            .font(.system(.body, design: .rounded).weight(.semibold))
                                            .foregroundStyle(LMSColors.brandNavy)
                                            .frame(maxWidth: .infinity)
                                            .frame(height: 52)
                                            .background(LMSColors.brandNavy.opacity(0.12))
                                            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
                                    }

                                    Button(action: { showReassignSheet = true }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: "arrow.triangle.2.circlepath")
                                            Text("Reassign to Another Officer")
                                        }
                                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                        .foregroundStyle(LMSColors.textSecondary)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 44)
                                    }
                                }
                            }

                            Spacer().frame(height: LMSSpacing.xl)
                        }
                        .padding(.horizontal, LMSSpacing.screenHorizontal)
                        .padding(.top, LMSSpacing.md)
                    }
                    .sheet(item: $actionType) { action in
                        ManagerApplicantActionSheet(
                            applicant: applicant,
                            actionType: action,
                            viewModel: viewModel,
                            onComplete: { dismiss() }
                        )
                    }
                    .sheet(isPresented: $showReassignSheet) {
                        ApplicationAssignmentSheet(
                            applicant: applicant,
                            officers: viewModel.officers,
                            onAssign: { officerId in
                                viewModel.reassignApplicant(applicant.id, to: officerId)
                            }
                        )
                    }
                } else {
                    // Applicant was removed from queue (approved / rejected)
                    VStack(spacing: LMSSpacing.lg) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(LMSColors.emerald)
                        Text("Application no longer pending")
                            .font(.system(.title3, design: .rounded).bold())
                            .foregroundStyle(LMSColors.textPrimary)
                        Text("It may have been approved, rejected, or moved.")
                            .font(.system(.callout, design: .rounded))
                            .foregroundStyle(LMSColors.textSecondary)
                            .multilineTextAlignment(.center)
                        Button("Close") { dismiss() }
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(LMSColors.actionBlue)
                    }
                    .padding(LMSSpacing.xl)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(LMSColors.background)
            .navigationTitle("Application Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .font(.system(.body, design: .rounded).bold())
                }
            }
        }
    }

    private func statusPillStyle(_ status: ManagerApplicantStatus) -> LMSStatusPill.Style {
        switch status {
        case .approved, .disbursed: return .success
        case .rejected: return .error
        case .sentToManager, .needsClarification: return .warning
        case .escalated: return .info
        }
    }
}


private struct DetailRow: View {
    let label: String
    let value: String
    var icon: String? = nil

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(LMSColors.textSecondary)
            Spacer()
            HStack(spacing: 4) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundStyle(LMSColors.textSecondary)
                }
                Text(value)
                    .font(.system(.footnote, design: .rounded).weight(.semibold))
                    .foregroundStyle(LMSColors.textPrimary)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, LMSSpacing.lg)
    }
}


private struct CIBILScoreCard: View {
    let score: Int

    private var color: Color {
        if score >= 750 { return LMSColors.emerald }
        if score >= 650 { return LMSColors.amber }
        return LMSColors.coral
    }

    private var rating: String {
        if score >= 750 { return "Excellent" }
        if score >= 700 { return "Good" }
        if score >= 650 { return "Fair" }
        return "Poor"
    }

    var body: some View {
        HStack(spacing: LMSSpacing.lg) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 6)
                    .frame(width: 60, height: 60)
                Circle()
                    .trim(from: 0, to: Double(score) / 900.0)
                    .stroke(color, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))

                Text("\(score)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(LMSColors.textPrimary)
                    .monospacedDigit()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("CIBIL SCORE")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
                Text(rating)
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundStyle(color)
                Text("Based on credit bureau report")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(LMSColors.textTertiary)
            }

            Spacer()
        }
        .padding(LMSSpacing.lg)
        .background(LMSColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
    }
}


private struct VerificationProgressCard: View {
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            HStack {
                Text("VERIFICATION PROGRESS")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(progress >= 1.0 ? LMSColors.emerald : LMSColors.actionBlue)
                    .monospacedDigit()
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(LMSColors.actionBlue.opacity(0.15))
                        .frame(height: 6)
                    Capsule()
                        .fill(progress >= 1.0 ? LMSColors.emerald : LMSColors.actionBlue)
                        .frame(width: geo.size.width * progress, height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                ProgressStep(label: "Docs", completed: progress >= 0.25)
                ProgressStep(label: "KYC", completed: progress >= 0.50)
                ProgressStep(label: "Credit", completed: progress >= 0.75)
                ProgressStep(label: "Final", completed: progress >= 1.0)
            }
        }
        .padding(LMSSpacing.lg)
        .background(LMSColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
    }
}

private struct ProgressStep: View {
    let label: String
    let completed: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: completed ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 14))
                .foregroundStyle(completed ? LMSColors.emerald : LMSColors.textTertiary)
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(completed ? LMSColors.textPrimary : LMSColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }
}


private struct DocumentsSection: View {
    let documents: [ManagerDocument]

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("DOCUMENTS")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(LMSColors.textSecondary)

            VStack(spacing: 0) {
                ForEach(documents) { doc in
                    HStack(spacing: LMSSpacing.md) {
                        Image(systemName: "doc.richtext.fill")
                            .foregroundStyle(LMSColors.actionBlue)
                            .font(.system(size: 16))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(doc.name)
                                .font(.system(.caption, design: .rounded).bold())
                                .foregroundStyle(LMSColors.textPrimary)
                            Text(doc.type)
                                .font(.system(.caption2, design: .rounded))
                                .foregroundStyle(LMSColors.textTertiary)
                        }

                        Spacer()

                        HStack(spacing: 3) {
                            Image(systemName: doc.status.icon)
                                .font(.system(size: 10))
                            Text(doc.status.rawValue)
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(doc.status.themeColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(doc.status.themeColor.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, LMSSpacing.lg)

                    if doc.id != documents.last?.id {
                        Divider().padding(.leading, 48)
                    }
                }
            }
            .background(LMSColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        }
    }
}


private struct OfficerRecommendationCard: View {
    let officerName: String
    let remarks: String

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            HStack {
                Image(systemName: "person.badge.shield.checkmark.fill")
                    .foregroundStyle(LMSColors.brandNavy)
                Text("OFFICER RECOMMENDATION")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
            }

            HStack(alignment: .top, spacing: LMSSpacing.sm) {
                ZStack {
                    Circle()
                        .fill(LMSColors.brandNavy.opacity(0.12))
                        .frame(width: 32, height: 32)
                    Text(String(officerName.prefix(2)).uppercased())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.brandNavy)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(officerName)
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                    Text(remarks)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(LMSColors.textPrimary)
                        .lineSpacing(3)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LMSSpacing.lg)
        .background(LMSColors.amber.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                .stroke(LMSColors.amber.opacity(0.15), lineWidth: 0.5)
        )
    }
}


private struct ManagerRemarksCard: View {
    let remarks: String

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
            HStack {
                Image(systemName: "pencil.and.outline")
                    .foregroundStyle(LMSColors.emerald)
                Text("MANAGER REMARKS")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
            }
            Text(remarks)
                .font(.system(.footnote, design: .rounded))
                .foregroundStyle(LMSColors.textPrimary)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LMSSpacing.lg)
        .background(LMSColors.emerald.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                .stroke(LMSColors.emerald.opacity(0.15), lineWidth: 0.5)
        )
    }
}


/// Prominent card showing the currently assigned Loan Officer with real-time
/// data pulled from viewModel.officers, plus the loan type badge and a
/// quick-reassign button.
private struct AssignedOfficerCard: View {
    let applicant: ManagerApplicant
    let officerRecord: ManagerOfficer?
    let onReassign: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {

            // Section header
            HStack {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .foregroundStyle(LMSColors.actionBlue)
                Text("ASSIGNED LOAN OFFICER")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
                Spacer()
                // Loan type pill
                HStack(spacing: 4) {
                    Image(systemName: applicant.loanType.symbol)
                        .font(.system(size: 9, weight: .bold))
                    Text(applicant.loanType.rawValue)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                }
                .foregroundStyle(applicant.loanType.themeColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(applicant.loanType.themeColor.opacity(0.12))
                .clipShape(Capsule())
            }

            // Officer identity row
            HStack(spacing: LMSSpacing.md) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(LMSColors.brandNavy.opacity(0.12))
                        .frame(width: 50, height: 50)
                    Text(officerRecord?.initials ?? String(applicant.assignedOfficer.prefix(2)).uppercased())
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.brandNavy)
                }
                .overlay(
                    Circle()
                        .stroke(LMSColors.brandNavy.opacity(0.15), lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(applicant.assignedOfficer)
                        .font(.system(.callout, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)

                    Text(officerRecord?.role ?? "Loan Officer")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)

                    // Active cases bar
                    if let record = officerRecord {
                        HStack(spacing: LMSSpacing.xs) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(LMSColors.separatorLight)
                                        .frame(height: 4)
                                    Capsule()
                                        .fill(record.capacityColor)
                                        .frame(width: geo.size.width * min(1, record.capacityPercentage), height: 4)
                                }
                            }
                            .frame(height: 4)

                            Text("\(record.activeCases)/\(record.maxCapacity) cases")
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundStyle(record.capacityColor)
                                .monospacedDigit()
                        }
                    }
                }

                Spacer()

                // Approval rate ring (only if we have the full record)
                if let record = officerRecord, record.loansProcessedYTD > 0 {
                    VStack(spacing: 2) {
                        ZStack {
                            Circle()
                                .stroke(LMSColors.emerald.opacity(0.15), lineWidth: 4)
                                .frame(width: 38, height: 38)
                            Circle()
                                .trim(from: 0, to: record.approvalRate / 100)
                                .stroke(LMSColors.emerald, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                .frame(width: 38, height: 38)
                                .rotationEffect(.degrees(-90))
                            Text("\(Int(record.approvalRate))%")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(LMSColors.textPrimary)
                                .monospacedDigit()
                        }
                        Text("approval")
                            .font(.system(size: 8, design: .rounded))
                            .foregroundStyle(LMSColors.textTertiary)
                    }
                }
            }

            // Quick reassign button (only for pending applications)
            if applicant.status == .sentToManager || applicant.status == .needsClarification {
                Button(action: {
                    HapticsManager.triggerImpact(style: .light)
                    onReassign()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Reassign Officer")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(LMSColors.actionBlue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(LMSColors.actionBlue.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous)
                            .stroke(LMSColors.actionBlue.opacity(0.20), lineWidth: 0.5)
                    )
                }
            }
        }
        .padding(LMSSpacing.lg)
        .background(LMSColors.actionBlue.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                .stroke(LMSColors.actionBlue.opacity(0.15), lineWidth: 0.5)
        )
    }
}



#Preview {
    NavigationStack {
        ManagerApplicantDetailView(
            applicantId: PreviewSupport.sampleManagerApplicant.id,
            viewModel: PreviewSupport.managerViewModel
        )
    }
    .previewManagerEnvironment()
}

