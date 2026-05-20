import SwiftUI

struct QuickActionItem: Identifiable {
    let id = UUID()
    let title: String
    let symbol: String
    let color: Color
    let identifier: String
}

struct QuickActionRowView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onActionTapped: (String) -> Void
    
    private let actions = [
        QuickActionItem(title: "New App", symbol: "plus.circle.fill", color: AppTheme.brandNavy, identifier: "new_app"),
        QuickActionItem(title: "Verify Docs", symbol: "doc.text.magnifyingglass", color: AppTheme.actionBlue, identifier: "verify_docs"),
        QuickActionItem(title: "Messages", symbol: "bubble.left.and.bubble.right.fill", color: Color.teal, identifier: "messages"),
        QuickActionItem(title: "Reports", symbol: "chart.bar.fill", color: Color.purple, identifier: "reports"),
        QuickActionItem(title: "Borrowers", symbol: "person.2.fill", color: AppTheme.successGreen, identifier: "borrowers"),
        QuickActionItem(title: "Escalate", symbol: "arrow.up.forward.circle.fill", color: AppTheme.warningAmber, identifier: "escalate")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Actions")
                .font(.system(.subheadline, design: .rounded).bold())
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(actions) { action in
                        Button(action: {
                            HapticsManager.triggerImpact(style: .medium)
                            onActionTapped(action.identifier)
                        }) {
                            VStack(spacing: 8) {
                                ZStack {
                                    Circle()
                                        .fill(action.color.opacity(0.12))
                                        .frame(width: 40, height: 40)
                                    
                                    Image(systemName: action.symbol)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(action.color)
                                }
                                
                                Text(action.title)
                                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                            }
                            .frame(width: 76, height: 76)
                            .background(.ultraThinMaterial)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .accessibilityLabel("Quick action: \(action.title)")
                        .accessibilityHint("Triggers \(action.title) workflow")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
            }
        }
    }
}

// Micro-animation ButtonStyle
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.5), value: configuration.isPressed)
    }
}
