import SwiftUI

// MARK: - Manager Floating Tab Bar (3 Tabs)
struct ManagerFloatingTabBar: View {
    @Binding var selectedTab: Int
    var unreadChatCount: Int = 0

    var body: some View {
        HStack {
            ManagerTabBarButton(
                iconName: "chart.bar",
                activeIconName: "chart.bar.fill",
                title: "Dashboard",
                isSelected: selectedTab == 0,
                badge: 0
            ) {
                selectedTab = 0
            }

            Spacer()

            ManagerTabBarButton(
                iconName: "person.2",
                activeIconName: "person.2.fill",
                title: "Applicants",
                isSelected: selectedTab == 1,
                badge: 0
            ) {
                selectedTab = 1
            }

            Spacer()

            ManagerTabBarButton(
                iconName: "bubble.left.and.bubble.right",
                activeIconName: "bubble.left.and.bubble.right.fill",
                title: "Messages",
                isSelected: selectedTab == 2,
                badge: unreadChatCount
            ) {
                selectedTab = 2
            }
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 8)
        .background(
            VisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
                .clipShape(Capsule())
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 5)
        )
        .overlay(
            Capsule()
                .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }
}

// MARK: - Tab Bar Button
private struct ManagerTabBarButton: View {
    let iconName: String
    let activeIconName: String
    let title: String
    let isSelected: Bool
    var badge: Int = 0
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticsManager.triggerImpact(style: .light)
            action()
        }) {
            VStack(spacing: 4) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: isSelected ? activeIconName : iconName)
                        .font(.system(size: 20, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? LMSColors.brandNavy : .secondary)
                        .frame(height: 24)

                    if badge > 0 {
                        Text("\(badge)")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 14, height: 14)
                            .background(LMSColors.coral)
                            .clipShape(Circle())
                            .offset(x: 6, y: -4)
                    }
                }

                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .semibold, design: .rounded))
                    .foregroundColor(isSelected ? LMSColors.brandNavy : .secondary)
            }
            .frame(width: 72)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(title) tab")
    }
}

#Preview {
    @Previewable @State var tab = 0
    ManagerFloatingTabBar(selectedTab: $tab, unreadChatCount: 2)
        .padding()
}

fileprivate struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView()
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
}
