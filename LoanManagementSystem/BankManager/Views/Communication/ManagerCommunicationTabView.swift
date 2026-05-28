import SwiftUI


struct ManagerCommunicationTabView: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel

    @State private var activeConversation: ManagerChatConversation? = nil
    @State private var showBroadcastSheet = false

    var body: some View {
        let filtered = viewModel.filteredConversations

        List {
            Section {
                Picker("Filter", selection: $viewModel.selectedChatFilter) {
                    ForEach(ManagerDashboardViewModel.ChatFilterMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, LMSSpacing.screenHorizontal)
                .padding(.vertical, LMSSpacing.sm)
                .listRowInsets(EdgeInsets())
                .listRowBackground(LMSColors.background)
                .listRowSeparator(.hidden)
            }

            if filtered.isEmpty {
                ContentUnavailableView(
                    "No Conversations",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Loan officer conversations and branch announcements will appear here.")
                )
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .padding(.top, LMSSpacing.xxxl)
            } else {
                ForEach(filtered) { conversation in
                    Button(action: {
                        HapticsManager.triggerImpact(style: .medium)
                        viewModel.markConversationRead(conversation.id)
                        activeConversation = conversation
                    }) {
                        ConversationRow(conversation: conversation)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(
                        conversation.unreadCount > 0
                            ? LMSColors.actionBlue.opacity(0.03)
                            : LMSColors.surface
                    )
                }
            }
        }
        .listStyle(.plain)
        .background(LMSColors.background)
        .searchable(text: $viewModel.chatSearchQuery, prompt: "Search officers…")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    HapticsManager.triggerImpact(style: .medium)
                    showBroadcastSheet = true
                }) {
                    Label("Broadcast", systemImage: "megaphone")
                }
                .disabled(viewModel.officers.isEmpty)
                .accessibilityLabel("Broadcast announcement")
            }
        }
        .sheet(item: $activeConversation) { conversation in
            ManagerChatDetailView(
                conversation: conversation,
                viewModel: viewModel
            )
        }
        .sheet(isPresented: $showBroadcastSheet) {
            BroadcastAnnouncementSheet(viewModel: viewModel)
        }
    }
}


private struct ConversationRow: View {
    let conversation: ManagerChatConversation

    var body: some View {
        HStack(spacing: LMSSpacing.md) {

            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(LMSColors.brandNavy.opacity(0.10))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(conversation.officerInitials)
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(LMSColors.brandNavy)
                    )

                if conversation.priority != .normal {
                    Circle()
                        .fill(conversation.priority.color)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color(UIColor.systemBackground), lineWidth: 2))
                        .offset(x: 2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if conversation.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(LMSColors.amber)
                    }
                    Text(conversation.officerName)
                        .font(.system(.callout, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)

                    Spacer()

                    Text(conversation.timestamp, style: .relative)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(LMSColors.textTertiary)
                }

                HStack {
                    Text(conversation.officerRole)
                        .font(.system(.caption2, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textTertiary)
                    Spacer()
                }

                HStack {
                    Text(conversation.lastMessage)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(conversation.unreadCount > 0 ? LMSColors.textPrimary : LMSColors.textSecondary)
                        .lineLimit(1)

                    Spacer()

                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .frame(width: 20, height: 20)
                            .background(LMSColors.actionBlue)
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(.vertical, LMSSpacing.md)
        .padding(.horizontal, LMSSpacing.lg)
    }
}


private struct ManagerChatDetailView: View {
    let conversation: ManagerChatConversation
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @Environment(\.dismiss) var dismiss

    @State private var chatText = ""

    private var currentMessages: [ManagerChatMessage] {
        viewModel.conversations.first { $0.id == conversation.id }?.messages ?? conversation.messages
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                HStack(spacing: LMSSpacing.md) {
                    ZStack(alignment: .bottomTrailing) {
                        Circle()
                            .fill(LMSColors.brandNavy.opacity(0.12))
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(conversation.officerInitials)
                                    .font(.system(.subheadline, design: .rounded).bold())
                                    .foregroundStyle(LMSColors.brandNavy)
                            )
                        Circle()
                            .fill(LMSColors.emerald)
                            .frame(width: 10, height: 10)
                            .overlay(Circle().stroke(Color(UIColor.systemBackground), lineWidth: 1.5))
                            .offset(x: 1, y: 1)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(conversation.officerName)
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundStyle(LMSColors.textPrimary)
                        Text("\(conversation.officerRole) · Online")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(LMSColors.emerald)
                    }
                    Spacer()
                }
                .padding(LMSSpacing.lg)
                .background(LMSColors.surface)

