import SwiftUI

struct ContentView: View {

    // Firebase/Auth Manager
    @EnvironmentObject private var authManager: AuthManager

    // App State Manager
    @StateObject private var appState = AppStateManager()

    // Observed Profile Store
    @ObservedObject private var profileStore = BorrowerProfileStore.shared

    // Splash control
    @State private var showSplash = true

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

                        switch appState.selectedRole {
                        case .customer:
                            if profileStore.profile?.isOnboardingCompleted == true {
                                MainTabView()
                                    .environmentObject(authManager)
                                    .environmentObject(appState)
                                    .transition(.asymmetric(
                                        insertion: .move(edge: .trailing).combined(with: .opacity),
                                        removal: .move(edge: .leading).combined(with: .opacity)
                                    ))
                            } else {
                                OnboardingQuestionnaireView()
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
                            BankManagerDashboardView()
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
            syncBorrowerProfileIfNeeded()

            // MARK: - Splash Delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {

                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
        .onChange(of: authManager.userEmail) {
            syncBorrowerProfileIfNeeded()
        }
    }

    private var isCurrentRoleAuthenticated: Bool {
        if appState.selectedRole == .customer {
            return authManager.isAuthenticated
        }
        return appState.isAuthenticated
    }

    private func syncBorrowerProfileIfNeeded() {
        guard appState.selectedRole == .customer,
              authManager.isAuthenticated,
              let email = authManager.userEmail else {
            return
        }

        profileStore.ensureProfile(
            email: email,
            name: authManager.userDisplayName
        )
    }

    // MARK: - Splash View
    private var splashView: some View {
        ZStack {
            LinearGradient(
                colors: [
                    LMSColors.brandNavy,
                    LMSColors.brandNavyLight
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: LMSSpacing.xxl) {
                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.system(size: 64, weight: .light))
                    .foregroundStyle(.white.opacity(0.95))
                    .shadow(color: .white.opacity(0.3), radius: 20, x: 0, y: 0)

                VStack(spacing: LMSSpacing.sm) {
                    Text("Loan Manager")
                        .font(LMSFont.largeTitle)
                        .foregroundColor(.white)

                    Text("Smart Lending, Simplified")
                        .font(LMSFont.footnote.weight(.medium))
                        .foregroundColor(.white.opacity(0.6))
                }

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white.opacity(0.7))
                    .scaleEffect(0.9)
                    .padding(.top, LMSSpacing.lg)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
