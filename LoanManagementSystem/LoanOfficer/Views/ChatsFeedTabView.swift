import SwiftUI

struct ChatsFeedTabView: View {
    enum ChatFilterType {
        case all
        case unread
        case queries
    }

    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    @State private var selectedFilter: ChatFilterType = .all

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {

                HStack(alignment: .center) {
                    Text(selectedFilter == .queries ? "Queries" : (selectedFilter == .unread ? "Unread Messages" : "All Messages"))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Spacer()

                    Menu {
                        Section(header: Text("Filter By")) {
                            Button {
                                selectedFilter = .all
                            } label: {
                                Label("All Messages", systemImage: selectedFilter == .all ? "checkmark" : "")
                            }
                            Button {
                                selectedFilter = .unread
                            } label: {
                                Label("Unread", systemImage: selectedFilter == .unread ? "checkmark" : "")
                            }
                            Button {
                                selectedFilter = .queries
                            } label: {
                                Label("Queries", systemImage: selectedFilter == .queries ? "checkmark" : "")
                            }
                        }

                        if viewModel.unreadActivityCount > 0 {
                            Section {
                                Button {
                                    HapticsManager.triggerImpact(style: .medium)
                                    viewModel.markAllActivityRead()
                                } label: {
                                    Label("Mark All as Read", systemImage: "checkmark.circle")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.system(size: 26))
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 4)


                let items = viewModel.activityFeed.filter { item in
                    switch selectedFilter {
                    case .all: return true
                    case .unread: return !item.isRead
                    case .queries: return item.eventType == .queryRaised
                    }
                }

                if items.isEmpty {
                    Spacer()
                    ContentUnavailableView(
                        selectedFilter == .queries ? "No Active Queries" : (selectedFilter == .unread ? "No Unread Messages" : "No Activities"),
                        systemImage: selectedFilter == .queries ? "bubble.left.and.bubble.right.fill" : "bell.slash",
                        description: Text(selectedFilter == .queries ? "Borrowers have not raised any clarification queries." : "Timeline is clean! All alerts processed.")
                    )
                    Spacer()
                } else {
                    List {

                        if viewModel.unreadActivityCount > 0 && selectedFilter != .queries {
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
                                .foregroundStyle(AppTheme.actionBlue)
                                .padding(.vertical, 4)
                            }
                            .listRowBackground(Color.clear)
                        }

                        ForEach(items) { item in
                            NavigationLink(destination: ChatDetailResolverView(item: item)
                                .onAppear {
                                    viewModel.markActivityRead(item.id)
                                }
                            ) {
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
                                        viewModel.markActivityRead(item.id)
                                    }
                                )
                            }
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color(.systemBackground))
                            .listRowSeparator(.visible)
                        }
                    }
                    .listStyle(.plain)
                    .refreshable {
                        await viewModel.fetchDashboardData()
                    }
                }
            }
            .background(Color(.systemBackground))
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}


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
    @State private var chatText = ""
    @State private var messages: [SimulatedChatMessage] = []

    var body: some View {
        VStack(spacing: 0) {

            HStack(spacing: 12) {
                Circle()
                    .fill(AppTheme.brandNavy.opacity(0.1))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Text(String(item.borrowerName.prefix(2)))
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundStyle(AppTheme.brandNavy)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.borrowerName)
                        .font(.system(.subheadline, design: .rounded).bold())
                    Text("\(item.loanType) · \(item.applicationId)")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                }
                Spacer()
            }
            .padding()
            .background(AppTheme.neutralSurface)


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


            HStack(spacing: 12) {
                Button(action: {}) {
                    Image(systemName: "plus")
                        .font(.system(size: 20))
                        .foregroundColor(Color(.systemGray))
                        .padding(8)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }

                HStack {
                    TextField("Message", text: $chatText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                    if !chatText.trimmingCharacters(in: .whitespaces).isEmpty {
                        Button(action: sendChatMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.blue)
                        }
                        .padding(.trailing, 4)
                    } else {
                        Image(systemName: "mic")
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                            .padding(.trailing, 12)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .background(Color(.systemBackground).clipShape(RoundedRectangle(cornerRadius: 20)))
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    ZStack {
                        Circle().fill(Color(.systemGray5)).frame(width: 32, height: 32)
                        Text(String(item.borrowerName.prefix(2)).uppercased())
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(Color(.darkGray))
                    }
                    Text(item.borrowerName)
                        .font(.caption)
                        .bold()
                }
            }
        }
        .onAppear {
            loadSimulatedChat()
        }
    }


    private func loadSimulatedChat() {
        if messages.isEmpty {
            messages = [
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
    }

    private func sendChatMessage() {
        guard !chatText.trimmingCharacters(in: .whitespaces).isEmpty else { return }


        let newMsg = SimulatedChatMessage(sender: .officer, text: chatText, time: "Just now")
        messages.append(newMsg)
        let sentText = chatText
        chatText = ""

        HapticsManager.triggerImpact(style: .medium)


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

            messages.append(SimulatedChatMessage(sender: .borrower, text: replyText, time: "Just now"))
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
                    .foregroundStyle(LMSColors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(LMSColors.textPrimary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                Spacer()
            } else {
                VStack(alignment: msg.sender == .officer ? .trailing : .leading, spacing: 3) {
                    Text(msg.text)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(msg.sender == .officer ? .white : .primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(msg.sender == .officer ? AppTheme.actionBlue : AppTheme.neutralSurface)
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 18,
                                bottomLeadingRadius: msg.sender == .officer ? 18 : 4,
                                bottomTrailingRadius: msg.sender == .officer ? 4 : 18,
                                topTrailingRadius: 18
                            )
                        )

                    Text(msg.time)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                        .padding(.horizontal, 4)
                }
            }

            if msg.sender == .borrower {
                Spacer()
            }
        }
        .contextMenu {
            if msg.sender != .system {
                Button {

                    UIPasteboard.general.string = msg.text
                    HapticsManager.triggerImpact(style: .light)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }

                Button {

                    HapticsManager.triggerImpact(style: .light)
                } label: {
                    Label("Reply", systemImage: "arrowshape.turn.up.left")
                }

                Button {

                    HapticsManager.triggerImpact(style: .light)
                } label: {
                    Label("Translate", systemImage: "character.book.closed")
                }

                Button {

                    HapticsManager.triggerImpact(style: .light)
                } label: {
                    Label("More...", systemImage: "ellipsis.circle")
                }
            }
        }
    }
}

#Preview {
    ChatsFeedTabView(viewModel: PreviewSupport.loanOfficerViewModel)
        .previewLoanOfficerEnvironment()
}

