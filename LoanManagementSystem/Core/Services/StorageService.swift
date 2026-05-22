//
//  StorageService.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 22/05/26.
//

import Foundation
import Supabase

/// Service for managing file uploads, deletions, and URLs in Supabase Storage.
final class StorageService {
    static let shared = StorageService()
    private init() {}
    
    /// Uploads document data to the specified bucket and returns the public URL.
    func uploadDocument(data: Data, bucket: String, path: String) async throws -> URL {
        try await SupabaseManager.shared.client
            .storage
            .from(bucket)
            .upload(
                path: path,
                file: data,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: "image/jpeg",
                    upsert: true
                )
            )
        
        return try SupabaseManager.shared.client
            .storage
            .from(bucket)
            .getPublicURL(path: path)
    }
    
    /// Deletes a document from the specified storage bucket.
    func deleteDocument(bucket: String, path: String) async throws {
        _ = try await SupabaseManager.shared.client
            .storage
            .from(bucket)
            .remove(paths: [path])
    }
}
