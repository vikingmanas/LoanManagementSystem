






import SwiftUI
import Combine
import Supabase



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



@MainActor
final class AuthManager: ObservableObject {




    @Published var isAuthenticated: Bool = false


    @Published var currentUser: AuthSessionUser? = nil


    @Published var isLoading: Bool = false


    @Published var errorMessage: String? = nil


    @Published var isAuthStateResolved: Bool = false



    init() {}


    func configure() {
        Task {
            do {
                let client = SupabaseManager.shared.client
                if let currentSession = try? await client.auth.session {
                    let user = currentSession.user
                    let role = try await AuthService.shared.fetchUserRole(uid: user.id)

                    self.currentUser = AuthSessionUser(
                        uid: user.id.uuidString,
                        email: user.email,
                        displayName: user.userMetadata["display_name"]?.description ?? "User"
                    )
                    self.isAuthenticated = true


                    if role == "borrower" {
                        BorrowerProfileStore.shared.ensureProfile(
                            email: user.email ?? "",
                            name: user.userMetadata["display_name"]?.description ?? "User"
                        )
                    }
                }
            } catch {
                print("Supabase Session Restore failed or timed out: \(error.localizedDescription)")
            }
            self.isAuthStateResolved = true
        }
    }



    @discardableResult
    func signIn(email: String, password: String) async -> (success: Bool, role: String?) {
        clearError()
        isLoading = true

        #if DEBUG

        if email == "bm1234@lms.com" || email == "lo1234@lms.com" || email == "ad1234@lms.com" {
            let role: String
            if email.starts(with: "bm") { role = "loan_manager" }
            else if email.starts(with: "lo") { role = "loan_officer" }
            else { role = "admin" }

            self.currentUser = AuthSessionUser(
                uid: UUID().uuidString,
                email: email,
                displayName: "Test Staff"
            )
            self.isAuthenticated = true
            self.isLoading = false
            return (true, role)
        }
        #endif

        do {
            let session = try await AuthService.shared.signIn(email: email, password: password)
            let user = session.user


            let role = try await AuthService.shared.fetchUserRole(uid: user.id)

            self.currentUser = AuthSessionUser(
                uid: user.id.uuidString,
                email: user.email,
                displayName: user.userMetadata["display_name"]?.description ?? "User"
            )
            self.isAuthenticated = true
            self.isLoading = false

            return (true, role)
        } catch {
            self.errorMessage = mapSupabaseError(error)
            self.isLoading = false
            return (false, nil)
        }
    }



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
        Task {
            try? await AuthService.shared.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
            BorrowerProfileStore.shared.signOut()
        }
    }



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




    func clearError() {
        errorMessage = nil
    }


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


    var userDisplayName: String {
        if let name = currentUser?.displayName,
           !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name
        }
        return currentUser?.email ?? "User"
    }


    var userEmail: String? {
        currentUser?.email
    }



    private func mapSupabaseError(_ error: Error) -> String {

        if let authServiceError = error as? AuthServiceError {
            return authServiceError.errorDescription ?? error.localizedDescription
        }

        let errDesc = error.localizedDescription


        if errDesc.localizedCaseInsensitiveContains("invalid login credentials") ||
           errDesc.localizedCaseInsensitiveContains("invalid credentials") {
            return "Incorrect email or password. Please try again."
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

