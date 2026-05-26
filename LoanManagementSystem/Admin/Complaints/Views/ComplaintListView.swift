import SwiftUI

struct ComplaintListView: View {
    @ObservedObject var viewModel: ComplaintViewModel
    
    var body: some View {
        ScrollView {
            // Origin Toggle
            Picker("Type", selection: Binding(
                get: { viewModel.selectedOrigin ?? .complaint },
                set: { viewModel.selectedOrigin = viewModel.selectedOrigin == $0 ? nil : $0 }
            )) {
                Text("All").tag(Optional<TicketOrigin>.none)
                ForEach(TicketOrigin.allCases) { origin in
                    Label(origin.rawValue, systemImage: origin.iconName).tag(Optional(origin))
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, LMSSpacing.screenHorizontal)
            .padding(.top, 8)
            
            LazyVStack(spacing: 16) {
                ForEach(viewModel.filteredTickets) { ticket in
                    NavigationLink(destination: ComplaintDetailView(viewModel: viewModel, ticketId: ticket.id)) {
                        ComplaintCard(ticket: ticket)
                    }
                    .buttonStyle(LMSPressableStyle())
                }
                
                if viewModel.filteredTickets.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 40))
                            .foregroundStyle(LMSColors.emerald)
                        Text("No tickets found")
                            .font(LMSFont.headline)
                            .foregroundStyle(LMSColors.textSecondary)
                        Text("Try adjusting your filters or search terms.")
                            .font(LMSFont.subheadline)
                            .foregroundStyle(LMSColors.textTertiary)
                    }
                    .padding(.top, 60)
                }
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)
            .padding(.vertical, 16)
        }
        .background(LMSColors.background.ignoresSafeArea())
        .navigationTitle("Complaints & Issues")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, prompt: "Search ID, Title, Borrower, or Manager")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Section("Status") {
                        Button("All") { viewModel.selectedStatus = nil }
                        ForEach(ComplaintStatus.allCases) { s in
                            Button(s.rawValue) { viewModel.selectedStatus = s }
                        }
                    }
                    Section("Priority") {
                        Button("All") { viewModel.selectedPriority = nil }
                        ForEach(ComplaintPriority.allCases) { p in
                            Button(p.rawValue) { viewModel.selectedPriority = p }
                        }
                    }
                    Section("Category") {
                        Button("All") { viewModel.selectedCategory = nil }
                        ForEach(ComplaintCategory.allCases) { c in
                            Button(c.rawValue) { viewModel.selectedCategory = c }
                        }
                    }
                    Section("Manager") {
                        Button("All") { viewModel.selectedManager = nil }
                        ForEach(viewModel.availableManagers, id: \.self) { m in
                            Button(m) { viewModel.selectedManager = m }
                        }
                    }
                    Section {
                        Button("Clear All Filters", role: .destructive) { viewModel.clearAllFilters() }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 18))
                        .foregroundStyle(LMSColors.brandNavy)
                        .overlay(
                            Circle()
                                .fill(LMSColors.coral)
                                .frame(width: 8, height: 8)
                                .offset(x: 8, y: -8)
                                .opacity(hasActiveFilter ? 1 : 0)
                        )
                }
            }
        }
    }
    
    private var hasActiveFilter: Bool {
        viewModel.selectedStatus != nil || viewModel.selectedPriority != nil ||
        viewModel.selectedCategory != nil || viewModel.selectedManager != nil
    }
}

#Preview {
    NavigationStack {
        ComplaintListView(viewModel: ComplaintViewModel())
    }
}
