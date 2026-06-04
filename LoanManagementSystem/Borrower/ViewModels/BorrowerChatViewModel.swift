import SwiftUI
import Combine
import Supabase

struct BorrowerConversation: Identifiable, Hashable {
    let id: UUID           // applicationId
    let applicationId: UUID
    let applicationDisplayId: String
    let loanProductName: String
    let messages: [DBMessage]

    var latestMessage: DBMessage? {
        messages.max { $0.sentAt < $1.sentAt }
    }

    var unreadCount: Int {
        guard let uid = AuthManager.shared.currentUser?.uid,
              let borrowerId = UUID(uuidString: uid) else { return 0 }
        return messages.filter { $0.receiverId == borrowerId && !$0.isRead }.count
    }

    // Custom Hashable & Equatable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: BorrowerConversation, rhs: BorrowerConversation) -> Bool {
        lhs.id == rhs.id &&
        lhs.applicationDisplayId == rhs.applicationDisplayId &&
        lhs.loanProductName == rhs.loanProductName &&
        lhs.messages == rhs.messages
    }
}

@MainActor
final class BorrowerChatViewModel: ObservableObject {

    // MARK: - Published State
    @Published var conversations: [BorrowerConversation] = []
    @Published var isLoading: Bool = false
    @Published var hasError: Bool = false

    /// Total unread messages across all conversations (for tab badge).
    var totalUnreadCount: Int {
        conversations.reduce(0) { $0 + $1.unreadCount }
    }

    // MARK: - Private
    private var borrowerUserId: UUID? {
        guard let uid = AuthManager.shared.currentUser?.uid else { return nil }
        return UUID(uuidString: uid)
    }
    
    private var realtimeChannel: RealtimeChannelV2?
    
    deinit {
        let channel = realtimeChannel
        Task {
            await channel?.unsubscribe()
        }
    }

    // MARK: - Realtime
    func setupRealtime() async {
        guard let userId = borrowerUserId else { return }
        
        if let channel = realtimeChannel {
            await channel.unsubscribe()
        }
        
        realtimeChannel = await DatabaseService.shared.subscribeToAllMessages(forUserId: userId) { [weak self] newMessage in
            Task { @MainActor in
                self?.handleNewRealtimeMessage(newMessage)
            }
        }
    }
    
    private func handleNewRealtimeMessage(_ msg: DBMessage) {
        guard let appId = msg.applicationId else { return }
        if let idx = conversations.firstIndex(where: { $0.applicationId == appId }) {
            let conv = conversations[idx]
            if !conv.messages.contains(where: { $0.messageId == msg.messageId }) {
                var newMessages = conv.messages
                newMessages.append(msg)
                
                let updatedConv = BorrowerConversation(
                    id: conv.id,
                    applicationId: conv.applicationId,
                    applicationDisplayId: conv.applicationDisplayId,
                    loanProductName: conv.loanProductName,
                    messages: newMessages.sorted { $0.sentAt < $1.sentAt }
                )
                conversations[idx] = updatedConv
                
                conversations.sort {
                    ($0.latestMessage?.sentAt ?? .distantPast) > ($1.latestMessage?.sentAt ?? .distantPast)
                }
            }
        } else {
            Task {
                await self.fetchConversations()
            }
        }
    }

    // MARK: - Fetch All Conversations
    func fetchConversations() async {
        guard let userId = borrowerUserId else { return }
        isLoading = true
        hasError = false

        do {
            let allMessages = try await DatabaseService.shared.fetchMessages(for: userId)

            // Only keep messages relevant to this borrower (sent or received)
            let borrowerMessages = allMessages.filter {
                $0.senderId == userId || $0.receiverId == userId
            }

            // Group by applicationId
            let grouped = Dictionary(grouping: borrowerMessages) { msg -> UUID in
                msg.applicationId ?? UUID()
            }

            // Resolve application display names from CentralLoanRepository
            let repoApps = CentralLoanRepository.shared.applications

            var convos: [BorrowerConversation] = []
            for (appId, msgs) in grouped {
                let matchedApp = repoApps.first(where: { $0.id == appId })
                let displayId = matchedApp?.displayIdentifier ?? "APP-\(appId.uuidString.prefix(6).uppercased())"
                let productName = matchedApp?.product.type.title ?? "Loan Application"

                // Filter unread: only messages where the borrower is the receiver
                let messagesWithCorrectReadState = msgs.map { msg -> DBMessage in
                    // We only count messages as unread if the borrower is the receiver
                    if msg.receiverId == userId {
                        return msg
                    } else {
                        // Messages the borrower sent — always "read" from borrower's perspective
                        return DBMessage(
                            messageId: msg.messageId,
                            senderId: msg.senderId,
                            receiverId: msg.receiverId,
                            applicationId: msg.applicationId,
                            content: msg.content,
                            sentAt: msg.sentAt,
                            isRead: true
                        )
                    }
                }

                convos.append(BorrowerConversation(
                    id: appId,
                    applicationId: appId,
                    applicationDisplayId: displayId,
                    loanProductName: productName,
                    messages: messagesWithCorrectReadState.sorted { $0.sentAt < $1.sentAt }
                ))
            }

            // Sort conversations by latest message timestamp (most recent first)
            conversations = convos.sorted {
                ($0.latestMessage?.sentAt ?? .distantPast) > ($1.latestMessage?.sentAt ?? .distantPast)
            }

            isLoading = false
        } catch {
            print("[BorrowerChatVM] Failed to fetch messages: \(error)")
            hasError = true
            isLoading = false
        }
    }

