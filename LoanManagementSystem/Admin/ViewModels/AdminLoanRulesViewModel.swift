import Foundation
import Combine
import SwiftUI
import OSLog

@MainActor
final class AdminLoanRulesViewModel: ObservableObject {
    @Published var loanProducts: [AdminLoanProduct] = []
    @Published var globalRules = GlobalLoanRules(minCibilScore: 700, maxDTI: 50.0, maxLTV: 80.0)
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        // Load global rules from UserDefaults if saved
        if let data = UserDefaults.standard.data(forKey: "GlobalLoanRules"),
           let savedRules = try? JSONDecoder().decode(GlobalLoanRules.self, from: data) {
            self.globalRules = savedRules
        }
    }
    
    func loadRules() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let products = try await AdminDashboardService.shared.fetchLoanProducts()
            loanProducts = products
        } catch {
            logger.error("AdminLoanRulesViewModel: Failed to load rules: \(error.localizedDescription)")
            errorMessage = "Failed to load loan rules."
        }
        
        isLoading = false
    }
    
    func updateProduct(_ product: AdminLoanProduct) async {
        if let index = loanProducts.firstIndex(where: { $0.id == product.id }) {
            loanProducts[index] = product
        }
        
        do {
            try await AdminDashboardService.shared.upsertLoanProduct(product)
            logger.info("AdminLoanRulesViewModel: Successfully updated product \(product.name) in Supabase.")
        } catch {
            logger.error("AdminLoanRulesViewModel: Failed to update product: \(error.localizedDescription)")
            errorMessage = "Failed to save product changes to Supabase."
        }
    }
    
    func addLoanProduct(_ product: AdminLoanProduct) async {
        loanProducts.append(product)
        
        do {
            try await AdminDashboardService.shared.upsertLoanProduct(product)
            logger.info("AdminLoanRulesViewModel: Successfully added product \(product.name) to Supabase.")
        } catch {
            logger.error("AdminLoanRulesViewModel: Failed to add product: \(error.localizedDescription)")
            errorMessage = "Failed to save new product to Supabase."
        }
    }
    
    func updateGlobalRules(_ rules: GlobalLoanRules) async {
        globalRules = rules
        if let encoded = try? JSONEncoder().encode(rules) {
            UserDefaults.standard.set(encoded, forKey: "GlobalLoanRules")
        }
    }
    
    private let logger = Logger(subsystem: "galgotias.in.akash", category: "AdminLoanRulesViewModel")
}
