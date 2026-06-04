
import SwiftUI
import Combine


struct BorrowerChatView: View {
    @State private var viewModel = BorrowerChatViewModel()
    @State private var searchText = ""

    private var filteredConversations: [BorrowerConversation] {
        if searchText.isEmpty {
            return viewModel.conversations
        }
        return viewModel.conversations.filter {
            $0.loanProductName.localizedCaseInsensitiveContains(searchText) ||
            $0.applicationDisplayId.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.conversations.isEmpty {
                    loadingState
                } else if viewModel.conversations.isEmpty {
                    emptyState
                } else {
                    conversationsList
                }
            }
            .navigationTitle("Messages")
            .searchable(text: $searchText, prompt: "Search by loan type or application")
            .refreshable {
                await viewModel.fetchConversations()
            }
            .task {
                await viewModel.fetchConversations()
                await viewModel.setupRealtime()
            }
        }
    }

    private var loadingState: some View {
        VStack(spacing: LMSSpacing.lg) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(LMSColors.brandNavy)
                .scaleEffect(1.2)
            Text("Loading messages…")
                .font(LMSFont.footnote)
                .foregroundStyle(LMSColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LMSColors.background)
    }

    private var emptyState: some View {
        VStack(spacing: LMSSpacing.lg) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 52, weight: .light))
                .foregroundStyle(LMSColors.brandNavy.opacity(0.6))
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: LMSSpacing.sm) {
                Text("No Conversations Yet")
                    .font(LMSFont.headline)
                    .foregroundStyle(LMSColors.textPrimary)

                Text("Messages from your assigned loan officer will appear here once your application is under review.")
                    .font(LMSFont.footnote)
                    .foregroundStyle(LMSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, LMSSpacing.xxl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LMSColors.background)
    }

    private var conversationsList: some View {
        List {
            ForEach(filteredConversations) { conversation in
                NavigationLink {
                    BorrowerMessageThreadView(conversation: conversation, viewModel: viewModel)
                } label: {
                    BorrowerConversationRow(conversation: conversation)
                }
            }
        }
        .listStyle(.insetGrouped)
    }
}


private struct BorrowerConversationRow: View {
    let conversation: BorrowerConversation

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Circle()
                .fill(conversation.unreadCount > 0 ? LMSColors.actionBlue : Color.clear)
                .frame(width: 10, height: 10)

            BorrowerChatAvatar(
                name: "Loan Officer",
                icon: "person.badge.shield.checkmark.fill",
                tint: LMSColors.brandNavy
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(conversation.loanProductName)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(LMSColors.textPrimary)
                            .lineLimit(1)

                        Text(conversation.applicationDisplayId)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(LMSColors.textSecondary)
                    }

                    Spacer()

