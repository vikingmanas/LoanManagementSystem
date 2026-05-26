import SwiftUI

/// iOS-native checkbox with animated SF Symbol toggle and brand styling.
struct CheckboxView: View {
    @Binding var isChecked: Bool
    var label: String

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isChecked.toggle()
            }
            HapticsManager.triggerImpact(style: .light)
        }) {
            HStack(alignment: .center, spacing: LMSSpacing.md) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(isChecked ? LMSColors.brandNavy : LMSColors.textTertiary)
                    .contentTransition(.symbolEffect(.replace))

                Text(label)
                    .font(LMSFont.footnote)
                    .foregroundStyle(LMSColors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isChecked ? "Checked" : "Unchecked")
    }
}

#Preview {
    CheckboxView(isChecked: .constant(true), label: "I agree to the Terms and Conditions")
        .padding()
}
