import SwiftUI

struct DocumentQueueView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onReviewTapped: (DocumentQueueItem) -> Void
    var onSeeAllTapped: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    Text("Document Queue")
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                    
                    Text("\(viewModel.pendingDocumentCount) Pending")
                        .font(.system(.caption2, design: .rounded).bold())
                        .foregroundStyle(LMSColors.amber)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(LMSColors.amber.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                
                Spacer()
                
                Button(action: {
                    HapticsManager.triggerImpact(style: .light)
                    onSeeAllTapped()
                }) {
                    Text("See All")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundStyle(LMSColors.actionBlue)
                }
                .accessibilityLabel("View all documents in the verification queue")
            }
            .padding(.horizontal, 16)
            
            VStack(spacing: 0) {
                let items = viewModel.documentQueueList.prefix(5)
                if items.isEmpty {
                    ContentUnavailableView(
                        "No Documents Awaiting Review",
                        systemImage: "doc.text.fill",
                        description: Text("All submitted documentation has been verified.")
                    )
                    .frame(height: 150)
                } else {
                    ForEach(items) { item in
                        DocumentStatusRow(item: item) {
                            onReviewTapped(item)
                        }
                        
                        if item.id != items.last?.id {
                            Divider()
                                .padding(.leading, 62)
                        }
                    }
                }
            }
            .background(LMSColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 3)
        }
    }
}

struct DocumentStatusRow: View {
    typealias DocumentStatus = OfficerDocumentStatus
    let item: DocumentQueueItem
    var onReview: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(item.docType.iconColor.opacity(0.12))
                    .frame(width: 38, height: 38)
                
                Image(systemName: item.docType.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(item.docType.iconColor)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(item.borrowerName)
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)
                
                Text(item.docType.rawValue)
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundStyle(LMSColors.textSecondary)
            }
            
            Spacer()
            
            Text(statusLabel(for: item.status))
                .font(.system(.caption2, design: .rounded).bold())
                .foregroundStyle(item.status == .pending ? LMSColors.amber : .white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(item.status == .pending ? LMSColors.amber.opacity(0.15) : item.status.themeColor)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            if item.status == .uploaded || item.status == .reUploaded {
                Button(action: {
                    HapticsManager.triggerImpact(style: .medium)
                    onReview()
                }) {
                    HStack(spacing: 2) {
                        Text("Review")
                            .font(.system(.caption2, design: .rounded).bold())
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundStyle(LMSColors.actionBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(LMSColors.actionBlue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel("Review \(item.docType.rawValue) uploaded by \(item.borrowerName)")
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture {
            HapticsManager.triggerImpact(style: .medium)
            onReview()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.borrowerName), document \(item.docType.rawValue), status is \(statusLabel(for: item.status)).")
    }
    
    private func statusLabel(for status: DocumentStatus) -> String {
        switch status {
        case .pending: return "Awaiting Upload"
        case .uploaded: return "New Upload"
        case .underReview: return "In Review"
        case .verified: return "Verified ✓"
        case .rejectFlag: return "Re-upload Req."
        case .reUploaded: return "Re-Uploaded"
        }
    }
}
