//
//  AppConfiguration.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 22/05/26.
//

import Foundation

struct AppConfiguration {
    static var supabaseURL: URL {
        let fallbackURLString = "https://zufrhozjfmvvucswmudj.supabase.co"
        let urlString = ProcessInfo.processInfo.environment["SUPABASE_URL"]
            ?? Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
            ?? fallbackURLString
        
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            fatalError("SUPABASE_URL is invalid.")
        }
        return url
    }
    
    static var supabaseKey: String {
        let fallbackKey = "sb_publishable_C8TSNkIM4-1f4zJuPTeqYA_bTEGFtFe"
        let key = ProcessInfo.processInfo.environment["SUPABASE_KEY"]
            ?? Bundle.main.object(forInfoDictionaryKey: "SUPABASE_KEY") as? String
            ?? fallbackKey
        return key.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // IMPORTANT: In a production app, the Service Role Key should NOT be hardcoded in the client app.
    // It is used here for internal admin functionality as requested.
    static var supabaseServiceRoleKey: String {
        let fallbackKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp1ZnJob3pqZm12dnVjc3dtdWRqIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3OTQwODUyNywiZXhwIjoyMDk0OTg0NTI3fQ.4s7NAypvWIFMcncs72zdrnFlULVPNfpP98eNybX6Rno" // Service Role Key
        let key = ProcessInfo.processInfo.environment["SUPABASE_SERVICE_ROLE_KEY"]
            ?? Bundle.main.object(forInfoDictionaryKey: "SUPABASE_SERVICE_ROLE_KEY") as? String
            ?? fallbackKey
        return key.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
