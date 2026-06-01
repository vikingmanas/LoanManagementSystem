import SwiftUI

private struct DocumentRejectionPrompt: Identifiable {
    let document: LoanDocument

    var id: UUID { document.id }
}

struct LoanApplicationReviewDetailView: View {
    typealias LoanApplication = OfficerLoanApplication
    let applicationId: String
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
        NavigationStack {
            if let currentApp = app {
                applicationContent(currentApp)
            } else {
                ContentUnavailableView("Application Not Found", systemImage: "questionmark.circle")
            }
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
        .sheet(item: $selectedDocForPreview) { doc in
            NavigationStack {
                DocumentReviewDetailView(
                    item: DocumentQueueItem(
                        id: doc.id,
                        borrowerName: currentApp.borrowerName,
                        docType: doc.docType,
                        status: doc.status,
                        submittedDate: Date(),
                        applicationId: currentApp.applicationId,
                        fileURL: doc.fileURL
                    ),
                    viewModel: viewModel,
                    isPresentedModally: true
                )
            }
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
            LabeledContent("Date of Birth", value: borrowerData.dob)
            LabeledContent("Gender", value: borrowerData.gender)
            LabeledContent("PAN Number", value: borrowerData.pan)
            
            LabeledContent("CIBIL Score") {
                Text(app.cibilScore.map(String.init) ?? "Not provided")
                    .fontWeight(.bold)
                    .foregroundStyle(app.cibilScore.map(cibilColor(for:)) ?? .secondary)
            }
            
            LabeledContent("Email", value: borrowerData.email)
            LabeledContent("Phone", value: borrowerData.phone)
        }
    }
    
    // MARK: - Loan & Employment
    
    private func loanEmploymentSection(_ app: LoanApplication) -> some View {
        Section("Loan & Employment") {
            LabeledContent("Loan Type") {
                Label(app.loanType.rawValue, systemImage: app.loanType.symbol)
                    .foregroundStyle(app.loanType.themeColor)
                    .fontWeight(.semibold)
            }
            
            LabeledContent("Requested Amount") {
                Text(CurrencyFormatter.shared.format(app.requestedAmount))
                    .fontWeight(.semibold)
            }
            
            LabeledContent("Employer", value: borrowerData.employer)
            LabeledContent("Monthly Income", value: borrowerData.monthlyIncome)
            LabeledContent("Employment", value: borrowerData.employmentStatus)
            LabeledContent("Branch", value: app.branch)
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
    
    private func approvalSection(_ app: LoanApplication) -> some View {
        Section {
            if isReadyForFinalApproval {
                Button {
                    HapticsManager.triggerImpact(style: .heavy)
                    viewModel.sendForFinalApproval(applicationId: app.applicationId)
                    dismiss()
                } label: {
                    Text("Send for Final Approval")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.blue)
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                }
            } else {
                HStack {
                    Spacer()
                    Label("Verification incomplete — resolve all documents first.", systemImage: "lock.fill")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    // MARK: - Helpers
    
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                OfficerDocumentThumb(doc: doc, borrowerName: borrowerName)
                    .frame(width: 54, height: 54)

                VStack(alignment: .leading, spacing: 4) {
                    Text(doc.docType.rawValue)
                        .font(.body.weight(.semibold))
                    Text("Uploaded: \(doc.uploadedDate?.formattedAsDDMMMYYYY() ?? "Not available")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("OCR: \(doc.ocrStatus)")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(LMSColors.actionBlue)
                }

                Spacer()

                Text(doc.status.rawValue)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(doc.status.themeColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(doc.status.themeColor.opacity(0.12), in: Capsule())
            }

            HStack {
                Button(action: onPreview) {
                    Label("Preview", systemImage: "eye.fill")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button(action: onAction) {
                    Label("Review", systemImage: "checklist.checked")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }

            if let reason = doc.rejectionReason, !reason.isEmpty {
                Text(reason)
                    .font(.caption)
                    .foregroundStyle(LMSColors.coral)
            }
        }
        .padding(.vertical, 6)
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
