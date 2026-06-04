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
            Form {
                Section {
                    HStack(spacing: LMSSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(actionColor.opacity(0.12))
                                .frame(width: 54, height: 54)
                            Image(systemName: actionIcon)
                                .font(.title3.bold())
                                .foregroundStyle(actionColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(actionTitle)
                                .font(LMSFont.headline)
                            Text("Process clearance for this application")
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    LabeledContent("Borrower", value: applicant.borrowerName)
                    LabeledContent("Application ID", value: applicant.applicationId)
                    LabeledContent("Amount", value: CurrencyFormatter.shared.format(applicant.requestedAmount))
                }

                Section {
                    TextEditor(text: $remarks)
                        .frame(minHeight: 120)
                        .overlay(alignment: .topLeading) {
                            if remarks.isEmpty {
                                Text("Enter your decision remarks here...")
                                    .font(LMSFont.body)
                                    .foregroundStyle(LMSColors.textTertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 5)
                            }
                        }
                } header: {
                    Text("DECISION REMARKS")
                } footer: {
                    if let validationMessage {
                        Text(validationMessage)
                            .foregroundStyle(LMSColors.coral)
                    } else {
                        Text("These remarks will be visible to the loan officer and borrower.")
                    }
                }

                Section {
                    Button(action: performAction) {
                        HStack {
                            Spacer()
                            if isProcessing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text(confirmLabel)
                                    .font(LMSFont.body.bold())
                            }
                            Spacer()
                        }
                    }
                    .listRowBackground(actionColor)
                    .foregroundStyle(.white)
                    .disabled(isProcessing)
                }
            }
            .navigationTitle("Clearance Action")
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
            validationMessage = "Unable to process this action. Confirm it is still awaiting manager review."
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
