import Foundation
import Combine
import SwiftUI

@MainActor
final class AdminLoanRulesViewModel: ObservableObject {
    @Published var loanProducts: [AdminLoanProduct] = []
    @Published var globalRules = GlobalLoanRules(minCibilScore: 700, maxDTI: 50.0, maxLTV: 80.0)
    
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func loadRules() async {
        isLoading = true
        errorMessage = nil
        
        // Simulating network fetch
        do {
            try await Task.sleep(nanoseconds: 600_000_000)
            
            loanProducts = [
                AdminLoanProduct(id: UUID(), name: "Standard Home Loan", loanType: "Home Loan", isActive: true, minRate: 8.5, maxRate: 11.0, minAmount: 500_000, maxAmount: 50_000_000, maxTenure: 360, processingFee: 0.5, requiredDocuments: ["Aadhaar", "PAN", "Salary Slip", "Bank Statement", "Property Documents"]),
                AdminLoanProduct(id: UUID(), name: "Instant Personal Loan", loanType: "Personal Loan", isActive: true, minRate: 10.5, maxRate: 18.0, minAmount: 50_000, maxAmount: 1_500_000, maxTenure: 60, processingFee: 2.0, requiredDocuments: ["Aadhaar", "PAN", "Salary Slip", "Bank Statement"]),
                AdminLoanProduct(id: UUID(), name: "SME Business Loan", loanType: "Business Loan", isActive: true, minRate: 12.0, maxRate: 24.0, minAmount: 500_000, maxAmount: 10_000_000, maxTenure: 120, processingFee: 1.5, requiredDocuments: ["Aadhaar", "PAN", "GST Certificate", "ITR", "Business Bank Statement"])
            ]
            
        } catch {
            errorMessage = "Failed to load loan rules."
        }
        
        isLoading = false
    }
    
    func updateProduct(_ product: AdminLoanProduct) async {
        // Find index and update locally (Mocking Supabase update)
        if let index = loanProducts.firstIndex(where: { $0.id == product.id }) {
            loanProducts[index] = product
        }
    }
    
    func addLoanProduct(_ product: AdminLoanProduct) {
        loanProducts.append(product)
    }
    
    func updateGlobalRules(_ rules: GlobalLoanRules) async {
        globalRules = rules
    }
}
