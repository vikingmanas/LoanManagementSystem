import SwiftUI

private struct DocumentRejectionPrompt: Identifiable {
    let document: LoanDocument

    var id: UUID { document.id }
}

struct LoanApplicationReviewDetailView: View {
    typealias LoanApplication = OfficerLoanApplication
    let applicationId: String
    let initialDocumentId: UUID?
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var isRunningAIAudit = false
    @State private var aiAuditRun = false
    @State private var aiStatusText = ""
    
    @State private var selectedDocForPreview: LoanDocument? = nil
    @State private var showingActionSheetForDoc: LoanDocument? = nil
    @State private var rejectionText = ""
    @State private var rejectionPrompt: DocumentRejectionPrompt?
    @State private var documentActionStatus: OfficerDocumentStatus = .rejectFlag
    @State private var escalationReason = ""
    @State private var showingEscalationAlert = false
    @State private var escalationAlertMessage = ""
    @State private var showingApplicationRejectPrompt = false
    @State private var applicationRejectReason = ""
    @State private var hasPresentedInitialDocument = false

    init(applicationId: String, initialDocumentId: UUID? = nil, viewModel: LoanOfficerDashboardViewModel) {
        self.applicationId = applicationId
        self.initialDocumentId = initialDocumentId
        self.viewModel = viewModel
    }
    
    var app: LoanApplication? {
        viewModel.applications.first { $0.applicationId == applicationId }
    }
    
    var loanDocuments: [LoanDocument] {
        guard let app = app else { return [] }
        return app.documents
    }
    
    var borrowerData: BorrowerDetails {
        app?.borrowerDetails ?? .empty
    }
    
    var isReadyForFinalApproval: Bool {
        guard !loanDocuments.isEmpty else { return false }
        return loanDocuments.allSatisfy { $0.status == .verified }
    }
    
    var body: some View {
        if let currentApp = app {
            applicationContent(currentApp)
                .onAppear {
                    claimApplicationIfNeeded(currentApp)
                    presentInitialDocumentIfNeeded(in: currentApp)
                }
        } else {
            ContentUnavailableView("Application Not Found", systemImage: "questionmark.circle")
        }
    }

    private func claimApplicationIfNeeded(_ app: LoanApplication) {
        guard let officerId = viewModel.officerProfile?.id,
              let officerName = viewModel.officerProfile?.fullName,
              CentralLoanRepository.shared.isLoanUnassigned(applicationId: app.id) else { return }
        CentralLoanRepository.shared.assignOfficer(userId: officerId, name: officerName, toApplicationId: app.id)
        viewModel.refreshFromRepository()
    }

