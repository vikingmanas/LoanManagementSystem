import SwiftUI


struct ManagerApplicantDetailView: View {
    let applicant: ManagerApplicant
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

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: LMSSpacing.xl) {


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
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LMSSpacing.xl)
                    .background(LMSColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: LMSRadius.xl, style: .continuous))


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
            .background(LMSColors.background)
            .navigationTitle("Application Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .font(.system(.body, design: .rounded).bold())
                }
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
                ReassignOfficerSheet(
                    applicant: applicant,
                    officers: viewModel.officers,
                    onReassign: { officerId in
                        viewModel.reassignApplicant(applicant.id, to: officerId)
                        showReassignSheet = false
                    }
                )
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


private struct ReassignOfficerSheet: View {
    let applicant: ManagerApplicant
    let officers: [ManagerOfficer]
    let onReassign: (UUID) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(officers) { officer in
                    Button(action: {
                        HapticsManager.triggerImpact(style: .medium)
                        onReassign(officer.id)
                        dismiss()
                    }) {
                        HStack(spacing: LMSSpacing.md) {
                            ZStack {
                                Circle()
                                    .fill(LMSColors.brandNavy.opacity(0.10))
                                    .frame(width: 40, height: 40)
                                Text(officer.initials)
                                    .font(.system(.caption, design: .rounded).bold())
                                    .foregroundStyle(LMSColors.brandNavy)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(officer.name)
                                    .font(.system(.callout, design: .rounded).bold())
                                    .foregroundStyle(LMSColors.textPrimary)
                                Text("\(officer.role) · \(officer.activeCases)/\(officer.maxCapacity) cases")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(LMSColors.textSecondary)
                            }

                            Spacer()

                            if officer.id == applicant.assignedOfficerId {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(LMSColors.emerald)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Reassign Officer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ManagerApplicantDetailView(
            applicant: PreviewSupport.sampleManagerApplicant,
            viewModel: PreviewSupport.managerViewModel
        )
    }
    .previewManagerEnvironment()
}