                    if let latest = conversation.latestMessage {
                        Text(RelativeDateFormatter.shared.relativeString(from: latest.sentAt))
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(conversation.unreadCount > 0 ? LMSColors.actionBlue : LMSColors.textTertiary)
                    }
                }

                if let latest = conversation.latestMessage {
                    Text(latest.content)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(conversation.unreadCount > 0 ? LMSColors.textPrimary : LMSColors.textSecondary)
                        .lineLimit(2)
                }

                if conversation.unreadCount > 0 {
                    HStack {
                        Spacer()
                        Text("\(conversation.unreadCount)")
                            .font(.system(.caption2, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(LMSColors.actionBlue, in: Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(conversation.loanProductName), \(conversation.unreadCount) unread messages")
    }
}


private struct BorrowerMessageThreadView: View {
    let conversation: BorrowerConversation
    @Bindable var viewModel: BorrowerChatViewModel

    @State private var messageText = ""
    @State private var messages: [DBMessage] = []
    @FocusState private var isComposerFocused: Bool

    /// The officer's user ID for this conversation (derived from message participants).
    private var officerUserId: UUID? {
        guard let borrowerUid = AuthManager.shared.currentUser?.uid,
              let borrowerId = UUID(uuidString: borrowerUid) else { return nil }
        return messages.first(where: { $0.senderId != borrowerId })?.senderId
            ?? messages.first(where: { $0.receiverId != borrowerId })?.receiverId
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(messages) { message in
                            BorrowerMessageBubble(message: message, isBorrower: isBorrowerMessage(message))
                                .id(message.id)
                        }
                    }
                    .padding(.horizontal, LMSSpacing.lg)
                    .padding(.vertical, LMSSpacing.md)
                }
                .background(LMSColors.background)
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last?.id {
                        withAnimation(.snappy) {
                            proxy.scrollTo(last, anchor: .bottom)
                        }
                    }
                }
            }

            BorrowerMessageComposer(text: $messageText, isFocused: $isComposerFocused, onSend: sendMessage)
        }
        .navigationTitle(conversation.loanProductName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Text(conversation.applicationDisplayId)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(LMSColors.textSecondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(LMSColors.surfaceTertiary, in: Capsule())
            }
        }
        .onAppear {
            messages = conversation.messages
            Task {
                let freshMsgs = await viewModel.fetchMessagesForThread(applicationId: conversation.applicationId)
                if !freshMsgs.isEmpty {
                    messages = freshMsgs
                }
                await viewModel.markMessagesAsRead(messages: messages)
            }
        }
        .onChange(of: viewModel.conversations) { _, newConvos in
            if let updated = newConvos.first(where: { $0.applicationId == conversation.applicationId }) {
                if updated.messages.count != messages.count {
                    messages = updated.messages
                    Task {
                        await viewModel.markMessagesAsRead(messages: messages)
                    }
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
    }

    private func isBorrowerMessage(_ message: DBMessage) -> Bool {
        guard let uid = AuthManager.shared.currentUser?.uid,
              let borrowerId = UUID(uuidString: uid) else { return false }
        return message.senderId == borrowerId
    }

    private func sendMessage() {
        let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard let receiverId = officerUserId else {
            print("[BorrowerChat] Cannot determine officer ID for reply.")
            return
        }

        messageText = ""
        let appId = conversation.applicationId

        Task {
            if let sent = await viewModel.sendMessage(content: trimmed, applicationId: appId, receiverId: receiverId) {
                messages.append(sent)
            }
        }
    }
}


private struct BorrowerMessageComposer: View {
    @Binding var text: String
    var isFocused: FocusState<Bool>.Binding
    let onSend: () -> Void

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Message", text: $text, axis: .vertical)
                .focused(isFocused)
                .lineLimit(1...5)
                .textFieldStyle(.plain)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(LMSColors.surfaceElevated, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(LMSColors.separatorLight, lineWidth: 0.5)
                )
                .onSubmit(onSend)

            Button(action: onSend) {
                Image(systemName: canSend ? "arrow.up.circle.fill" : "arrow.up.circle")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(canSend ? LMSColors.brandNavy : LMSColors.textTertiary)
            }
            .disabled(!canSend)
            .accessibilityLabel("Send message")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }
}


private struct BorrowerMessageBubble: View {
    let message: DBMessage
    let isBorrower: Bool

    var body: some View {
        HStack(alignment: .bottom) {
            if isBorrower { Spacer(minLength: 52) }

            VStack(alignment: isBorrower ? .trailing : .leading, spacing: 4) {
                if !isBorrower {
                    Text("Loan Officer")
                        .font(.system(.caption2, design: .rounded).weight(.semibold))
                        .foregroundStyle(LMSColors.textTertiary)
                        .padding(.horizontal, 4)
                }

                Text(message.content)
                    .font(.body)
                    .foregroundStyle(isBorrower ? .white : LMSColors.textPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isBorrower
                            ? AnyShapeStyle(LinearGradient(
                                colors: [LMSColors.brandNavy, LMSColors.brandNavyLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                              ))
                            : AnyShapeStyle(LMSColors.surfaceElevated),
                        in: UnevenRoundedRectangle(
                            topLeadingRadius: 18,
                            bottomLeadingRadius: isBorrower ? 18 : 5,
                            bottomTrailingRadius: isBorrower ? 5 : 18,
                            topTrailingRadius: 18,
                            style: .continuous
                        )
                    )
                    .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)

                Text(message.sentAt, style: .time)
                    .font(.caption2)
                    .foregroundStyle(LMSColors.textTertiary)
                    .padding(.horizontal, 4)
            }
            .contextMenu {
                Button { UIPasteboard.general.string = message.content } label: { Label("Copy", systemImage: "doc.on.doc") }
            }

            if !isBorrower { Spacer(minLength: 52) }
        }
    }
}


private struct BorrowerChatAvatar: View {
    let name: String
    let icon: String
    let tint: Color

    var body: some View {
        Image(systemName: icon)
            .font(.system(.subheadline, weight: .bold))
            .foregroundStyle(tint)
            .frame(width: 44, height: 44)
            .background(tint.opacity(0.12), in: Circle())
    }
}


#Preview {
    BorrowerChatView()
        .environment(AuthManager())
}
