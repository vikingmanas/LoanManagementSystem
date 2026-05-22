//
//  DesignSystem.swift
//  LoanManagementSystem
//
//  Unified design system — the single source of truth for colors,
//  typography, spacing, radii, shadows, and reusable view modifiers
//  across every module (Borrower, LoanOfficer, Manager, Admin).
//
//  Apple HIG · iOS 17+ · Dynamic Type · Light & Dark mode
//

import SwiftUI

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Colors
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Semantic color tokens that adapt to Light / Dark mode.
/// Usage: `LMSColors.brandNavy` or `Color.lmsBrandNavy` (via extension below).
public enum LMSColors {

    // ── Brand ──────────────────────────────────────────────────────────────────
    /// Primary brand navy — deep, trustworthy, and authoritative.
    public static let brandNavy = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 74/255, green: 114/255, blue: 190/255, alpha: 1)   // #4A72BE – lighter for dark bg
            : UIColor(red: 10/255, green: 37/255, blue: 64/255, alpha: 1)     // #0A2540
    })

    /// Lighter navy variant for gradients and deep headers.
    public static let brandNavyLight = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 26/255, green: 54/255, blue: 93/255, alpha: 1)     // #1A365D
            : UIColor(red: 46/255, green: 59/255, blue: 132/255, alpha: 1)    // #2E3B84
    })

    /// Action blue — interactive elements, links, tints.
    public static let actionBlue = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 64/255, green: 156/255, blue: 255/255, alpha: 1)   // #409CFF
            : UIColor(red: 26/255, green: 115/255, blue: 232/255, alpha: 1)   // #1A73E8
    })

    // ── Semantic Status ────────────────────────────────────────────────────────
    public static let emerald = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 5/255, green: 224/255, blue: 165/255, alpha: 1)    // #05E0A5
            : UIColor(red: 0/255, green: 196/255, blue: 140/255, alpha: 1)    // #00C48C
    })

    public static let emeraldDark = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0/255, green: 120/255, blue: 90/255, alpha: 1)
            : UIColor(red: 0/255, green: 158/255, blue: 134/255, alpha: 1)
    })

    public static let amber = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 255/255, green: 196/255, blue: 54/255, alpha: 1)   // #FFC436
            : UIColor(red: 255/255, green: 179/255, blue: 0/255, alpha: 1)    // #FFB300
    })

    public static let coral = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 255/255, green: 115/255, blue: 117/255, alpha: 1)  // #FF7375
            : UIColor(red: 255/255, green: 77/255, blue: 79/255, alpha: 1)    // #FF4D4F
    })

    public static let teal = Color(UIColor { tc in
        tc.userInterfaceStyle == .dark
            ? UIColor(red: 0/255, green: 188/255, blue: 212/255, alpha: 1)
            : UIColor(red: 0/255, green: 162/255, blue: 196/255, alpha: 1)    // #00A2C4
    })

    // ── Surfaces ───────────────────────────────────────────────────────────────
    /// Primary background — equivalent to systemGroupedBackground.
    public static let background = Color(UIColor.systemGroupedBackground)

    /// Secondary grouped surface — card backgrounds.
    public static let surface = Color(UIColor.secondarySystemGroupedBackground)

    /// Elevated surface — sheets, modals, floating cards.
    public static let surfaceElevated = Color(UIColor.systemBackground)

    /// Tertiary surface — inset grouped content.
    public static let surfaceTertiary = Color(UIColor.tertiarySystemGroupedBackground)

    // ── Text ───────────────────────────────────────────────────────────────────
    public static let textPrimary   = Color(UIColor.label)
    public static let textSecondary = Color(UIColor.secondaryLabel)
    public static let textTertiary  = Color(UIColor.tertiaryLabel)

    // ── Separators ─────────────────────────────────────────────────────────────
    public static let separator     = Color(UIColor.separator)
    public static let separatorLight = Color(UIColor.separator).opacity(0.18)
}

// Convenience extensions so existing `.brandNavy` shorthand keeps working.
extension Color {
    // Brand
    public static let lmsBrandNavy      = LMSColors.brandNavy
    public static let lmsBrandNavyLight = LMSColors.brandNavyLight
    public static let lmsActionBlue     = LMSColors.actionBlue

    // Status
    public static let lmsEmerald     = LMSColors.emerald
    public static let lmsEmeraldDark = LMSColors.emeraldDark
    public static let lmsAmber       = LMSColors.amber
    public static let lmsCoral       = LMSColors.coral
    public static let lmsTeal        = LMSColors.teal
}


// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Typography
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Dynamic Type–friendly type scale with `.rounded` design for fintech personality.
public enum LMSFont {

