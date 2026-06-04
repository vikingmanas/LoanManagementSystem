
import Observation
import SwiftUI
import Combine
import Supabase

/// Custom User representation replacing FirebaseAuth.User to prepare for Supabase.
struct AuthSessionUser: Codable {
    let uid: String
    let email: String?
    let displayName: String?
    
    init(uid: String, email: String?, displayName: String?) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
    }
}

/// Centralized authentication service wrapping Supabase Auth.
@MainActor
@Observable
final class AuthManager {
    static let shared = AuthManager()


    /// Whether a user is currently authenticated.
    var isAuthenticated: Bool = false

    /// The currently signed-in user, if any.
    var currentUser: AuthSessionUser? = nil

    /// The detailed profile for the currently signed-in staff member, if any.
    var currentStaffProfile: StaffMember? = nil

    /// Controls the loading overlay in auth views.
    var isLoading: Bool = false

    /// User-friendly error message shown in alerts/banners.
    var errorMessage: String? = nil

    /// Indicates the auth state listener has resolved at least once.
    var isAuthStateResolved: Bool = false

    /// True while the user is in the password-reset OTP flow.
    /// When true, ContentView should NOT route to the dashboard.
    var isResettingPassword: Bool = false


    init() {}

    /// Restores the Supabase session on app launch if one exists.
    func configure(appState: AppStateManager? = nil) {
        Task {
            let client = SupabaseManager.shared.client
            do {
                let session = try await client.auth.session
                let user = session.user
                
                let role = try? await AuthService.shared.fetchUserRole(uid: user.id)
                
                self.currentUser = AuthSessionUser(
                    uid: user.id.uuidString,
                    email: user.email,
                    displayName: user.userMetadata["display_name"]?.description ?? "User"
                )
                Task {
                    await PushNotificationService.shared.registerCurrentDeviceTokenIfPossible()
                }
                
                if role == "loan_officer" {
                    if let officerProfile = try? await DatabaseService.shared.fetchLoanOfficerProfile(userId: user.id) {
                        self.currentStaffProfile = officerProfile
                    }
                }
                
                self.isAuthenticated = true
                self.isAuthStateResolved = true
                
                if let appState = appState {
                    if let role = role {
                        switch role {
                        case "admin": appState.selectedRole = .admin
                        case "manager", "loan_manager": appState.selectedRole = .bankManager
                        case "loan_officer": appState.selectedRole = .loanOfficer
                        default: appState.selectedRole = .customer
                        }
                    } else {
                        appState.selectedRole = .customer
                    }
                    if appState.selectedRole != .customer {
                        appState.login()
                    }
                }
                
                print("[AuthManager] Session restored for user: \(user.email ?? "unknown"), role: \(role ?? "borrower")")
                
                if role == "borrower" || role == nil {
                    await CentralLoanRepository.shared.fetchApplicationsFromSupabase(borrowerId: user.id)
                }
            } catch {
                self.currentUser = nil
                self.isAuthenticated = false
                self.isAuthStateResolved = true
                print("[AuthManager] No existing session found. User must sign in.")
            }
        }
    }

    /// Signs in an existing user with email and password, returning their assigned role.
    @discardableResult
    func signIn(email: String, password: String) async -> (success: Bool, role: String?) {
        clearError()
        isLoading = true

        do {
            let session = try await AuthService.shared.signIn(email: email, password: password)
            let user = session.user
            
            let role = try await AuthService.shared.fetchUserRole(uid: user.id)
            
            if role == "loan_officer" {
                if let officerProfile = try? await DatabaseService.shared.fetchLoanOfficerProfile(userId: user.id) {
                    self.currentStaffProfile = officerProfile
                }
            }
            
            self.currentUser = AuthSessionUser(
                uid: user.id.uuidString,
                email: user.email,
                displayName: user.userMetadata["display_name"]?.description ?? "User"
            )
            Task {
                await PushNotificationService.shared.registerCurrentDeviceTokenIfPossible()
            }
            self.isAuthenticated = true
            self.isLoading = false
            
            if role == "borrower" {
                Task {
                    await CentralLoanRepository.shared.fetchApplicationsFromSupabase(borrowerId: user.id)
                }
            }
            
            return (true, role)
        } catch {
            self.errorMessage = mapSupabaseError(error)
            self.isLoading = false
            return (false, nil)
        }
    }

    @discardableResult
    func sendEmailOTP(email: String) async -> Bool {
        clearError()
        isLoading = true

        do {
            try await AuthService.shared.sendEmailOTP(email: email)
            isLoading = false
            return true
        } catch {
            self.errorMessage = mapSupabaseError(error)
            isLoading = false
            return false
        }
    }

    @discardableResult
    func verifyEmailOTP(email: String, token: String) async -> (success: Bool, role: String?) {
        clearError()
        isLoading = true

        do {
            let response = try await AuthService.shared.verifyEmailOTP(email: email, token: token)
            let user = response.user
            let role = try await AuthService.shared.fetchUserRole(uid: user.id)

            if role == "loan_officer" {
                if let officerProfile = try? await DatabaseService.shared.fetchLoanOfficerProfile(userId: user.id) {
                    self.currentStaffProfile = officerProfile
                }
            }

            self.currentUser = AuthSessionUser(
                uid: user.id.uuidString,
                email: user.email,
                displayName: user.userMetadata["display_name"]?.description ?? "User"
            )
            Task {
                await PushNotificationService.shared.registerCurrentDeviceTokenIfPossible()
            }
            self.isAuthenticated = true
            self.isLoading = false

            if role == "borrower" {
                Task {
                    await CentralLoanRepository.shared.fetchApplicationsFromSupabase(borrowerId: user.id)
                }
            }

            return (true, role)
        } catch {
            self.errorMessage = mapSupabaseError(error)
            self.isLoading = false
            return (false, nil)
        }
    }

