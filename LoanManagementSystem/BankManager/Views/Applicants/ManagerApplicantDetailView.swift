import SwiftUI


struct ManagerApplicantDetailView: View {
    let applicant: ManagerApplicant
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @Environment(\.dismiss) var dismiss

    @State private var showActionSheet = false
    @State private var actionType: ActionType? = nil
    @State private var showReassignSheet = false
    @State private var managerRemarks = ""
    @State private var showCIBILSheet = false

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
                        LabeledContent {
                            Text(applicant.loanType.rawValue)
                                .font(.body.weight(.semibold))
                        } label: {
                            Label("LOAN TYPE", systemImage: applicant.loanType.symbol)
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, LMSSpacing.lg)

                        Divider().padding(.leading, 44)

                        LabeledContent {
                            Text(CurrencyFormatter.shared.format(applicant.requestedAmount))
                                .font(.body.weight(.semibold))
                        } label: {
                            Label("AMOUNT", systemImage: "indianrupeesign.circle")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, LMSSpacing.lg)

                        Divider().padding(.leading, 44)

                        LabeledContent {
                            Text("\(applicant.tenure) months")
                                .font(.body.weight(.semibold))
                        } label: {
                            Label("TENURE", systemImage: "calendar")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, LMSSpacing.lg)

                        Divider().padding(.leading, 44)

