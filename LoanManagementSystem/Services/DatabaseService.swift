//
//  DatabaseService.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 22/05/26.
//

import Foundation
import Supabase

/// Service for managing database queries using Supabase Database (PostgREST) with local fallback.
final class DatabaseService {
    static let shared = DatabaseService()
    private init() {}
    
    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }
    
    /// Fetches borrower profile from "profiles" table.
    func fetchProfile(userId: String) async throws -> BorrowerProfile? {
        // Query as an array to distinguish "no rows" (empty array) from "error" (thrown exception)
        let profiles: [BorrowerProfile] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .execute()
            .value
        
        if let profile = profiles.first {
            // Cache it locally on successful fetch
            saveProfileLocally(profile, userId: userId)
            return profile
        } else {
            // Nil indicates that the profile record does not exist on Supabase
            return nil
        }
    }
    
    /// Updates borrower profile metadata in "profiles" table.
    func updateProfile(_ profile: BorrowerProfile) async throws {
        // Save locally first so user's work is not lost
        saveProfileLocally(profile, userId: profile.id)
        
        do {
            try await client
                .from("profiles")
                .upsert(profile)
                .execute()
            print("[DatabaseService] Profile upserted to Supabase successfully.")
        } catch {
            print("[DatabaseService] Failed to update profile in Supabase: \(error.localizedDescription)")
            // Graceful fallback: we do not rethrow since local cache has successfully saved the data.
        }
    }
    
    // MARK: - Local Cache Helpers
    
    private func saveProfileLocally(_ profile: BorrowerProfile, userId: String) {
        do {
            let data = try JSONEncoder().encode(profile)
            let fileURL = getLocalProfileURL(userId: userId)
            try data.write(to: fileURL, options: .atomic)
            print("[DatabaseService] Cached profile locally for user: \(userId)")
        } catch {
            print("[DatabaseService] Error caching profile locally: \(error.localizedDescription)")
        }
    }
    
    func loadProfileLocally(userId: String) -> BorrowerProfile? {
        let fileURL = getLocalProfileURL(userId: userId)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let profile = try JSONDecoder().decode(BorrowerProfile.self, from: data)
            print("[DatabaseService] Loaded profile from local cache for user: \(userId)")
            return profile
        } catch {
            print("[DatabaseService] Error loading cached profile: \(error.localizedDescription)")
            return nil
        }
    }
    
    private func getLocalProfileURL(userId: String) -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let directory = paths[0].appendingPathComponent("Profiles", isDirectory: true)
        // Ensure directory exists
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        return directory.appendingPathComponent("\(userId).json")
    }
}
