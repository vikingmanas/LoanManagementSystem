import SwiftUI

struct PasswordStrengthView: View {
    var isMinLength: Bool
    var hasUppercase: Bool
    var hasNumber: Bool
    var hasSpecialChar: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Password Requirements:")
                .font(Font.AppTheme.caption)
                .fontWeight(.semibold)
                .foregroundColor(Color.AppTheme.textSecondary)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    RequirementRow(isMet: isMinLength, text: "Min 8 characters")
                    RequirementRow(isMet: hasUppercase, text: "1 Uppercase")
                }
                
                VStack(alignment: .leading, spacing: 4) {
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
                .foregroundColor(isMet ? Color.AppTheme.success : Color.AppTheme.textSecondary)
                .font(.system(size: 12))
            
            Text(text)
                .font(Font.AppTheme.caption)
                .foregroundColor(isMet ? Color.AppTheme.textPrimary : Color.AppTheme.textSecondary)
        }
    }
}

struct PasswordStrengthView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordStrengthView(isMinLength: true, hasUppercase: false, hasNumber: true, hasSpecialChar: false)
            .padding()
    }
}
