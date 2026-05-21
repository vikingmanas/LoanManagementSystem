//
//  AuthManager.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 19/05/26.
//

import SwiftUI
import Combine
import FirebaseAuth

// MARK: - AuthManager
/// Centralized authentication service wrapping Firebase Auth.
/// Observes auth state changes for automatic session persistence and auto-login.
@MainActor
public final class AuthManager: ObservableObject {

    // MARK: - Published State

    /// Whether a user is currently authenticated.
    @Published public var isAuthenticated: Bool = false

    /// The currently signed-in Firebase user, if any.
    @Published public var currentUser: FirebaseAuth.User? = nil

    /// Controls the loading overlay in auth views.
    @Published public var isLoading: Bool = false

    /// User-friendly error message shown in alerts/banners.
    @Published public var errorMessage: String? = nil

    /// Indicates the auth state listener has resolved at least once (used for splash screen).
    @Published public var isAuthStateResolved: Bool = false

    // MARK: - Private

    /// Handle for the Firebase auth state listener.
    /// Marked nonisolated(unsafe) so deinit (which is nonisolated) can access it to remove the listener.
    private nonisolated(unsafe) var authStateListenerHandle: AuthStateDidChangeListenerHandle?

    // MARK: - Init / Deinit

    public init() {
        // Listener setup is deferred to configure() which must be called
        // after FirebaseApp.configure() in the App's init().
    }

    /// Call this once after FirebaseApp.configure() to start listening for auth state changes.
    public func configure() {
        guard authStateListenerHandle == nil else { return }
        listenToAuthState()
    }

    nonisolated deinit {
        if let handle = authStateListenerHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Auth State Listener
    /// Listens for Firebase auth state changes (login, logout, token refresh).
    /// This automatically handles session persistence — if the user was previously
    /// logged in, Firebase restores the session and fires this listener on app launch.
    private func listenToAuthState() {
        authStateListenerHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                guard let self = self else { return }
                self.currentUser = user
                self.isAuthenticated = (user != nil)
                self.isAuthStateResolved = true
            }
        }
    }

    // MARK: - Sign In
    /// Signs in an existing user with email and password.
    /// - Parameters:
    ///   - email: The user's email address.
    ///   - password: The user's password.
    @discardableResult
    public func signIn(email: String, password: String) async -> Bool {
        clearError()
        isLoading = true

        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.currentUser = result.user
            self.isAuthenticated = true
            isLoading = false
            return true
        } catch {
            self.errorMessage = mapFirebaseError(error)
            isLoading = false
            return false
        }
    }

    // MARK: - Sign Up
    /// Creates a new user account with email and password, then sets the display name.
    /// - Parameters:
    ///   - name: The user's display name (optional but recommended).
    ///   - email: The user's email address.
    ///   - password: The user's chosen password (min 6 characters, enforced by Firebase).
    @discardableResult
    public func signUp(name: String, email: String, password: String) async -> Bool {
        clearError()
        isLoading = true

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)

            // Update the user's display name profile
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : name.trimmingCharacters(in: .whitespacesAndNewlines)
            try await changeRequest.commitChanges()

            // Refresh the local user reference to pick up the display name
            try await result.user.reload()
            self.currentUser = Auth.auth().currentUser
            self.isAuthenticated = true
            isLoading = false
            return true
        } catch {
            self.errorMessage = mapFirebaseError(error)
            isLoading = false
            return false
        }
    }

    // MARK: - Sign Out
    /// Signs out the current user and resets state.
    public func signOut() {
        do {
            try Auth.auth().signOut()
            self.currentUser = nil
            self.isAuthenticated = false
        } catch {
            self.errorMessage = mapFirebaseError(error)
        }
    }

    // MARK: - Password Reset
    /// Sends a password reset email via Firebase.
    /// - Parameter email: The email address to send the reset link to.
    /// - Returns: `true` if the email was sent successfully.
    @discardableResult
    public func resetPassword(email: String) async -> Bool {
        clearError()
        isLoading = true

        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            isLoading = false
            return true
        } catch {
            self.errorMessage = mapFirebaseError(error)
            isLoading = false
            return false
        }
    }

    // MARK: - Helpers

    /// Clears any existing error message.
    public func clearError() {
        errorMessage = nil
    }

    /// Returns the user's display name initials (e.g., "Raj Kumar" → "RK").
    /// Falls back to the first character of the email, or "U" if nothing is available.
    public var userInitials: String {
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
    public var userDisplayName: String {
        if let name = currentUser?.displayName,
           !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return name
        }
        return currentUser?.email ?? "User"
    }

    /// Returns the signed-in user's email without leaking Firebase types into views.
    public var userEmail: String? {
        currentUser?.email
    }

    // MARK: - Firebase Error Mapping
    /// Converts Firebase Auth errors into user-friendly messages.
    private func mapFirebaseError(_ error: Error) -> String {
        guard let authError = AuthErrorCode(_bridgedNSError: error as NSError) else {
            return error.localizedDescription
        }

        switch authError.code {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .emailAlreadyInUse:
            return "This email is already registered. Try logging in instead."
        case .weakPassword:
            return "Password is too weak. Use at least 6 characters."
        case .wrongPassword, .invalidCredential:
            return "Incorrect email or password. Please try again."
        case .userNotFound:
            return "No account found with this email. Please sign up first."
        case .userDisabled:
            return "This account has been disabled. Contact support for help."
        case .tooManyRequests:
            return "Too many attempts. Please wait a moment and try again."
        case .networkError:
            return "Network error. Please check your internet connection."
        case .operationNotAllowed:
            return "Email/Password sign-in is not enabled. Contact the administrator."
        default:
            return error.localizedDescription
        }
    }
}
