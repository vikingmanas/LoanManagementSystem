import SwiftUI
import Supabase

struct ContentView: View {

    @Environment(AuthManager.self) private var authManager: AuthManager

    @State private var appState = AppStateManager()

    @Bindable private var profileStore = BorrowerProfileStore.shared

    @State private var showSplash = true

    @AppStorage("biometricEnabled") private var biometricEnabled = false
    @State private var isAppUnlocked = false

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {

            if showSplash || !authManager.isAuthStateResolved {

                splashView
                    .transition(.opacity)

            } else if appState.showRoleSelection && !authManager.isAuthenticated && !appState.isAuthenticated {

                RoleSelectionView()
                    .environment(appState)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

            } else {

                Group {

                    if isCurrentRoleAuthenticated {
                        
                        if biometricEnabled && !isAppUnlocked {
                            AppLockView(isUnlocked: $isAppUnlocked)
                                .transition(.opacity)
                        } else {
                            switch appState.selectedRole {
                        case .customer:
                            if appState.requiresBorrowerOnboarding && profileStore.profile?.isOnboardingCompleted != true {
                                OnboardingQuestionnaireView()
                                    .environment(authManager)
                                    .environment(appState)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            } else {
                                MainTabView()
                                    .environment(authManager)
                                    .environment(appState)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            }
                        case .loanOfficer:
                            LoanOfficerDashboardView()
                                .environment(authManager)
                                .environment(appState)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        case .bankManager:
                            ManagerDashboardView()
                                .environment(authManager)
                                .environment(appState)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        case .admin:
                            AdminDashboardView()
                                .environment(authManager)
                                .environment(appState)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                        }

                    } else {

                        if appState.selectedRole == .customer {
                            SignInView()
                                .environment(authManager)
                                .environment(appState)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        } else {
                            StaffLoginView()
                                .environment(authManager)
                                .environment(appState)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        }
                    }
                }
            }
        }
        .animation(
            .spring(response: 0.5, dampingFraction: 0.85),
            value: authManager.isAuthenticated
        )
        .animation(
            .spring(response: 0.5, dampingFraction: 0.85),
            value: appState.isAuthenticated
        )
        .animation(
            .spring(response: 0.5, dampingFraction: 0.85),
            value: appState.showRoleSelection
        )
        .animation(
            .easeInOut(duration: 0.4),
            value: authManager.isAuthStateResolved
        )
        .onAppear {
            authManager.configure(appState: appState)

            let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            let delay = isPreview ? 0.5 : 2.6
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
        .onChange(of: authManager.isAuthenticated) {
            syncBorrowerProfileIfNeeded()

            if !authManager.isAuthenticated {
                isAppUnlocked = false
            }
        }
        .onChange(of: authManager.userEmail) {
            syncBorrowerProfileIfNeeded()
        }
        .onChange(of: scenePhase) {

            if scenePhase == .background && biometricEnabled {
                isAppUnlocked = false
            }
        }
        .animation(
            .easeInOut(duration: 0.3),
            value: isAppUnlocked
        )
    }

    private var isCurrentRoleAuthenticated: Bool {

        guard !authManager.isResettingPassword else { return false }
        
        if appState.selectedRole == .customer {
            return authManager.isAuthenticated
        }
        return authManager.isAuthenticated && appState.isAuthenticated
    }

    private func syncBorrowerProfileIfNeeded() {
        guard appState.selectedRole == .customer,
              authManager.isAuthenticated,
              let email = authManager.userEmail else {
            return
        }

        Task {
            if let session = try? await SupabaseManager.shared.client.auth.session {
                await profileStore.fetchProfileFromSupabase(
                    uid: session.user.id.uuidString,
                    email: session.user.email ?? email,
                    name: authManager.userDisplayName
                )
            }
        }
    }

    private var splashView: some View {
        LMSAnimatedSplashView()
    }
}

private struct LMSAnimatedSplashView: View {
    @State private var logoVisible = false
    @State private var titleVisible = false
    @State private var orbiting = false

    var body: some View {
        ZStack {
            Color(hex: "#020711")
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    Color(hex: "#12375E").opacity(0.72),
                    Color(hex: "#071523").opacity(0.52),
                    .clear
                ],
                center: .center,
                startRadius: 12,
                endRadius: 420
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(
                            AngularGradient(
                                colors: [
                                    .clear,
                                    LMSColors.actionBlue.opacity(0.8),
                                    LMSColors.emerald.opacity(0.9),
                                    .clear
                                ],
                                center: .center
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 226, height: 226)
                        .rotationEffect(.degrees(orbiting ? 360 : 0))

                    Circle()
                        .stroke(LMSColors.actionBlue.opacity(0.18), lineWidth: 1)
                        .frame(width: 194, height: 194)
                        .scaleEffect(logoVisible ? 1 : 0.55)

                    Circle()
                        .fill(LMSColors.actionBlue.opacity(0.18))
                        .frame(width: 168, height: 168)
                        .blur(radius: 28)
                        .scaleEffect(logoVisible ? 1.22 : 0.45)

                    Image("SplashLogo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 140, height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 32, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: LMSColors.actionBlue.opacity(0.6), radius: 28)
                        .shadow(color: LMSColors.emerald.opacity(0.28), radius: 48)
                        .scaleEffect(logoVisible ? 1 : 0.42)
                        .opacity(logoVisible ? 1 : 0)
                }

                VStack(spacing: 7) {
                    Text("LoanMate")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)

                    Text("Smarter lending. Simpler life.")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                        .foregroundStyle(Color.white.opacity(0.58))
                        .tracking(0.7)
                }
                .opacity(titleVisible ? 1 : 0)
                .offset(y: titleVisible ? 0 : 16)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.85, dampingFraction: 0.72)) {
                logoVisible = true
            }
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                orbiting = true
            }
            withAnimation(.easeOut(duration: 0.7).delay(0.45)) {
                titleVisible = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("LoanMate")
    }
}

#Preview {
    ContentView()
        .environment(AuthManager())
}
