import SwiftUI

public enum LMSColors {
    public static let brandNavy = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 74/255, green: 114/255, blue: 190/255, alpha: 1)
            : UIColor(red: 10/255, green: 37/255, blue: 64/255, alpha: 1)
    })

    public static let brandNavyLight = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 26/255, green: 54/255, blue: 93/255, alpha: 1)
            : UIColor(red: 46/255, green: 59/255, blue: 132/255, alpha: 1)
    })

    public static let actionBlue = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 64/255, green: 156/255, blue: 255/255, alpha: 1)
            : UIColor(red: 26/255, green: 115/255, blue: 232/255, alpha: 1)
    })

    public static let emerald = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 5/255, green: 224/255, blue: 165/255, alpha: 1)
            : UIColor(red: 0/255, green: 196/255, blue: 140/255, alpha: 1)
    })

    public static let emeraldDark = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0/255, green: 120/255, blue: 90/255, alpha: 1)
            : UIColor(red: 0/255, green: 158/255, blue: 134/255, alpha: 1)
    })

    public static let amber = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 255/255, green: 196/255, blue: 54/255, alpha: 1)
            : UIColor(red: 255/255, green: 179/255, blue: 0/255, alpha: 1)
    })

    public static let coral = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 255/255, green: 115/255, blue: 117/255, alpha: 1)
            : UIColor(red: 255/255, green: 77/255, blue: 79/255, alpha: 1)
    })

    public static let teal = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0/255, green: 188/255, blue: 212/255, alpha: 1)
            : UIColor(red: 0/255, green: 162/255, blue: 196/255, alpha: 1)
    })

    public static let background = Color(UIColor.systemGroupedBackground)
    public static let surface = Color(UIColor.secondarySystemGroupedBackground)
    public static let surfaceElevated = Color(UIColor.systemBackground)
    public static let surfaceTertiary = Color(UIColor.tertiarySystemGroupedBackground)

    public static let textPrimary = Color(UIColor.label)
    public static let textSecondary = Color(UIColor.secondaryLabel)
    public static let textTertiary = Color(UIColor.tertiaryLabel)

    public static let separator = Color(UIColor.separator)
    public static let separatorLight = Color(UIColor.separator).opacity(0.18)
}

extension Color {
    public static let lmsBrandNavy = LMSColors.brandNavy
    public static let lmsBrandNavyLight = LMSColors.brandNavyLight
    public static let lmsActionBlue = LMSColors.actionBlue
    public static let lmsEmerald = LMSColors.emerald
    public static let lmsEmeraldDark = LMSColors.emeraldDark
    public static let lmsAmber = LMSColors.amber
    public static let lmsCoral = LMSColors.coral
    public static let lmsTeal = LMSColors.teal
}

public enum LMSFont {
    public static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
    public static let title = Font.system(.title2, design: .rounded).weight(.bold)
    public static let title3 = Font.system(.title3, design: .rounded).weight(.semibold)
    public static let headline = Font.system(.headline, design: .rounded)
    public static let body = Font.system(.body, design: .rounded)
    public static let callout = Font.system(.callout, design: .rounded)
    public static let subheadline = Font.system(.subheadline, design: .rounded)
    public static let footnote = Font.system(.footnote, design: .rounded)
    public static let caption = Font.system(.caption, design: .rounded)
    public static let caption2 = Font.system(.caption2, design: .rounded)
    public static let button = Font.system(.body, design: .rounded).weight(.semibold)
    public static let monoDigit = Font.system(.body, design: .rounded).monospacedDigit()
}

public enum LMSSpacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 20
    public static let xxl: CGFloat = 24
    public static let xxxl: CGFloat = 32
    public static let screenHorizontal: CGFloat = 20
    public static let sectionGap: CGFloat = 16
}

public enum LMSRadius {
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 20
    public static let card: CGFloat = 22
}

public enum LMSShadow {
    public static func soft(_ content: some View) -> some View {
        content.shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
    }

    public static func medium(_ content: some View) -> some View {
        content.shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 5)
    }

    public static func prominent(_ content: some View) -> some View {
        content.shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 8)
    }
}

public struct LMSCardModifier: ViewModifier {
    var radius: CGFloat
    var elevated: Bool

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(LMSColors.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(LMSColors.separatorLight, lineWidth: 0.5)
            )
            .shadow(
                color: .black.opacity(elevated ? 0.08 : 0.04),
                radius: elevated ? 12 : 8,
                x: 0,
                y: elevated ? 5 : 3
            )
    }
}

extension View {
    public func lmsCard(radius: CGFloat = LMSRadius.xl) -> some View {
        modifier(LMSCardModifier(radius: radius, elevated: false))
    }

    public func lmsCardElevated(radius: CGFloat = LMSRadius.xl) -> some View {
        modifier(LMSCardModifier(radius: radius, elevated: true))
    }
}

public struct LMSPressableStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

public struct LMSGlassModifier: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
    }
}

extension View {
    public func lmsGlass() -> some View {
        modifier(LMSGlassModifier())
    }
}

extension Color {
    public struct AppTheme {
        public static let primary = LMSColors.brandNavy
        public static let secondary = LMSColors.surface
        public static let background = LMSColors.background
        public static let textPrimary = LMSColors.textPrimary
        public static let textSecondary = LMSColors.textSecondary
        public static let success = LMSColors.emerald
        public static let error = LMSColors.coral
    }
}

extension Font {
    public struct AppTheme {
        public static let title = LMSFont.largeTitle
        public static let subtitle = LMSFont.subheadline.weight(.medium)
        public static let body = LMSFont.footnote
        public static let button = LMSFont.button
        public static let caption = LMSFont.caption
        public static let input = LMSFont.body
    }
}

extension View {
    @ViewBuilder
    public func disableAutocapitalization() -> some View {
        #if os(iOS) || os(tvOS) || os(watchOS)
        self.textInputAutocapitalization(.never)
        #else
        self
        #endif
    }

    @ViewBuilder
    public func hideNavigationBar() -> some View {
        #if os(iOS) || os(tvOS) || os(watchOS)
        self.toolbar(.hidden, for: .navigationBar)
        #else
        self
        #endif
    }
}

extension Color {
    public init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
