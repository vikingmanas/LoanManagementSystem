






import Foundation
import Supabase


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


struct UserRoleResponse: Codable {
    let role: String
}


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


final class AuthService {
    static let shared = AuthService()
    private init() {}

    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }


    func signIn(email: String, password: String) async throws -> Session {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let session = try await client.auth.signIn(email: cleanEmail, password: password)
        return session
    }


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

            return false
        }
    }



    func signUp(email: String, password: String, name: String, phone: String) async throws -> Session? {
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        print("[Supabase Auth] Starting signup for: \(cleanEmail)")


        if await isEmailRegistered(cleanEmail) {
            print("[Supabase Auth] ✋ Email already exists in users table: \(cleanEmail)")
            throw AuthServiceError.emailAlreadyRegistered
        }


        let authResponse = try await client.auth.signUp(
            email: cleanEmail,
            password: password,
            data: ["display_name": .string(name)]
        )

        let user = authResponse.user
        print("[Supabase Auth] Auth signup returned UID: \(user.id)")





        let returnedEmail = (user.email ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if returnedEmail != cleanEmail {
            print("[Supabase Auth] ⚠️ Obfuscated signup detected!")
            print("[Supabase Auth]   Input email:    \(cleanEmail)")
            print("[Supabase Auth]   Returned email: \(returnedEmail)")
            print("[Supabase Auth]   Skipping public.users insert to prevent dummy user creation.")
            throw AuthServiceError.obfuscatedSignUpDetected
        }


        guard authResponse.session != nil else {
            print("[Supabase Auth] ⚠️ Signup returned nil session — email may require confirmation or already exists.")
            throw AuthServiceError.obfuscatedSignUpDetected
        }


        do {
            print("[Supabase DB] Attempting insert into public.users table...")
            try await insertUserRecord(uid: user.id, email: cleanEmail, role: "borrower", name: name, phone: phone)
            print("[Supabase DB] Insert into public.users succeeded!")
        } catch {
            print("[Supabase DB] Failed to insert profile into public.users: \(error.localizedDescription)")
            print("[Supabase DB] Debug error info: \(String(describing: error))")
            throw error
        }

        return authResponse.session
    }


    func insertUserRecord(uid: UUID, email: String, role: String, name: String, phone: String) async throws {
        let record = SupabaseUserInsert(id: uid, email: email, role: role, full_name: name, mobile_number: phone, created_at: Date())
        try await client
            .from("users")
            .insert(record)
            .execute()
    }


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


    func signOut() async throws {
        try await client.auth.signOut()
    }
}

