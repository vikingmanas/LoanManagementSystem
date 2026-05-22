import SwiftUI

struct DocumentQueueView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onReviewTapped: (DocumentQueueItem) -> Void
    var onSeeAllTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 12)

            Divider()
                .padding(.leading, 16)

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
        }
        .background(AppTheme.neutralSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LMSColors.textPrimary.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 3)
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Document Queue")
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)

                    Text("\(viewModel.pendingDocumentCount) Pending")
                        .font(.system(.caption2, design: .rounded).bold())
                        .foregroundStyle(AppTheme.warningAmber)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.warningAmber.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }

                Text("Review borrower uploads in priority order")
                    .font(.system(.caption2, design: .rounded).weight(.medium))
                    .foregroundStyle(LMSColors.textSecondary)
            }

            Spacer()

            Button(action: {
                HapticsManager.triggerImpact(style: .light)
                onSeeAllTapped()
            }) {
                HStack(spacing: 4) {
                    Text("See All")
                        .font(.system(.caption, design: .rounded).weight(.bold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(AppTheme.actionBlue)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(AppTheme.actionBlue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("View all documents in the verification queue")
        }
    }
}

struct DocumentStatusRow: View {
    typealias DocumentStatus = OfficerDocumentStatus
    let item: DocumentQueueItem
    var onReview: () -> Void
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Icon representing Document Status
            ZStack {
                Circle()
                    .fill(item.status.themeColor.opacity(0.12))
                    .frame(width: 38, height: 38)
                
                Image(systemName: item.docType.symbol)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(item.status.themeColor)
            }
            
            // Borrower details
            VStack(alignment: .leading, spacing: 3) {
                Text(item.borrowerName)
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)
                
                Text(item.docType.rawValue)
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundStyle(LMSColors.textSecondary)
            }
            
            Spacer()
            
            // Status Badge
            Text(statusLabel(for: item.status))
                .font(.system(.caption2, design: .rounded).bold())
                .foregroundStyle(item.status == .pending ? AppTheme.warningAmber : .white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(item.status == .pending ? AppTheme.warningAmber.opacity(0.15) : item.status.themeColor)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            
            // Action review CTA
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
                    .foregroundStyle(AppTheme.actionBlue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.actionBlue.opacity(0.1))
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
