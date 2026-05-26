import SwiftUI

struct DataRowView: View {
    var label: String
    var value: String
    var valueColor: Color = Color.AppTheme.textPrimary
    var isVerified: Bool = false
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(Font.AppTheme.body)
                .foregroundStyle(Color.AppTheme.textSecondary)
            
            Spacer()
            
            HStack(spacing: 4) {
                Text(value)
                    .font(Font.AppTheme.body)
                    .fontWeight(.medium)
                    .foregroundStyle(valueColor)
                    .multilineTextAlignment(.trailing)
                
                if isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.AppTheme.success)
                        .font(.system(size: 14))
                }
            }
        }
    }
}

#Preview {
    DataRowView(label: "Full Name", value: "Rahul Sharma", isVerified: true)
        .padding()
}