                Divider()


                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: LMSSpacing.md) {
                            ForEach(currentMessages) { msg in
                                ManagerChatBubble(message: msg)
                                    .id(msg.id)
                            }
                        }
                        .padding(LMSSpacing.lg)
                    }
                    .onChange(of: currentMessages.count) { _, _ in
                        if let lastId = currentMessages.last?.id {
                            withAnimation(.spring(response: 0.3)) {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()


                HStack(spacing: 10) {
                    TextField("Type a message…", text: $chatText, axis: .vertical)
                        .font(.system(.subheadline, design: .rounded))
                        .lineLimit(1...4)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(LMSColors.textPrimary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    Button(action: {
                        viewModel.sendMessage(chatText, toConversation: conversation.id)
                        chatText = ""
                    }) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(chatText.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : LMSColors.actionBlue)
                            .clipShape(Circle())
                    }
                    .disabled(chatText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(LMSSpacing.md)
                .background(LMSColors.surface)
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}


private struct ManagerChatBubble: View {
    let message: ManagerChatMessage

    var body: some View {
        HStack {
            if message.isFromManager { Spacer() }

            if message.isSystemMessage {
                Spacer()
                Text(message.text)
                    .font(.system(.caption2, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(LMSColors.textPrimary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Spacer()
            } else {
                VStack(alignment: message.isFromManager ? .trailing : .leading, spacing: 3) {
                    if !message.isFromManager {
                        Text(message.senderName)
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(LMSColors.textTertiary)
                    }

                    Text(message.text)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(message.isFromManager ? .white : LMSColors.textPrimary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            message.isFromManager
                                ? AnyShapeStyle(LinearGradient(colors: [LMSColors.brandNavy, LMSColors.actionBlue], startPoint: .leading, endPoint: .trailing))
                                : AnyShapeStyle(LMSColors.surfaceElevated)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    HStack(spacing: 4) {
                        Text(message.timestamp, style: .time)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(LMSColors.textTertiary)

                        if message.isFromManager {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(LMSColors.emerald)
                        }
                    }
                }
                .frame(maxWidth: 280, alignment: message.isFromManager ? .trailing : .leading)
            }

            if !message.isFromManager && !message.isSystemMessage { Spacer() }
        }
    }
}


private struct BroadcastAnnouncementSheet: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @Environment(\.dismiss) var dismiss

    @State private var subject = ""
    @State private var message = ""
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            VStack(spacing: LMSSpacing.xl) {

                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [LMSColors.brandNavy.opacity(0.15), LMSColors.actionBlue.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    Image(systemName: "megaphone.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(LMSColors.brandNavy)
                }
                .padding(.top, LMSSpacing.lg)

                Text("Broadcast to All Officers")
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)

                Text("This message will be sent to \(viewModel.officers.count) officers at \(viewModel.branchOverview.name).")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                    TextField("Subject", text: $subject)
                        .font(.system(.body, design: .rounded))
                        .padding(LMSSpacing.md)
                        .background(LMSColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))

                    TextEditor(text: $message)
                        .font(.system(.body, design: .rounded))
                        .frame(height: 120)
                        .padding(LMSSpacing.sm)
                        .background(LMSColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
                        )
                }

                Spacer()

                Button(action: {
                    isSending = true
                    HapticsManager.triggerImpact(style: .heavy)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        viewModel.broadcastAnnouncement(subject: subject, message: message)
                        isSending = false
                        dismiss()
                    }
                }) {
                    Group {
                        if isSending {
                            ProgressView().tint(.white)
                        } else {
                            Text("Send Broadcast")
                                .font(.system(.body, design: .rounded).weight(.bold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(LMSColors.brandNavy)
                    .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
                }
                .disabled(subject.isEmpty || message.isEmpty || isSending)
                .opacity(subject.isEmpty || message.isEmpty ? 0.5 : 1.0)
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)
            .navigationTitle("Broadcast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ManagerCommunicationTabView(viewModel: PreviewSupport.managerViewModel)
        .previewManagerEnvironment()
}
