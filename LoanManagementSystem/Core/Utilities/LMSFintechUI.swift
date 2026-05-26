import SwiftUI

enum LMSFintechUI {
    static let quickActionSize: CGFloat = 52
}

struct FintechQuickActionItem: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let tint: Color
    let action: () -> Void
}

struct FintechQuickActionGrid: View {
    let items: [FintechQuickActionItem]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: LMSSpacing.sm), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: LMSSpacing.lg) {
            ForEach(items) { item in
                Button(action: item.action) {
                    VStack(spacing: LMSSpacing.sm) {
                        ZStack {
                            RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                                .fill(item.tint.opacity(0.12))
                                .frame(width: LMSFintechUI.quickActionSize, height: LMSFintechUI.quickActionSize)
                            Image(systemName: item.icon)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundStyle(item.tint)
                                .symbolRenderingMode(.hierarchical)
                        }
                        Text(item.title)
                            .font(LMSFont.caption2.weight(.medium))
                            .foregroundStyle(LMSColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(LMSPressableStyle())
            }
        }
        .padding(.vertical, LMSSpacing.lg)
        .padding(.horizontal, LMSSpacing.md)
        .lmsCard(radius: LMSRadius.xl)
    }
}

struct FintechSectionLink: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                    .font(LMSFont.footnote.weight(.semibold))
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(LMSColors.actionBlue)
            .frame(minWidth: 44, minHeight: 44)
        }
        .buttonStyle(.plain)
    }
}

struct FintechStatPill: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(spacing: LMSSpacing.sm) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.12))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(tint)
            }
            Text(value)
                .font(LMSFont.callout.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(LMSColors.textPrimary)
            Text(title)
                .font(LMSFont.caption2)
                .foregroundStyle(LMSColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, LMSSpacing.md)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
    }
}

struct FintechHighlightCard<Content: View>: View {
    var accent: Color = LMSColors.amber
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(accent)
                .frame(width: 4)
            content
                .padding(LMSSpacing.lg)
        }
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

struct FintechToolbarButton: View {
    let systemName: String
    var showsBadge: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: systemName)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(LMSColors.brandNavy)
                    .frame(width: 40, height: 40)
                    .background(LMSColors.surface, in: Circle())
                    .overlay(
                        Circle()
                            .stroke(LMSColors.separatorLight, lineWidth: 0.5)
                    )
                if showsBadge {
                    Circle()
                        .fill(LMSColors.coral)
                        .frame(width: 9, height: 9)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(LMSPressableStyle())
    }
}

extension View {
    func fintechSegmentedContainer() -> some View {
        padding(LMSSpacing.md)
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                    .stroke(LMSColors.separatorLight, lineWidth: 0.5)
            )
    }
}

