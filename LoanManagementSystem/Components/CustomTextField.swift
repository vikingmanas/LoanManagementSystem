import SwiftUI

struct CustomTextField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    var isError: Bool = false
    var errorMessage: String = ""
    var keyboardType: UIKeyboardType = .default

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.xs) {
            HStack(spacing: LMSSpacing.md) {
                Image(systemName: icon)
                    .font(.system(.callout, design: .rounded))
                    .foregroundColor(iconColor)
                    .frame(width: 22)

                TextField(placeholder, text: $text)
                    .font(LMSFont.body)
                    .foregroundColor(LMSColors.textPrimary)
                    .disableAutocapitalization()
                    .autocorrectionDisabled(true)
                    .keyboardType(keyboardType)
                    .focused($isFocused)

                if !text.isEmpty && isFocused {
                    Button {
                        text = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(.callout))
                            .foregroundColor(LMSColors.textTertiary)
                    }
                    .buttonStyle(.plain)
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, LMSSpacing.lg)
            .frame(height: 50)
            .background(LMSColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            .animation(.easeInOut(duration: 0.2), value: isError)

            if isError && !errorMessage.isEmpty {
                HStack(spacing: LMSSpacing.xs) {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 11))
                    Text(errorMessage)
                        .font(LMSFont.caption)
                }
                .foregroundColor(LMSColors.coral)
                .padding(.leading, LMSSpacing.xs)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }

    private var iconColor: Color {
        if isError { return LMSColors.coral }
        if isFocused { return LMSColors.brandNavy }
        return LMSColors.textTertiary
    }

    private var borderColor: Color {
        if isError { return LMSColors.coral }
        if isFocused { return LMSColors.brandNavy }
        return LMSColors.separator.opacity(0.3)
    }

    private var borderWidth: CGFloat {
        (isFocused || isError) ? 1.5 : 0.5
    }
}
