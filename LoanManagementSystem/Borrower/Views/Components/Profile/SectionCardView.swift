import SwiftUI

struct SectionCardView<Content: View>: View {
    var title: String
    var icon: String
    var showEdit: Bool = true
    var onEdit: (() -> Void)? = nil
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.lg) {

            HStack(spacing: LMSSpacing.md) {
                Image(systemName: icon)
                    .font(.system(.callout, design: .rounded).weight(.semibold))
                    .foregroundStyle(LMSColors.brandNavy)
                    .frame(width: 22)

                Text(title)
                    .font(LMSFont.headline)
                    .foregroundStyle(LMSColors.textPrimary)

                Spacer()

                if showEdit {
                    Button(action: {
                        onEdit?()
                    }) {
                        Text("Edit")
                            .font(LMSFont.caption.weight(.semibold))
                            .foregroundStyle(LMSColors.brandNavy)
                    }
                }
            }

            Divider()

            content()
        }
        .padding(LMSSpacing.xl)
        .lmsCard(radius: LMSRadius.lg)
    }
}

#Preview {
    EmptyView()
}
