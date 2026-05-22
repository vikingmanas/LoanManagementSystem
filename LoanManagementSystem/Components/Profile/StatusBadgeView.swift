import SwiftUI

/// Type-safe status badge with consistent styling across all modules.
enum LMSStatusType {
    case success
    case warning
    case error
    case info
    case neutral

    var color: Color {
        switch self {
        case .success: return LMSColors.emerald
        case .warning: return LMSColors.amber
        case .error:   return LMSColors.coral
        case .info:    return LMSColors.actionBlue
        case .neutral: return LMSColors.textSecondary
        }
    }
}

struct StatusBadgeView: View {
    var status: String
    var type: LMSStatusType? = nil
    var icon: String? = nil

    var body: some View {
        HStack(spacing: LMSSpacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(status)
                .font(.system(size: 12, weight: .bold, design: .rounded))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .foregroundColor(resolvedColor)
        .background(resolvedColor.opacity(0.12))
        .clipShape(Capsule())
    }

    // Determine color from explicit type or infer from status string.
    private var resolvedColor: Color {
        if let type { return type.color }
        switch status.lowercased() {
        case "verified", "high", "active", "approved", "paid", "disbursed":
            return LMSColors.emerald
        case "pending", "under review", "medium", "due soon", "upcoming":
            return LMSColors.amber
        case "rejected", "low", "overdue", "failed":
            return LMSColors.coral
        case "in progress", "processing":
            return LMSColors.actionBlue
        default:
            return LMSColors.textSecondary
        }
    }
}

struct StatusBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            StatusBadgeView(status: "Verified", icon: "checkmark.seal.fill")
            StatusBadgeView(status: "Pending")
            StatusBadgeView(status: "Rejected")
            StatusBadgeView(status: "Active", type: .success)
        }
    }
}
