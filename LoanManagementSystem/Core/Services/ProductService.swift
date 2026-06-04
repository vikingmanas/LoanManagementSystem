
import Foundation
import Supabase
import OSLog

class ProductService {
    static let shared = ProductService()
    private let client = SupabaseManager.shared.client
    private let logger = Logger(subsystem: "galgotias.in.akash", category: "ProductService")
    
    private init() {}
    
    /// Fetches all active loan products from the Supabase 'loan_products' table.
    func fetchLoanProducts() async -> [BorrowerLoanProduct] {
        do {
            logger.info("ProductService: Fetching live loan products from Supabase...")
            let products: [BorrowerLoanProduct] = try await client
                .from("loan_products")
                .select()
                .eq("is_active", value: true)
                .execute()
                .value
            
            logger.info("ProductService: Successfully fetched \(products.count) live products.")
            return products
        } catch {
            logger.error("ProductService Error: Failed to fetch live products. Error: \(error.localizedDescription)")
            return []
        }
    }
}
