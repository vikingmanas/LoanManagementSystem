import SwiftUI


struct ManagerCommunicationTabView: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @State private var activeConversation: ManagerChatConversation? = nil
    @State private var showBroadcastSheet = false

    var body: some View {
        let filtered = viewModel.filteredConversations

        List {
            // Segmented Picker Header
            Section {
                Picker("Filter", selection: $viewModel.selectedChatFilter) {
                    ForEach(ManagerDashboardViewModel.ChatFilterMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                .listRowBackground(Color.clear)
            }

            if filtered.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No Conversations",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Officer conversations and announcements will appear here.")
                    )
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(filtered) { conversation in
                        NavigationLink {
                            ManagerChatDetailView(conversation: conversation, viewModel: viewModel)
                        } label: {
                            ConversationRow(conversation: conversation)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button {
                                viewModel.markConversationRead(conversation.id)
                            } label: {
                                Label("Read", systemImage: "envelope.open.fill")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $viewModel.chatSearchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search officers…")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    HapticsManager.triggerImpact(style: .light)
                    showBroadcastSheet = true
                } label: {
                    Label("Broadcast", systemImage: "megaphone.fill")
                }
                .disabled(viewModel.officers.isEmpty)
            }
        }
        .accessibleSheet(isPresented: $showBroadcastSheet) {
            BroadcastAnnouncementSheet(viewModel: viewModel)
        }
    }
}

private struct ConversationRow: View {
    let conversation: ManagerChatConversation

    var body: some View {
        HStack(spacing: 12) {
            // Avatar with Status
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(LMSColors.brandNavy.gradient)
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(conversation.officerInitials)
                            .font(.system(.body, design: .rounded).bold())
                            .foregroundStyle(.white)
                    )

                if conversation.priority == .high {
                    Circle()
                        .fill(.red)
                        .frame(width: 12, height: 12)
                        .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                        .offset(x: 2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.officerName)
                        .font(.headline)
                    
                    if conversation.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    
                    Spacer()
                    
                    Text(conversation.timestamp, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(conversation.lastMessage)
                    .font(.subheadline)
                    .foregroundStyle(conversation.unreadCount > 0 ? Color(.label) : .secondary)
                    .lineLimit(2)
            }

            if conversation.unreadCount > 0 {
                Circle()
                    .fill(.blue)
                    .frame(width: 8, height: 8)
            }
        }
        .padding(.vertical, 4)
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
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(currentMessages) { msg in
                            ChatBubble(message: msg)
                                .id(msg.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: currentMessages.count) { _, _ in
                    if let lastId = currentMessages.last?.id {
                        withAnimation(.spring()) { proxy.scrollTo(lastId, anchor: .bottom) }
                    }
                }
            }

            // Native Input Bar
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    TextField("Message", text: $chatText, axis: .vertical)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.secondarySystemFill), in: RoundedRectangle(cornerRadius: 20))
                        .lineLimit(1...5)

                    Button {
                        viewModel.sendMessage(chatText, toConversation: conversation.id)
                        chatText = ""
                    } label: {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(chatText.isEmpty ? Color(.systemGray4) : .blue)
                    }
                    .disabled(chatText.isEmpty)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial)
            }
        }
        .navigationTitle(conversation.officerName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text(conversation.officerName).font(.headline)
                    Text(conversation.officerRole).font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct ChatBubble: View {
    let message: ManagerChatMessage

    var body: some View {
        HStack {
            if message.isFromManager { Spacer() }
            
            Text(message.text)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(message.isFromManager ? Color.blue : Color(.secondarySystemFill))
                .foregroundStyle(message.isFromManager ? .white : Color(.label))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            
            if !message.isFromManager { Spacer() }
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
            List {
                Section {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "megaphone.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(LMSColors.brandNavy.gradient)
                        
                        Text("Broadcast Announcement")
                            .font(.title3.bold())
                        
                        Text("Sent to all \(viewModel.officers.count) officers in \(viewModel.branchOverview.name)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                .listRowBackground(Color.clear)

                Section("Details") {
                    TextField("Subject", text: $subject)
                    TextEditor(text: $message)
                        .frame(minHeight: 150)
                }

                Section {
                    Button {
                        isSending = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            viewModel.broadcastAnnouncement(subject: subject, message: message)
                            isSending = false
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Spacer()
                            if isSending {
                                ProgressView().tint(.white)
                            } else {
                                Text("Send to All Officers").bold()
                            }
                            Spacer()
                        }
                    }
                    .foregroundStyle(.white)
                    .listRowBackground(subject.isEmpty || message.isEmpty ? Color.gray : LMSColors.brandNavy)
                    .disabled(subject.isEmpty || message.isEmpty || isSending)
                }
            }
            .navigationTitle("New Broadcast")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

