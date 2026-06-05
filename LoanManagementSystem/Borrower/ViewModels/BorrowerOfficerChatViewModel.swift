import Observation
import SwiftUI
import Combine

@MainActor
@Observable
final class BorrowerOfficerChatViewModel {
    let application: BorrowerLoanApplication
    let borrowerUserId: UUID?
    
    var messages: [DBMessage] = []
    var messageText = ""
    var officerUserId: UUID?
    var isLoading = true
    var isSending = false
    var errorMessage: String?
    
    var canSend: Bool {
        borrowerUserId != nil &&
        officerUserId != nil &&
        !messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !isSending
    }
    
    init(application: BorrowerLoanApplication, borrowerUserId: UUID?) {
        self.application = application
        self.borrowerUserId = borrowerUserId
    }
    
    func loadConversation() async {
        isLoading = true
        errorMessage = nil

        do {
            guard borrowerUserId != nil else {
                errorMessage = "Sign in again to message your loan officer."
                isLoading = false
                return
            }

            if let assignedUserId = application.assignedOfficer?.userId {
                officerUserId = assignedUserId
            } else if application.assignedOfficerId != nil {
                officerUserId = try await DatabaseService.shared.fetchAssignedLoanOfficerUserId(applicationId: application.id)
            } else {
                officerUserId = nil
            }
            guard officerUserId != nil else {
                errorMessage = "No loan officer is available for this application yet."
                isLoading = false
                return
            }

            messages = try await DatabaseService.shared.fetchMessagesForApplication(applicationId: application.id)
            isLoading = false
        } catch {
            errorMessage = "Could not load messages. Please try again."
            isLoading = false
        }
    }
    
    func sendMessage() async {
        guard let borrowerUserId,
              let officerUserId else { return }

        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSending = true
        let outgoingText = trimmed
        messageText = ""
        
        let outgoing = DBMessage(
            messageId: UUID(),
            senderId: borrowerUserId,
            receiverId: officerUserId,
            applicationId: application.id,
            content: outgoingText,
            sentAt: Date(),
            isRead: false
        )
        messages.append(outgoing)

        do {
            try await DatabaseService.shared.sendMessage(outgoing)
            try? await DatabaseService.shared.createNotification(
                userId: officerUserId,
                title: "New borrower message",
                message: "\(application.displayIdentifier): \(outgoingText)"
            )
        } catch {
            messages.removeAll { $0.messageId == outgoing.messageId }
            messageText = outgoingText
            errorMessage = "Message could not be sent. Please try again."
        }
        isSending = false
    }
}
