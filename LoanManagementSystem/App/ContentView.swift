import SwiftUI
import Supabase

// MARK: - ContentView (Auth Router)
/// Root view that switches between authentication and dashboard flows
/// based on the current Supabase auth state.
struct ContentView: View {

    // Supabase/Auth Manager
    @EnvironmentObject private var authManager: AuthManager

    // App State Manager
    @StateObject private var appState = AppStateManager()

    // Observed Profile Store
    @ObservedObject private var profileStore = BorrowerProfileStore.shared

    // Splash control
    @State private var showSplash = true

    // Biometrics State
    @AppStorage("biometricEnabled") private var biometricEnabled = false
    @State private var isAppUnlocked = false

    var body: some View {
        ZStack {

            // MARK: - Splash Screen
            if showSplash || !authManager.isAuthStateResolved {

                splashView
                    .transition(.opacity)

            } else if appState.showRoleSelection && !authManager.isAuthenticated && !appState.isAuthenticated {

                RoleSelectionView()
                    .environmentObject(appState)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))

            } else {

                Group {

                    // MARK: - Authenticated Flow
                    if isCurrentRoleAuthenticated {
                        
                        if biometricEnabled && !isAppUnlocked {
                            AppLockView(isUnlocked: $isAppUnlocked)
                                .transition(.opacity)
                        } else {
                            switch appState.selectedRole {
                        case .customer:
                            if appState.requiresBorrowerOnboarding && profileStore.profile?.isOnboardingCompleted != true {
                                OnboardingQuestionnaireView()
                                    .environmentObject(authManager)
                                    .environmentObject(appState)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            } else {
                                MainTabView()
                                    .environmentObject(authManager)
                                    .environmentObject(appState)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            }
                        case .loanOfficer:
                            LoanOfficerDashboardView()
                                .environmentObject(authManager)
                                .environmentObject(appState)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        case .bankManager:
                            ManagerDashboardView()
                                .environmentObject(authManager)
                                .environmentObject(appState)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        case .admin:
                            AdminDashboardView()
                                .environmentObject(authManager)
                                .environmentObject(appState)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        }
                        }

                    } else {

                        // MARK: - Authentication Flow
                        if appState.selectedRole == .customer {
                            SignInView()
                                .environmentObject(authManager)
                                .environmentObject(appState)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        } else {
                            StaffLoginView()
                                .environmentObject(authManager)
                                .environmentObject(appState)
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

            // MARK: - Splash Delay
            // Skip the splash delay inside SwiftUI Previews for instant canvas rendering.
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
        }
        .onChange(of: authManager.userEmail) {
            syncBorrowerProfileIfNeeded()
        }
    }

    private var isCurrentRoleAuthenticated: Bool {
        // Block dashboard routing while user is in the password reset flow
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

    // MARK: - Splash View
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
        .environmentObject(AuthManager())
}
