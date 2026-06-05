import SwiftUI

struct DocumentUploadCardView: View {
    var documentName: String
    var status: VerificationStatus
    var fileName: String? = nil
    var onUpload: () -> Void
    var onDelete: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.AppTheme.primary.opacity(0.1))
                    .frame(width: 40, height: 40)

                Image(systemName: iconForStatus)
                    .foregroundStyle(colorForStatus)
                    .font(.system(size: 18))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(documentName)
                    .font(Font.AppTheme.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.AppTheme.textPrimary)

                if let fileName = fileName {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 10))
                        Text(fileName)
                    }
                    .font(Font.AppTheme.caption)
                    .foregroundStyle(Color.AppTheme.primary)
                } else {
                    Text(status.rawValue)
                        .font(Font.AppTheme.caption)
                        .foregroundStyle(colorForStatus)
                }
            }

            Spacer()

            if status == .pending || status == .rejected {
                Button(action: onUpload) {
                    Text("Upload")
                        .font(Font.AppTheme.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.AppTheme.primary)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            } else {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.AppTheme.error)
                }
            }
        }
        .padding(16)
        .background(Color.AppTheme.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }

    private var iconForStatus: String {
        if fileName != nil { return "doc.richtext.fill" }
        switch status {
        case .verified: return "checkmark.seal.fill"
        case .pending: return "doc.text.viewfinder"
        case .underReview: return "hourglass"
        case .rejected: return "xmark.octagon.fill"
        }
    }

    private var colorForStatus: Color {
        if fileName != nil { return Color.AppTheme.primary }
        switch status {
        case .verified: return Color.AppTheme.success
        case .pending: return Color.AppTheme.textSecondary
        case .underReview: return Color.orange
        case .rejected: return Color.AppTheme.error
        }
    }
}

#Preview {
    DocumentUploadCardView(
        documentName: "PAN Card",
        status: .verified,
        onUpload: {},
        onDelete: {}
    )
    .padding()
}
