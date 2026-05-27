import SwiftUI

struct AdminAuditTrailView: View {
    @StateObject private var viewModel = AdminAuditViewModel()
    
    var body: some View {
        List {
            if viewModel.isLoading && viewModel.auditEntries.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else if viewModel.filteredEntries.isEmpty {
                Text("No audit logs found.")
                    .font(LMSFont.body)
                    .foregroundStyle(LMSColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(viewModel.filteredEntries) { entry in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: entry.type.icon)
                                .foregroundStyle(entry.type.color)
                            
                            Text(entry.action)
                                .font(LMSFont.headline)
                            
                            Spacer()
                            
                            Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                        
                        Text("\(entry.userName) • \(entry.entityType) (\(entry.entityId))")
                            .font(LMSFont.subheadline)
                            .foregroundStyle(LMSColors.textPrimary)
                        
                        Text(entry.details)
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Audit Trail")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.searchText, prompt: "Search logs...")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("All Types") { viewModel.selectedType = nil }
                    ForEach(AuditLogType.allCases, id: \.self) { type in
                        Button(type.rawValue) {
                            viewModel.selectedType = type
                        }
                    }
                } label: {
                    Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .task {
            if viewModel.auditEntries.isEmpty {
                await viewModel.loadAuditLog()
            }
        }
    }
}
