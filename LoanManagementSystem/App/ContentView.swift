import SwiftUI




struct ContentView: View {


    @EnvironmentObject private var authManager: AuthManager


    @StateObject private var appState = AppStateManager()


    @ObservedObject private var profileStore = BorrowerProfileStore.shared


    @State private var showSplash = true

    var body: some View {
        ZStack {


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

                    } else {


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
            authManager.configure()
            syncBorrowerProfileIfNeeded()



            let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            let delay = isPreview ? 3.0 : 5.0

            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
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


    private var splashView: some View {
        ZStack {

            LinearGradient(
                colors: [
                    Color.brandNavy,
                    Color(hex: "#2E3B84")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {

                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.white)

                Text("Loan Manager")
                    .font(.system(.title, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.white.opacity(0.8))
                    .scaleEffect(1.1)
            }

        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}

