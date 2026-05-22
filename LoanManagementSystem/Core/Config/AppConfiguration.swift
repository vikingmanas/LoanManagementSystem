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
}
