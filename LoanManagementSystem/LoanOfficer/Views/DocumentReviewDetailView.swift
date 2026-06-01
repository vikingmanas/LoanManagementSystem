import SwiftUI

struct DocumentReviewDetailView: View {
    typealias LoanApplication = OfficerLoanApplication
    typealias DocumentType = OfficerDocumentType
    typealias DocumentStatus = OfficerDocumentStatus
    let item: DocumentQueueItem
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    let isPresentedModally: Bool
    @Environment(\.dismiss) var dismiss
    
    @State private var showingRejectionAlert = false
    @State private var rejectionReason = ""
    @State private var showingDocumentViewer = false
    
    init(item: DocumentQueueItem, viewModel: LoanOfficerDashboardViewModel, isPresentedModally: Bool = false) {
        self.item = item
        self.viewModel = viewModel
        self.isPresentedModally = isPresentedModally
    }
    
    var loanDetails: LoanApplication? {
        viewModel.applications.first { $0.applicationId == item.applicationId }
    }

    private var reviewedDocument: LoanDocument? {
        loanDetails?.documents.first { $0.id == item.id }
    }

    private var documentURLString: String? {
        reviewedDocument?.fileURL ?? item.fileURL
    }
    
    var body: some View {
        List {
            borrowerSection
            documentPreviewSection
            extractedDataSection
            documentMetadataSection
            
            Section {
                actionsSection
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 16, trailing: 0))
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Document Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isPresentedModally {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .alert("Flag Document", isPresented: $showingRejectionAlert) {
            TextField("E.g. Photo blur, Signature mismatch...", text: $rejectionReason)
            Button("Submit Flag", role: .destructive) {
                viewModel.updateDocumentStatus(
                    applicationId: item.applicationId,
                    docId: item.id,
                    newStatus: .rejectFlag,
                    rejectionReason: rejectionReason.isEmpty ? "Signature mismatch or photo unclear." : rejectionReason
                )
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter clarification reason for requesting re-upload from borrower.")
        }
        .fullScreenCover(isPresented: $showingDocumentViewer) {
            LoanOfficerDocumentViewer(
                title: item.docType.rawValue,
                fileURLString: documentURLString
            )
        }
    }
    
    // MARK: - Borrower Info Section
    
    private var borrowerSection: some View {
        Section {
            if let app = loanDetails {
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
                    
                    if let cibil = app.cibilScore {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("CIBIL")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                            Text("\(cibil)")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(cibilColor(for: cibil))
                        }
                    }
                }
                .padding(.vertical, 4)
                
                LabeledContent("Loan Type") {
                    Text(app.loanType.rawValue)
                        .foregroundStyle(app.loanType.themeColor)
                        .fontWeight(.semibold)
                }
                
                LabeledContent("Requested Amount") {
                    Text(CurrencyFormatter.shared.format(app.requestedAmount))
                        .fontWeight(.semibold)
                }
                
                LabeledContent("Branch") {
                    Text(app.branch)
                }
                
                LabeledContent("Document Stage") {
                    Text(item.status.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(item.status.themeColor)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(item.status.themeColor.opacity(0.12), in: Capsule())
                }
            }
        } header: {
            Text("Borrower & Loan")
        }
    }
    
    // MARK: - Document Preview
    
    private var documentPreviewSection: some View {
        Section {
            VStack(spacing: 0) {
                OfficerUploadedDocumentPreview(
                    docType: item.docType,
                    borrowerName: item.borrowerName,
                    fileURLString: documentURLString
                )
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .onTapGesture {
                        showingDocumentViewer = true
                    }

                Button {
                    showingDocumentViewer = true
                } label: {
                    Label("Open Full Screen Viewer", systemImage: "arrow.up.left.and.arrow.down.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .padding(.top, 10)
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        } header: {
            Text("Uploaded Document")
        }
    }

    private var extractedDataSection: some View {
        Section("OCR Data Extraction") {
            if let fields = reviewedDocument?.extractedFields, !fields.isEmpty {
                ForEach(fields.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    LabeledContent(key, value: value)
                }
            } else {
                ContentUnavailableView("No OCR Data", systemImage: "text.viewfinder")
            }
        }
    }
    
    private var documentMetadataSection: some View {
        Section {
            LabeledContent("Document Type") {
                Label(item.docType.rawValue, systemImage: item.docType.symbol)
                    .font(.subheadline)
                    .foregroundStyle(item.docType.iconColor)
            }
            
            LabeledContent("Submitted") {
                Text(reviewedDocument?.uploadedDate ?? item.submittedDate, style: .date)
            }
            
            LabeledContent("Status") {
                Text(item.status.rawValue)
                    .foregroundStyle(item.status.themeColor)
                    .fontWeight(.semibold)
            }

            LabeledContent("OCR") {
                Text(reviewedDocument?.ocrStatus ?? "Pending Review")
                    .fontWeight(.semibold)
            }

            if let documentURLString {
                LabeledContent("File URL") {
                    Text(documentURLString)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
        } header: {
            Text("File Details")
        }
    }
    
    // MARK: - Actions
    
    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                HapticsManager.triggerImpact(style: .heavy)
                viewModel.updateDocumentStatus(applicationId: item.applicationId, docId: item.id, newStatus: .verified)
                dismiss()
            } label: {
                Text("Verify & Approve")
                    .font(.body.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            
            Button {
                HapticsManager.triggerImpact(style: .medium)
                showingRejectionAlert = true
            } label: {
                Text("Flag for Re-upload")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.red.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }
    
    private func cibilColor(for score: Int) -> Color {
        if score >= 750 { return LMSColors.emerald }
        if score >= CentralLoanRepository.shared.globalRules.minCibilScore { return LMSColors.amber }
        return LMSColors.coral
    }
}

struct OfficerUploadedDocumentPreview: View {
    let docType: OfficerDocumentType
    let borrowerName: String
    let fileURLString: String?

    var body: some View {
        if let fileURLString,
           fileURLString.hasPrefix("data:image"),
           let image = imageFromDataURL(fileURLString) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding(8)
        } else if let fileURLString,
           let url = URL(string: fileURLString),
           url.scheme?.hasPrefix("http") == true {
            if url.pathExtension.lowercased() == "pdf" {
                VStack(spacing: 10) {
                    Image(systemName: "doc.richtext.fill")
                        .font(.system(size: 42, weight: .semibold))
                        .foregroundStyle(docType.iconColor)
                    Text("PDF document")
                        .font(.subheadline.weight(.semibold))
                    Text("Tap to open full screen")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                            .padding(8)
                    case .failure:
                        uploadedFileFallback
                    @unknown default:
                        uploadedFileFallback
                    }
                }
            }
        } else {
            uploadedFileFallback
        }
    }

    private var uploadedFileFallback: some View {
        VStack(spacing: 12) {
            Image(systemName: docType.symbol)
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(docType.iconColor)
            Text(fileURLString == nil ? "No uploaded file URL available" : "Uploaded file")
                .font(.subheadline.weight(.semibold))
            if let fileURLString {
                Text(fileURLString)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .truncationMode(.middle)
            }
        }
        .padding(20)
    }

    private func imageFromDataURL(_ dataURL: String) -> UIImage? {
        guard let commaIndex = dataURL.firstIndex(of: ",") else { return nil }
        let payload = String(dataURL[dataURL.index(after: commaIndex)...])
        guard let data = Data(base64Encoded: payload) else { return nil }
        return UIImage(data: data)
    }
}

private struct LoanOfficerDocumentViewer: View {
    let title: String
    let fileURLString: String?
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1
    @State private var rotation: Angle = .zero
    @State private var page = 1

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                content
                    .scaleEffect(scale)
                    .rotationEffect(rotation)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = min(max(value, 0.75), 5)
                            }
                    )
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .bottomBar) {
                    Button { scale = max(0.75, scale - 0.25) } label: {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    Button { scale = min(5, scale + 0.25) } label: {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    Button { rotation += .degrees(90) } label: {
                        Image(systemName: "rotate.right")
                    }
                    Button { page = max(1, page - 1) } label: {
                        Image(systemName: "chevron.left")
                    }
                    Text("Page \(page)")
                        .font(.caption.weight(.semibold))
                    Button { page += 1 } label: {
                        Image(systemName: "chevron.right")
                    }
                    if let url = externalURL {
                        ShareLink(item: url) {
                            Image(systemName: "square.and.arrow.down")
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    @ViewBuilder
    private var content: some View {
        if let fileURLString,
           fileURLString.hasPrefix("data:image"),
           let image = imageFromDataURL(fileURLString) {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .padding()
        } else if let url = externalURL {
            if url.pathExtension.lowercased() == "pdf" {
                VStack(spacing: 14) {
                    Image(systemName: "doc.richtext.fill")
                        .font(.system(size: 58, weight: .semibold))
                    Text("PDF Preview")
                        .font(.headline)
                    Link("Open PDF", destination: url)
                        .buttonStyle(.borderedProminent)
                }
                .foregroundStyle(.white)
            } else {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ProgressView().tint(.white)
                    case .success(let image):
                        image.resizable().scaledToFit().padding()
                    case .failure:
                        unavailableView
                    @unknown default:
                        unavailableView
                    }
                }
            }
        } else {
            unavailableView
        }
    }

    private var externalURL: URL? {
        guard let fileURLString,
              let url = URL(string: fileURLString),
              url.scheme?.hasPrefix("http") == true else {
            return nil
        }
        return url
    }

    private var unavailableView: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.questionmark")
                .font(.system(size: 52, weight: .semibold))
            Text("Document preview unavailable")
                .font(.headline)
        }
        .foregroundStyle(.white)
    }

    private func imageFromDataURL(_ dataURL: String) -> UIImage? {
        guard let commaIndex = dataURL.firstIndex(of: ",") else { return nil }
        let payload = String(dataURL[dataURL.index(after: commaIndex)...])
        guard let data = Data(base64Encoded: payload) else { return nil }
        return UIImage(data: data)
    }
}

// Graphic preview mockups simulating scanner screenshots
struct DocumentGraphicMockView: View {
    typealias DocumentType = OfficerDocumentType
    let docType: DocumentType
    let borrowerName: String
    
    var body: some View {
        switch docType {
        case .aadhaar:
            aadhaarPreview
        case .salarySlip:
            salarySlipPreview
        case .bankStatement:
            bankStatementPreview
        case .gstCertificate:
            gstPreview
        default:
            genericPreview
        }
    }
    
    private var aadhaarPreview: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "building.columns.fill")
                    .foregroundStyle(.orange)
                Text("GOVERNMENT OF INDIA")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.primary)
                Spacer()
            }
            
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 60, height: 75)
                    Image(systemName: "person.fill")
                        .font(.system(size: 30))
                        .foregroundStyle(.secondary.opacity(0.5))
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(borrowerName.uppercased())
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                    Text("DOB/Year: 1994")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Text("Gender: M/F")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    Text("Address: Verified Resident")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            
            Spacer()
            
            Text("XXXX XXXX 9847")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundStyle(.primary)
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(Color.primary.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .padding(16)
    }
    
    private var salarySlipPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("CROWN INDUSTRIES PVT. LTD.")
                .font(.system(size: 10, weight: .bold, design: .rounded))
            Text("SALARY SLIP · MONTH: MAY 2026")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
            
            Divider()
            
            VStack(spacing: 5) {
                ledgerRow("Basic Pay", "₹ 85,000.00")
                ledgerRow("HRA Allowance", "₹ 15,000.00")
                ledgerRow("PF Deductions", "- ₹ 5,500.00", isDebit: true)
                Divider()
                ledgerRow("NET DISBURSED AMOUNT", "₹ 94,500.00", isBold: true, creditColor: LMSColors.emerald)
            }
            .font(.system(size: 9, design: .monospaced))
        }
        .padding(16)
    }
    
    private var bankStatementPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "building.columns.fill")
                    .foregroundStyle(LMSColors.actionBlue)
                Text("SECURE HDFC BANK STATEMENT")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                Spacer()
            }
            
            Text("Statement Period: 01 Apr to 30 Apr")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
            
            Divider()
            
            VStack(spacing: 6) {
                ledgerRow("12 Apr · UPI Credit", "+ ₹ 12,000", creditColor: LMSColors.emerald)
                ledgerRow("15 Apr · AutoDebit EMI", "- ₹ 8,500", isDebit: true)
                ledgerRow("28 Apr · Salary Credited", "+ ₹ 94,500", creditColor: LMSColors.emerald)
                Divider()
                ledgerRow("CLOSING ACCOUNT BALANCE", "₹ 1,12,300.00", isBold: true)
            }
            .font(.system(size: 9, design: .monospaced))
        }
        .padding(16)
    }
    
    private var gstPreview: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 26))
                .foregroundStyle(LMSColors.emerald)
            
            Text("FORM GST REG-06")
                .font(.system(size: 10, weight: .bold, design: .rounded))
            Text("GOVERNMENT OF INDIA FINANCE DEPT")
                .font(.system(size: 8))
                .foregroundStyle(.secondary)
            
            Divider()
            
            Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 4) {
                GridRow {
                    Text("Legal Name:")
                    Text(borrowerName.uppercased())
                }
                GridRow {
                    Text("Trade Name:")
                    Text("Vibrant Retailers")
                }
                GridRow {
                    Text("GSTIN No:")
                    Text("27AAACV9847K1Z3")
                }
            }
            .font(.system(size: 8, design: .monospaced))
        }
        .padding(16)
    }
    
    private var genericPreview: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 40))
                .foregroundStyle(LMSColors.actionBlue)
            
            Text("Uploaded Document Scan")
                .font(.subheadline.weight(.semibold))
            Text("File Name: \(docType.rawValue.lowercased())_signed.pdf")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
    }
    
    private func ledgerRow(_ label: String, _ value: String, isDebit: Bool = false, isBold: Bool = false, creditColor: Color? = nil) -> some View {
        HStack {
            Text(label)
                .fontWeight(isBold ? .bold : .regular)
            Spacer()
            Text(value)
                .fontWeight(isBold ? .bold : .regular)
                .foregroundStyle(isDebit ? .red : (creditColor ?? .primary))
        }
    }
}
