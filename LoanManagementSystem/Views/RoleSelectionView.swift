import SwiftUI

struct RoleSelectionView: View {
    @EnvironmentObject var appState: AppStateManager
    @State private var tempSelectedRole: PortalRole = .customer
    
    var body: some View {
        ZStack {
            // Elegant background gradient matching Splash Screen branding
            LinearGradient(
                colors: [
                    Color(hex: "#0A2540"), // Deep Brand Navy
                    Color(hex: "#162E5C"),
                    Color(hex: "#203A70")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Subtle backdrop glowing circles for high-end visual depth
            VStack {
                HStack {
                    Circle()
                        .fill(Color(hex: "#1A73E8").opacity(0.12))
                        .frame(width: 250, height: 250)
                        .blur(radius: 50)
                        .offset(x: -80, y: -50)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Circle()
                        .fill(Color(hex: "#00C48C").opacity(0.08))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: 100, y: 100)
                }
            }
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header Logo and Subtitle
                VStack(spacing: 12) {
                    Image(systemName: "indianrupeesign.circle.fill")
                        .font(.system(size: 52))
                        .foregroundColor(.white)
                        .shadow(color: Color(hex: "#1A73E8").opacity(0.4), radius: 10, x: 0, y: 4)
                    
                    Text("Astra Loan Portal")
                        .font(.system(.title2, design: .rounded).bold())
                        .foregroundColor(.white)
                    
                    Text("Select your role to access your personalized workspace")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                .padding(.top, 30)
                .padding(.bottom, 10)
                
                // Roles Cards Container
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 14) {
                        ForEach(PortalRole.allCases) { role in
                            RoleCardView(
                                role: role,
                                isSelected: tempSelectedRole == role,
                                onTap: {
                                    HapticsManager.triggerImpact(style: .medium)
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        tempSelectedRole = role
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                }
                
                // Bottom Button Action Space
                VStack(spacing: 16) {
                    Button(action: {
                        HapticsManager.triggerImpact(style: .heavy)
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            appState.selectedRole = tempSelectedRole
                            appState.showRoleSelection = false
                        }
                    }) {
                        HStack {
                            Text("Continue as \(tempSelectedRole.rawValue)")
                                .font(.system(.body, design: .rounded).weight(.bold))
                            
                            Image(systemName: "arrow.right")
                                .font(.system(.body, design: .rounded).weight(.bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#1A73E8"),
                                    Color(hex: "#1557B0")
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: Color(hex: "#1A73E8").opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Role Card View
struct RoleCardView: View {
    let role: PortalRole
    let isSelected: Bool
    var onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon Frame
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.white.opacity(0.16) : Color.white.opacity(0.06))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: role.icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                }
                
                // Info block
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.rawValue)
                        .font(.system(.callout, design: .rounded).bold())
                        .foregroundColor(.white)
                    
                    Text(role.description)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Checkmark Selector
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color(hex: "#1A73E8") : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 22, height: 22)
                    
                    if isSelected {
                        Circle()
                            .fill(Color(hex: "#1A73E8"))
                            .frame(width: 12, height: 12)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.all, 16)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isSelected ? Color(hex: "#1A73E8").opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1.5)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct RoleSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        RoleSelectionView()
            .environmentObject(AppStateManager())
    }
}
