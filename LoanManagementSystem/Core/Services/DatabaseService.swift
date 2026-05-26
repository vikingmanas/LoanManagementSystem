






import Foundation
import Supabase


final class DatabaseService {
    static let shared = DatabaseService()
    private init() {}

    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }


    func fetchProfile(userId: String) async throws -> BorrowerProfile? {

        let profiles: [BorrowerProfile] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .execute()
            .value

        if let profile = profiles.first {

            saveProfileLocally(profile, userId: userId)
            return profile
        } else {

            return nil
        }
    }


    func updateProfile(_ profile: BorrowerProfile) async throws {

        saveProfileLocally(profile, userId: profile.id)


        if let userId = UUID(uuidString: profile.id) {
            let userUpsert: [String: String] = [
                "id": userId.uuidString,
                "email": profile.email,
                "full_name": profile.fullName,
                "mobile_number": profile.mobileNumber
            ]
            print("UPSERT REQUEST - Table: users, ID: \(userId), Payload: \(userUpsert)")
            do {
                try await client
                    .from("users")
                    .upsert(userUpsert)
                    .execute()
                print("UPSERT RESPONSE - Table: users, Status: Success")
            } catch {
                print("EXACT SUPABASE ERROR - Table: users, Sync Error: \(error.localizedDescription)")
                throw error
            }
        }


        print("UPDATE REQUEST - Table: profiles, ID: \(profile.id)")
        do {
            try await client
                .from("profiles")
                .upsert(profile)
                .execute()
            print("UPDATED RESPONSE - Table: profiles, Status: Success")
        } catch {
            print("EXACT SUPABASE ERROR - Table: profiles, Error: \(error.localizedDescription)")
            throw error
        }
    }



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

        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        return directory.appendingPathComponent("\(userId).json")
    }
}