    /// Screen-level large title — 34pt bold rounded.
    public static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)

    /// Section header / screen title — title2 bold rounded.
    public static let title = Font.system(.title2, design: .rounded).weight(.bold)

    /// Sub-section title — title3 semibold rounded.
    public static let title3 = Font.system(.title3, design: .rounded).weight(.semibold)

    /// Card title — headline weight.
    public static let headline = Font.system(.headline, design: .rounded)

    /// Body text — default readable.
    public static let body = Font.system(.body, design: .rounded)

    /// Supporting text — callout.
    public static let callout = Font.system(.callout, design: .rounded)

    /// Sub-body text.
    public static let subheadline = Font.system(.subheadline, design: .rounded)

    /// Small supporting text.
    public static let footnote = Font.system(.footnote, design: .rounded)

    /// Fine-print, metadata.
    public static let caption = Font.system(.caption, design: .rounded)

    /// Tiny labels, badges.
    public static let caption2 = Font.system(.caption2, design: .rounded)

    /// Button / CTA text — body-weight semibold.
    public static let button = Font.system(.body, design: .rounded).weight(.semibold)

    /// Monospaced digit helper — for currency / numbers.
    public static let monoDigit = Font.system(.body, design: .rounded).monospacedDigit()
}


// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Spacing (4pt Grid)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public enum LMSSpacing {
    /// 4pt — hairline gaps, inner padding micro-adjustments.
    public static let xs:   CGFloat = 4
    /// 8pt — tight element spacing.
    public static let sm:   CGFloat = 8
    /// 12pt — standard inner spacing within cards/groups.
    public static let md:   CGFloat = 12
    /// 16pt — standard section padding, card inner padding.
    public static let lg:   CGFloat = 16
    /// 20pt — screen horizontal margins (Apple standard).
    public static let xl:   CGFloat = 20
    /// 24pt — generous spacing between major sections.
    public static let xxl:  CGFloat = 24
    /// 32pt — top-of-screen / hero spacing.
    public static let xxxl: CGFloat = 32

    /// Standard horizontal screen margin (20pt — Apple HIG).
    public static let screenHorizontal: CGFloat = 20
    /// Standard vertical gap between sections.
    public static let sectionGap: CGFloat = 16
}


// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Corner Radii
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public enum LMSRadius {
    /// 8pt — small elements (badges, chips, inline fields).
    public static let sm:   CGFloat = 8
    /// 12pt — standard interactive controls (buttons, text fields).
    public static let md:   CGFloat = 12
    /// 16pt — medium cards, grouped sections.
    public static let lg:   CGFloat = 16
    /// 20pt — large hero cards, portfolio cards.
    public static let xl:   CGFloat = 20
    /// 22pt — premium card variant.
    public static let card: CGFloat = 22
}


// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Shadows
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

public enum LMSShadow {
    /// Subtle — list rows, surface-level cards.
    public static func soft(_ content: some View) -> some View {
        content.shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
    /// Standard — elevated cards and panels.
    public static func medium(_ content: some View) -> some View {
        content.shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 5)
    }
    /// Prominent — floating elements, hero cards.
    public static func prominent(_ content: some View) -> some View {
        content.shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: 8)
    }
}


// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Reusable View Modifiers
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Standard card styling — surface background, continuous corners, soft shadow.
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
    /// Apply standard card styling.
    public func lmsCard(radius: CGFloat = LMSRadius.xl) -> some View {
        modifier(LMSCardModifier(radius: radius, elevated: false))
    }

    /// Apply elevated card styling (stronger shadow).
    public func lmsCardElevated(radius: CGFloat = LMSRadius.xl) -> some View {
        modifier(LMSCardModifier(radius: radius, elevated: true))
    }
}

/// Pressable button style — subtle scale on press with spring.
public struct LMSPressableStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.75), value: configuration.isPressed)
    }
}

/// Glass-morphism frosted overlay (for premium hero sections).
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


// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// MARK: - Legacy Compatibility Aliases
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// These preserve backward compatibility with existing code that uses:
//   Color.AppTheme.primary / .secondary / .background / etc.
//   Font.AppTheme.title / .body / .button / etc.
// They simply redirect to the new unified tokens.

extension Color {
    public struct AppTheme {
        public static let primary       = LMSColors.brandNavy
        public static let secondary     = LMSColors.surface
        public static let background    = LMSColors.background
        public static let textPrimary   = LMSColors.textPrimary
        public static let textSecondary = LMSColors.textSecondary
        public static let success       = LMSColors.emerald
        public static let error         = LMSColors.coral
    }
}

extension Font {
    public struct AppTheme {
        public static let title    = LMSFont.largeTitle
        public static let subtitle = LMSFont.subheadline.weight(.medium)
        public static let body     = LMSFont.footnote
        public static let button   = LMSFont.button
        public static let caption  = LMSFont.caption
        public static let input    = LMSFont.body
    }
}

// Keep the utility modifiers from the old Theme.swift
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
        self.navigationBarHidden(true)
        #else
        self
        #endif
    }
}

// Keep the hex initializer available everywhere.
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
