import SwiftUI

// MARK: - Manager Applicant Action Sheet
struct ManagerApplicantActionSheet: View {
    let applicant: ManagerApplicant
    let actionType: ManagerApplicantDetailView.ActionType
    @ObservedObject var viewModel: ManagerDashboardViewModel
    var onComplete: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var remarks = ""
    @State private var isProcessing = false

    var body: some View {
        NavigationStack {
            VStack(spacing: LMSSpacing.xl) {
                // Action Icon
                ZStack {
                    Circle()
                        .fill(actionColor.opacity(0.12))
                        .frame(width: 72, height: 72)
                    Image(systemName: actionIcon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(actionColor)
                }
                .padding(.top, LMSSpacing.xl)

                // Title
                Text(actionTitle)
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)
                    .multilineTextAlignment(.center)

                // Summary
                VStack(spacing: LMSSpacing.sm) {
                    HStack {
                        Text("Borrower")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(LMSColors.textSecondary)
                        Spacer()
                        Text(applicant.borrowerName)
                            .font(.system(.caption, design: .rounded).bold())
                    }
                    HStack {
                        Text("Application")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(LMSColors.textSecondary)
                        Spacer()
                        Text(applicant.applicationId)
                            .font(.system(.caption, design: .monospaced).bold())
                    }
                    HStack {
                        Text("Amount")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(LMSColors.textSecondary)
                        Spacer()
                        Text(CurrencyFormatter.shared.format(applicant.requestedAmount))
                            .font(.system(.caption, design: .rounded).bold())
                    }
                }
                .padding(LMSSpacing.lg)
                .background(LMSColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))

                // Remarks
                VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                    Text("Remarks (Required)")
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textSecondary)

                    TextEditor(text: $remarks)
                        .font(.system(.body, design: .rounded))
                        .frame(height: 100)
                        .padding(LMSSpacing.sm)
                        .background(LMSColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
                        )
                }

                Spacer()

                // Confirm Button
                Button(action: performAction) {
                    Group {
                        if isProcessing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(confirmLabel)
                                .font(.system(.body, design: .rounded).weight(.bold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(actionColor)
                    .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
                }
                .disabled(isProcessing)

                Button("Cancel") { dismiss() }
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(LMSColors.textSecondary)
                    .padding(.bottom, LMSSpacing.md)
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)
            .navigationTitle(actionTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    // MARK: - Perform Action
    private func performAction() {
        guard !remarks.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || actionType == .escalate else {
            HapticsManager.triggerNotification(type: .warning)
            return
        }

        isProcessing = true
        HapticsManager.triggerImpact(style: .heavy)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            switch actionType {
            case .approve:
                viewModel.approveApplicant(applicant.id, remarks: remarks)
            case .reject:
                viewModel.rejectApplicant(applicant.id, remarks: remarks)
            case .sendBack:
                viewModel.sendBackApplicant(applicant.id, remarks: remarks)
            case .escalate:
                viewModel.escalateApplicant(applicant.id)
            }

            isProcessing = false
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                onComplete()
            }
        }
    }

    // MARK: - Computed Properties
    private var actionTitle: String {
        switch actionType {
        case .approve:  return "Approve Application"
        case .reject:   return "Reject Application"
        case .sendBack: return "Request Clarification"
        case .escalate: return "Escalate to Admin"
        }
    }

    private var confirmLabel: String {
        switch actionType {
        case .approve:  return "Confirm Approval"
        case .reject:   return "Confirm Rejection"
        case .sendBack: return "Send Back to Officer"
        case .escalate: return "Escalate Now"
        }
    }

    private var actionIcon: String {
        switch actionType {
        case .approve:  return "checkmark.seal.fill"
        case .reject:   return "xmark.octagon.fill"
        case .sendBack: return "arrow.uturn.backward.circle.fill"
        case .escalate: return "arrow.up.forward.circle.fill"
        }
    }

    private var actionColor: Color {
        switch actionType {
        case .approve:  return LMSColors.emerald
        case .reject:   return LMSColors.coral
        case .sendBack: return LMSColors.brandNavy
        case .escalate: return Color.purple
        }
    }
}

#Preview {
    ManagerApplicantActionSheet(
        applicant: PreviewSupport.sampleManagerApplicant,
        actionType: .approve,
        viewModel: PreviewSupport.managerViewModel,
        onComplete: {}
    )
}
