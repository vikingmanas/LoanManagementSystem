import SwiftUI

struct PrimaryButton: View {
    var title: String
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .font(Font.AppTheme.button)
                }
                Spacer()
            }
            .padding()
            .foregroundColor(.white)
            .background(
                isDisabled ? Color.gray.opacity(0.5) : Color.AppTheme.primary
            )
            .cornerRadius(12)
            .shadow(color: isDisabled ? Color.clear : Color.AppTheme.primary.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isDisabled || isLoading)
    }
}
