import SwiftUI

public enum LMSAppearance {
    public static func configure() {
        let nav = UINavigationBarAppearance()
        nav.configureWithDefaultBackground()
        nav.backgroundColor = UIColor.secondarySystemGroupedBackground
        nav.shadowColor = UIColor.separator.withAlphaComponent(0.35)
        nav.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        nav.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]

        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav

        UINavigationBar.appearance().tintColor = UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor(red: 74/255, green: 114/255, blue: 190/255, alpha: 1)
                : UIColor(red: 10/255, green: 37/255, blue: 64/255, alpha: 1)
        }

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor.secondarySystemGroupedBackground
        tab.shadowColor = UIColor.black.withAlphaComponent(0.06)
        tab.stackedLayoutAppearance.normal.iconColor = UIColor.tertiaryLabel
        tab.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.tertiaryLabel,
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]

        let brandNavyUIColor = UIColor { tc in
            tc.userInterfaceStyle == .dark
                ? UIColor(red: 74/255, green: 114/255, blue: 190/255, alpha: 1)
                : UIColor(red: 10/255, green: 37/255, blue: 64/255, alpha: 1)
        }

        tab.stackedLayoutAppearance.selected.iconColor = brandNavyUIColor
        tab.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: brandNavyUIColor,
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
        UITabBar.appearance().tintColor = brandNavyUIColor
        UITabBar.appearance().unselectedItemTintColor = UIColor.tertiaryLabel
    }
}

extension View {
    @ViewBuilder
    public func lmsTabBadge(_ count: Int) -> some View {
        if count > 0 {
            badge(count)
        } else {
            self
        }
    }

    public func lmsScreenBackground() -> some View {
        background(LMSColors.background.ignoresSafeArea())
    }

    public func lmsInsetGroupedCard() -> some View {
        background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                    .stroke(LMSColors.separatorLight, lineWidth: 0.5)
            )
    }
}

public struct LMSGroupedSectionHeader: View {
    let title: LocalizedStringKey
    var subtitle: String? = nil

    public var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.xs) {
            Text(title)
                .font(LMSFont.title3)
                .foregroundStyle(LMSColors.textPrimary)
            if let subtitle {
                Text(subtitle)
                    .font(LMSFont.footnote)
                    .foregroundStyle(LMSColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, LMSSpacing.screenHorizontal)
    }
}

public struct LMSListRow: View {
    let title: String
    var subtitle: String? = nil
    var value: String? = nil
    let icon: String
    var iconColor: Color = LMSColors.brandNavy
    var showChevron: Bool = true

    public var body: some View {
        HStack(spacing: LMSSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(LMSFont.callout.weight(.medium))
                    .foregroundStyle(LMSColors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: LMSSpacing.sm)

            if let value {
                Text(value)
                    .font(LMSFont.footnote.weight(.semibold))
                    .foregroundStyle(LMSColors.textSecondary)
                    .lineLimit(1)
            }

            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(LMSColors.textTertiary)
            }
        }
        .padding(.vertical, 13)
        .padding(.horizontal, LMSSpacing.lg)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }
}

public struct LMSGroupedDivider: View {
    public var body: some View {
        Divider()
            .padding(.leading, 62)
    }
}

public struct LMSDashboardGreeting: View {
    let firstName: String
    var customerID: String? = nil
    var onNotifications: (() -> Void)? = nil
    var onProfile: (() -> Void)? = nil
    var initials: String = "U"

    public var body: some View {
        HStack(alignment: .center, spacing: LMSSpacing.md) {
            VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                Text("Hello, \(firstName)")
                    .font(LMSFont.subheadline.weight(.medium))
                    .foregroundStyle(LMSColors.textSecondary)
                if let customerID {
                    Label(customerID, systemImage: "number")
                        .font(LMSFont.caption.monospacedDigit().weight(.semibold))
                        .foregroundStyle(LMSColors.brandNavy)
                        .padding(.horizontal, LMSSpacing.sm)
                        .padding(.vertical, 3)
                        .background(LMSColors.brandNavy.opacity(0.10), in: Capsule())
                }
            }
            Spacer()
            HStack(spacing: LMSSpacing.sm) {
                if let onNotifications {
                    Button(action: onNotifications) {
                        Image(systemName: "bell.badge.fill")
                            .font(.title3)
                            .symbolRenderingMode(.multicolor)
                            .frame(width: 44, height: 44)
                            .background(LMSColors.surface, in: Circle())
                    }
                    .buttonStyle(LMSPressableStyle())
                }
                if let onProfile {
                    Button(action: onProfile) {
                        Text(initials)
                            .font(LMSFont.callout.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(LMSColors.brandNavy, in: Circle())
                    }
                    .buttonStyle(LMSPressableStyle())
                    .accessibilityLabel("Profile")
                }
            }
        }
        .padding(.horizontal, LMSSpacing.screenHorizontal)
        .padding(.bottom, LMSSpacing.sm)
    }
}

public struct LMSStatusPill: View {
    public enum Style { case success, warning, error, info, neutral }

