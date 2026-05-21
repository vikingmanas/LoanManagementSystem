import SwiftUI

struct CheckboxView: View {
    @Binding var isChecked: Bool
    var label: String
    
    var body: some View {
        Button(action: {
            withAnimation {
                isChecked.toggle()
            }
        }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isChecked ? "checkmark.square.fill" : "square")
                    .foregroundColor(isChecked ? Color.AppTheme.primary : Color.AppTheme.textSecondary)
                    .font(.system(size: 20))
                
                Text(label)
                    .font(Font.AppTheme.body)
                    .foregroundColor(Color.AppTheme.textSecondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CheckboxView_Previews: PreviewProvider {
    static var previews: some View {
        CheckboxView(isChecked: .constant(true), label: "I agree to the Terms and Conditions")
            .padding()
    }
}
