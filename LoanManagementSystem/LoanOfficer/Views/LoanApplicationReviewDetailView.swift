import SwiftUI

struct LoanApplicationReviewDetailView: View {
    typealias LoanApplication = OfficerLoanApplication
    let applicationId: String
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @Environment(\.dismiss) var dismiss
    
    // AI OCR Simulation States
    @State private var isRunningAIAudit = false
    @State private var aiAuditRun = false
    @State private var aiStatusText = ""
    
    // Document review action states
    @State private var selectedDocForPreview: LoanDocument? = nil
    @State private var showingActionSheetForDoc: LoanDocument? = nil
    @State private var showingRejectionTextAlert = false
    @State private var rejectionText = ""
    @State private var activeDocForRejection: LoanDocument? = nil
    @State private var documentNotesState: [UUID: String] = [:]
    
    // Find dynamic application details
    var app: LoanApplication? {
        viewModel.applications.first { $0.applicationId == applicationId }
    }
    
    // Seed default documents if list is empty, to ensure rich checklist contents
    var loanDocuments: [LoanDocument] {
        guard let app = app else { return [] }
        if app.documents.isEmpty {
            // Generate standard document list according to LoanType
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
    
    // Fetch mock borrower/employer details
    var borrowerData: BorrowerDetails {
        details(for: app?.borrowerName ?? "")
    }
    
    // Check if final approval is enabled (all documents must be verified)
    var isReadyForFinalApproval: Bool {
        guard !loanDocuments.isEmpty else { return false }
        return loanDocuments.allSatisfy { $0.status == .verified }
    }
    
    var body: some View {
        NavigationStack {
            if let currentApp = app {
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // 1. APPLICATION HEADER
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(currentApp.borrowerName)
                                        .font(.system(.title3, design: .rounded).bold())
                                    Text("Application ID: \(currentApp.applicationId)")
                                        .font(.system(.caption, design: .rounded).weight(.semibold))
                                        .foregroundStyle(LMSColors.textSecondary)
                                }
                                
                                Spacer()
                                
                                // Status Indicator Pill
                                Text(currentApp.status.rawValue)
                                    .font(.system(.caption, design: .rounded).bold())
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(currentApp.status.themeColor)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                            
                            // Progress bar
                            let verifiedCount = loanDocuments.filter { $0.status == .verified }.count
                            let totalDocs = loanDocuments.count
                            let completionPct = totalDocs > 0 ? Int((Double(verifiedCount) / Double(totalDocs)) * 100) : 0
                            
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Verification Progress")
                                        .font(.system(.caption2, design: .rounded).bold())
                                        .foregroundStyle(LMSColors.textSecondary)
                                    Spacer()
                                    Text("\(completionPct)% Completed (\(verifiedCount)/\(totalDocs) Docs)")
                                        .font(.system(.caption2, design: .rounded).bold())
                                        .foregroundStyle(AppTheme.actionBlue)
                                }
                                
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(LMSColors.textPrimary.opacity(0.06))
                                            .frame(height: 6)
                                        
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(AppTheme.actionBlue)
                                            .frame(width: geo.size.width * CGFloat(Double(completionPct) / 100.0), height: 6)
                                    }
                                }
                                .frame(height: 6)
                            }
                            .padding(.top, 4)
                        }
                        .padding(16)
                        .background(AppTheme.neutralSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, 16)
                        
                        // 2. BORROWER DETAILS GRID
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Borrower Information")
                                .font(.system(.subheadline, design: .rounded).bold())
                                .foregroundStyle(LMSColors.textPrimary)
                                .padding(.horizontal, 16)
                            
                            VStack(spacing: 12) {
                                // Sub-section: Personal Info
                                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                                    GridRow {
                                        InfoCell(label: "DATE OF BIRTH", val: borrowerData.dob)
                                        InfoCell(label: "GENDER", val: borrowerData.gender)
                                    }
                                    GridRow {
                                        InfoCell(label: "PAN NUMBER", val: borrowerData.pan)
                                        InfoCell(label: "CIBIL SCORE", val: "\(currentApp.cibilScore ?? 720)", color: cibilColor(for: currentApp.cibilScore ?? 720))
                                    }
                                    GridRow {
                                        InfoCell(label: "EMAIL ADDRESS", val: borrowerData.email)
                                        InfoCell(label: "PHONE NUMBER", val: borrowerData.phone)
                                    }
                                }
                                
                                Divider()
                                
                                // Sub-section: Loan requested
                                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                                    GridRow {
                                        InfoCell(label: "LOAN REQUESTED", val: currentApp.loanType.rawValue, color: currentApp.loanType.themeColor)
                                        InfoCell(label: "REQUESTED AMOUNT", val: CurrencyFormatter.shared.format(currentApp.requestedAmount))
                                    }
                                }
                                
                                Divider()
                                
                                // Sub-section: Income/Employment details
                                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                                    GridRow {
                                        InfoCell(label: "EMPLOYER NAME", val: borrowerData.employer)
                                        InfoCell(label: "MONTHLY INCOME", val: borrowerData.monthlyIncome)
                                    }
                                    GridRow {
                                        InfoCell(label: "EMPLOYMENT STATUS", val: borrowerData.employmentStatus)
                                        InfoCell(label: "BRANCH DESIGNATION", val: currentApp.branch)
                                    }
                                }
                            }
                            .padding(16)
                            .background(AppTheme.neutralSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 16)
                        }
                        
                        // 3. AI OCR AUTO-VALIDATION PANEL
                        VStack(alignment: .leading, spacing: 10) {
                            Text("AI/OCR Auto-Validation Audit")
                                .font(.system(.subheadline, design: .rounded).bold())
                                .foregroundStyle(LMSColors.textPrimary)
                                .padding(.horizontal, 16)
                            
                            VStack(spacing: 12) {
                                if isRunningAIAudit {
                                    HStack(spacing: 12) {
                                        ProgressView()
                                            .tint(AppTheme.actionBlue)
                                        Text(aiStatusText)
                                            .font(.system(.caption, design: .rounded).bold())
                                            .foregroundStyle(LMSColors.textSecondary)
                                    }
                                    .padding(.vertical, 8)
                                } else if aiAuditRun {
                                    // Show list of AI scanner findings
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Image(systemName: "cpu.fill")
                                                .foregroundStyle(AppTheme.successGreen)
                                            Text("OCR Audit Completed")
                                                .font(.system(.caption, design: .rounded).bold())
                                                .foregroundStyle(AppTheme.successGreen)
                                            Spacer()
                                        }
                                        
                                        Divider()
                                        
                                        // Specific dynamic warnings based on borrower
                                        AIFindingRow(
                                            type: .warning,
                                            docName: "Aadhaar Card",
                                            desc: "Aadhaar image clarity threshold: 94%. Checked successfully."
                                        )
                                        
                                        if currentApp.borrowerName == "Rohit Mehta" {
                                            AIFindingRow(
                                                type: .critical,
                                                docName: "Salary Slip",
                                                desc: "Blurry document detected (42% readability). Verify manually."
                                            )
                                        }
                                        
                                        if currentApp.borrowerName == "Anita Desai" {
                                            AIFindingRow(
                                                type: .warning,
                                                docName: "PAN Card",
                                                desc: "Name Mismatch detected: 'Anita D.' on document does not match 'Anita Desai' exactly."
                                            )
                                        }
                                        
                                        AIFindingRow(
                                            type: .success,
                                            docName: "All Verification Files",
                                            desc: "No expired document records detected."
                                        )
                                    }
                                } else {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Run Auto OCR bureau scans")
                                                .font(.system(.caption, design: .rounded).bold())
                                            Text("Scans files for blur, mismatches, and date validity.")
                                                .font(.system(.caption2, design: .rounded))
                                                .foregroundStyle(LMSColors.textSecondary)
                                        }
                                        Spacer()
                                        
                                        Button(action: runMockAIAudit) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "cpu")
                                                Text("Run Audit")
                                            }
                                            .font(.system(.caption, design: .rounded).bold())
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 8)
                                            .background(AppTheme.actionBlue)
                                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                        }
                                    }
                                }
                            }
                            .padding(14)
                            .background(AppTheme.neutralSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .padding(.horizontal, 16)
                        }
                        
                        // 4. DOCUMENT CHECKLIST SECTION
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Document Checklist")
                                .font(.system(.subheadline, design: .rounded).bold())
                                .foregroundStyle(LMSColors.textPrimary)
                                .padding(.horizontal, 16)
                            
                            VStack(spacing: 0) {
                                ForEach(loanDocuments) { doc in
                                    DocumentChecklistItemRow(doc: doc) {
                                        // Tap opens preview detail directly
                                        selectedDocForPreview = doc
                                    } onAction: {
                                        showingActionSheetForDoc = doc
                                    }
                                    
                                    if doc.id != loanDocuments.last?.id {
                                        Divider()
                                            .padding(.leading, 50)
                                    }
                                }
                            }
                            .background(AppTheme.neutralSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .shadow(color: .black.opacity(0.02), radius: 5, x: 0, y: 3)
                            .padding(.horizontal, 16)
                        }
                        
                        // 5. ACTIVITY TIMELINE SECTION
                        let timelineItems = viewModel.activityFeed.filter { $0.applicationId == currentApp.applicationId }
                        if !timelineItems.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Verification Activity Timeline")
                                    .font(.system(.subheadline, design: .rounded).bold())
                                    .foregroundStyle(LMSColors.textPrimary)
                                    .padding(.horizontal, 16)
                                
                                VStack(alignment: .leading, spacing: 16) {
                                    ForEach(timelineItems) { item in
                                        HStack(alignment: .top, spacing: 12) {
                                            // Symbol circle
                                            ZStack {
                                                Circle()
                                                    .fill(item.eventType.themeColor.opacity(0.12))
                                                    .frame(width: 28, height: 28)
                                                Image(systemName: item.eventType.symbol)
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundStyle(item.eventType.themeColor)
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(item.eventDescription)
                                                    .font(.system(.caption, design: .rounded).bold())
                                                    .foregroundStyle(LMSColors.textPrimary)
                                                
                                                Text(RelativeDateFormatter.shared.relativeString(from: item.timestamp))
                                                    .font(.system(.caption2, design: .rounded))
                                                    .foregroundStyle(LMSColors.textSecondary)
                                            }
                                        }
                                    }
                                }
                                .padding(16)
                                .background(AppTheme.neutralSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .padding(.horizontal, 16)
                            }
                        }
                        
                        // 6. BOTTOM SUBMISSION STATE BAR
                        VStack(spacing: 8) {
                            if isReadyForFinalApproval {
                                Button(action: {
                                    HapticsManager.triggerImpact(style: .heavy)
                                    viewModel.sendForFinalApproval(applicationId: currentApp.applicationId)
                                    dismiss()
                                }) {
                                    HStack {
                                        Image(systemName: "paperplane.fill")
                                        Text("Send for Final Approval")
                                            .font(.system(.subheadline, design: .rounded).bold())
                                    }
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(AppTheme.successGreen)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            } else {
                                VStack(spacing: 8) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "exclamationmark.circle.fill")
                                            .foregroundStyle(AppTheme.criticalRed)
                                        Text("Verification Incomplete: Resolve missing or rejected documents.")
                                            .font(.system(.caption2, design: .rounded).bold())
                                            .foregroundStyle(AppTheme.criticalRed)
                                    }
                                    
                                    Button(action: {}) {
                                        HStack {
                                            Image(systemName: "lock.fill")
                                            Text("Send for Final Approval")
                                                .font(.system(.subheadline, design: .rounded).bold())
                                        }
                                        .foregroundStyle(.white.opacity(0.6))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(LMSColors.textSecondary.opacity(0.3))
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                    }
                                    .disabled(true)
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        
                        Spacer()
                            .frame(height: 12)
                    }
                    .padding(.vertical, 16)
                }
                .navigationTitle("Verify Application")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back") { dismiss() }
                    }
                }
                .sheet(item: $selectedDocForPreview) { doc in
                    DocumentReviewDetailView(
                        item: DocumentQueueItem(
                            id: doc.id,
                            borrowerName: currentApp.borrowerName,
                            docType: doc.docType,
                            status: doc.status,
                            submittedDate: Date(),
                            applicationId: currentApp.applicationId
                        ),
                        viewModel: viewModel
                    )
                }
                .confirmationDialog("Verification Actions", isPresented: Binding(
                    get: { showingActionSheetForDoc != nil },
                    set: { if !$0 { showingActionSheetForDoc = nil } }
                ), titleVisibility: .visible) {
                    if let doc = showingActionSheetForDoc {
                        Button("Verify Document") {
                            HapticsManager.triggerImpact(style: .medium)
                            viewModel.updateDocumentStatus(applicationId: currentApp.applicationId, docId: doc.id, newStatus: .verified)
                        }
                        
                        Button("Flag for Re-upload / Reject", role: .destructive) {
                            activeDocForRejection = doc
                            showingRejectionTextAlert = true
                        }
                        
                        Button("Mark as Missing") {
                            HapticsManager.triggerImpact(style: .medium)
                            viewModel.updateDocumentStatus(
                                applicationId: currentApp.applicationId,
                                docId: doc.id,
                                newStatus: .pending,
                                rejectionReason: "Required document is missing."
                            )
                        }
                        
                        Button("Cancel", role: .cancel) {}
                    }
                } message: {
                    if let doc = showingActionSheetForDoc {
                        Text("Select verification status update for \(doc.docType.rawValue).")
                    }
                }
                .alert("Flag Document", isPresented: $showingRejectionTextAlert) {
                    TextField("Reason (e.g. Blurry photo, blurred name)", text: $rejectionText)
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
            } else {
                ContentUnavailableView("Application Not Found", systemImage: "questionmark.circle")
            }
        }
    }
    
    // AI OCR scans simulation
    private func runMockAIAudit() {
        HapticsManager.triggerImpact(style: .medium)
        isRunningAIAudit = true
        aiStatusText = "Extracting document boundaries..."
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            aiStatusText = "Scanning details against Bureau record databases..."
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            isRunningAIAudit = false
            aiAuditRun = true
            HapticsManager.triggerImpact(style: .heavy)
        }
    }
    
    private func cibilColor(for score: Int) -> Color {
        if score >= 750 { return AppTheme.successGreen }
        if score >= 650 { return AppTheme.warningAmber }
        return AppTheme.criticalRed
    }
}

