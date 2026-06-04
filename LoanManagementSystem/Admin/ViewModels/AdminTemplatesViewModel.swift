import Observation
import Foundation
import Combine
import SwiftUI
import OSLog

@MainActor
@Observable
class AdminTemplatesViewModel {
    var templates: [MessageTemplate] = []
    var isLoading = false
    
    init() {}
    
    func loadTemplates() async {
        isLoading = true
        do {
            let fetched = try await AdminDashboardService.shared.fetchNotificationTemplates()
            self.templates = fetched
        } catch {
            logger.error("AdminTemplatesViewModel: Failed to load templates: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    func saveTemplate(_ template: MessageTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
        } else {
            templates.append(template)
        }
        
        Task {
            do {
                try await AdminDashboardService.shared.upsertNotificationTemplate(template)
                logger.info("AdminTemplatesViewModel: Successfully saved template \(template.name) to Supabase.")
            } catch {
                logger.error("AdminTemplatesViewModel: Failed to save template: \(error.localizedDescription)")
            }
        }
    }
    
    func deleteTemplate(_ template: MessageTemplate) {
        templates.removeAll { $0.id == template.id }
        
        Task {
            do {
                try await AdminDashboardService.shared.deleteNotificationTemplate(id: template.id)
                logger.info("AdminTemplatesViewModel: Successfully deleted template from Supabase.")
            } catch {
                logger.error("AdminTemplatesViewModel: Failed to delete template: \(error.localizedDescription)")
            }
        }
    }
    
    private let logger = Logger(subsystem: "galgotias.in.akash", category: "AdminTemplatesViewModel")
}
