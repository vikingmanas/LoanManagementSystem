
import Foundation
import Supabase

final class StorageService {
    static let shared = StorageService()
    private init() {}

    func uploadDocument(data: Data, bucket: String, path: String, contentType: String = "image/jpeg") async throws -> URL {
        try await SupabaseManager.shared.client
            .storage
            .from(bucket)
            .upload(
                path,
                data: data,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: contentType,
                    upsert: true
                )
            )

        return try SupabaseManager.shared.client
            .storage
            .from(bucket)
            .getPublicURL(path: path)
    }

    func deleteDocument(bucket: String, path: String) async throws {
        _ = try await SupabaseManager.shared.client
            .storage
            .from(bucket)
            .remove(paths: [path])
    }
}
