import SwiftUI

struct AdminAuditTrailView: View {
    @State private var viewModel = AdminAuditViewModel()
    @State private var showingExportOptions = false
    @State private var shareURL: URL?
    @State private var isShowingShareSheet = false
    @State private var expandedLogId: UUID?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                if viewModel.isLoading && viewModel.auditEntries.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, minHeight: 200)
                } else if viewModel.filteredEntries.isEmpty {
                    ContentUnavailableView.search(text: viewModel.searchText)
                        .padding(.top, 60)
                } else {
                    HStack {
                        Text("\(viewModel.filteredEntries.count) of \(viewModel.auditEntries.count) logs")
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                    .padding(.top, LMSSpacing.sm)
                    .padding(.bottom, LMSSpacing.md)
                    
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.filteredEntries) { entry in
                            AuditLogCard(
                                entry: entry,
                                isExpanded: expandedLogId == entry.id,
                                onToggle: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        expandedLogId = expandedLogId == entry.id ? nil : entry.id
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                    .padding(.bottom, LMSSpacing.lg)
                }
            }
        }
        .background(LMSColors.background.ignoresSafeArea())
        .navigationTitle("Audit Logs")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search logs…")
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
        .accessibleSheet(isPresented: $isShowingShareSheet) {
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

private struct AuditLogCard: View {
    let entry: AuditLogEntry
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    ZStack {
                        Image(systemName: entry.displayIcon)
                            .symbolVariant(.fill)
                            .font(.title3)
                            .foregroundStyle(entry.displayColor)
                    }
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.action)
                            .font(LMSFont.subheadline.weight(.medium))
                            .foregroundStyle(LMSColors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text("\(entry.userName) • \(entry.entityId)")
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                    
                    Spacer(minLength: 4)
                    
                    VStack(alignment: .trailing, spacing: 6) {
                        Text(RelativeDateFormatter.shared.relativeString(from: entry.timestamp))
                            .font(LMSFont.caption2)
                            .foregroundStyle(LMSColors.textTertiary)
                        
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(LMSColors.textTertiary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }
                .padding(14)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()
                        .padding(.horizontal, 14)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        detailRow(label: "Entity", value: "\(entry.entityType) (\(entry.entityId))")
                        detailRow(label: "Performed By", value: entry.userName)
                        detailRow(label: "Timestamp", value: entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                        if !entry.details.isEmpty {
                            detailRow(label: "Details", value: entry.details)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 14)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
    }
    
    private func detailRow(label: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(LMSFont.caption.weight(.medium))
                .foregroundStyle(LMSColors.textTertiary)
                .frame(width: 72, alignment: .leading)
            Text(value)
                .font(LMSFont.caption)
                .foregroundStyle(LMSColors.textSecondary)
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
