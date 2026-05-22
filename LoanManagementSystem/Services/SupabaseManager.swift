import Foundation
import Supabase

final class SupabaseManager {

    static let shared = SupabaseManager()

    let client: SupabaseClient

    private init() {

        client = SupabaseClient(
            supabaseURL: URL(string: "https://zufrhozjfmvvucswmudj.supabase.co")!,
            supabaseKey: "sb_publishable_C8TSNkIM4-1f4zJuPTeqYA_bTEGFtFe"
        )
    }
}
