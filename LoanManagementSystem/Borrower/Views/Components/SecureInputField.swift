import SwiftUI

struct SecureInputField: View {
    var placeholder: String
    @Binding var text: String
    @State private var isVisible: Bool = false
    var isError: Bool = false
    var errorMessage: String = ""

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.xs) {
            HStack(spacing: LMSSpacing.md) {
                Image(systemName: "lock.fill")
                    .font(.system(.callout, design: .rounded))
                    .foregroundStyle(iconColor)
                    .frame(width: 22)

                Group {
                    if isVisible {
                        TextField(placeholder, text: $text)
                    } else {
                        SecureField(placeholder, text: $text)
                    }
                }
                .font(LMSFont.body)
                .foregroundStyle(LMSColors.textPrimary)
                .disableAutocapitalization()
                .autocorrectionDisabled(true)
                .focused($isFocused)

                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isVisible.toggle()
                    }
                } label: {
                    Image(systemName: isVisible ? "eye.fill" : "eye.slash.fill")
                        .font(.system(.callout, design: .rounded))
                        .foregroundStyle(LMSColors.textTertiary)
                        .contentTransition(.symbolEffect(.replace))
                }
                .buttonStyle(.plain)
                .frame(width: 44, height: 44)
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
                .foregroundStyle(LMSColors.coral)
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

#Preview {
    @Previewable @State var text = ""
    SecureInputField(placeholder: "Password", text: $text)
        .padding()
}
