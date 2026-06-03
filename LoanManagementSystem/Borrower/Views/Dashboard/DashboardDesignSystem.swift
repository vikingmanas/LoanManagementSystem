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

/// Standard inner card used for every dashboard section body.
struct DashboardSectionCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(LMSSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
                    .stroke(LMSColors.separatorLight, lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
}

struct DashboardSectionHeader: View {
    let title: LocalizedStringKey
    var subtitle: String? = nil
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: LMSSpacing.sm) {
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
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(LMSFont.footnote.weight(.semibold))
                    .foregroundStyle(LMSColors.brandNavy)
            }
        }
    }
}

struct DashboardEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: LMSSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(LMSColors.brandNavy.opacity(0.85))
                .symbolRenderingMode(.hierarchical)
                .frame(width: 64, height: 64)
                .background(LMSColors.brandNavy.opacity(0.08), in: Circle())

            Text(title)
                .font(LMSFont.headline)
                .foregroundStyle(LMSColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(message)
                .font(LMSFont.footnote)
                .foregroundStyle(LMSColors.textSecondary)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(LMSFont.footnote.weight(.semibold))
                    .foregroundStyle(LMSColors.brandNavy)
                    .padding(.top, LMSSpacing.xs)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LMSSpacing.xl)
    }
}

struct DashboardFilledButton: View {
    let title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var tint: Color = LMSColors.brandNavy
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: LMSSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                }
                Text(title)
                    .font(LMSFont.button)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundStyle(.white)
            .background(isDisabled ? Color.gray.opacity(0.35) : tint, in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
        }
        .buttonStyle(DashboardPressableStyle())
        .disabled(isDisabled || isLoading)
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

