import SwiftUI

struct ChatsFeedTabView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @State private var searchText = ""
    @State private var showUnreadOnly = false
    @State private var showingCompose = false

    private var conversations: [OfficerConversation] {
        OfficerConversation.make(from: viewModel.activityFeed)
            .filter { conversation in
                let matchesSearch = searchText.isEmpty || conversation.borrowerName.localizedCaseInsensitiveContains(searchText) || conversation.applicationId.localizedCaseInsensitiveContains(searchText) || conversation.loanType.localizedCaseInsensitiveContains(searchText)
                let matchesUnread = !showUnreadOnly || conversation.unreadCount > 0
                return matchesSearch && matchesUnread
            }
    }

    var body: some View {
        NavigationStack {
            List {
                if conversations.isEmpty {
                    ContentUnavailableView(
                        showUnreadOnly ? "No Unread Messages" : "No Conversations",
                        systemImage: "message",
                        description: Text("Borrower conversations and clarification threads appear here.")
                    )
                } else {
                    Section {
                        ForEach(conversations) { conversation in
                            NavigationLink {
                                OfficerMessageThreadView(conversation: conversation, viewModel: viewModel)
                            } label: {
                                OfficerConversationRow(conversation: conversation)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    conversation.items.forEach { viewModel.dismissActivity($0.id) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    conversation.items.forEach { viewModel.markActivityRead($0.id) }
                                } label: {
                                    Label("Read", systemImage: "envelope.open")
                                }
                                .tint(.blue)
                            }
                            .contextMenu {
                                Button {
                                    conversation.items.forEach { viewModel.markActivityRead($0.id) }
                                } label: {
                                    Label("Mark as Read", systemImage: "envelope.open")
                                }

                                Button { } label: {
                                    Label("Pin", systemImage: "pin")
                                }

                                Button(role: .destructive) {
                                    conversation.items.forEach { viewModel.dismissActivity($0.id) }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Messages")
            .searchable(text: $searchText, prompt: "Borrower or application")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showUnreadOnly.toggle()
                    } label: {
                        Image(systemName: showUnreadOnly ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                    }
                    .accessibilityLabel(showUnreadOnly ? "Show all messages" : "Show unread messages")

                    Button {
                        showingCompose = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                    }
                    .accessibilityLabel("Compose message")
                }
            }
            .refreshable { await viewModel.fetchDashboardData() }
            .sheet(isPresented: $showingCompose) {
                OfficerComposeMessageSheet(viewModel: viewModel)
            }
        }
    }
}

struct OfficerConversation: Identifiable, Hashable {
    let id: String
    let borrowerName: String
    let applicationId: String
    let loanType: String
    let items: [ActivityFeedItem]

    var unreadCount: Int { items.filter { !$0.isRead }.count }
    var latestItem: ActivityFeedItem? { items.sorted { $0.timestamp > $1.timestamp }.first }
    var requiresAction: Bool { items.contains { $0.requiresAction } }

    static func make(from items: [ActivityFeedItem]) -> [OfficerConversation] {
        Dictionary(grouping: items, by: { $0.applicationId })
            .compactMap { applicationId, groupedItems in
                guard let first = groupedItems.sorted(by: { $0.timestamp > $1.timestamp }).first else { return nil }
                return OfficerConversation(
                    id: applicationId,
                    borrowerName: first.borrowerName,
                    applicationId: applicationId,
                    loanType: first.loanType,
                    items: groupedItems.sorted { $0.timestamp < $1.timestamp }
                )
            }
            .sorted { ($0.latestItem?.timestamp ?? .distantPast) > ($1.latestItem?.timestamp ?? .distantPast) }
    }
}

private struct OfficerConversationRow: View {
    let conversation: OfficerConversation

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Unread indicator (Native iOS Messages style)
            Circle()
                .fill(conversation.unreadCount > 0 ? Color.blue : Color.clear)
                .frame(width: 10, height: 10)
            
            OfficerAvatar(name: conversation.borrowerName, tint: conversation.requiresAction ? .orange : .blue)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    Text(conversation.borrowerName)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let latest = conversation.latestItem {
                        Text(RelativeDateFormatter.shared.relativeString(from: latest.timestamp))
                            .font(.subheadline)
                            .foregroundStyle(conversation.unreadCount > 0 ? .blue : .secondary)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(UIColor.tertiaryLabel))
                }

                Text(conversation.latestItem?.eventDescription ?? "No recent message")
                    .font(.subheadline)
                    .foregroundStyle(conversation.unreadCount > 0 ? .primary : .secondary)
                    .lineLimit(2)
                
                HStack(spacing: 6) {
                    Text("\(conversation.loanType) · \(conversation.applicationId)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.9)
                    
                    Spacer()
                    
                    if conversation.requiresAction {
                        Text("Action Required")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15), in: Capsule())
                    }
                }
                .padding(.top, 2)
            }
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Conversation with \(conversation.borrowerName), \(conversation.unreadCount) unread messages")
    }
}

