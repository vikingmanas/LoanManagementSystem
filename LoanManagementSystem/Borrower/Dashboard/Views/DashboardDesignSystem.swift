import SwiftUI

enum DashboardSpacing {
    static let screenHorizontal: CGFloat = 20
    static let sectionVertical: CGFloat = 16
    static let cardCornerRadius: CGFloat = 22
}

struct DashboardPressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.8), value: configuration.isPressed)
    }
}

struct DashboardCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: DashboardSpacing.cardCornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DashboardSpacing.cardCornerRadius, style: .continuous)
                    .stroke(Color(.separator).opacity(0.18), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.04), radius: 12, x: 0, y: 5)
    }
}

extension View {
    func dashboardCardStyle() -> some View {
        modifier(DashboardCardModifier())
    }
}

struct SectionContainer<Content: View, Trailing: View>: View {
    let title: LocalizedStringKey
    let subtitle: String?
    @ViewBuilder let trailing: Trailing
    @ViewBuilder let content: Content

    init(
        title: LocalizedStringKey,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(Color(.label))
                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundColor(Color(.secondaryLabel))
                    }
                }
                Spacer()
                trailing
            }
            content
        }
        .padding(.horizontal, DashboardSpacing.screenHorizontal)
    }
}

extension SectionContainer where Trailing == EmptyView {
    init(
        title: LocalizedStringKey,
        subtitle: String? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.init(title: title, subtitle: subtitle, trailing: { EmptyView() }, content: content)
    }
}

struct LoanCard: View {
    let title: String
    let subtitle: String
    let outstandingAmount: Double
    let repaidFraction: Double
    let monthlyEMI: Double
    let nextEMIDateText: String
    let accent: Color

    private var clampedFraction: Double {
        min(max(repaidFraction, 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.72))
                }
                Spacer()
                Text("\(Int(clampedFraction * 100))% repaid")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.18), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Outstanding")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                Text(outstandingAmount.formattedAsINR())
                    .font(.title2.weight(.bold))
                    .monospacedDigit()
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
            }

            ProgressView(value: clampedFraction)
                .tint(accent)
                .animation(.easeInOut(duration: 0.35), value: clampedFraction)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Monthly EMI")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    Text(monthlyEMI.formattedAsINR())
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.8)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    Text("Next due")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                    Text(nextEMIDateText)
                        .font(.footnote.weight(.semibold))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(18)
        .background(
            LinearGradient(
                colors: [Color(hex: "0D1B4C"), Color(hex: "2D3FA5")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DashboardSpacing.cardCornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 7)
    }
}
