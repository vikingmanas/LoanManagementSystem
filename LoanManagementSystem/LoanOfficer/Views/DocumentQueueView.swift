import SwiftUI

struct DocumentQueueView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onReviewTapped: (DocumentQueueItem) -> Void

    @State private var showingTodayQueue = false

    private var todayItems: [DocumentQueueItem] {
        Array(viewModel.todayDocumentQueueList.prefix(5))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 8)

            VStack(spacing: 0) {
                if todayItems.isEmpty {
                    ContentUnavailableView(
                        "No Uploads Today",
                        systemImage: "tray",
                        description: Text("Borrower documents uploaded today will appear here for review.")
                    )
                    .frame(height: 150)
                } else {
                    ForEach(todayItems) { item in
                        DocumentStatusRow(item: item) {
                            onReviewTapped(item)
                        }
                    }
                }
            }
            .padding(.bottom, 8)
        }
        .background(AppTheme.neutralSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LMSColors.textPrimary.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 3)
        .sheet(isPresented: $showingTodayQueue) {
            TodayDocumentReviewQueueView(
                viewModel: viewModel,
                onReviewTapped: { item in
                    showingTodayQueue = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        onReviewTapped(item)
                    }
                }
            )
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text("Today's Document Review Queue")
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)

                    if viewModel.todayDocumentReviewCount > 0 {
                        Text("\(viewModel.todayDocumentReviewCount) To Review")
                            .font(.system(.caption2, design: .rounded).bold())
                            .foregroundStyle(AppTheme.warningAmber)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.warningAmber.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }

                Text("Uploaded today · Tap any row to open review")
                    .font(.system(.caption2, design: .rounded).weight(.medium))
                    .foregroundStyle(LMSColors.textSecondary)
            }

            Spacer(minLength: 8)

            Button {
                HapticsManager.triggerImpact(style: .light)
                showingTodayQueue = true
            } label: {
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
            .accessibilityLabel("View all documents uploaded today")
        }
    }
}



struct TodayDocumentReviewQueueView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onReviewTapped: (DocumentQueueItem) -> Void
    @Environment(\.dismiss) private var dismiss

    private var todayDateLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, d MMM yyyy"
        return formatter.string(from: Date())
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.todayDocumentQueueList.isEmpty {
                    ContentUnavailableView(
                        "No Uploads Today",
                        systemImage: "doc.text",
                        description: Text("When borrowers upload documents today, they will show up in this queue.")
                    )
                } else {
                    List {
                        Section {
                            Text(todayDateLabel)
                                .font(LMSFont.footnote)
                                .foregroundStyle(LMSColors.textSecondary)
                        }

                        Section("Needs Review") {
                            let needsReview = viewModel.todayDocumentQueueList.filter {
                                $0.status == .uploaded || $0.status == .reUploaded || $0.status == .underReview
                            }
                            if needsReview.isEmpty {
                                Text("All of today's uploads have been reviewed.")
                                    .font(LMSFont.footnote)
                                    .foregroundStyle(LMSColors.textSecondary)
                            } else {
                                ForEach(needsReview) { item in
                                    todayQueueRow(item)
                                }
                            }
                        }

                        let completed = viewModel.todayDocumentQueueList.filter { $0.status == .verified }
                        if !completed.isEmpty {
                            Section("Reviewed Today") {
                                ForEach(completed) { item in
                                    todayQueueRow(item)
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Today's Review Queue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func todayQueueRow(_ item: DocumentQueueItem) -> some View {
        Button {
            HapticsManager.triggerImpact(style: .medium)
            onReviewTapped(item)
        } label: {
            HStack(spacing: LMSSpacing.md) {
                ZStack {
                    Circle()
                        .fill(item.status.themeColor.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: item.docType.symbol)
                        .foregroundStyle(item.status.themeColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.borrowerName)
                        .font(LMSFont.subheadline.weight(.semibold))
                        .foregroundStyle(LMSColors.textPrimary)
                    Text("\(item.docType.rawValue) · \(item.applicationId)")
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textSecondary)
                    Text("Uploaded \(RelativeDateFormatter.shared.relativeString(from: item.submittedDate))")
                        .font(LMSFont.caption2)
                        .foregroundStyle(LMSColors.actionBlue)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(LMSColors.textTertiary)
            }
        }
        .buttonStyle(.plain)
    }
}



struct DocumentStatusRow: View {
    typealias DocumentStatus = OfficerDocumentStatus
    let item: DocumentQueueItem
    var onReview: () -> Void

    private var canReview: Bool {
        item.status == .uploaded || item.status == .reUploaded || item.status == .underReview || item.status == .verified
    }

    var body: some View {
        Button {
            guard canReview else { return }
            HapticsManager.triggerImpact(style: .medium)
            onReview()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(item.status.themeColor.opacity(0.12))
                        .frame(width: 38, height: 38)

                    Image(systemName: item.docType.symbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(item.status.themeColor)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(item.borrowerName)
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)

                    Text(item.docType.rawValue)
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundStyle(LMSColors.textSecondary)

                    Text("Uploaded \(RelativeDateFormatter.shared.relativeString(from: item.submittedDate))")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(LMSColors.actionBlue)
                }

                Spacer()

                Text(statusLabel(for: item.status))
                    .font(.system(.caption2, design: .rounded).bold())
                    .foregroundStyle(item.status == .pending ? AppTheme.warningAmber : .white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(item.status == .pending ? AppTheme.warningAmber.opacity(0.15) : item.status.themeColor)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                if needsReviewAction {
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
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!canReview)
        .accessibilityLabel("\(item.borrowerName), \(item.docType.rawValue), uploaded \(RelativeDateFormatter.shared.relativeString(from: item.submittedDate)). \(statusLabel(for: item.status)).")
        .accessibilityHint(canReview ? "Opens document review." : "")
    }

    private var needsReviewAction: Bool {
        item.status == .uploaded || item.status == .reUploaded || item.status == .underReview
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

#Preview {
    DocumentQueueView(
        viewModel: PreviewSupport.loanOfficerViewModel,
        onReviewTapped: { _ in }
    )
    .padding()
}