    // MARK: - Fetch Messages for a Single Thread
    func fetchMessagesForThread(applicationId: UUID) async -> [DBMessage] {
        do {
            let msgs = try await DatabaseService.shared.fetchMessagesForApplication(applicationId: applicationId)
            // Update local conversations cache
            if let idx = conversations.firstIndex(where: { $0.applicationId == applicationId }) {
                let conv = conversations[idx]
                conversations[idx] = BorrowerConversation(
                    id: conv.id,
                    applicationId: conv.applicationId,
                    applicationDisplayId: conv.applicationDisplayId,
                    loanProductName: conv.loanProductName,
                    messages: msgs.sorted { $0.sentAt < $1.sentAt }
                )
            }
            return msgs.sorted { $0.sentAt < $1.sentAt }
        } catch {
            print("[BorrowerChatVM] Failed to fetch thread messages: \(error)")
            return []
        }
    }

    // MARK: - Send Message
    func sendMessage(content: String, applicationId: UUID, receiverId: UUID) async -> DBMessage? {
        guard let userId = borrowerUserId else { return nil }
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let newMsg = DBMessage(
            messageId: UUID(),
            senderId: userId,
            receiverId: receiverId,
            applicationId: applicationId,
            content: trimmed,
            sentAt: Date(),
            isRead: false
        )

        do {
            try await DatabaseService.shared.sendMessage(newMsg)
            appendMessageToConversation(newMsg, borrowerSent: true)

            // Send a notification to the officer
            try? await DatabaseService.shared.createNotification(
                userId: receiverId,
                title: "New message from borrower",
                message: trimmed
            )

            return newMsg
        } catch {
            print("[BorrowerChatVM] Failed to send message: \(error)")
            return nil
        }
    }

    private func appendMessageToConversation(_ message: DBMessage, borrowerSent: Bool) {
        guard let applicationId = message.applicationId,
              let index = conversations.firstIndex(where: { $0.applicationId == applicationId }) else {
            return
        }

        let conversation = conversations[index]
        guard !conversation.messages.contains(where: { $0.messageId == message.messageId }) else { return }

        let cachedMessage = borrowerSent
            ? DBMessage(
                messageId: message.messageId,
                senderId: message.senderId,
                receiverId: message.receiverId,
                applicationId: message.applicationId,
                content: message.content,
                sentAt: message.sentAt,
                isRead: true
            )
            : message

        conversations[index] = BorrowerConversation(
            id: conversation.id,
            applicationId: conversation.applicationId,
            applicationDisplayId: conversation.applicationDisplayId,
            loanProductName: conversation.loanProductName,
            messages: (conversation.messages + [cachedMessage]).sorted { $0.sentAt < $1.sentAt }
        )
        conversations.sort {
            ($0.latestMessage?.sentAt ?? .distantPast) > ($1.latestMessage?.sentAt ?? .distantPast)
        }
    }

    // MARK: - Mark Messages as Read
    func markMessagesAsRead(messages: [DBMessage]) async {
        guard let userId = borrowerUserId else { return }
        let unreadIds = messages
            .filter { $0.receiverId == userId && !$0.isRead }
            .map(\.messageId)

        guard !unreadIds.isEmpty else { return }

        do {
            try await DatabaseService.shared.markMessagesRead(messageIds: unreadIds)
            let unreadIdSet = Set(unreadIds)
            conversations = conversations.map { conversation in
                let updatedMessages = conversation.messages.map { message in
                    guard unreadIdSet.contains(message.messageId) else { return message }
                    return DBMessage(
                        messageId: message.messageId,
                        senderId: message.senderId,
                        receiverId: message.receiverId,
                        applicationId: message.applicationId,
                        content: message.content,
                        sentAt: message.sentAt,
                        isRead: true
                    )
                }
                return BorrowerConversation(
                    id: conversation.id,
                    applicationId: conversation.applicationId,
                    applicationDisplayId: conversation.applicationDisplayId,
                    loanProductName: conversation.loanProductName,
                    messages: updatedMessages
                )
            }
        } catch {
            print("[BorrowerChatVM] Failed to mark messages as read: \(error)")
        }
    }
}
