import SwiftUI

struct RoleSelectionView: View {
    @EnvironmentObject var appState: AppStateManager
    @State private var tempSelectedRole: PortalRole = .customer
    @State private var showAdminSignUp = false

    var body: some View {
        ZStack {

            LinearGradient(
                colors: [
                    LMSColors.brandNavy,
                    LMSColors.brandNavyLight,
                    Color(hex: "203A70")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()


            VStack {
                HStack {
                    Circle()
                        .fill(LMSColors.actionBlue.opacity(0.10))
                        .frame(width: 240, height: 240)
                        .blur(radius: 60)
                        .offset(x: -80, y: -50)
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Circle()
                        .fill(LMSColors.emerald.opacity(0.07))
                        .frame(width: 280, height: 280)
                        .blur(radius: 70)
                        .offset(x: 100, y: 80)
                }
            }
            .ignoresSafeArea()

            VStack(spacing: LMSSpacing.xl) {

                VStack(spacing: LMSSpacing.md) {
                    Button(action: {
                        HapticsManager.triggerImpact(style: .medium)
                        showAdminSignUp = true
                    }) {
                        Image(systemName: "indianrupeesign.circle.fill")
                            .font(.system(size: 52, weight: .light))
                            .foregroundStyle(.white.opacity(0.95))
                            .shadow(color: LMSColors.actionBlue.opacity(0.35), radius: 12, x: 0, y: 4)
                    }

                    Text("Loan Manager")
                        .font(LMSFont.title)
                        .foregroundStyle(.white)

                    Text("Select your role to access your workspace")
                        .font(LMSFont.subheadline)
                        .foregroundStyle(.white.opacity(0.65))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, LMSSpacing.xxxl)
                }
                .padding(.top, LMSSpacing.xxxl)
                .padding(.bottom, LMSSpacing.sm)


                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: LMSSpacing.md) {
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
                    .padding(.horizontal, LMSSpacing.xxl)
                    .padding(.vertical, LMSSpacing.sm)
                }


                VStack(spacing: LMSSpacing.lg) {
                    Button(action: {
                        HapticsManager.triggerImpact(style: .heavy)
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            appState.selectedRole = tempSelectedRole
                            appState.showRoleSelection = false
                        }
                    }) {
                        HStack(spacing: LMSSpacing.sm) {
                            Text("Continue as \(tempSelectedRole.rawValue)")
                                .font(LMSFont.button)

                            Image(systemName: "arrow.right")
                                .font(.system(.body, design: .rounded).weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(
                            LinearGradient(
                                colors: [LMSColors.actionBlue, Color(hex: "1557B0")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
                        .shadow(color: LMSColors.actionBlue.opacity(0.3), radius: 8, x: 0, y: 4)
                    }
                    .padding(.horizontal, LMSSpacing.xxl)
                }
                .padding(.bottom, LMSSpacing.xxxl)
            }
        }
        .accessibleSheet(isPresented: $showAdminSignUp) {
            AdminSignUpView()
        }
    }
}


struct RoleCardView: View {
    let role: PortalRole
    let isSelected: Bool
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: LMSSpacing.lg) {

                ZStack {
                    RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                        .fill(isSelected ? Color.white.opacity(0.16) : Color.white.opacity(0.06))
                        .frame(width: 48, height: 48)

                    Image(systemName: role.icon)
                        .font(.system(size: 20))
                        .foregroundStyle(isSelected ? .white : .white.opacity(0.7))
                }


                VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                    Text(role.rawValue)
                        .font(LMSFont.callout.weight(.bold))
                        .foregroundStyle(.white)

                    Text(role.description)
                        .font(LMSFont.caption)
                        .foregroundStyle(.white.opacity(0.55))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }

                Spacer()


                ZStack {
                    Circle()
                        .stroke(isSelected ? LMSColors.actionBlue : Color.white.opacity(0.2), lineWidth: 2)
                        .frame(width: 22, height: 22)

                    if isSelected {
                        Circle()
                            .fill(LMSColors.actionBlue)
                            .frame(width: 22, height: 22)

                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .padding(LMSSpacing.lg)
            .background(
                RoundedRectangle(cornerRadius: LMSRadius.xl, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.11) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: LMSRadius.xl, style: .continuous)
                    .stroke(isSelected ? LMSColors.actionBlue.opacity(0.5) : Color.white.opacity(0.08), lineWidth: 1.5)
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RoleSelectionView()
        .environmentObject(AppStateManager())
}

