import SwiftUI

struct LockedFieldRow: View {
    var label: String
    var value: String
    var onRequestChange: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(Font.AppTheme.caption)
                    .foregroundStyle(Color.AppTheme.textSecondary)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(Color.AppTheme.success)
                        .font(.system(size: 12))
                    Text("Verified")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.AppTheme.success)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color.AppTheme.success.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }
            
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Color.AppTheme.textSecondary)
                    .font(.system(size: 14))
                
                Text(value)
                    .font(Font.AppTheme.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.AppTheme.textPrimary)
                
                Spacer()
                
                Button(action: onRequestChange) {
                    Text("Request Change")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.AppTheme.primary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.vertical, 4)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    Form {
        LockedFieldRow(label: "Full Name", value: "Rahul Sharma") {
            print("Request change tapped")
        }
    }
}