    /// Creates a new borrower account with email and password, then inserts them in the users table.
    @discardableResult
    func signUp(name: String, email: String, password: String, phone: String) async -> Bool {
        clearError()
        isLoading = true

        do {
            if let session = try await AuthService.shared.signUp(email: email, password: password, name: name, phone: phone) {
                let user = session.user
                self.currentUser = AuthSessionUser(
                    uid: user.id.uuidString,
                    email: user.email,
                    displayName: name
                )
                Task {
                    await PushNotificationService.shared.registerCurrentDeviceTokenIfPossible()
                }
                self.isAuthenticated = true
            } else {
                self.errorMessage = "Account created! Please check your email inbox to confirm your email before signing in."
                self.isLoading = false
                return false
            }
            self.isLoading = false
            return true
        } catch {
            self.errorMessage = mapSupabaseError(error)
            self.isLoading = false
            return false
        }
    }

    func signOut() {
        self.currentUser = nil
        self.currentStaffProfile = nil
        self.isAuthenticated = false
        BorrowerProfileStore.shared.signOut()
        CentralLoanRepository.shared.clearState()
        Task {
            await PushNotificationService.shared.deactivateCurrentDeviceToken()
            try? await AuthService.shared.signOut()
            self.currentUser = nil
            self.currentStaffProfile = nil
            self.isAuthenticated = false
            BorrowerProfileStore.shared.signOut()
            CentralLoanRepository.shared.clearState()
        }
    }

    /// Sends a password reset email via Supabase.
    @discardableResult
    func resetPassword(email: String) async -> Bool {
        clearError()
        isLoading = true

        do {
            try await SupabaseManager.shared.client.auth.resetPasswordForEmail(email)
            self.isLoading = false
            return true
        } catch {
            self.errorMessage = mapSupabaseError(error)
            self.isLoading = false
            return false
        }
    }

    /// Verifies the 6-digit password recovery code.
    /// NOTE: Does NOT set isAuthenticated to avoid routing to dashboard.
    /// Instead sets isResettingPassword so the UI stays on the reset flow.
    @discardableResult
    func verifyRecoveryOTP(email: String, token: String) async -> Bool {
        clearError()
        isLoading = true

        do {
            try await SupabaseManager.shared.client.auth.verifyOTP(
                email: email,
                token: token,
                type: .recovery
            )
            
            self.isResettingPassword = true
            self.isLoading = false
            return true
        } catch {
            self.errorMessage = mapSupabaseError(error)
            self.isLoading = false
            return false
        }
    }
    
    /// Updates the password for the currently signed-in user.
    /// After success, signs the user out so they can log in fresh with the new password.
    @discardableResult
    func updatePassword(newPassword: String) async -> Bool {
        clearError()
        isLoading = true

        do {
            try await AuthService.shared.updatePassword(newPassword: newPassword)
            signOut()
            self.isResettingPassword = false
            self.isLoading = false
            return true
        } catch {
            self.errorMessage = mapSupabaseError(error)
            self.isLoading = false
            return false
        }
    }


    /// Clears any existing error message.
    func clearError() {
        errorMessage = nil
    }

    /// Returns the user's display name initials (e.g., "Raj Kumar" → "RK").
    var userInitials: String {
        if let displayName = currentUser?.displayName,
           !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let parts = displayName.split(separator: " ")
            if parts.count >= 2 {
                return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
            }
            return String(displayName.prefix(2)).uppercased()
        }
        if let email = currentUser?.email {
            return String(email.prefix(1)).uppercased()
        }
        return "U"
    }

    /// Returns the user's display name, or email, or "User" as fallback.
    var userDisplayName: String {
        if let name = currentUser?.displayName,
           !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name
        }
        return currentUser?.email ?? "User"
    }

    /// Returns the signed-in user's email.
    var userEmail: String? {
        currentUser?.email
    }

    /// Converts Supabase Auth/DB errors into user-friendly messages.
    private func mapSupabaseError(_ error: Error) -> String {
        if let authServiceError = error as? AuthServiceError {
            return authServiceError.errorDescription ?? error.localizedDescription
        }
        
        let errDesc = error.localizedDescription
        
        if errDesc.localizedCaseInsensitiveContains("invalid login credentials") ||
           errDesc.localizedCaseInsensitiveContains("invalid credentials") {
            return "Incorrect email or password. Please try again."
        } else if errDesc.localizedCaseInsensitiveContains("email address") && errDesc.localizedCaseInsensitiveContains("is invalid") {
            return "You are not registered."
        } else if errDesc.localizedCaseInsensitiveContains("email already in use") ||
                  errDesc.localizedCaseInsensitiveContains("user already exists") ||
                  errDesc.localizedCaseInsensitiveContains("already registered") {
            return "This email is already registered. Try logging in instead."
        } else if errDesc.localizedCaseInsensitiveContains("password is too weak") ||
                  errDesc.localizedCaseInsensitiveContains("password should be") {
            return "Password is too weak. Ensure it is at least 6 characters and strong."
        } else if errDesc.localizedCaseInsensitiveContains("network") ||
                  errDesc.localizedCaseInsensitiveContains("connection") ||
                  errDesc.localizedCaseInsensitiveContains("timed out") {
            return "Network connection issue. Please check your internet connection."
        }
        
        return errDesc
    }
}