                        LabeledContent {
                            Text(String(format: "%.2f%% p.a.", applicant.interestRate))
                                .font(.body.weight(.semibold))
                        } label: {
                            Label("INTEREST", systemImage: "percent")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, LMSSpacing.lg)
                    }
                    .background(LMSColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))


                    AdvancedRiskSection(applicant: applicant)


                    DocumentsSection(documents: applicant.documents)


                    if !applicant.isAssignedToOfficer {
                        HStack(spacing: LMSSpacing.sm) {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .foregroundStyle(LMSColors.amber)
                            Text("This loan is not assigned to a loan officer yet. Reassign it so branch performance and ratings stay accurate.")
                                .font(.footnote)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                        .padding(LMSSpacing.md)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(LMSColors.amber.opacity(0.10), in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
                    }

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

                            Button(action: { actionType = .reject }) {
                                Text("Reject")
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                    .foregroundStyle(LMSColors.coral)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(LMSColors.coral.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
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
                    Button("Done") { dismiss() }
                        .bold()
                }
            }
            .accessibleSheet(item: $actionType) { action in
                ManagerApplicantActionSheet(
                    applicant: applicant,
                    actionType: action,
                    viewModel: viewModel,
                    onComplete: { dismiss() }
                )
            }
            .accessibleSheet(isPresented: $showReassignSheet) {
                ReassignOfficerSheet(
                    applicant: applicant,
                    officers: viewModel.officers,
                    onReassign: { officerId in
                        viewModel.reassignApplicant(applicant.id, to: officerId)
                        showReassignSheet = false
                    }
                )
            }
            .accessibleSheet(isPresented: $showCIBILSheet) {
                CIBILDetailSheet(
                    score: applicant.cibilScore,
                    insight: LoanRiskInsightService.insight(for: applicant)
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





private struct AdvancedRiskSection: View {
    let applicant: ManagerApplicant
    @State private var appearAnimation = false
    
    private var riskPillStyle: LMSStatusPill.Style {
        switch applicant.riskLevel {
        case .low: return .success
        case .medium: return .warning
        case .high, .critical: return .error
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            HStack {
                Text("INTELLIRISK ENGINE™")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
                Spacer()
                LMSStatusPill(text: applicant.riskLevel.rawValue, style: riskPillStyle, icon: applicant.riskLevel.icon)
            }

            VStack(spacing: 0) {
                // Header: Standard Score Display
                HStack(spacing: LMSSpacing.lg) {
                    ZStack {
                        Circle()
                            .stroke(applicant.riskLevel.themeColor.opacity(0.15), lineWidth: 6)
                            .frame(width: 60, height: 60)
                            
                        Circle()
                            .trim(from: 0, to: appearAnimation ? Double(applicant.compositeRiskScore) / 100.0 : 0)
                            .stroke(applicant.riskLevel.themeColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                            .animation(.easeOut(duration: 1.2).delay(0.2), value: appearAnimation)

                        Text("\(applicant.compositeRiskScore)")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(LMSColors.textPrimary)
                            .monospacedDigit()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(applicant.riskLevel.rawValue + " Risk")
                            .font(LMSFont.headline)
                            .foregroundStyle(applicant.riskLevel.themeColor)
                        
                        Text("Proprietary AI risk assessment based on multiple data points.")
                            .font(LMSFont.subheadline)
                            .foregroundStyle(LMSColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                }
                .padding(LMSSpacing.lg)

                LMSGroupedDivider()

                // Factors - displayed as standard grouped rows
                ForEach(Array(applicant.riskFactors.enumerated()), id: \.element.id) { index, factor in
                    LMSListRow(
                        title: factor.title,
                        subtitle: factor.description,
                        icon: factor.isPositive ? "checkmark" : "exclamationmark.triangle.fill",
                        iconColor: factor.isPositive ? LMSColors.emerald : LMSColors.amber,
                        showChevron: false
                    )
                    
                    if index < applicant.riskFactors.count - 1 {
                        LMSGroupedDivider()
                    }
                }
            }
            .background(LMSColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
            .onAppear {
                appearAnimation = true
            }
        }
    }
}


private struct CIBILDetailSheet: View {
    let score: Int
    let insight: LoanRiskInsight
    @Environment(\.dismiss) var dismiss

    private var cibilColor: Color {
        if score >= 700 { return LMSColors.emerald }
        if score >= CentralLoanRepository.shared.globalRules.minCibilScore { return LMSColors.amber }
        return LMSColors.coral
    }

    private var cibilRating: String {
        if score >= 750 { return "Excellent" }
        if score >= 700 { return "Good" }
        if score >= CentralLoanRepository.shared.globalRules.minCibilScore { return "Fair" }
        return "Poor"
    }

    private var riskTint: Color {
        if insight.score >= 80 { return LMSColors.emerald }
        if insight.score >= 60 { return LMSColors.amber }
        return LMSColors.coral
    }

    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: LMSSpacing.xl) {

                    // CIBIL Score detail
                    VStack(spacing: LMSSpacing.lg) {
                        ZStack {
                            Circle()
                                .stroke(cibilColor.opacity(0.15), lineWidth: 8)
                                .frame(width: 100, height: 100)
                            Circle()
                                .trim(from: 0, to: Double(score) / 900.0)
                                .stroke(cibilColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(-90))

                            VStack(spacing: 2) {
                                Text("\(score)")
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundStyle(LMSColors.textPrimary)
                                    .monospacedDigit()
                                Text("/ 900")
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundStyle(LMSColors.textTertiary)
                            }
                        }

                        Text(cibilRating)
                            .font(.system(.title3, design: .rounded).bold())
                            .foregroundStyle(cibilColor)

                        Text("Based on credit bureau report")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(LMSColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LMSSpacing.xl)
                    .background(LMSColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: LMSRadius.xl, style: .continuous))

                    // Local Risk Insight
                    VStack(alignment: .leading, spacing: LMSSpacing.md) {
                        HStack(spacing: 6) {
                            Image(systemName: "cpu.fill")
                            Text("LOCAL RISK INSIGHT")
                        }
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)

                        HStack(spacing: LMSSpacing.lg) {
                            ZStack {
                                Circle()
                                    .fill(riskTint.opacity(0.12))
                                    .frame(width: 60, height: 60)
                                Text("\(insight.score)")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundStyle(riskTint)
                                    .monospacedDigit()
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(insight.label)
                                    .font(.system(.subheadline, design: .rounded).bold())
                                    .foregroundStyle(riskTint)

                                Text(insight.explanation)
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(LMSColors.textTertiary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()
                        }
                    }
                    .padding(LMSSpacing.lg)
                    .background(LMSColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))

                    Spacer().frame(height: LMSSpacing.xl)
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)
                .padding(.top, LMSSpacing.md)
            }
            .background(LMSColors.background)
            .navigationTitle("Credit & Risk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            }
        }
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

