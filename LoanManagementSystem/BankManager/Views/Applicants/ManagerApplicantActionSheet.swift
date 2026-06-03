import SwiftUI


struct ManagerApplicantActionSheet: View {
    let applicant: ManagerApplicant
    let actionType: ManagerApplicantDetailView.ActionType
    @ObservedObject var viewModel: ManagerDashboardViewModel
    var onComplete: () -> Void

    @Environment(\.dismiss) var dismiss
    @State private var remarks = ""
    @State private var isProcessing = false
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: LMSSpacing.xl) {

                ZStack {
                    Circle()
                        .fill(actionColor.opacity(0.12))
                        .frame(width: 72, height: 72)
                    Image(systemName: actionIcon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundStyle(actionColor)
                }
                .padding(.top, LMSSpacing.xl)


                Text(actionTitle)
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)
                    .multilineTextAlignment(.center)


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
                        .onChange(of: remarks) { _, _ in
                            validationMessage = nil
                        }

                    if let validationMessage {
                        Text(validationMessage)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(LMSColors.coral)
                    }
                }

                Spacer()


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


    private func performAction() {
        let trimmedRemarks = remarks.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedRemarks.isEmpty || actionType == .escalate else {
            validationMessage = "Please enter remarks before confirming."
            HapticsManager.triggerNotification(type: .warning)
            return
        }

        isProcessing = true
        HapticsManager.triggerImpact(style: .heavy)

        let succeeded: Bool
        switch actionType {
        case .approve:
            succeeded = viewModel.approveApplicant(applicant.id, remarks: trimmedRemarks)
        case .reject:
            viewModel.rejectApplicant(applicant.id, remarks: trimmedRemarks)
            succeeded = true
        case .sendBack:
            viewModel.sendBackApplicant(applicant.id, remarks: trimmedRemarks)
            succeeded = true
        case .escalate:
            viewModel.escalateApplicant(applicant.id)
            succeeded = true
        }

        isProcessing = false

        guard succeeded else {
            validationMessage = "Unable to approve this application. Confirm it is still awaiting manager review."
            HapticsManager.triggerNotification(type: .error)
            return
        }

        dismiss()
        onComplete()
    }


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


