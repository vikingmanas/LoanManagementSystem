import SwiftUI

struct StatusBadgeView: View {
    var status: String
    
    var body: some View {
        Text(status)
            .font(Font.system(size: 12, weight: .bold))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .foregroundColor(textColor)
            .background(backgroundColor)
            .cornerRadius(12)
    }
    
    private var textColor: Color {
        switch status.lowercased() {
        case "verified", "high", "active":
            return Color.AppTheme.success
        case "pending", "under review", "medium":
            return Color.orange
        case "rejected", "low":
            return Color.AppTheme.error
        default:
            return Color.AppTheme.textSecondary
        }
    }
    
    private var backgroundColor: Color {
        textColor.opacity(0.15)
    }
}

struct StatusBadgeView_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            StatusBadgeView(status: "Verified")
            StatusBadgeView(status: "Pending")
            StatusBadgeView(status: "Rejected")
        }
    }
}
