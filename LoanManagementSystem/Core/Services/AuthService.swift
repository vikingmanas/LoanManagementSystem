//
//  AuthService.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 22/05/26.
//

import Foundation
import Supabase

/// Record for insertion into the Supabase 'users' table.
struct SupabaseUserInsert: Codable {
    let id: UUID
    let email: String
    let role: String
    let full_name: String
    let mobile_number: String
    let created_at: Date
    
    enum CodingKeys: String, CodingKey {
        case id, email, role
        case full_name = "full_name"
        case mobile_number = "mobile_number"
        case created_at = "created_at"
    }
}

/// Helper structure to decode the role from the 'users' table.
struct UserRoleResponse: Codable {
    let role: String
}

/// Custom errors for AuthService operations.
enum AuthServiceError: LocalizedError {
    case emailAlreadyRegistered
    case obfuscatedSignUpDetected
    
    var errorDescription: String? {
        switch self {
        case .emailAlreadyRegistered:
            return "This email is already registered. Please sign in instead."
        case .obfuscatedSignUpDetected:
            return "Sign up could not be completed. This email may already be in use."
        }
    }
}

/// Service for managing Supabase Authentication flow and role-based lookups.
final class AuthService {
    static let shared = AuthService()
    private init() {}
    
    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }
    
    /// Signs in a user using email and password.
    func signIn(email: String, password: String) async throws -> Session {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let session = try await client.auth.signIn(email: cleanEmail, password: password)
        return session
    }
    
    /// Checks whether an email is already registered in the 'users' table.
    func isEmailRegistered(_ email: String) async -> Bool {
        do {
            let results: [UserRoleResponse] = try await client
                .from("users")
                .select("role")
                .eq("email", value: email)
                .execute()
                .value
            return !results.isEmpty
        } catch {
            print("[Supabase Auth] Email existence check failed: \(error.localizedDescription)")
            // On network/query failure, allow signup to proceed (Supabase Auth will catch real duplicates)
            return false
        }
    }
    
    /// Signs up a new user using email, password, and registers them in the database.
    /// Includes protection against Supabase's obfuscated/fake user responses.
    func signUp(email: String, password: String, name: String, phone: String) async throws -> Session? {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        print("[Supabase Auth] Starting signup for: \(cleanEmail)")
        
        // 1. Pre-check: Reject if email already exists in the users table
        if await isEmailRegistered(cleanEmail) {
            print("[Supabase Auth] ✋ Email already exists in users table: \(cleanEmail)")
            throw AuthServiceError.emailAlreadyRegistered
        }
        
        // 2. Sign up the user with Supabase Auth (passing all potential metadata keys to prevent trigger errors)
        let authResponse = try await client.auth.signUp(
            email: cleanEmail,
            password: password,
            data: [
                "display_name": .string(name),
                "full_name": .string(name),
                "phone": .string(phone),
                "mobile_number": .string(phone)
            ]
        )
        
        let user = authResponse.user
        print("[Supabase Auth] Auth signup returned UID: \(user.id)")
        
        // 3. Detect Supabase's obfuscated/fake user responses
        let returnedEmail = (user.email ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if returnedEmail != cleanEmail {
            print("[Supabase Auth] ⚠️ Obfuscated signup detected!")
            throw AuthServiceError.obfuscatedSignUpDetected
        }
        
        // 4. Verify the session exists (confirms this is a real, new user)
        guard authResponse.session != nil else {
            print("[Supabase Auth] ⚠️ Signup returned nil session — email may require confirmation or already exists.")
            throw AuthServiceError.obfuscatedSignUpDetected
        }
        
        // 5. Insert corresponding profile into public 'users' table
        do {
            print("[Supabase DB] Attempting insert into public.users table...")
            try await insertUserRecord(uid: user.id, email: cleanEmail, role: "borrower", name: name, phone: phone)
            print("[Supabase DB] Insert into public.users succeeded!")
        } catch {
            print("[Supabase DB] Failed to insert profile into public.users: \(error.localizedDescription)")
            throw error
        }
        
        return authResponse.session
    }
    
    /// Inserts a new user record in the Supabase 'users' table.
    func insertUserRecord(uid: UUID, email: String, role: String, name: String, phone: String) async throws {
        let record = SupabaseUserInsert(id: uid, email: email, role: role, full_name: name, mobile_number: phone, created_at: Date())
        try await client
            .from("users")
            .upsert(record)
            .execute()
    }
    
    /// Fetches the user's role from the 'users' table.
    func fetchUserRole(uid: UUID) async throws -> String {
        let results: [UserRoleResponse] = try await client
            .from("users")
            .select("role")
            .eq("id", value: uid)
            .execute()
            .value
        
        guard let userRole = results.first?.role else {
            return "borrower"
        }
        return userRole
    }
    
    /// Signs out the current authenticated session.
    func signOut() async throws {
        try await client.auth.signOut()
    }
    
    /// Updates the password for the currently signed-in user.
    func updatePassword(newPassword: String) async throws {
        _ = try await client.auth.update(user: UserAttributes(password: newPassword))
    }
}
