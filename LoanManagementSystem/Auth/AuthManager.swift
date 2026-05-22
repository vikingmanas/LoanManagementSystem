//
//  AuthManager.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 19/05/26.
//

import SwiftUI
import Combine
import Supabase

// MARK: - AuthSessionUser
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

// MARK: - AuthManager
/// Centralized authentication service wrapping Supabase Auth.
@MainActor
final class AuthManager: ObservableObject {

    // MARK: - Published State

    /// Whether a user is currently authenticated.
    @Published var isAuthenticated: Bool = false

    /// The currently signed-in user, if any.
    @Published var currentUser: AuthSessionUser? = nil

    /// Controls the loading overlay in auth views.
    @Published var isLoading: Bool = false

    /// User-friendly error message shown in alerts/banners.
    @Published var errorMessage: String? = nil

    /// Indicates the auth state listener has resolved at least once.
    @Published var isAuthStateResolved: Bool = false

    // MARK: - Init

    init() {}

    /// Restores the Supabase session on app launch if one exists.
    func configure() {
        // Reset auth state synchronously and immediately to guarantee a clean, unauthenticated onboarding flow
        // and prevent the splash screen from hanging or waiting for network-dependent sign-out tasks.
        self.currentUser = nil
        self.isAuthenticated = false
        self.isAuthStateResolved = true
        
        // Execute the server-side sign-out asynchronously in the background.
        Task {
            let client = SupabaseManager.shared.client
            try? await client.auth.signOut()
        }
    }

    // MARK: - Sign In
    /// Signs in an existing user with email and password, returning their assigned role.
    @discardableResult
    func signIn(email: String, password: String) async -> (success: Bool, role: String?) {
        clearError()
        isLoading = true

        #if DEBUG
        // Development bypass for staff testing without requiring Supabase seeded users
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
            
            // Fetch role from users database table
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

    // MARK: - Sign Up
    /// Creates a new borrower account with email and password, then inserts them in the users table.
    @discardableResult
    func signUp(name: String, email: String, password: String) async -> Bool {
        clearError()
        isLoading = true

        do {
            if let session = try await AuthService.shared.signUp(email: email, password: password, name: name) {
                let user = session.user
                self.currentUser = AuthSessionUser(
                    uid: user.id.uuidString,
                    email: user.email,
                    displayName: name
                )
                self.isAuthenticated = true
            } else {
                // Sign up succeeded but session is nil because email confirmation is enabled
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

    // MARK: - Sign Out
    /// Signs out the current user and resets state.
    func signOut() {
        Task {
            try? await AuthService.shared.signOut()
            self.currentUser = nil
            self.isAuthenticated = false
            BorrowerProfileStore.shared.signOut()
        }
    }

    // MARK: - Password Reset
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

    // MARK: - Helpers

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

    // MARK: - Error Mapping
    /// Converts Supabase Auth/DB errors into user-friendly messages.
    private func mapSupabaseError(_ error: Error) -> String {
        let errDesc = error.localizedDescription
        
        // Handle common auth/network string matches
        if errDesc.localizedCaseInsensitiveContains("invalid login credentials") ||
           errDesc.localizedCaseInsensitiveContains("invalid credentials") {
            return "Incorrect email or password. Please try again."
        } else if errDesc.localizedCaseInsensitiveContains("email already in use") ||
                  errDesc.localizedCaseInsensitiveContains("user already exists") {
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
