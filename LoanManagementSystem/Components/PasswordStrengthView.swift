import SwiftUI

/// Animated password strength indicator with progress bar and requirement checks.
struct PasswordStrengthView: View {
    var isMinLength: Bool
    var hasUppercase: Bool
    var hasNumber: Bool
    var hasSpecialChar: Bool

    private var metCount: Int {
        [isMinLength, hasUppercase, hasNumber, hasSpecialChar].filter { $0 }.count
    }

    private var strengthFraction: CGFloat {
        CGFloat(metCount) / 4.0
    }

    private var strengthColor: Color {
        switch metCount {
        case 0...1: return LMSColors.coral
        case 2:     return LMSColors.amber
        case 3:     return LMSColors.amber
        default:    return LMSColors.emerald
        }
    }

    private var strengthLabel: String {
        switch metCount {
        case 0...1: return "Weak"
        case 2:     return "Fair"
        case 3:     return "Good"
        default:    return "Strong"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
            // Strength bar
            HStack(spacing: LMSSpacing.sm) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(LMSColors.separator.opacity(0.2))
                            .frame(height: 4)

                        Capsule()
                            .fill(strengthColor)
                            .frame(width: geo.size.width * strengthFraction, height: 4)
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: strengthFraction)
                    }
                }
                .frame(height: 4)

                Text(strengthLabel)
                    .font(LMSFont.caption.weight(.bold))
                    .foregroundStyle(strengthColor)
                    .frame(width: 50, alignment: .trailing)
                    .animation(.easeInOut, value: metCount)
            }

            // Requirements grid
            HStack(spacing: LMSSpacing.lg) {
                VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                    RequirementRow(isMet: isMinLength, text: "Min 8 characters")
                    RequirementRow(isMet: hasUppercase, text: "1 Uppercase")
                }

                VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                    RequirementRow(isMet: hasNumber, text: "1 Number")
                    RequirementRow(isMet: hasSpecialChar, text: "1 Special char")
                }
            }
        }
    }
}

struct RequirementRow: View {
    var isMet: Bool
    var text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isMet ? LMSColors.emerald : LMSColors.textTertiary)
                .font(.system(size: 13))
                .contentTransition(.symbolEffect(.replace))

            Text(text)
                .font(LMSFont.caption)
                .foregroundStyle(isMet ? LMSColors.textPrimary : LMSColors.textTertiary)
        }
    }
}

#Preview {
    PasswordStrengthView(isMinLength: true, hasUppercase: false, hasNumber: true, hasSpecialChar: false)
        .padding()
}
