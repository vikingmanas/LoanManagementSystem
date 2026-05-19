import SwiftUI

struct OTPInputView: View {
    let length: Int = 6
    @Binding var otpCode: String
    
    // Single focus state for the invisible text field
    @FocusState private var isFocused: Bool
    
    var body: some View {
        ZStack {
            // Invisible TextField to handle actual input reliably
            TextField("", text: $otpCode)
                .keyboardType(.numberPad)
                .focused($isFocused)
                .opacity(0)
                .onChange(of: otpCode) { newValue in
                    if newValue.count > length {
                        otpCode = String(newValue.prefix(length))
                    }
                    if newValue.count == length {
                        isFocused = false
                    }
                }
            
            // Visual Boxes overlay
            HStack(spacing: 12) {
                ForEach(0..<length, id: \.self) { index in
                    OTPBox(
                        char: getChar(at: index),
                        isFocused: isFocused && (otpCode.count == index || (otpCode.count == length && index == length - 1))
                    )
                }
            }
            // Tapping the boxes focuses the invisible text field
            .onTapGesture {
                isFocused = true
            }
        }
        .onAppear {
            isFocused = true
        }
    }
    
    private func getChar(at index: Int) -> String {
        guard index < otpCode.count else { return "" }
        let stringIndex = otpCode.index(otpCode.startIndex, offsetBy: index)
        return String(otpCode[stringIndex])
    }
}

struct OTPBox: View {
    var char: String
    var isFocused: Bool
    
    var body: some View {
        Text(char)
            .font(.system(size: 24, weight: .bold))
            .foregroundColor(Color.AppTheme.textPrimary)
            .frame(width: 45, height: 55)
            .background(Color.AppTheme.secondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isFocused ? Color.AppTheme.primary : Color.gray.opacity(0.3), lineWidth: isFocused ? 2 : 1)
            )
            .shadow(color: Color.black.opacity(isFocused ? 0.05 : 0), radius: 4, x: 0, y: 2)
    }
}
