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
            HStack(alignment: .top, spacing: LMSSpacing.md) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundColor(isChecked ? LMSColors.brandNavy : LMSColors.textTertiary)
                    .contentTransition(.symbolEffect(.replace))

                Text(label)
                    .font(LMSFont.footnote)
                    .foregroundColor(LMSColors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .accessibilityValue(isChecked ? "Checked" : "Unchecked")
    }
}

struct CheckboxView_Previews: PreviewProvider {
    static var previews: some View {
        CheckboxView(isChecked: .constant(true), label: "I agree to the Terms and Conditions")
            .padding()
    }
}
