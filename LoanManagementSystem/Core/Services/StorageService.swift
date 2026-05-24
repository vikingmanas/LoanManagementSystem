//
//  StorageService.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 22/05/26.
//

import Foundation

/// Service for managing file uploads, deletions, and URLs in Supabase Storage.
final class StorageService {
    static let shared = StorageService()
    private init() {}
    
    // TODO: Implement actual Supabase Storage uploads and URL fetches
    
    /// Uploads document data to the specified bucket and returns the public URL.
    func uploadDocument(data: Data, bucket: String, path: String) async throws -> URL {
        // TODO: Replace with Supabase Storage:
        // let file = File(name: "kyc.jpg", data: data, mimeType: "image/jpeg")
        // try await SupabaseManager.shared.client
        //     .storage
        //     .from(bucket)
        //     .upload(path: path, file: file)
        //
        // return try await SupabaseManager.shared.client
        //     .storage
        //     .from(bucket)
        //     .getPublicUrl(path: path)
        return URL(string: "https://placeholder-url.com")!
    }
    
    /// Deletes a document from the specified storage bucket.
    func deleteDocument(bucket: String, path: String) async throws {
        // TODO: Replace with Supabase Storage:
        // try await SupabaseManager.shared.client
        //     .storage
        //     .from(bucket)
        //     .remove(paths: [path])
    }
}
