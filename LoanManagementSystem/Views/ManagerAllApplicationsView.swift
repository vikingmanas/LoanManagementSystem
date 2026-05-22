import SwiftUI

struct ManagerAllApplicationsView: View {
    @Binding var applications: [ManagerLoanApplication]
    @Environment(\.dismiss) var dismiss
    
    @State private var searchText: String = ""
    @State private var selectedFilter: ApplicationStatusFilter = .all
    
    enum ApplicationStatusFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case approved = "Approved"
        case rejected = "Rejected"
    }
    
    var filteredApplications: [ManagerLoanApplication] {
        var filtered = applications
        
        // Filter by status
        switch selectedFilter {
        case .all:
            break
        case .pending:
            filtered = filtered.filter { $0.status == "Sent to Manager" || $0.status == "Needs Clarification" }
        case .approved:
            filtered = filtered.filter { $0.status == "Approved" || $0.status == "Disbursed" }
        case .rejected:
            filtered = filtered.filter { $0.status == "Rejected" }
        }
        
        // Filter by search text
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filtered = filtered.filter { 
                $0.borrowerName.localizedCaseInsensitiveContains(searchText) ||
                $0.applicationId.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return filtered
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Filtering and Search Section
                VStack(spacing: 12) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(LMSColors.textSecondary)
                        
                        TextField("Search by Name or ID...", text: $searchText)
                            .font(.system(.body, design: .rounded))
                        
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(LMSColors.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(LMSColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    
                    // Status Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(ApplicationStatusFilter.allCases, id: \.self) { filter in
                                Button(action: {
                                    HapticsManager.triggerImpact(style: .light)
                                    withAnimation {
                                        selectedFilter = filter
                                    }
                                }) {
                                    Text(filter.rawValue)
                                        .font(.system(.subheadline, design: .rounded).bold())
                                        .foregroundStyle(selectedFilter == filter ? .white : .primary)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedFilter == filter ? Color.AppTheme.primary : LMSColors.surfaceElevated)
                                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(LMSColors.surface)
                
                Divider()
                
                // List of Applications
                ScrollView(.vertical, showsIndicators: false) {
                    if filteredApplications.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 44))
                                .foregroundStyle(LMSColors.textSecondary)
                            
                            Text("No Applications Found")
                                .font(.system(.headline, design: .rounded))
                            
                            Text("Try adjusting your search or filters.")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                        .padding(.top, 60)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredApplications) { app in
                                ManagerApplicationRowView(app: app)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 16)
                    }
                }
                .background(LMSColors.background)
            }
            .navigationTitle("All Applications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct ManagerApplicationRowView: View {
    let app: ManagerLoanApplication
    
    var statusColor: Color {
        switch app.status {
        case "Sent to Manager", "Needs Clarification": return Color(hex: "#FFB300")
        case "Approved", "Disbursed": return Color(hex: "#00C48C")
        case "Rejected": return Color(hex: "#FF4D4F")
        default: return Color(hex: "#1A73E8")
        }
    }
    
    var statusIcon: String {
        switch app.status {
        case "Sent to Manager", "Needs Clarification": return "clock.fill"
        case "Approved", "Disbursed": return "checkmark.seal.fill"
        case "Rejected": return "xmark.octagon.fill"
        default: return "doc.fill"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(statusColor.opacity(0.12))
                    .frame(width: 48, height: 48)
                
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(app.borrowerName)
                        .font(.system(.callout, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                    
                    Spacer()
                    
                    Text("₹ \(Int(app.requestedAmount / 100_000))L")
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                }
                
                HStack {
                    Text("\(app.applicationId)")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(LMSColors.textSecondary)
                    
                    Spacer()
                    
                    Text(app.loanType)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                }
                
                HStack {
                    Text(app.submissionDate)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                    
                    Spacer()
                    
                    Text(app.status)
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(statusColor.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
        }
        .padding(.all, 14)
        .background(LMSColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 2)
    }
}
