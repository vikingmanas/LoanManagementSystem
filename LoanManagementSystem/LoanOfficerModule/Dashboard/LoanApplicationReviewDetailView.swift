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
    
    // UI Expand States
    @State private var isBorrowerInfoExpanded = false
    @State private var isTimelineExpanded = false
    
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
        if let currentApp = app {
            List {
                // 1. HEADER: APPLICATION HEALTH
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(currentApp.borrowerName)
                                .font(.title3.bold())
                            Text(currentApp.applicationId)
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Image(systemName: "shield.lefthalf.filled")
                                Text("Risk: Low")
                            }
                            .font(.caption.bold())
                            .foregroundColor(AppTheme.successGreen)
                            .padding(.top, 4)
                        }
                        
                        Spacer()
                        
                        // Verification Progress Ring
                        let verifiedCount = loanDocuments.filter { $0.status == .verified }.count
                        let totalDocs = loanDocuments.count
                        let completionPct = totalDocs > 0 ? Double(verifiedCount) / Double(totalDocs) : 0.0
                        
                        VStack {
                            ZStack {
                                Circle()
                                    .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                                Circle()
                                    .trim(from: 0, to: completionPct)
                                    .stroke(AppTheme.actionBlue, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                    .rotationEffect(.degrees(-90))
                                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: completionPct)
                                
                                Text("\(Int(completionPct * 100))%")
                                    .font(.caption.bold())
                                    .contentTransition(.numericText())
                            }
                            .frame(width: 50, height: 50)
                            
                            Text(currentApp.status.rawValue)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(currentApp.status.themeColor)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                // 2. AI OCR AUDIT
                Section {
                    if isRunningAIAudit {
                        HStack(spacing: 12) {
                            ProgressView()
                                .tint(AppTheme.actionBlue)
                            Text(aiStatusText)
                                .font(.caption.bold())
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    } else if aiAuditRun {
                        AIFindingRow(type: .warning, docName: "Aadhaar Card", desc: "Aadhaar image clarity threshold: 94%. Checked successfully.")
                        
                        if currentApp.borrowerName == "Rohit Mehta" {
                            AIFindingRow(type: .critical, docName: "Salary Slip", desc: "Blurry document detected (42% readability). Verify manually.")
                        }
                        
                        if currentApp.borrowerName == "Anita Desai" {
                            AIFindingRow(type: .warning, docName: "PAN Card", desc: "Name Mismatch detected: 'Anita D.' vs 'Anita Desai'.")
                        }
                        
                        AIFindingRow(type: .success, docName: "All Files", desc: "No expired document records detected.")
                    } else {
                        Button {
                            runMockAIAudit()
                        } label: {
                            HStack {
                                Image(systemName: "cpu")
                                VStack(alignment: .leading) {
                                    Text("Run Auto OCR Scans")
                                        .font(.callout.bold())
                                    Text("Scan for blur, mismatches & validity")
                                        .font(.caption)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                            }
                        }
                        .foregroundStyle(AppTheme.actionBlue)
                    }
                } header: {
                    Text("AI Validation Audit")
                } footer: {
                    if !aiAuditRun && !isRunningAIAudit {
                        Text("Running AI checks may take a few seconds to parse bureau databases.")
                    }
                }
                
                // 3. DOCUMENT VERIFICATION CENTER
                let pendingDocs = loanDocuments.filter { $0.status != .verified }
                if !pendingDocs.isEmpty {
                    Section {
                        ForEach(pendingDocs) { doc in
                            DocumentRowView(doc: doc, currentApp: currentApp, viewModel: viewModel) {
                                selectedDocForPreview = doc
                            } onFlag: {
                                activeDocForRejection = doc
                                showingRejectionTextAlert = true
                            }
                        }
                    } header: {
                        Text("Action Required")
                    }
                }
                
                let verifiedDocs = loanDocuments.filter { $0.status == .verified }
                if !verifiedDocs.isEmpty {
                    Section {
                        ForEach(verifiedDocs) { doc in
                            DocumentRowView(doc: doc, currentApp: currentApp, viewModel: viewModel) {
                                selectedDocForPreview = doc
                            } onFlag: {
                                activeDocForRejection = doc
                                showingRejectionTextAlert = true
                            }
                        }
                    } header: {
                        Text("Verified Documents")
                    }
                }
                
                // 4. BORROWER PROFILE (Collapsible)
                Section {
                    DisclosureGroup(isExpanded: $isBorrowerInfoExpanded) {
                        LabeledContent("Date of Birth", value: borrowerData.dob)
                        LabeledContent("Gender", value: borrowerData.gender)
                        LabeledContent("PAN Number") {
                            Text(borrowerData.pan).monospaced()
                        }
                        LabeledContent("CIBIL Score") {
                            Text("\(currentApp.cibilScore ?? 720)")
                                .bold()
                                .foregroundColor(cibilColor(for: currentApp.cibilScore ?? 720))
                        }
                        LabeledContent("Phone", value: borrowerData.phone)
                        LabeledContent("Email") {
                            Text(borrowerData.email)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        LabeledContent("Employer", value: borrowerData.employer)
                        LabeledContent("Monthly Income", value: borrowerData.monthlyIncome)
                    } label: {
                        Label("Borrower Details", systemImage: "person.text.rectangle")
                            .font(.headline)
                    }
                }
                
                // 5. TIMELINE
                let timelineItems = viewModel.activityFeed.filter { $0.applicationId == currentApp.applicationId }
                if !timelineItems.isEmpty {
                    Section {
                        DisclosureGroup(isExpanded: $isTimelineExpanded) {
                            ForEach(timelineItems) { item in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: item.eventType.symbol)
                                        .font(.caption)
                                        .foregroundColor(item.eventType.themeColor)
                                        .frame(width: 20)
                                        .padding(.top, 4)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.eventDescription)
                                            .font(.caption.bold())
                                            .foregroundColor(.primary)
                                        Text(RelativeDateFormatter.shared.relativeString(from: item.timestamp))
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        } label: {
                            Label("Activity Timeline", systemImage: "clock.arrow.circlepath")
                                .font(.headline)
                        }
                    }
                }
                
                // Spacer for bottom bar
                Spacer().frame(height: 60).listRowBackground(Color.clear)
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Verify Application")
            .navigationBarTitleDisplayMode(.inline)

            .safeAreaInset(edge: .bottom) {
                // 6. STICKY BOTTOM BAR
                VStack(spacing: 8) {
                    if isReadyForFinalApproval {
                        Button(action: {
                            HapticsManager.triggerImpact(style: .heavy)
                            viewModel.sendForFinalApproval(applicationId: currentApp.applicationId)
                            dismiss()
                        }) {
                            Label("Send for Final Approval", systemImage: "paperplane.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppTheme.successGreen)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                    } else {
                        Button(action: {}) {
                            Label("Resolve Issues to Approve", systemImage: "lock.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.secondary.opacity(0.2))
                                .foregroundColor(.secondary)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .disabled(true)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
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
        } else {
            ContentUnavailableView("Application Not Found", systemImage: "questionmark.circle")
        }
    }
    
    // AI OCR scans simulation
    private func runMockAIAudit() {
        HapticsManager.triggerImpact(style: .medium)
        isRunningAIAudit = true
        aiStatusText = "Extracting document boundaries..."
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            aiStatusText = "Scanning details against Bureau records..."
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

// MARK: - Subcomponents

struct DocumentRowView: View {
    let doc: LoanDocument
    let currentApp: OfficerLoanApplication
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onPreview: () -> Void
    var onFlag: () -> Void
    
    var body: some View {
        Button {
            onPreview()
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(doc.status.themeColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: doc.docType.symbol)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(doc.status.themeColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(doc.docType.rawValue)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    if let reason = doc.rejectionReason, doc.status == .rejectFlag {
                        Text(reason)
                            .font(.caption2)
                            .foregroundColor(AppTheme.criticalRed)
                            .lineLimit(1)
                    } else {
                        Text(doc.status.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if doc.status == .verified {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppTheme.successGreen)
                        .font(.title3)
                } else if doc.status == .rejectFlag {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(AppTheme.criticalRed)
                        .font(.title3)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundColor(Color(uiColor: .tertiaryLabel))
                }
            }
            .padding(.vertical, 4)
        }
        .swipeActions(edge: .leading) {
            if doc.status != .verified {
                Button {
                    HapticsManager.triggerImpact(style: .medium)
                    viewModel.updateDocumentStatus(applicationId: currentApp.applicationId, docId: doc.id, newStatus: .verified)
                } label: {
                    Label("Verify", systemImage: "checkmark")
                }
                .tint(AppTheme.successGreen)
            }
        }
        .swipeActions(edge: .trailing) {
            if doc.status != .rejectFlag {
                Button(role: .destructive) {
                    HapticsManager.triggerImpact(style: .medium)
                    onFlag()
                } label: {
                    Label("Flag", systemImage: "flag")
                }
            }
            if doc.status != .pending {
                Button {
                    HapticsManager.triggerImpact(style: .medium)
                    viewModel.updateDocumentStatus(applicationId: currentApp.applicationId, docId: doc.id, newStatus: .pending, rejectionReason: "Document marked as missing")
                } label: {
                    Label("Missing", systemImage: "questionmark")
                }
                .tint(AppTheme.warningAmber)
            }
        }
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
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: type.icon)
                .font(.subheadline)
                .foregroundColor(type.color)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(docName)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
                Text(desc)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

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
        return BorrowerDetails(dob: "14 Feb 2003", gender: "Female", pan: "FRVPN4830D", email: "kavya.nair@student.edu", phone: "+91 97444 88899", employer: "N/A (Co-Applicant: Rajesh Nair)", monthlyIncome: "₹ 1,80,000", employmentStatus: "Student / Co-Applicant Salaried")
    default:
        return BorrowerDetails(dob: "18 Oct 1991", gender: "Male", pan: "AZYPM9876Z", email: "borrower.service@bank.com", phone: "+91 98000 11122", employer: "Global Enterprises", monthlyIncome: "₹ 1,10,000", employmentStatus: "Salaried")
    }
}