private struct OfficerMessageThreadView: View {
    let conversation: OfficerConversation
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel

    @State private var messageText = ""
    @State private var messages: [OfficerThreadMessage]
    @FocusState private var isComposerFocused: Bool

    init(conversation: OfficerConversation, viewModel: LoanOfficerDashboardViewModel) {
        self.conversation = conversation
        self.viewModel = viewModel
        _messages = State(initialValue: OfficerThreadMessage.seed(from: conversation))
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            OfficerMessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemGroupedBackground))
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last?.id {
                        withAnimation(.snappy) {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
            }

            OfficerMessageComposer(text: $messageText, isFocused: $isComposerFocused, onSend: sendMessage)
        }
        .navigationTitle(conversation.borrowerName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { } label: { Image(systemName: "phone") }
                    .accessibilityLabel("Call borrower")
                Button { } label: { Image(systemName: "info.circle") }
                    .accessibilityLabel("Conversation details")
            }
        }
        .onAppear {
            conversation.items.forEach { viewModel.markActivityRead($0.id) }
            Task {
                await loadMessages()
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }

    private func loadMessages() async {
        guard let app = viewModel.applications.first(where: { $0.applicationId == conversation.applicationId }) else { return }
        do {
            let dbMsgs = try await DatabaseService.shared.fetchMessagesForApplication(applicationId: app.id)
            if !dbMsgs.isEmpty {
                self.messages = dbMsgs.map { dbMsg in
                    let isOfficerSender = dbMsg.senderId == viewModel.officerProfile?.id
                    return OfficerThreadMessage(
                        id: dbMsg.messageId,
                        sender: isOfficerSender ? .officer : .borrower,
                        text: dbMsg.content,
                        timestamp: dbMsg.sentAt
                    )
                }
                if let officerId = viewModel.officerProfile?.id {
                    let unreadIncoming = dbMsgs
                        .filter { $0.receiverId == officerId && !$0.isRead }
                        .map(\.messageId)
                    try? await DatabaseService.shared.markMessagesRead(messageIds: unreadIncoming)
                }
            } else {
                self.messages = []
            }
        } catch {
            print("Failed to fetch messages: \(error)")
        }
    }

    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        messageText = ""

        guard let app = viewModel.applications.first(where: { $0.applicationId == conversation.applicationId }) else { return }
        let officerId = viewModel.officerProfile?.id ?? UUID()
        let borrowerId = app.borrowerId
        let appId = app.id

        let officerMsgId = UUID()
        let officerMsg = OfficerThreadMessage(id: officerMsgId, sender: .officer, text: trimmed, timestamp: Date())
        messages.append(officerMsg)

        Task {
            let dbMsg = DBMessage(
                messageId: officerMsgId,
                senderId: officerId,
                receiverId: borrowerId,
                applicationId: appId,
                content: trimmed,
                sentAt: Date(),
                isRead: false
            )
            do {
                try await DatabaseService.shared.sendMessage(dbMsg)
                try? await DatabaseService.shared.createNotification(
                    userId: borrowerId,
                    title: "New message from your loan officer",
                    message: trimmed
                )
            } catch {
                print("Failed to send officer message to DB: \(error)")
            }
        }
    }
}

