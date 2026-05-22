import SwiftUI

struct ChatsFeedTabView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    
    @State private var filterOnlyQueries = false
    @State private var activeChatApp: ActivityFeedItem? = nil
    @State private var chatText = ""
    @State private var simulatedReplies: [SimulatedChatMessage] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Sticky Filter Header
            VStack(spacing: 12) {
                Picker("Feed Mode", selection: $filterOnlyQueries) {
                    Text("All Activity").tag(false)
                    Text("Raised Queries").tag(true)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            .background(Color(.systemBackground))
            .shadow(color: .black.opacity(0.03), radius: 3, x: 0, y: 3)
            
            // Timeline Content
            let items = viewModel.activityFeed.filter { item in
                filterOnlyQueries ? (item.eventType == .queryRaised) : true
            }
            
            if items.isEmpty {
                Spacer()
                ContentUnavailableView(
                    filterOnlyQueries ? "No Active Queries" : "No Activities",
                    systemImage: filterOnlyQueries ? "bubble.left.and.bubble.right.fill" : "bell.slash",
                    description: Text(filterOnlyQueries ? "Borrowers have not raised any clarification queries." : "Timeline is clean! All alerts processed.")
                )
                Spacer()
            } else {
                List {
                    // Quick Action: Mark all read
                    if viewModel.unreadActivityCount > 0 && !filterOnlyQueries {
                        Button(action: {
                            HapticsManager.triggerImpact(style: .medium)
                            viewModel.markAllActivityRead()
                        }) {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                Text("Mark All Read")
                                    .font(.system(.caption, design: .rounded).bold())
                                Spacer()
                            }
                            .foregroundColor(AppTheme.actionBlue)
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.clear)
                    }
                    
                    ForEach(items) { item in
                        ActivityFeedRow(
                            item: item,
                            onMarkRead: {
                                viewModel.markActivityRead(item.id)
                            },
                            onDismiss: {
                                viewModel.dismissActivity(item.id)
                            },
                            onActionTapped: { _ in
                                HapticsManager.triggerImpact(style: .medium)
                                activeChatApp = item
                                loadSimulatedChat(for: item)
                            }
                        )
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(item.isRead ? Color.clear : AppTheme.actionBlue.opacity(0.03))
                        .listRowSeparator(.visible)
                        .onTapGesture {
                            HapticsManager.triggerImpact(style: .light)
                            viewModel.markActivityRead(item.id)
                            activeChatApp = item
                            loadSimulatedChat(for: item)
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    await viewModel.fetchDashboardData()
                }
            }
        }
        .sheet(item: $activeChatApp) { item in
            ChatDetailResolverView(
                item: item,
                chatText: $chatText,
                messages: $simulatedReplies,
                onSend: {
                    sendChatMessage(for: item)
                }
            )
        }
    }
    
    // Simulate interactive chatting
    private func loadSimulatedChat(for item: ActivityFeedItem) {
        simulatedReplies = [
            SimulatedChatMessage(
                sender: .borrower,
                text: "Hello, I received a notification regarding the query on \(item.loanType). Let me know what information is missing.",
                time: "2 hours ago"
            ),
            SimulatedChatMessage(
                sender: .system,
                text: "Clarification query raised: \(item.eventDescription)",
                time: "1 hour ago"
            )
        ]
    }
    
    private func sendChatMessage(for item: ActivityFeedItem) {
        guard !chatText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        
        // 1. Append officer message
        let newMsg = SimulatedChatMessage(sender: .officer, text: chatText, time: "Just now")
        simulatedReplies.append(newMsg)
        let sentText = chatText
        chatText = ""
        
        HapticsManager.triggerImpact(style: .medium)
        
        // 2. Simulate user reply after 1.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            HapticsManager.triggerImpact(style: .light)
            let replyText: String
            if sentText.lowercased().contains("document") || sentText.lowercased().contains("upload") {
                replyText = "Understood. I will re-upload the correct self-attested bank statements through my portal right away."
            } else if sentText.lowercased().contains("cibil") || sentText.lowercased().contains("score") {
                replyText = "Yes, I had closed an older credit card account last month, which might explain the score discrepancy."
            } else {
                replyText = "Thank you, Officer Arjun. I appreciate the guidance and will coordinate the details."
            }
            
            simulatedReplies.append(SimulatedChatMessage(sender: .borrower, text: replyText, time: "Just now"))
        }
    }
}

// Chat helper types
struct SimulatedChatMessage: Identifiable {
    let id = UUID()
    enum Sender {
        case officer
        case borrower
        case system
    }
    let sender: Sender
    let text: String
    let time: String
}

struct ChatDetailResolverView: View {
    let item: ActivityFeedItem
    @Binding var chatText: String
    @Binding var messages: [SimulatedChatMessage]
    var onSend: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header details
                HStack(spacing: 12) {
                    Circle()
                        .fill(AppTheme.brandNavy.opacity(0.1))
                        .frame(width: 44, height: 44)
                        .overlay(
                            Text(String(item.borrowerName.prefix(2)))
                                .font(.system(.subheadline, design: .rounded).bold())
                                .foregroundColor(AppTheme.brandNavy)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.borrowerName)
                            .font(.system(.subheadline, design: .rounded).bold())
                        Text("\(item.loanType) · \(item.applicationId)")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding()
                .background(AppTheme.neutralSurface)
                
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 14) {
                            ForEach(messages) { msg in
                                ChatMessageBubble(msg: msg)
                                    .id(msg.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { _, _ in
                        if let lastId = messages.last?.id {
                            withAnimation {
                                proxy.scrollTo(lastId, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Typing Row
                HStack(spacing: 10) {
                    TextField("Type clarification instructions...", text: $chatText)
                        .font(.system(.subheadline, design: .rounded))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.primary.opacity(0.06))
                        .cornerRadius(20)
                    
                    Button(action: onSend) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 38, height: 38)
                            .background(AppTheme.actionBlue)
                            .clipShape(Circle())
                    }
                    .disabled(chatText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle("Borrower Chat Console")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct ChatMessageBubble: View {
    let msg: SimulatedChatMessage
    
    var body: some View {
        HStack {
            if msg.sender == .officer {
                Spacer()
            }
            
            if msg.sender == .system {
                Spacer()
                Text(msg.text)
                    .font(.system(.caption2, design: .rounded).bold())
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
                Spacer()
            } else {
                VStack(alignment: msg.sender == .officer ? .trailing : .leading, spacing: 3) {
                    Text(msg.text)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(msg.sender == .officer ? .white : .primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(msg.sender == .officer ? AppTheme.actionBlue : AppTheme.neutralSurface)
                        .cornerRadius(16)
                    
                    Text(msg.time)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 4)
                }
            }
            
            if msg.sender == .borrower {
                Spacer()
            }
        }
    }
}
