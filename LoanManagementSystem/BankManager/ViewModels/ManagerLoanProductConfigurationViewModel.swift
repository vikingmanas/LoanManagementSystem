import Foundation
import Combine
import OSLog
import UIKit

@MainActor
final class ManagerLoanProductConfigurationViewModel: ObservableObject {
    @Published var products: [AdminLoanProduct] = []
    @Published var isLoading = false
    @Published var isSaving = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let logger = Logger(subsystem: "galgotias.in.akash", category: "ManagerLoanProducts")

    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil

        do {
            products = try await AdminDashboardService.shared.fetchLoanProducts()
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        } catch {
            logger.error("Failed to load loan products: \(error.localizedDescription)")
            errorMessage = "Could not load loan products. Check your connection and try again."
        }

        isLoading = false
    }

    func saveProduct(_ product: AdminLoanProduct) async {
        isSaving = true
        errorMessage = nil
        successMessage = nil

        if let index = products.firstIndex(where: { $0.id == product.id }) {
            products[index] = product
        }

        do {
            try await AdminDashboardService.shared.upsertLoanProduct(product)
            successMessage = "\(product.name) pricing updated."
            HapticsManager.triggerNotification(type: .success)
        } catch {
            logger.error("Failed to save loan product: \(error.localizedDescription)")
            errorMessage = "Could not save \(product.name). Try again."
            HapticsManager.triggerNotification(type: .error)
        }

        isSaving = false
    }
}
