import SwiftUI

struct SecureInputField: View {
    var placeholder: String
    @Binding var text: String
    @State private var isVisible: Bool = false
    var isError: Bool = false
    var errorMessage: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                Image(systemName: "lock")
                    .foregroundColor(Color.AppTheme.textSecondary)
                    .frame(width: 20)
                
                if isVisible {
                    TextField(placeholder, text: $text)
                        .font(Font.AppTheme.body)
                        .foregroundColor(Color.AppTheme.textPrimary)
                        .disableAutocapitalization()
                        .autocorrectionDisabled(true)
                } else {
                    SecureField(placeholder, text: $text)
                        .font(Font.AppTheme.body)
                        .foregroundColor(Color.AppTheme.textPrimary)
                        .disableAutocapitalization()
                        .autocorrectionDisabled(true)
                }
                
                Button(action: {
                    isVisible.toggle()
                }) {
                    Image(systemName: isVisible ? "eye.slash" : "eye")
                        .foregroundColor(Color.AppTheme.textSecondary)
                }
            }
            .padding()
            .background(Color.AppTheme.secondary)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isError ? Color.AppTheme.error : Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            if isError && !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(Font.AppTheme.caption)
                    .foregroundColor(Color.AppTheme.error)
                    .padding(.leading, 12)
            }
        }
    }
}
