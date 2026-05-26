import SwiftUI


enum DashboardSpacing {
    static let screenHorizontal: CGFloat = LMSSpacing.screenHorizontal
    static let sectionVertical: CGFloat = LMSSpacing.sectionGap
    static let cardCornerRadius: CGFloat = LMSRadius.card
}


struct DashboardPressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}


struct DashboardCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .lmsCard(radius: LMSRadius.card)
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
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            HStack(alignment: .center, spacing: LMSSpacing.sm) {
                VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                    Text(title)
                        .font(LMSFont.title3)
                        .foregroundStyle(LMSColors.textPrimary)
                    if let subtitle {
                        Text(subtitle)
                            .font(LMSFont.footnote)
                            .foregroundStyle(LMSColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: LMSSpacing.sm)
                trailing
            }
            content
        }
        .padding(.horizontal, LMSSpacing.screenHorizontal)
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
        ZStack {
            LinearGradient(
                colors: [LMSColors.brandNavy, LMSColors.brandNavyLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(alignment: .leading, spacing: LMSSpacing.lg) {

                HStack(alignment: .top, spacing: LMSSpacing.sm) {
                    VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                        Text(title)
                            .font(LMSFont.headline)
                            .foregroundStyle(.white)
                        Text(subtitle)
                            .font(LMSFont.caption)
                            .foregroundStyle(.white.opacity(0.70))
                    }
                    Spacer()
                    Text("\(Int(clampedFraction * 100))% repaid")
                        .font(LMSFont.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.white.opacity(0.16), in: Capsule())
                }


                VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                    Text("Outstanding")
                        .font(LMSFont.caption)
                        .foregroundStyle(.white.opacity(0.65))
                    Text(outstandingAmount.formattedAsINR())
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .contentTransition(.numericText())
                }


                ProgressView(value: clampedFraction)
                    .tint(accent)
                    .animation(.easeInOut(duration: 0.35), value: clampedFraction)


                HStack(spacing: LMSSpacing.lg) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Monthly EMI")
                            .font(LMSFont.caption2)
                            .foregroundStyle(.white.opacity(0.65))
                        Text(monthlyEMI.formattedAsINR())
                            .font(LMSFont.footnote.weight(.semibold))
                            .foregroundStyle(.white)
                            .minimumScaleFactor(0.8)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 3) {
                        Text("Next due")
                            .font(LMSFont.caption2)
                            .foregroundStyle(.white.opacity(0.65))
                        Text(nextEMIDateText)
                            .font(LMSFont.footnote.weight(.semibold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(LMSSpacing.lg)
        }
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
    }
}

#Preview("SectionContainer") {
    SectionContainer(title: "Sample", subtitle: "Preview subtitle") {
        Text("Section content")
    }
    .padding()
}

