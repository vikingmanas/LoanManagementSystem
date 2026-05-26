import SwiftUI

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
    @State private var showingRejectionTextAlert = false
    @State private var rejectionText = ""
    @State private var activeDocForRejection: LoanDocument? = nil
    
    var app: LoanApplication? {
        viewModel.applications.first { $0.applicationId == applicationId }
    }
    
    var loanDocuments: [LoanDocument] {
        guard let app = app else { return [] }
        if app.documents.isEmpty {
            switch app.loanType {
            case .home:
                return [
                    LoanDocument(id: UUID(), docType: .aadhaar, status: .uploaded),
                    LoanDocument(id: UUID(), docType: .pan, status: .verified),
                    LoanDocument(id: UUID(), docType: .salarySlip, status: .uploaded),
                    LoanDocument(id: UUID(), docType: .propertyDoc, status: .pending)
                ]
            case .business:
                return [
                    LoanDocument(id: UUID(), docType: .aadhaar, status: .verified),
                    LoanDocument(id: UUID(), docType: .pan, status: .verified),
                    LoanDocument(id: UUID(), docType: .gstCertificate, status: .uploaded),
                    LoanDocument(id: UUID(), docType: .incomeTaxReturn, status: .uploaded)
                ]
            case .education:
                return [
                    LoanDocument(id: UUID(), docType: .aadhaar, status: .verified),
                    LoanDocument(id: UUID(), docType: .pan, status: .verified),
                    LoanDocument(id: UUID(), docType: .admissionLetter, status: .uploaded),
                    LoanDocument(id: UUID(), docType: .bankStatement, status: .uploaded)
                ]
            default:
                return [
                    LoanDocument(id: UUID(), docType: .aadhaar, status: .uploaded),
                    LoanDocument(id: UUID(), docType: .pan, status: .verified),
                    LoanDocument(id: UUID(), docType: .salarySlip, status: .uploaded),
                    LoanDocument(id: UUID(), docType: .bankStatement, status: .uploaded)
                ]
            }
        }
        return app.documents
    }
    
    var borrowerData: BorrowerDetails {
        details(for: app?.borrowerName ?? "")
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
                        applicationId: currentApp.applicationId
                    ),
                    viewModel: viewModel,
                    isPresentedModally: true
                )
            }
        }
        .alert("Flag Document", isPresented: $showingRejectionTextAlert) {
            TextField("Reason (e.g. Blurry photo)", text: $rejectionText)
            Button("Submit", role: .destructive) {
                if let doc = activeDocForRejection {
                    viewModel.updateDocumentStatus(
                        applicationId: currentApp.applicationId,
                        docId: doc.id,
                        newStatus: .rejectFlag,
                        rejectionReason: rejectionText.isEmpty ? "Incorrect copy. Please re-upload." : rejectionText
                    )
                }
                rejectionText = ""
                activeDocForRejection = nil
            }
            Button("Cancel", role: .cancel) {
                rejectionText = ""
                activeDocForRejection = nil
            }
        } message: {
            Text("Provide correction guidelines to send to borrower.")
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
                        title: "Flag for Re-upload",
                        icon: "arrow.triangle.2.circlepath",
                        tint: LMSColors.coral
                    ) {
                        activeDocForRejection = doc
                        showingActionSheetForDoc = nil
                        showingRejectionTextAlert = true
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
                Text("\(app.cibilScore ?? 720)")
                    .fontWeight(.bold)
                    .foregroundStyle(cibilColor(for: app.cibilScore ?? 720))
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
                
                AIFindingRow(
                    type: .warning,
                    docName: "Aadhaar Card",
                    desc: "Image clarity: 94%. Passed."
                )
                
                if app.borrowerName == "Rohit Mehta" {
                    AIFindingRow(
                        type: .critical,
                        docName: "Salary Slip",
                        desc: "Blurry document (42% readability). Manual review needed."
                    )
                }
                
                if app.borrowerName == "Anita Desai" {
                    AIFindingRow(
                        type: .warning,
                        docName: "PAN Card",
                        desc: "Name mismatch: 'Anita D.' vs 'Anita Desai'."
                    )
                }
                
                AIFindingRow(
                    type: .success,
                    docName: "All Files",
                    desc: "No expired document records."
                )
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
                        runMockAIAudit()
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
            ForEach(loanDocuments) { doc in
                HStack(spacing: 12) {
                    Image(systemName: doc.status == .verified ? "checkmark.circle.fill" : (doc.status == .rejectFlag ? "xmark.circle.fill" : "circle"))
                        .foregroundStyle(doc.status.themeColor)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text(doc.docType.rawValue)
                            .font(.body.weight(.medium))
                        
                        if let reason = doc.rejectionReason {
                            Text(reason)
                                .font(.caption)
                                .foregroundStyle(LMSColors.coral)
                                .lineLimit(1)
                        } else {
                            Text(doc.status.rawValue)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    Button {
                        selectedDocForPreview = doc
                    } label: {
                        Image(systemName: "eye")
                            .font(.body)
                            .foregroundStyle(LMSColors.actionBlue)
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        showingActionSheetForDoc = doc
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.vertical, 4)
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
    
    private func runMockAIAudit() {
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
        if score >= 650 { return LMSColors.amber }
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

// Mock Borrower details mapping helper
struct BorrowerDetails {
    let dob: String
    let gender: String
    let pan: String
    let email: String
    let phone: String
    let employer: String
    let monthlyIncome: String
    let employmentStatus: String
}

func details(for borrowerName: String) -> BorrowerDetails {
    switch borrowerName {
    case "Priya Sharma":
        return BorrowerDetails(dob: "12 Dec 1994", gender: "Female", pan: "BVDPS8942A", email: "priya.sharma@techcorp.in", phone: "+91 98765 43210", employer: "Tech Corp India", monthlyIncome: "₹ 1,25,000", employmentStatus: "Salaried")
    case "Rohit Mehta":
        return BorrowerDetails(dob: "05 Jun 1988", gender: "Male", pan: "CPYRM9140B", email: "rohit.mehta@crown.co", phone: "+91 99123 45678", employer: "Crown Industries", monthlyIncome: "₹ 95,000", employmentStatus: "Salaried")
    case "Anita Desai":
        return BorrowerDetails(dob: "22 Aug 1980", gender: "Female", pan: "DKLPA2938C", email: "anita@vibrantretail.com", phone: "+91 98111 22233", employer: "Vibrant Retailers", monthlyIncome: "₹ 2,40,000", employmentStatus: "Self-Employed (Business)")
    case "Kavya Nair":
        return BorrowerDetails(dob: "14 Feb 2003", gender: "Female", pan: "FRVPN4830D", email: "kavya.nair@student.edu", phone: "+91 97444 88899", employer: "N/A (Co-Applicant: Rajesh Nair)", monthlyIncome: "₹ 1,80,000 (Co-Applicant)", employmentStatus: "Student / Co-Applicant Salaried")
    default:
        return BorrowerDetails(dob: "18 Oct 1991", gender: "Male", pan: "AZYPM9876Z", email: "borrower.service@bank.com", phone: "+91 98000 11122", employer: "Global Enterprises", monthlyIncome: "₹ 1,10,000", employmentStatus: "Salaried")
    }
}
