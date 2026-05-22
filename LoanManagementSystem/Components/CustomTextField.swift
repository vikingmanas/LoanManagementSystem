import SwiftUI

struct CustomTextField: View {
    var icon: String
    var placeholder: String
    @Binding var text: String
    var isError: Bool = false
    var errorMessage: String = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .foregroundColor(Color.AppTheme.textSecondary)
                    .frame(width: 20)
                
                TextField(placeholder, text: $text)
                    .font(Font.AppTheme.input)
                    .foregroundColor(Color.AppTheme.textPrimary)
                    .disableAutocapitalization()
                    .autocorrectionDisabled(true)
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
