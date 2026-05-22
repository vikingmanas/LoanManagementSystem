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
    let created_at: Date
    
    enum CodingKeys: String, CodingKey {
        case id, email, role
        case created_at = "created_at"
    }
}

/// Helper structure to decode the role from the 'users' table.
struct UserRoleResponse: Codable {
    let role: String
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
    
    /// Signs up a new user using email, password, and registers them in the database.
    func signUp(email: String, password: String, name: String) async throws -> Session? {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        print("[Supabase Auth] Starting signup for: \(cleanEmail)")
        
        // 1. Sign up the user with Supabase Auth
        let authResponse = try await client.auth.signUp(
            email: cleanEmail,
            password: password,
            data: ["display_name": .string(name)]
        )
        
        let user = authResponse.user
        print("[Supabase Auth] Auth signup succeeded. Retrieved UID: \(user.id)")
        
        // 2. Insert corresponding profile into public 'users' table BEFORE checking session
        do {
            print("[Supabase DB] Attempting insert into public.users table...")
            try await insertUserRecord(uid: user.id, email: cleanEmail, role: "borrower")
            print("[Supabase DB] Insert into public.users succeeded!")
        } catch {
            print("[Supabase DB] Failed to insert profile into public.users: \(error.localizedDescription)")
            print("[Supabase DB] Debug error info: \(String(describing: error))")
            throw error
        }
        
        return authResponse.session
    }
    
    /// Inserts a new user record in the Supabase 'users' table.
    func insertUserRecord(uid: UUID, email: String, role: String) async throws {
        let record = SupabaseUserInsert(id: uid, email: email, role: role, created_at: Date())
        try await client
            .from("users")
            .insert(record)
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
            // Default fallback if record does not exist
            return "borrower"
        }
        return userRole
    }
    
    /// Signs out the current authenticated session.
    func signOut() async throws {
        try await client.auth.signOut()
    }
}
