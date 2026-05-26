import SwiftUI

public enum LMSButtonVariant {
    case primary
    case secondary
    case destructive
    case ghost
}

struct PrimaryButton: View {
    var title: String
    var icon: String? = nil
    var variant: LMSButtonVariant = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: {
            guard !isDisabled && !isLoading else { return }
            HapticsManager.triggerImpact(style: .medium)
            action()
        }) {
            HStack(spacing: LMSSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: foregroundColor))
                        .scaleEffect(0.9)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(.callout, design: .rounded).weight(.semibold))
                    }
                    Text(title)
                        .font(LMSFont.button)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .foregroundStyle(foregroundColor)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
            .overlay(overlayView)
            .shadow(
                color: shadowColor,
                radius: variant == .primary ? 8 : 0,
                x: 0,
                y: variant == .primary ? 4 : 0
            )
            .opacity(isDisabled ? 0.5 : 1)
        }
        .buttonStyle(LMSPressableStyle())
        .disabled(isDisabled || isLoading)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }

    private var foregroundColor: Color {
        switch variant {
        case .primary, .destructive:
            return .white
        case .secondary, .ghost:
            return isDisabled ? LMSColors.textTertiary : LMSColors.brandNavy
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch variant {
        case .primary:
            if isDisabled {
                Color.gray.opacity(0.3)
            } else {
                LinearGradient(
                    colors: [LMSColors.brandNavy, LMSColors.brandNavyLight],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case .secondary, .ghost:
            Color.clear
        case .destructive:
            isDisabled ? Color.gray.opacity(0.3) : LMSColors.coral
        }
    }

    @ViewBuilder
    private var overlayView: some View {
        switch variant {
        case .secondary:
            RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                .stroke(isDisabled ? Color.gray.opacity(0.3) : LMSColors.brandNavy, lineWidth: 1.5)
        default:
            EmptyView()
        }
    }

    private var shadowColor: Color {
        if isDisabled { return .clear }
        switch variant {
        case .primary:     return LMSColors.brandNavy.opacity(0.25)
        case .destructive: return LMSColors.coral.opacity(0.25)
        default:           return .clear
        }
    }
}

#Preview {
    PrimaryButton(title: "Continue", action: {})
        .padding()
}