    let text: String
    var style: Style = .neutral
    var icon: String? = nil

    private var tint: Color {
        switch style {
        case .success: return LMSColors.emerald
        case .warning: return LMSColors.amber
        case .error: return LMSColors.coral
        case .info: return LMSColors.actionBlue
        case .neutral: return LMSColors.textSecondary
        }
    }

    public var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption2.weight(.bold))
            }
            Text(text)
                .font(LMSFont.caption.weight(.semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(tint.opacity(0.12), in: Capsule())
    }
}

public struct LMSMetricTile: View {
    let title: String
    let value: String
    var icon: String? = nil
    var tint: Color = LMSColors.brandNavy

    public var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.xs) {
            if let icon {
                Image(systemName: icon)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(tint)
            }
            Text(value)
                .font(LMSFont.headline.monospacedDigit())
                .foregroundStyle(LMSColors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(title)
                .font(LMSFont.caption2)
                .foregroundStyle(LMSColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LMSSpacing.md)
        .background(tint.opacity(0.06), in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
    }
}

public struct LMSBanner: View {
    public enum Style { case success, warning, error }

    let message: String
    var style: Style
    var icon: String

    private var background: Color {
        switch style {
        case .success: return LMSColors.emerald
        case .warning: return LMSColors.amber
        case .error: return LMSColors.coral
        }
    }

    public var body: some View {
        HStack(spacing: LMSSpacing.sm) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
            Text(message)
                .font(LMSFont.callout.weight(.semibold))
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, LMSSpacing.lg)
        .padding(.vertical, LMSSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
    }
}

public struct LMSNotification: Identifiable, Hashable {
    public let id: UUID
    public let title: String
    public let body: String
    public let timestamp: Date
    public let icon: String
    public let tint: Color
    public var isUnread: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        body: String,
        timestamp: Date,
        icon: String,
        tint: Color = LMSColors.brandNavy,
        isUnread: Bool = true
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.timestamp = timestamp
        self.icon = icon
        self.tint = tint
        self.isUnread = isUnread
    }
}

public enum LMSMockNotifications {
    public static let sample: [LMSNotification] = [
        LMSNotification(
            title: "EMI Reminder",
            body: "Your home loan EMI of ₹42,500 is due on 5 Jun. Ensure sufficient balance in SBI ••7890.",
            timestamp: MockData.makeDate(year: 2025, month: 5, day: 22, hour: 9, minute: 15),
            icon: "calendar.badge.clock",
            tint: LMSColors.amber
        ),
        LMSNotification(
            title: "Payment Received",
            body: "EMI of ₹18,200 was debited successfully from HDFC ••3421 for Personal Loan.",
            timestamp: MockData.makeDate(year: 2025, month: 5, day: 20, hour: 14, minute: 2),
            icon: "checkmark.circle.fill",
            tint: LMSColors.emerald,
            isUnread: false
        ),
        LMSNotification(
            title: "KYC Update",
            body: "Upload your latest address proof to complete profile verification.",
            timestamp: MockData.makeDate(year: 2025, month: 5, day: 18, hour: 11, minute: 0),
            icon: "doc.badge.plus",
            tint: LMSColors.actionBlue
        ),
        LMSNotification(
            title: "Scheme Eligible",
            body: "You may qualify for PMAY subsidy on your home loan. Tap to explore benefits.",
            timestamp: MockData.makeDate(year: 2025, month: 5, day: 15, hour: 16, minute: 45),
            icon: "sparkles",
            tint: LMSColors.teal,
            isUnread: false
        ),
        LMSNotification(
            title: "Low Balance Alert",
            body: "SBI ••7890 balance is below the recommended amount for your upcoming EMI.",
            timestamp: MockData.makeDate(year: 2025, month: 5, day: 14, hour: 8, minute: 30),
            icon: "exclamationmark.triangle.fill",
            tint: LMSColors.coral
        )
    ]

    public static var unreadCount: Int {
        sample.filter(\.isUnread).count
    }
}

public struct LMSNotificationRow: View {
    let notification: LMSNotification

    private var timeText: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: notification.timestamp, relativeTo: Date())
    }

    public var body: some View {
        HStack(alignment: .top, spacing: LMSSpacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                    .fill(notification.tint.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: notification.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(notification.tint)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(notification.title)
                        .font(LMSFont.callout.weight(notification.isUnread ? .bold : .medium))
                        .foregroundStyle(LMSColors.textPrimary)
                    Spacer(minLength: LMSSpacing.sm)
                    Text(timeText)
                        .font(LMSFont.caption2)
                        .foregroundStyle(LMSColors.textTertiary)
                }
                Text(notification.body)
                    .font(LMSFont.footnote)
                    .foregroundStyle(LMSColors.textSecondary)
                    .lineLimit(3)
            }

            if notification.isUnread {
                Circle()
                    .fill(LMSColors.actionBlue)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .padding(.vertical, LMSSpacing.md)
        .padding(.horizontal, LMSSpacing.lg)
        .frame(minHeight: 72)
        .contentShape(Rectangle())
    }
}

