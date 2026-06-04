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
    
    init(item: DocumentQueueItem, viewModel: LoanOfficerDashboardViewModel, isPresentedModally: Bool = false) {
        self.item = item
        self.viewModel = viewModel
        self.isPresentedModally = isPresentedModally
    }
    
    var loanDetails: LoanApplication? {
        viewModel.applications.first { $0.applicationId == item.applicationId }
    }
    
    var documentDetails: LoanDocument? {
        loanDetails?.documents.first { $0.id == item.id }
    }

    private var canReviewDocument: Bool {
        guard let loanDetails else { return false }
        let currentDocumentStatus = documentDetails?.status ?? item.status
        let officerReviewStatuses: Set<OfficerApplicationStatus> = [
            .pending,
            .applied,
            .documentsPending,
            .documentsRejected,
            .underReview
        ]

        return officerReviewStatuses.contains(loanDetails.status) && currentDocumentStatus != .verified
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 22) {
                borrowerSection
                documentPreviewSection
                documentMetadataSection
                if canReviewDocument {
                    actionsSection
                }
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)
            .padding(.top, 18)
            .padding(.bottom, 118)
        }
        .background(LMSColors.background.ignoresSafeArea())
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
    }
    
    
    private var borrowerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle("Borrower & Loan")

            if let app = loanDetails {
                ReviewSurface {
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

                    Divider()

                    VStack(spacing: 0) {
                        DocumentDetailRow("Loan Type", value: app.loanType.rawValue, valueColor: app.loanType.themeColor)
                        DocumentDetailRow("Requested Amount", value: CurrencyFormatter.shared.format(app.requestedAmount))
                        DocumentDetailRow("Branch", value: app.branch)
                        DocumentDetailRow("Document Stage", value: item.status.rawValue, valueColor: item.status.themeColor, isLast: true)
                    }
                }
            }
        }
    }
    
    
    private var documentPreviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle("Uploaded Document")

            ReviewSurface(padding: 10) {
                if let urlString = documentDetails?.fileURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .frame(height: 260)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .frame(height: 260)
                        case .failure:
                            VStack(spacing: 12) {
                                Image(systemName: item.docType.symbol)
                                    .font(.system(size: 40))
                                    .foregroundStyle(item.docType.iconColor)
                                Text("Failed to load document image")
                                    .font(.subheadline.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 260)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: item.docType.symbol)
                            .font(.system(size: 40))
                            .foregroundStyle(item.docType.iconColor)
                        Text("No Document Uploaded")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            }
        }
    }
    
    private var documentMetadataSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionTitle("File Details")

            ReviewSurface {
                VStack(spacing: 0) {
                    DocumentDetailRow("Document Type", value: item.docType.rawValue, icon: item.docType.symbol, valueColor: item.docType.iconColor)
                    DocumentDetailRow("Submitted", value: item.submittedDate.formattedAsDDMMMYYYY())
                    DocumentDetailRow("Status", value: item.status.rawValue, valueColor: item.status.themeColor)
                    DocumentDetailRow("OCR Status", value: documentDetails?.ocrStatus ?? "Not available", valueColor: LMSColors.actionBlue, isLast: true)
                }
            }
        }
    }
    
    
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

private struct SectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.headline.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 2)
    }
}

private struct ReviewSurface<Content: View>: View {
    var padding: CGFloat = 16
    let content: () -> Content

    init(padding: CGFloat = 16, @ViewBuilder content: @escaping () -> Content) {
        self.padding = padding
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content()
        }
        .padding(padding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LMSColors.surfaceElevated, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
        )
    }
}

private struct DocumentDetailRow: View {
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
                    .frame(minWidth: 130, alignment: .leading)

                Spacer(minLength: 10)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    if let icon {
                        Image(systemName: icon)
                            .font(.subheadline.weight(.semibold))
                    }

                    Text(displayValue)
                        .font(.subheadline.weight(displayValue == "Not provided" ? .regular : .semibold))
                        .foregroundStyle(displayValue == "Not provided" ? .secondary : valueColor)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
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