// Sub-components

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
    case success
    case warning
    case critical
    
    var icon: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .critical: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .success: return AppTheme.successGreen
        case .warning: return AppTheme.warningAmber
        case .critical: return AppTheme.criticalRed
        }
    }
}

struct AIFindingRow: View {
    let type: AIFindingsType
    let docName: String
    let desc: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: type.icon)
                .font(LMSFont.caption)
                .foregroundStyle(type.color)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(docName)
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)
                Text(desc)
                    .font(.system(size: 9))
                    .foregroundStyle(LMSColors.textSecondary)
            }
        }
    }
}

struct DocumentChecklistItemRow: View {
    let doc: LoanDocument
    var onPreview: () -> Void
    var onAction: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkmark button status indicator
            Button(action: onAction) {
                ZStack {
                    Circle()
                        .stroke(doc.status.themeColor, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if doc.status == .verified {
                        Circle()
                            .fill(AppTheme.successGreen)
                            .frame(width: 14, height: 14)
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(.white)
                    } else if doc.status == .rejectFlag {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(AppTheme.criticalRed)
                    } else if doc.status == .pending {
                        Image(systemName: "questionmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundStyle(AppTheme.warningAmber)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Document title and notes
            VStack(alignment: .leading, spacing: 3) {
                Text(doc.docType.rawValue)
                    .font(.system(.footnote, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)
                
                if let reason = doc.rejectionReason {
                    Text("Correction: \(reason)")
                        .font(.system(size: 9))
                        .foregroundStyle(AppTheme.criticalRed)
                        .lineLimit(1)
                } else {
                    Text(doc.status.rawValue)
                        .font(.system(size: 9))
                        .foregroundStyle(LMSColors.textSecondary)
                }
            }
            
            Spacer()
            
            // Preview scan thumbnail
            Button(action: onPreview) {
                HStack(spacing: 4) {
                    Image(systemName: doc.docType.symbol)
                        .font(LMSFont.caption)
                    Text("Preview")
                        .font(.system(.caption2, design: .rounded).bold())
                }
                .foregroundStyle(AppTheme.actionBlue)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(AppTheme.actionBlue.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Edit status actions button
            Button(action: onAction) {
                Image(systemName: "ellipsis.circle.fill")
                    .font(LMSFont.title3)
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

#Preview {
    NavigationStack {
        LoanApplicationReviewDetailView(
            applicationId: PreviewSupport.sampleLoanApplicationId,
            viewModel: PreviewSupport.loanOfficerViewModel
        )
    }
}
