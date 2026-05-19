import SwiftUI

struct SectionCardView<Content: View>: View {
    var title: String
    var icon: String
    var showEdit: Bool = true
    var onEdit: (() -> Void)? = nil
    @ViewBuilder var content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color.AppTheme.primary)
                    .frame(width: 20)
                
                Text(title)
                    .font(Font.AppTheme.subtitle)
                    .fontWeight(.bold)
                    .foregroundColor(Color.AppTheme.textPrimary)
                
                Spacer()
                
                if showEdit {
                    Button(action: {
                        onEdit?()
                    }) {
                        Text("Edit")
                            .font(Font.AppTheme.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(Color.AppTheme.primary)
                    }
                }
            }
            
            Divider()
                .background(Color.gray.opacity(0.2))
            
            // Custom Content
            content()
        }
        .padding(20)
        .background(Color.AppTheme.secondary)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}
