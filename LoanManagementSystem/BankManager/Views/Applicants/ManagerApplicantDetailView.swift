import SwiftUI

struct ManagerApplicantDetailView: View {
    let applicant: ManagerApplicant
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @Environment(\.dismiss) var dismiss

    @State private var actionType: ActionType? = nil
    @State private var managerRemarks = ""

    enum ActionType: Identifiable {
        case approve, reject, escalate
        var id: String { String(describing: self) }
    }

    var body: some View {
        List {
                // MARK: - Profile Header
                Section {
                    VStack(spacing: LMSSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(applicant.loanType.themeColor.opacity(0.12))
                                .frame(width: 80, height: 80)
                            Text(applicant.borrowerInitials)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(applicant.loanType.themeColor)
                        }
                        .padding(.top, LMSSpacing.sm)

                        VStack(spacing: 4) {
                            Text(applicant.borrowerName)
                                .font(LMSFont.title3)
                                .foregroundStyle(LMSColors.textPrimary)
                            
                            HStack(spacing: LMSSpacing.sm) {
                                Text(applicant.applicationId)
                                    .font(.system(.caption, design: .monospaced).bold())
                                    .foregroundStyle(LMSColors.textSecondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(LMSColors.textSecondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 4))

                                LMSStatusPill(
                                    text: applicant.status.displayName,
                                    style: statusPillStyle(applicant.status),
                                    icon: applicant.status.icon
                                )
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .padding(.vertical, LMSSpacing.lg)
                }

                // MARK: - Loan Details
                Section("Loan Information") {
                    LabeledContent {
                        Text(applicant.loanType.rawValue)
                            .font(LMSFont.body.weight(.semibold))
                    } label: {
                        Label("Type", systemImage: applicant.loanType.symbol)
                            .foregroundStyle(LMSColors.textSecondary)
                    }

                    LabeledContent {
                        Text(CurrencyFormatter.shared.format(applicant.requestedAmount))
                            .font(LMSFont.body.weight(.semibold))
                    } label: {
                        Label("Amount", systemImage: "indianrupeesign.circle")
                            .foregroundStyle(LMSColors.textSecondary)
                    }

                    LabeledContent {
                        Text("\(applicant.tenure) months")
                            .font(LMSFont.body.weight(.semibold))
                    } label: {
                        Label("Tenure", systemImage: "calendar")
                            .foregroundStyle(LMSColors.textSecondary)
                    }

                    LabeledContent {
                        Text(String(format: "%.2f%% p.a.", applicant.interestRate))
                            .font(LMSFont.body.weight(.semibold))
                    } label: {
                        Label("Interest", systemImage: "percent")
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                }

                // MARK: - Advanced Risk Engine
                AdvancedRiskSection(applicant: applicant)
                    .listRowInsets(EdgeInsets(top: LMSSpacing.lg, leading: 0, bottom: LMSSpacing.lg, trailing: 0))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)

                // MARK: - Documents
                Section("Documents") {
                    if applicant.documents.isEmpty {
                        Text("No documents uploaded")
                            .font(LMSFont.footnote)
                            .foregroundStyle(LMSColors.textTertiary)
                    } else {
                        ForEach(applicant.documents) { doc in
                            DocumentRow(doc: doc)
                        }
                    }
                }

                // MARK: - Assignment Warning
                if !applicant.isAssignedToOfficer {
                    Section {
                        HStack(spacing: LMSSpacing.md) {
                            Image(systemName: "person.crop.circle.badge.exclamationmark")
                                .font(.title3)
                                .foregroundStyle(LMSColors.amber)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Unassigned Application")
                                    .font(LMSFont.subheadline.bold())
                                Text("This loan needs an officer assigned for accurate tracking.")
                                    .font(LMSFont.caption)
                                    .foregroundStyle(LMSColors.textSecondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                // MARK: - Reviewer Notes
                Section("Reviewer Context") {
                    VStack(alignment: .leading, spacing: LMSSpacing.md) {
                        OfficerRecommendationView(
                            officerName: applicant.assignedOfficer,
                            remarks: applicant.officerRemarks
                        )
                        
                        if !applicant.managerRemarks.isEmpty {
                            ManagerRemarksView(remarks: applicant.managerRemarks)
                        }
                    }
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets(top: 0, leading: LMSSpacing.lg, bottom: 0, trailing: LMSSpacing.lg))
                    .listRowBackground(Color.clear)
                }

                // MARK: - Actions
                if applicant.status == .sentToManager || applicant.status == .needsClarification {
                    Section {
                        Button(action: { actionType = .approve }) {
                            HStack {
                                Spacer()
                                Text("Approve Application")
                                    .font(LMSFont.body.bold())
                                Spacer()
                            }
                        }
                        .tint(LMSColors.emerald)

                        Button(role: .destructive, action: { actionType = .reject }) {
                            HStack {
                                Spacer()
                                Text("Reject Application")
                                    .font(LMSFont.body.bold())
                                Spacer()
                            }
                        }
                    }
                }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Application Review")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $actionType) { action in
            ManagerApplicantActionSheet(
                applicant: applicant,
                actionType: action,
                viewModel: viewModel,
                onComplete: { dismiss() }
            )
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

// MARK: - Helper Views

private struct CIBILScoreRow: View {
    let score: Int

    private var color: Color {
        if score >= 700 { return LMSColors.emerald }
        if score >= CentralLoanRepository.shared.globalRules.minCibilScore { return LMSColors.amber }
        return LMSColors.coral
    }

    private var rating: String {
        if score >= 750 { return "Excellent" }
        if score >= 700 { return "Good" }
        if score >= CentralLoanRepository.shared.globalRules.minCibilScore { return "Fair" }
        return "Poor"
    }

    var body: some View {
        HStack(spacing: LMSSpacing.md) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 4)
                    .frame(width: 44, height: 44)
                Circle()
                    .trim(from: 0, to: Double(score) / 900.0)
                    .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .frame(width: 44, height: 44)
                    .rotationEffect(.degrees(-90))

                Text("\(score)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(LMSColors.textPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("CIBIL Score")
                    .font(LMSFont.subheadline.bold())
                Text(rating)
                    .font(LMSFont.caption)
                    .foregroundStyle(color)
            }

            Spacer()
        }
        .padding(.vertical, 2)
    }
}

private struct DocumentRow: View {
    let doc: ManagerDocument

    var body: some View {
        HStack(spacing: LMSSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LMSColors.actionBlue.opacity(0.1))
                    .frame(width: 40, height: 40)
                Image(systemName: "doc.text.fill")
                    .foregroundStyle(LMSColors.actionBlue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(doc.name)
                    .font(LMSFont.subheadline.bold())
                Text(doc.type)
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)
            }

            Spacer()

            Text(doc.status.rawValue)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(doc.status.themeColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(doc.status.themeColor.opacity(0.1), in: Capsule())
        }
        .padding(.vertical, 4)
    }
}

private struct OfficerRecommendationView: View {
    let officerName: String
    let remarks: String

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
            Label("OFFICER RECOMMENDATION", systemImage: "person.badge.shield.checkmark.fill")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(LMSColors.textSecondary)

            VStack(alignment: .leading, spacing: LMSSpacing.md) {
                HStack(spacing: LMSSpacing.sm) {
                    Circle()
                        .fill(LMSColors.brandNavy.opacity(0.12))
                        .frame(width: 24, height: 24)
                        .overlay(
                            Text(String(officerName.prefix(2)).uppercased())
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(LMSColors.brandNavy)
                        )
                    
                    Text(officerName)
                        .font(LMSFont.subheadline.bold())
                }

                Text(remarks)
                    .font(LMSFont.footnote)
                    .foregroundStyle(LMSColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(LMSSpacing.md)
            .background(LMSColors.amber.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: LMSRadius.md)
                    .stroke(LMSColors.amber.opacity(0.15), lineWidth: 0.5)
            )
        }
    }
}

private struct ManagerRemarksView: View {
    let remarks: String

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
            Label("PREVIOUS MANAGER REMARKS", systemImage: "pencil.and.outline")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundStyle(LMSColors.textSecondary)

            Text(remarks)
                .font(LMSFont.footnote)
                .foregroundStyle(LMSColors.textPrimary)
                .padding(LMSSpacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LMSColors.emerald.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md))
                .overlay(
                    RoundedRectangle(cornerRadius: LMSRadius.md)
                        .stroke(LMSColors.emerald.opacity(0.15), lineWidth: 0.5)
                )
        }
    }
}

private struct CIBILDetailView: View {
    let score: Int
    let insight: LoanRiskInsight

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
        List {
            Section {
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

                    VStack(spacing: 4) {
                        Text(cibilRating)
                            .font(LMSFont.title3)
                            .foregroundStyle(cibilColor)
                        Text("Credit Bureau Rating")
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .padding(.vertical, LMSSpacing.xl)
            }

            Section("Local Risk Assessment") {
                HStack(spacing: LMSSpacing.lg) {
                    ZStack {
                        Circle()
                            .fill(riskTint.opacity(0.12))
                            .frame(width: 54, height: 54)
                        Text("\(insight.score)")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(riskTint)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(insight.label)
                            .font(LMSFont.subheadline.bold())
                            .foregroundStyle(riskTint)

                        Text(insight.explanation)
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Credit & Risk")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Advanced Risk UI

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
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(applicant.riskLevel.themeColor)
                    Text("INTELLIRISK ENGINE™")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                }
                Spacer()
                LMSStatusPill(text: applicant.riskLevel.rawValue, style: riskPillStyle, icon: applicant.riskLevel.icon)
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)

            VStack(spacing: LMSSpacing.lg) {
                // Solid Stat Cards
                HStack(spacing: 16) {
                    // CIBIL Box
                    VStack(alignment: .leading, spacing: 8) {
                        Text("CIBIL SCORE")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Text("\(Int(applicant.cibilScore))")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(applicant.cibilScore >= 750 ? LMSColors.emerald : (applicant.cibilScore >= 650 ? LMSColors.amber : LMSColors.coral))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    
                    // Composite Score Box
                    VStack(alignment: .leading, spacing: 8) {
                        Text("COMPOSITE RISK")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(.white.opacity(0.8))
                        
                        Text("\(applicant.compositeRiskScore)")
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(applicant.riskLevel.themeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)

                // Risk Factors List
                if !applicant.riskFactors.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(Array(applicant.riskFactors.enumerated()), id: \.element.id) { index, factor in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: factor.isPositive ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                    .foregroundStyle(factor.isPositive ? LMSColors.emerald : LMSColors.amber)
                                    .font(.system(size: 18))
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(factor.title)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(LMSColors.textPrimary)
                                    Text(factor.description)
                                        .font(.caption)
                                        .foregroundStyle(LMSColors.textSecondary)
                                }
                                Spacer()
                            }
                            if index < applicant.riskFactors.count - 1 {
                                Divider()
                            }
                        }
                    }
                    .padding(16)
                    .background(LMSColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(LMSColors.separatorLight, lineWidth: 1)
                    )
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                }
            }
        }
    }
}
