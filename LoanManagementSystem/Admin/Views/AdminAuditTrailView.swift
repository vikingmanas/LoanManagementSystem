import SwiftUI

struct AdminAuditTrailView: View {
    @StateObject private var viewModel = AdminAuditViewModel()
    @State private var showingExportOptions = false
    @State private var shareURL: URL?
    @State private var isShowingShareSheet = false
    
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
                            Image(systemName: entry.displayIcon)
                                .foregroundStyle(entry.displayColor)
                            
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
                HStack(spacing: 16) {
                    Button {
                        showingExportOptions = true
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .disabled(viewModel.filteredEntries.isEmpty)

                    Menu {
                        Button("All Types") { viewModel.selectedType = nil }
                        ForEach(AuditLogType.allCases.filter { $0 != .systemAction }, id: \.self) { type in
                            Button(type.rawValue) {
                                viewModel.selectedType = type
                            }
                        }
                    } label: {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
        .confirmationDialog("Export Audit Trail", isPresented: $showingExportOptions, titleVisibility: .visible) {
            Button("Export as PDF") {
                if let url = viewModel.exportPDF() {
                    shareURL = url
                    isShowingShareSheet = true
                }
            }
            Button("Export as CSV") {
                if let url = viewModel.exportCSV() {
                    shareURL = url
                    isShowingShareSheet = true
                }
            }
            Button("Cancel", role: .cancel) {}
        }
        .sheet(isPresented: $isShowingShareSheet) {
            if let url = shareURL {
                AdminAuditShareSheet(items: [url])
            }
        }
        .task {
            if viewModel.auditEntries.isEmpty {
                await viewModel.loadAuditLog()
            }
        }
    }
}

private struct AdminAuditShareSheet: UIViewControllerRepresentable {
    var items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
