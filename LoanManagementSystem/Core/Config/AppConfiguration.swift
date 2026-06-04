






import Foundation

struct AppConfiguration {
    static var supabaseURL: URL {
        let fallbackURLString = "https://cizshycoedfsysfdfkav.supabase.co"
        let urlString = ProcessInfo.processInfo.environment["SUPABASE_URL"]
            ?? Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String
            ?? fallbackURLString

        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            fatalError("SUPABASE_URL is invalid.")
        }
        return url
    }

    static var supabaseKey: String {
        let fallbackKey = "sb_publishable_gdjiLrW6eSrQxm7b7r1kiw_U4mx_tZ6"
        let key = ProcessInfo.processInfo.environment["SUPABASE_KEY"]
            ?? Bundle.main.object(forInfoDictionaryKey: "SUPABASE_KEY") as? String
            ?? fallbackKey
        return key.trimmingCharacters(in: .whitespacesAndNewlines)
    }



    static var supabaseServiceRoleKey: String {
        let fallbackKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNpenNoeWNvZWRmc3lzZmRma2F2Iiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc4MDUzNTk0NiwiZXhwIjoyMDk2MTExOTQ2fQ.K4b94armK5EvDsxZVPAlpozNp_EhAlAsnoq6hKYQ-90"
        let key = ProcessInfo.processInfo.environment["SUPABASE_SERVICE_ROLE_KEY"]
            ?? Bundle.main.object(forInfoDictionaryKey: "SUPABASE_SERVICE_ROLE_KEY") as? String
            ?? fallbackKey
        return key.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    static var googleAppsScriptURL: URL {
        let fallbackString = "https://script.google.com/macros/s/AKfycbwMzB9kRDbjkIiMYXjZ1FaMlbh7ZfVD31p87f-mgvzOYwhQA62ulG6v4DGU22sb7mWZ/exec"
        let urlString = ProcessInfo.processInfo.environment["GOOGLE_APPS_SCRIPT_URL"]
            ?? Bundle.main.object(forInfoDictionaryKey: "GOOGLE_APPS_SCRIPT_URL") as? String
            ?? fallbackString
            
        return URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines))!
    }
}

