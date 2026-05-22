import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - ContentView (Auth Router)
/// Root view that switches between authentication and dashboard flows
/// based on the current Firebase auth state.
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
            authManager.configure()
            
            // Perform initial session check after configuration listener registers
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                handleUserAuthenticationStateChange()
            }

            // MARK: - Splash Delay
            // Skip the splash delay inside SwiftUI Previews for instant canvas rendering.
            let isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
            let delay = isPreview ? 3.0 : 5.0
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showSplash = false
                }
            }
        }
        .onChange(of: authManager.isAuthenticated) {
            handleUserAuthenticationStateChange()
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

    private func handleUserAuthenticationStateChange() {
        guard authManager.isAuthenticated, let user = authManager.currentUser else {
            // Clean up session if not authenticated
            if appState.selectedRole != .customer {
                appState.logout()
            }
            return
        }
        
        // Fetch the user document from Firestore to resolve the role
        Task {
            do {
                let doc = try await Firestore.firestore().collection("users").document(user.uid).getDocument()
                if let data = doc.data(), let roleString = data["role"] as? String {
                    await MainActor.run {
                        switch roleString {
                        case "admin":
                            appState.selectedRole = .admin
                            appState.isAuthenticated = true
                            appState.showRoleSelection = false
                        case "loanOfficer", "loan_officer":
                            appState.selectedRole = .loanOfficer
                            appState.isAuthenticated = true
                            appState.showRoleSelection = false
                        case "bankManager", "bank_manager":
                            appState.selectedRole = .bankManager
                            appState.isAuthenticated = true
                            appState.showRoleSelection = false
                        default:
                            appState.selectedRole = .customer
                            appState.isAuthenticated = false
                            appState.showRoleSelection = false
                            // Trigger customer profile sync
                            syncBorrowerProfileIfNeeded()
                        }
                    }
                } else {
                    // Fallback to customer if role is missing
                    await MainActor.run {
                        appState.selectedRole = .customer
                        syncBorrowerProfileIfNeeded()
                    }
                }
            } catch {
                print("Error resolving user role: \(error.localizedDescription)")
                // Fallback to customer
                await MainActor.run {
                    appState.selectedRole = .customer
                    syncBorrowerProfileIfNeeded()
                }
            }
        }
    }

    // MARK: - Splash View
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
