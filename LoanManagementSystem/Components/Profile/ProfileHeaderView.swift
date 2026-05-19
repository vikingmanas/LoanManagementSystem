import SwiftUI

struct ProfileHeaderView: View {
    var name: String
    var id: String
    var completionPercentage: Int
    var isVerified: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            // Circular Avatar with Progress Ring
            ZStack {
                // Background Track
                Circle()
                    .stroke(Color.AppTheme.textSecondary.opacity(0.15), lineWidth: 3.5)
                    .frame(width: 78, height: 78)
                
                // Progress Arc
                Circle()
                    .trim(from: 0.0, to: CGFloat(completionPercentage) / 100.0)
                    .stroke(
                        Color.AppTheme.primary,
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )
                    .frame(width: 78, height: 78)
                    .rotationEffect(.degrees(-90))
                
                // Avatar Image
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(Color.AppTheme.primary)
                    .frame(width: 70, height: 70)
                    .background(Circle().fill(Color.AppTheme.secondary.opacity(0.8)))
                
                // Verification Badge
                if isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.AppTheme.success)
                        .background(Circle().fill(Color.AppTheme.background))
                        .offset(x: 26, y: 26)
                }
            }
            .frame(width: 82, height: 82)
            
            // Name, ID and Completion Status
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Color.AppTheme.textPrimary)
                
                Text("Borrower ID: \(id)")
                    .font(Font.AppTheme.caption)
                    .foregroundColor(Color.AppTheme.textSecondary)
                
                // Completion Tag
                HStack(spacing: 4) {
                    Circle()
                        .fill(completionPercentage == 100 ? Color.AppTheme.success : Color.AppTheme.primary)
                        .frame(width: 6, height: 6)
                    
                    Text("\(completionPercentage)% Setup")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(completionPercentage == 100 ? Color.AppTheme.success : Color.AppTheme.primary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill((completionPercentage == 100 ? Color.AppTheme.success : Color.AppTheme.primary).opacity(0.12))
                )
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
    }
}