    private func presentInitialDocumentIfNeeded(in app: LoanApplication) {
        guard !hasPresentedInitialDocument,
              let initialDocumentId,
              let document = app.documents.first(where: { $0.id == initialDocumentId }) else { return }

        hasPresentedInitialDocument = true
        DispatchQueue.main.async {
            selectedDocForPreview = document
        }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private func applicationContent(_ currentApp: LoanApplication) -> some View {
        ZStack {
            List {
                applicationHeaderSection(currentApp)
                progressSection(currentApp)
                personalDetailsSection(currentApp)
                loanEmploymentSection(currentApp)
                aiAuditSection(currentApp)
                documentChecklistSection(currentApp)
                timelineSection(currentApp)
                approvalSection(currentApp)
            }
            .listStyle(.insetGrouped)

            if let doc = showingActionSheetForDoc {
                centeredVerificationActions(for: doc, in: currentApp)
                    .transition(.opacity.combined(with: .scale(scale: 0.94)))
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.86), value: showingActionSheetForDoc?.id)
        .navigationTitle("Application Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
        .navigationDestination(item: $selectedDocForPreview) { doc in
            DocumentReviewDetailView(
                item: DocumentQueueItem(
                    id: doc.id,
                    borrowerName: currentApp.borrowerName,
                    docType: doc.docType,
                    status: doc.status,
                    submittedDate: doc.uploadedDate ?? currentApp.submittedDate,
                    applicationId: currentApp.applicationId,
                    fileURL: doc.fileURL
                ),
                viewModel: viewModel
            )
        }
        .alert("Document Remarks", isPresented: rejectionPromptIsPresented) {
            TextField("Reason / remarks", text: $rejectionText)
            Button("Submit", role: .destructive) {
                if let prompt = rejectionPrompt {
                    viewModel.updateDocumentStatus(
                        applicationId: currentApp.applicationId,
                        docId: prompt.document.id,
                        newStatus: documentActionStatus,
                        rejectionReason: rejectionText.isEmpty ? defaultReason(for: documentActionStatus) : rejectionText
                    )
                }
                rejectionText = ""
                rejectionPrompt = nil
            }
            Button("Cancel", role: .cancel) {
                rejectionText = ""
                rejectionPrompt = nil
            }
        } message: {
            Text("Add a reason for the borrower and audit trail.")
        }
        .alert("Reject Application", isPresented: $showingApplicationRejectPrompt) {
            TextField("Reason for borrower", text: $applicationRejectReason)
            Button("Reject Application", role: .destructive) {
                let reason = applicationRejectReason.trimmingCharacters(in: .whitespacesAndNewlines)
                if viewModel.rejectApplication(applicationId: currentApp.applicationId, reason: reason) {
                    HapticsManager.triggerNotification(type: .success)
                    applicationRejectReason = ""
                    dismiss()
                } else {
                    applicationRejectReason = ""
                    escalationAlertMessage = "Could not reject this application right now."
                    showingEscalationAlert = true
                }
            }
            Button("Cancel", role: .cancel) {
                applicationRejectReason = ""
            }
        } message: {
            Text("This rejects the complete loan application, not just one document. The borrower will be notified.")
        }
        .task {
            await viewModel.refreshDocuments(for: currentApp.applicationId)
        }
    }

    private func centeredVerificationActions(for doc: LoanDocument, in app: LoanApplication) -> some View {
        ZStack {
            Color.black.opacity(0.46)
                .ignoresSafeArea()
                .onTapGesture {
                    showingActionSheetForDoc = nil
                }

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Verification Actions")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.primary)

                    Text("Select verification status update for \(doc.docType.rawValue).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(spacing: 10) {
                    verificationActionButton(
                        title: "Verify Document",
                        icon: "checkmark.seal.fill",
                        tint: LMSColors.actionBlue
                    ) {
                        HapticsManager.triggerImpact(style: .medium)
                        viewModel.updateDocumentStatus(applicationId: app.applicationId, docId: doc.id, newStatus: .verified)
                        showingActionSheetForDoc = nil
                    }

                    verificationActionButton(
                        title: "Reject Document",
                        icon: "xmark.octagon.fill",
                        tint: LMSColors.coral
                    ) {
                        showingActionSheetForDoc = nil
                        rejectionText = ""
                        documentActionStatus = .rejectFlag
                        let prompt = DocumentRejectionPrompt(document: doc)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            rejectionPrompt = prompt
                        }
                    }

                    verificationActionButton(
                        title: "Request Re-upload",
                        icon: "arrow.triangle.2.circlepath",
                        tint: LMSColors.coral
                    ) {
                        showingActionSheetForDoc = nil
                        rejectionText = ""
                        documentActionStatus = .rejectFlag
                        let prompt = DocumentRejectionPrompt(document: doc)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                            rejectionPrompt = prompt
                        }
                    }

                    verificationActionButton(
                        title: "Mark as Missing",
                        icon: "questionmark.folder.fill",
                        tint: LMSColors.actionBlue
                    ) {
                        HapticsManager.triggerImpact(style: .medium)
                        viewModel.updateDocumentStatus(
                            applicationId: app.applicationId,
                            docId: doc.id,
                            newStatus: .pending,
                            rejectionReason: "Required document is missing."
                        )
                        showingActionSheetForDoc = nil
                    }
                }

                Button("Cancel") {
                    showingActionSheetForDoc = nil
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.top, 2)
            }
            .padding(20)
            .frame(maxWidth: 300)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(LMSColors.separatorLight, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.26), radius: 24, x: 0, y: 14)
            .padding(.horizontal, 32)
        }
    }

    private func verificationActionButton(title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .frame(width: 22)

                Text(title)
                    .font(.subheadline.weight(.semibold))

                Spacer()
            }
            .foregroundStyle(tint)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var rejectionPromptIsPresented: Binding<Bool> {
        Binding {
            rejectionPrompt != nil
        } set: { isPresented in
            if !isPresented {
                rejectionText = ""
                rejectionPrompt = nil
            }
        }
    }

    private func defaultReason(for status: OfficerDocumentStatus) -> String {
        status == .rejectFlag
            ? "Document requires re-upload. Please provide a clear valid copy."
            : "Reviewed by loan officer."
    }
    
    // MARK: - Application Header
    
    private func applicationHeaderSection(_ app: LoanApplication) -> some View {
        Section {
            HStack(spacing: 14) {
                OfficerAvatar(name: app.borrowerName, tint: app.loanType.themeColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(app.borrowerName)
                        .font(.headline)
                    Text(app.applicationId)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Text(app.status.rawValue)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(app.status.themeColor, in: Capsule())
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Progress
    
    private func progressSection(_ app: LoanApplication) -> some View {
        let verifiedCount = loanDocuments.filter { $0.status == .verified }.count
        let pendingCount = loanDocuments.filter { $0.status != .verified && $0.status != .rejectFlag }.count
        let rejectedCount = loanDocuments.filter { $0.status == .rejectFlag }.count
        let totalDocs = loanDocuments.count
        let completionPct = totalDocs > 0 ? Double(verifiedCount) / Double(totalDocs) : 0
        
        return Section("Verification Progress") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(Int(completionPct * 100))% Complete")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(LMSColors.actionBlue)
                    Spacer()
                    Text("\(verifiedCount) of \(totalDocs) verified")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                ProgressView(value: completionPct)
                    .tint(completionPct >= 1.0 ? LMSColors.emerald : LMSColors.actionBlue)

                HStack(spacing: 12) {
                    Label("\(verifiedCount) Verified", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(LMSColors.emerald)
                    Label("\(pendingCount) Pending", systemImage: "clock.fill")
                        .foregroundStyle(LMSColors.amber)
                    Label("\(rejectedCount) Rejected", systemImage: "xmark.octagon.fill")
                        .foregroundStyle(LMSColors.coral)
                }
                .font(.caption2.weight(.semibold))
            }
            .padding(.vertical, 4)
        }
    }
    
    // MARK: - Personal Details
    
    private func personalDetailsSection(_ app: LoanApplication) -> some View {
        Section("Personal Information") {
            VStack(spacing: 0) {
                ApplicationDetailRow("Full Name", value: app.borrowerName)
                ApplicationDetailRow("Date of Birth", value: borrowerData.dob)
                ApplicationDetailRow("Age", value: borrowerData.age)
                ApplicationDetailRow("Gender", value: borrowerData.gender)
                ApplicationDetailRow("PAN Number", value: borrowerData.pan)
                ApplicationDetailRow("CIBIL Score", value: app.cibilScore.map(String.init) ?? "Not provided", valueColor: app.cibilScore.map(cibilColor(for:)) ?? .secondary)
                ApplicationDetailRow("Email", value: borrowerData.email)
                ApplicationDetailRow("Phone", value: borrowerData.phone)
                ApplicationDetailRow("Address", value: borrowerData.address, isLast: true)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
    }
    
    // MARK: - Loan & Employment
    
    private func loanEmploymentSection(_ app: LoanApplication) -> some View {
        Section("Loan & Employment") {
            VStack(spacing: 0) {
                ApplicationDetailRow(
                    "Loan Type",
                    value: app.loanType.rawValue,
                    icon: app.loanType.symbol,
                    valueColor: app.loanType.themeColor
                )
                ApplicationDetailRow("Requested Amount", value: CurrencyFormatter.shared.format(app.requestedAmount), valueColor: LMSColors.brandNavy)
                ApplicationDetailRow("Tenure", value: borrowerData.tenure)
                ApplicationDetailRow("Purpose", value: borrowerData.loanPurpose)
                ApplicationDetailRow("Employment Type", value: borrowerData.employmentStatus)
                ApplicationDetailRow("Occupation", value: borrowerData.occupation)
                ApplicationDetailRow("Employer", value: borrowerData.employer)
                ApplicationDetailRow("Work Experience", value: borrowerData.workExperience)
                ApplicationDetailRow("Monthly Income", value: borrowerData.monthlyIncome)
                ApplicationDetailRow("Annual Income", value: borrowerData.annualIncome)
                ApplicationDetailRow("Existing EMIs", value: borrowerData.existingEMIs)
                ApplicationDetailRow("Credit Card Obligations", value: borrowerData.creditCardObligations)
                ApplicationDetailRow("Repayment", value: borrowerData.repaymentPreference)
                ApplicationDetailRow("Branch", value: app.branch, isLast: true)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        }
    }
    
    // MARK: - AI Audit
    
    private func aiAuditSection(_ app: LoanApplication) -> some View {
        Section("AI / OCR Validation") {
            if isRunningAIAudit {
                HStack(spacing: 12) {
                    ProgressView()
                        .tint(LMSColors.actionBlue)
                    Text(aiStatusText)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } else if aiAuditRun {
                Label("OCR Audit Completed", systemImage: "cpu.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LMSColors.emerald)
                
                ForEach(loanDocuments) { doc in
                    AIFindingRow(
                        type: doc.status == .rejectFlag ? .critical : (doc.status == .verified ? .success : .warning),
                        docName: doc.docType.rawValue,
                        desc: "\(doc.ocrStatus). \(doc.status.rawValue)."
                    )
                }
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Auto OCR Bureau Scans")
                            .font(.subheadline.weight(.semibold))
                        Text("Scans for blur, mismatches, and date validity.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Run Audit") {
                        runAIAudit()
                    }
                    .font(.caption.weight(.bold))
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                .padding(.vertical, 2)
            }
        }
    }
    
    // MARK: - Document Checklist
    
    private func documentChecklistSection(_ app: LoanApplication) -> some View {
        Section("Documents (\(loanDocuments.filter { $0.status == .verified }.count)/\(loanDocuments.count) verified)") {
            if loanDocuments.isEmpty {
                ContentUnavailableView(
                    "No Uploaded Documents",
                    systemImage: "doc.badge.questionmark",
                    description: Text("No borrower document records were found for this application or customer.")
                )
            } else {
                ForEach(loanDocuments) { doc in
                    OfficerDocumentReviewCard(
                        doc: doc,
                        borrowerName: app.borrowerName,
                        onPreview: { selectedDocForPreview = doc },
                        onAction: { showingActionSheetForDoc = doc }
                    )
                }
            }
        }
    }
    
    // MARK: - Timeline
    
    private func timelineSection(_ app: LoanApplication) -> some View {
        let timelineItems = viewModel.activityFeed.filter { $0.applicationId == app.applicationId }
        
        return Group {
            if !timelineItems.isEmpty {
                Section("Activity Timeline") {
                    ForEach(timelineItems) { item in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: item.eventType.symbol)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(item.eventType.themeColor)
                                .frame(width: 28, height: 28)
                                .background(item.eventType.themeColor.opacity(0.12), in: Circle())
                            
                            VStack(alignment: .leading, spacing: 3) {
                                Text(item.eventDescription)
                                    .font(.caption.weight(.medium))
                                
                                Text(RelativeDateFormatter.shared.relativeString(from: item.timestamp))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }
    
    // MARK: - Approval
    
    @ViewBuilder
    private func approvalSection(_ app: LoanApplication) -> some View {
        if shouldShowOfficerActions(for: app) {
            Section {
                approvalReadinessRow

                Button {
                    HapticsManager.triggerImpact(style: .heavy)
                    viewModel.sendForFinalApproval(applicationId: app.applicationId)
                    dismiss()
                } label: {
                    Label("Send for Approval", systemImage: "paperplane.circle.fill")
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!canSendForFinalApproval(app))
                .accessibilityHint(canSendForFinalApproval(app) ? "Sends the verified loan application to the manager module." : "Verify every uploaded document before sending this application to the manager.")

                if canRejectCompleteApplication(app) {
                    Button(role: .destructive) {
                        HapticsManager.triggerImpact(style: .medium)
                        applicationRejectReason = ""
                        showingApplicationRejectPrompt = true
                    } label: {
                        VStack(spacing: 3) {
                            Text("Reject Application")
                                .font(.body.weight(.semibold))
                            Text("Rejects the complete application")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                    }
                }

                TextField("Escalation reason for branch manager", text: $escalationReason, axis: .vertical)
                    .lineLimit(2...4)

                Button {
                    let reason = escalationReason.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !reason.isEmpty else {
                        escalationAlertMessage = "Add a short reason before escalating to your manager."
                        showingEscalationAlert = true
                        return
                    }
                    if viewModel.escalateApplication(applicationId: app.applicationId, reason: reason) {
                        HapticsManager.triggerNotification(type: .success)
                        dismiss()
                    } else {
                        escalationAlertMessage = "Could not escalate this application right now."
                        showingEscalationAlert = true
                    }
                } label: {
                    Text("Escalate to Branch Manager")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(Color.purple)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            }
            .alert("Escalation", isPresented: $showingEscalationAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(escalationAlertMessage)
            }
        }
    }

    private var approvalReadinessRow: some View {
        let verifiedCount = loanDocuments.filter { $0.status == .verified }.count
        let totalCount = loanDocuments.count

        return Label {
            Text(isReadyForFinalApproval ? "All documents verified. Ready for manager approval." : "Verify all documents before sending for approval.")
                .font(.caption.weight(.medium))
        } icon: {
            Image(systemName: isReadyForFinalApproval ? "checkmark.seal.fill" : "lock.fill")
        }
        .foregroundStyle(isReadyForFinalApproval ? LMSColors.emerald : .secondary)
        .badge("\(verifiedCount)/\(totalCount)")
    }
    
    // MARK: - Helpers

    private func shouldShowOfficerActions(for app: LoanApplication) -> Bool {
        switch app.status {
        case .approved, .rejected, .disbursed, .sentToManager, .finalApprovalPending:
            return false
        default:
            return true
        }
    }

    private func canSendForFinalApproval(_ app: LoanApplication) -> Bool {
        isReadyForFinalApproval && [.underReview, .verificationCompleted].contains(app.status)
    }

    private func canRejectCompleteApplication(_ app: LoanApplication) -> Bool {
        [.pending, .applied, .documentsPending, .documentsRejected, .underReview, .verificationCompleted].contains(app.status)
    }
    
    private func runAIAudit() {
        HapticsManager.triggerImpact(style: .medium)
        isRunningAIAudit = true
        aiStatusText = "Extracting document boundaries..."
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            aiStatusText = "Scanning against Bureau databases..."
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isRunningAIAudit = false
            aiAuditRun = true
            HapticsManager.triggerImpact(style: .heavy)
        }
    }
    
    private func cibilColor(for score: Int) -> Color {
        if score >= 750 { return LMSColors.emerald }
        if score >= CentralLoanRepository.shared.globalRules.minCibilScore { return LMSColors.amber }
        return LMSColors.coral
    }
}

// MARK: - Supporting Views

struct InfoCell: View {
    let label: String
    let val: String
    var color: Color = .primary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(LMSColors.textSecondary)
            Text(val)
                .font(.system(.footnote, design: .rounded).bold())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ApplicationDetailRow: View {
    let label: String
    let value: String
    var icon: String?
    var valueColor: Color
    var isLast: Bool

    init(_ label: String, value: String, icon: String? = nil, valueColor: Color = .primary, isLast: Bool = false) {
        self.label = label
        self.value = value
        self.icon = icon
        self.valueColor = valueColor
        self.isLast = isLast
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(label)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .frame(minWidth: 118, maxWidth: 142, alignment: .leading)

                Spacer(minLength: 8)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    if let icon {
                        Image(systemName: icon)
                            .font(.subheadline.weight(.semibold))
                    }

                    Text(displayValue)
                        .font(.subheadline.weight(value == "Not provided" ? .regular : .semibold))
                        .foregroundStyle(value == "Not provided" ? .secondary : valueColor)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.vertical, 11)

            if !isLast {
                Divider()
            }
        }
    }

    private var displayValue: String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Not provided" : value
    }
}

enum AIFindingsType {
    case success, warning, critical
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return LMSColors.emerald
        case .warning: return LMSColors.amber
        case .critical: return LMSColors.coral
        }
    }
}

struct AIFindingRow: View {
    let type: AIFindingsType
    let docName: String
    let desc: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: type.icon)
                .font(.caption)
                .foregroundStyle(type.color)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(docName)
                    .font(.caption.weight(.semibold))
                Text(desc)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct OfficerDocumentReviewCard: View {
    let doc: LoanDocument
    let borrowerName: String
    var onPreview: () -> Void
    var onAction: () -> Void

    private var statusLabel: String {
        doc.status.rawValue.replacingOccurrences(of: " ✓", with: "")
    }

    private var ocrTint: Color {
        doc.ocrStatus.localizedCaseInsensitiveContains("pending") ? LMSColors.amber : LMSColors.actionBlue
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 12) {
                Button(action: onPreview) {
                    ZStack(alignment: .bottomTrailing) {
                        OfficerDocumentThumb(doc: doc, borrowerName: borrowerName)
                            .frame(width: 58, height: 58)

                        Image(systemName: "eye.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 24, height: 24)
                            .background(.black.opacity(0.55), in: Circle())
                            .overlay(Circle().stroke(.white, lineWidth: 1.5))
                            .offset(x: 4, y: 4)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Preview \(doc.docType.rawValue)")

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(doc.docType.rawValue)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(LMSColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)

                        if doc.status == .verified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(LMSColors.emerald)
                                .accessibilityLabel("Verified")
                        }
                    }

                    Label(doc.uploadedDate?.formattedAsDDMMMYYYY() ?? "Date unavailable", systemImage: "calendar")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                Button(action: onAction) {
                    Image(systemName: doc.status == .verified ? "checkmark.circle.fill" : "ellipsis.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(doc.status == .verified ? LMSColors.emerald : LMSColors.actionBlue)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(doc.status == .verified ? "\(doc.docType.rawValue) verified" : "Review \(doc.docType.rawValue)")
            }

            if doc.status != .verified {
                HStack(spacing: 8) {
                    DocumentStatusChip(
                        title: statusLabel,
                        systemImage: "doc.badge.clock",
                        tint: doc.status.themeColor
                    )

                    Spacer(minLength: 0)
                }
                .padding(.leading, 70)
            }

            if let reason = doc.rejectionReason, !reason.isEmpty {
                Label(reason, systemImage: "exclamationmark.triangle.fill")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(LMSColors.coral)
                    .lineLimit(2)
                    .padding(.leading, 70)
            }
        }
        .padding(.vertical, 8)
    }
}

private struct DocumentStatusChip: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.system(.caption2, design: .rounded).weight(.semibold))
            .foregroundStyle(tint)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

private struct OfficerDocumentThumb: View {
    let doc: LoanDocument
    let borrowerName: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(doc.docType.iconColor.opacity(0.12))

            if let fileURL = doc.fileURL,
               fileURL.hasPrefix("data:image"),
               let image = imageFromDataURL(fileURL) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else if let fileURL = doc.fileURL,
                      let url = URL(string: fileURL),
                      url.scheme?.hasPrefix("http") == true,
                      url.pathExtension.lowercased() != "pdf" {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        Image(systemName: doc.docType.symbol)
                            .font(.title2.weight(.semibold))
                            .foregroundStyle(doc.docType.iconColor)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            } else {
                Image(systemName: doc.docType.symbol)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(doc.docType.iconColor)
            }
        }
        .clipped()
    }

    private func imageFromDataURL(_ dataURL: String) -> UIImage? {
        guard let commaIndex = dataURL.firstIndex(of: ",") else { return nil }
        let payload = String(dataURL[dataURL.index(after: commaIndex)...])
        guard let data = Data(base64Encoded: payload) else { return nil }
        return UIImage(data: data)
    }
}

struct DocumentChecklistItemRow: View {
    let doc: LoanDocument
    var onPreview: () -> Void
    var onAction: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: onAction) {
                ZStack {
                    Circle()
                        .stroke(doc.status.themeColor, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if doc.status == .verified {
                        Circle()
                            .fill(LMSColors.emerald)
                            .frame(width: 14, height: 14)
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                    } else if doc.status == .rejectFlag {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(LMSColors.coral)
                    } else if doc.status == .pending {
                        Image(systemName: "questionmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(LMSColors.amber)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 3) {
                Text(doc.docType.rawValue)
                    .font(.footnote.weight(.semibold))
                
                if let reason = doc.rejectionReason {
                    Text("Correction: \(reason)")
                        .font(.system(size: 9))
                        .foregroundStyle(LMSColors.coral)
                        .lineLimit(1)
                } else {
                    Text(doc.status.rawValue)
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onPreview) {
                HStack(spacing: 4) {
                    Image(systemName: doc.docType.symbol)
                        .font(.caption)
                    Text("Preview")
                        .font(.caption2.weight(.bold))
                }
                .foregroundStyle(LMSColors.actionBlue)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(LMSColors.actionBlue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(PlainButtonStyle())
            
            Button(action: onAction) {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.secondary.opacity(0.7))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
    }
}
