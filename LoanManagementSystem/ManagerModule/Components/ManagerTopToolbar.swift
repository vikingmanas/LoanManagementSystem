import SwiftUI

// MARK: - Manager Top Toolbar
struct ManagerTopToolbar: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    var onNotificationPressed: () -> Void
    var onSettingsPressed: () -> Void
    var onProfilePressed: () -> Void
    var onSearchPressed: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            // Left — Greeting + Branch
            VStack(alignment: .leading, spacing: 2) {
                Text(greetingText)
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)

                Text("Branch Manager · \(ManagerMockData.branchName)")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
            }

            Spacer()

            // Right — Action Buttons
            HStack(spacing: 10) {
                // Search
                ToolbarCircleButton(
                    icon: "magnifyingglass",
                    action: {
                        HapticsManager.triggerImpact(style: .light)
                        onSearchPressed()
                    }
                )

                // Notifications
                ToolbarCircleButton(
                    icon: "bell.fill",
                    badge: viewModel.unreadNotificationCount,
                    action: {
                        HapticsManager.triggerImpact(style: .light)
                        onNotificationPressed()
                    }
                )
                .accessibilityLabel("Notifications. \(viewModel.unreadNotificationCount) unread.")

                // Settings
                ToolbarCircleButton(
                    icon: "gearshape.fill",
                    action: {
                        HapticsManager.triggerImpact(style: .light)
                        onSettingsPressed()
                    }
                )

                // Profile Avatar
                Button(action: {
                    HapticsManager.triggerImpact(style: .medium)
                    onProfilePressed()
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "#00C48C"), Color(hex: "#009E70")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 34, height: 34)

                        Text(ManagerMockData.managerInitials)
                            .font(.system(.caption2, design: .rounded).bold())
                            .foregroundStyle(.white)
                    }
                    .shadow(color: Color(hex: "#00C48C").opacity(0.25), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(LMSPressableStyle())
                .accessibilityLabel("Profile: \(ManagerMockData.managerName)")
            }
        }
        .padding(.horizontal, LMSSpacing.lg)
        .padding(.top, LMSSpacing.md)
        .padding(.bottom, LMSSpacing.md)
        .background(LMSColors.surface)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting: String
        switch hour {
        case 5..<12:  greeting = "Good Morning"
        case 12..<17: greeting = "Good Afternoon"
        case 17..<22: greeting = "Good Evening"
        default:      greeting = "Hello"
        }
        let firstName = ManagerMockData.managerName.components(separatedBy: " ").first ?? "Manager"
        return "\(greeting), \(firstName) 🏢"
    }
}

// MARK: - Toolbar Circle Button
private struct ToolbarCircleButton: View {
    let icon: String
    var badge: Int = 0
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(LMSColors.surfaceElevated)
                    .frame(width: 34, height: 34)
                    .overlay(
                        Circle()
                            .stroke(LMSColors.separatorLight, lineWidth: 0.5)
                    )

                Image(systemName: icon)
                    .foregroundStyle(LMSColors.textSecondary)
                    .font(.system(size: 14, weight: .semibold))

                if badge > 0 {
                    Circle()
                        .fill(LMSColors.coral)
                        .frame(width: 10, height: 10)
                        .overlay(
                            Circle().stroke(Color(UIColor.systemBackground), lineWidth: 1.5)
                        )
                        .offset(x: -1, y: 1)
                }
            }
        }
        .buttonStyle(LMSPressableStyle())
    }
}
