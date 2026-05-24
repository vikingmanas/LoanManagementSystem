import SwiftUI

public struct SchemeCardView: View {
    let scheme: GovernmentScheme
    var onApplyTap: (() -> Void)? = nil
    
    public init(scheme: GovernmentScheme, onApplyTap: (() -> Void)? = nil) {
        self.scheme = scheme
        self.onApplyTap = onApplyTap
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Top Row: Category badge & Icon
            HStack(alignment: .center) {
                Text(categoryBadgeText)
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(categoryColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(categoryColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                
                Spacer()
                
                Image(systemName: iconName)
                    .font(.subheadline.bold())
                    .foregroundStyle(categoryColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(scheme.title)
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(scheme.description)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer(minLength: 0)
            
            // Bottom Row
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("VALID UNTIL")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.textTertiary)
                    Text(scheme.validTill.formattedAsDDMMMYYYY())
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.textPrimary)
                }
                
                Spacer()
                
                Button {
                    onApplyTap?()
                } label: {
                    Text("Explore")
                        .font(.system(.caption2, design: .rounded).bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(LMSColors.brandNavy, in: Capsule())
                }
            }
        }
        .padding(16)
        .frame(width: 240, height: 180)
        .background(LMSColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 4)
    }
    
    // MARK: - Category Helpers
    private var categoryColor: Color {
        switch scheme.category {
        case .businessLoan: return LMSColors.brandNavy
        case .homeLoan:     return LMSColors.actionBlue
        case .agriculture:  return LMSColors.emerald
        case .education:    return LMSColors.coral
        }
    }
    
    private var categoryBadgeText: String {
        switch scheme.category {
        case .businessLoan, .agriculture: return "GOVT SCHEME"
        case .homeLoan, .education:       return "BANK OFFER"
        }
    }
    
    private var iconName: String {
        switch scheme.category {
        case .businessLoan: return "briefcase.fill"
        case .agriculture:  return "leaf.fill"
        case .homeLoan:     return "house.fill"
        case .education:    return "graduationcap.fill"
        }
    }
}

// MARK: - Scheme Skeleton Card
public struct SchemeCardSkeleton: View {
    public init() {}
    
    public var body: some View {
        RoundedRectangle(cornerRadius: 22)
            .fill(LMSColors.surfaceElevated)
            .frame(width: 240, height: 180)
            .shimmer(active: true)
    }
}
