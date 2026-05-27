import Foundation
import Combine
import SwiftUI

@MainActor
class AdminTemplatesViewModel: ObservableObject {
    @Published var templates: [MessageTemplate] = []
    @Published var isLoading = false
    
    init() {
        // Mock data
        self.templates = [
            MessageTemplate(
                id: UUID(),
                name: "Loan Approval",
                subject: "Congratulations! Your loan is approved",
                body: "Dear {{user_name}},\n\nWe are pleased to inform you that your {{loan_type}} loan application for {{amount}} has been approved.",
                type: .email,
                isActive: true
            ),
            MessageTemplate(
                id: UUID(),
                name: "EMI Reminder",
                subject: "Upcoming EMI Payment",
                body: "Reminder: Your EMI of {{emi_amount}} is due on {{due_date}}. Please maintain sufficient balance.",
                type: .sms,
                isActive: true
            )
        ]
    }
    
    func saveTemplate(_ template: MessageTemplate) {
        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
        } else {
            templates.append(template)
        }
    }
    
    func deleteTemplate(_ template: MessageTemplate) {
        templates.removeAll { $0.id == template.id }
    }
}
