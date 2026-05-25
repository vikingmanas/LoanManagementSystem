import SwiftUI

public struct SchemeCardView: View {
    let scheme: GovernmentScheme
    var onApplyTap: (() -> Void)? = nil

    public init(scheme: GovernmentScheme, onApplyTap: (() -> Void)? = nil) {
        self.scheme = scheme
        self.onApplyTap = onApplyTap
    }

    public var body: some View {
        ZStack {

            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: 8) {

                HStack(alignment: .center) {

                    Text(categoryBadgeText)
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(categoryBadgeBgColor)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Spacer()


                    Image(systemName: iconName)
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                }


                Text(scheme.title)
                    .font(LMSFont.callout.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(1)


                Text(scheme.description)
                    .font(LMSFont.caption2)
                    .foregroundStyle(.white.opacity(0.85))
                    .lineLimit(2)
                    .frame(height: 30, alignment: .topLeading)

                Spacer()


                HStack {
                    Text("Valid: \(scheme.validTill.formattedAsDDMMMYYYY())")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.75))

                    Spacer()


                    Button {
                        onApplyTap?()
                    } label: {
                        Text("Apply →")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.white.opacity(0.2))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
        }
        .frame(width: 240, height: 140)
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }


    private var gradientColors: [Color] {
        switch scheme.category {
        case .businessLoan:

            return [Color(hex: "#FF8C00"), Color(hex: "#FF5E00")]
        case .homeLoan:

            return [Color(hex: "#3F51B5"), Color(hex: "#1A237E")]
        case .agriculture:

            return [Color(hex: "#4CAF50"), Color(hex: "#2E7D32")]
        case .education:

            return [Color(hex: "#E91E63"), Color(hex: "#C2185B")]
        }
    }

    private var categoryBadgeText: String {
        switch scheme.category {
        case .businessLoan, .agriculture:
            return "Govt. Scheme"
        case .homeLoan, .education:
            return "Bank Offer"
        }
    }

    private var categoryBadgeBgColor: Color {
        switch scheme.category {
        case .businessLoan, .agriculture:

            return Color(hex: "#E05A00").opacity(0.85)
        case .homeLoan, .education:

            return LMSColors.brandNavy.opacity(0.8)
        }
    }

    private var iconName: String {
        switch scheme.category {
        case .businessLoan: return "briefcase.fill"
        case .agriculture: return "leaf.fill"
        case .homeLoan: return "house.fill"
        case .education: return "graduationcap.fill"
        }
    }
}


public struct SchemeCardSkeleton: View {
    public init() {}

    public var body: some View {
        RoundedRectangle(cornerRadius: LMSRadius.card)
            .fill(LMSColors.surfaceElevated)
            .frame(width: 240, height: 140)
            .shimmer(active: true)
    }
}

#Preview("Scheme Card") {
    SchemeCardView(scheme: MockData.sampleSchemes[0])
}

#Preview("Scheme Skeleton") {
    SchemeCardSkeleton()
}