private struct OfficerMessageComposer: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let onSend: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            Menu {
                Button { } label: { Label("Attach Document", systemImage: "paperclip") }
                Button { } label: { Label("Send EMI Schedule", systemImage: "calendar") }
                Button { } label: { Label("Request Re-upload", systemImage: "arrow.triangle.2.circlepath") }
            } label: {
                Image(systemName: "plus")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.blue)
                    .frame(width: 34, height: 34)
                    .background(Color(.tertiarySystemFill), in: Circle())
            }

            TextField("Message", text: $text, axis: .vertical)
                .focused(isFocused)
                .lineLimit(1...5)
                .textFieldStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color(.separator).opacity(0.45), lineWidth: 0.5)
                )
                .onSubmit(onSend)

            Button(action: onSend) {
                Image(systemName: text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "mic.fill" : "arrow.up.circle.fill")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary : Color.blue)
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

private struct OfficerMessageBubble: View {
    let message: OfficerThreadMessage

    var body: some View {
        HStack(alignment: .bottom) {
            if message.sender == .officer { Spacer(minLength: 52) }

            VStack(alignment: message.sender == .officer ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(message.sender == .officer ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(message.sender == .officer ? Color.blue : Color(.secondarySystemGroupedBackground), in: UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: message.sender == .officer ? 18 : 5, bottomTrailingRadius: message.sender == .officer ? 5 : 18, topTrailingRadius: 18, style: .continuous))

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            .contextMenu {
                Button { UIPasteboard.general.string = message.text } label: { Label("Copy", systemImage: "doc.on.doc") }
                Button { } label: { Label("Reply", systemImage: "arrowshape.turn.up.left") }
                Button { } label: { Label("Forward", systemImage: "arrowshape.turn.up.right") }
            }

            if message.sender == .borrower { Spacer(minLength: 52) }
        }
    }
}

private struct OfficerThreadMessage: Identifiable, Hashable {
    enum Sender { case officer, borrower }

    let id: UUID
    let sender: Sender
    let text: String
    let timestamp: Date

    init(id: UUID = UUID(), sender: Sender, text: String, timestamp: Date) {
        self.id = id
        self.sender = sender
        self.text = text
        self.timestamp = timestamp
    }

    static func seed(from conversation: OfficerConversation) -> [OfficerThreadMessage] {
        var seeded: [OfficerThreadMessage] = [
            OfficerThreadMessage(sender: .borrower, text: "Hello Officer, I’m checking the status of my \(conversation.loanType).", timestamp: Date().addingTimeInterval(-7200))
        ]

        seeded += conversation.items.map {
            OfficerThreadMessage(sender: .borrower, text: $0.eventDescription, timestamp: $0.timestamp)
        }

        seeded.append(
            OfficerThreadMessage(sender: .officer, text: "I’m reviewing this now. I’ll update you if any document needs correction.", timestamp: Date().addingTimeInterval(-1800))
        )

        return seeded.sorted { $0.timestamp < $1.timestamp }
    }
}

private struct OfficerComposeMessageSheet: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedApplicationId = ""
    @State private var message = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Borrower") {
                    Picker("Application", selection: $selectedApplicationId) {
                        Text("Select").tag("")
                        ForEach(viewModel.applications) { app in
                            Text("\(app.borrowerName) · \(app.applicationId)").tag(app.applicationId)
                        }
                    }
                }

                Section("Message") {
                    TextField("Type message", text: $message, axis: .vertical)
                        .lineLimit(4...8)
                }
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        sendMessage()
                        dismiss()
                    }
                    .disabled(selectedApplicationId.isEmpty || message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func sendMessage() {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let app = viewModel.applications.first(where: { $0.applicationId == selectedApplicationId }) else { return }
        let officerId = viewModel.officerProfile?.id ?? UUID()
        let borrowerId = app.borrowerId
        let appId = app.id
        
        let messageId = UUID()
        
        Task {
            let dbMsg = DBMessage(
                messageId: messageId,
                senderId: officerId,
                receiverId: borrowerId,
                applicationId: appId,
                content: trimmed,
                sentAt: Date(),
                isRead: false
            )
            do {
                try await DatabaseService.shared.sendMessage(dbMsg)
                try? await DatabaseService.shared.createNotification(
                    userId: borrowerId,
                    title: "New message from your loan officer",
                    message: trimmed
                )
                print("Message composed and sent successfully.")
            } catch {
                print("Failed to send composed message to DB: \(error)")
            }
        }
    }
}
