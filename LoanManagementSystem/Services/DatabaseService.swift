//
//  DatabaseService.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 22/05/26.
//

import Foundation

/// Service for managing database queries using Supabase Database (PostgREST).
final class DatabaseService {
    static let shared = DatabaseService()
    private init() {}
    
    // TODO: Implement actual Supabase DB fetching/updating
    
    /// Fetches borrower profile from "profiles" table.
    func fetchProfile(userId: String) async throws -> BorrowerProfile? {
        // TODO: Replace with Supabase query:
        // let profile: BorrowerProfile = try await SupabaseManager.shared.client
        //     .database
        //     .from("profiles")
        //     .select()
        //     .eq("id", value: userId)
        //     .single()
        //     .execute()
        //     .value
        // return profile
        return nil
    }
    
    /// Updates borrower profile metadata in "profiles" table.
    func updateProfile(_ profile: BorrowerProfile) async throws {
        // TODO: Replace with Supabase upsert:
        // try await SupabaseManager.shared.client
        //     .database
        //     .from("profiles")
        //     .upsert(profile)
        //     .execute()
    }
}
