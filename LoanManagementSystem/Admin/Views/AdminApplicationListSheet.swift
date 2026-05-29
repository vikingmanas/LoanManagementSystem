import SwiftUI


struct AdminApplicationListSheet: View {
    let kpiType: KPIType
    let applications: [DBLoanApplication]
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedApplication: DBLoanApplication? = nil
    
    private var filteredApplications: [DBLoanApplication] {
        let baseList: [DBLoanApplication]
        switch kpiType {
        case .totalApplications:
            baseList = applications
        case .activeLoans:
            baseList = applications.filter { $0.status == "disbursed" || $0.status == "approved" }
        case .pendingApprovals:
            let pendingStatuses = ["submitted", "under_review", "document_verification", "officer_review", "manager_review"]
            baseList = applications.filter { pendingStatuses.contains($0.status.lowercased()) }
        case .totalDisbursed:
            baseList = applications.filter { $0.status == "disbursed" || $0.status == "approved" }
        }
        
        if searchText.isEmpty {
            return baseList
        } else {
            return baseList.filter { app in
                app.formData.fullName.localizedCaseInsensitiveContains(searchText) ||
                "APP-\(app.applicationId.uuidString.prefix(6))".localizedCaseInsensitiveContains(searchText) ||
                app.purpose.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText, placeholder: "Search by name or Application ID...")
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                    .padding(.top, LMSSpacing.md)
                    .padding(.bottom, LMSSpacing.sm)
                
                if filteredApplications.isEmpty {
                    Spacer()
                    VStack(spacing: LMSSpacing.md) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 48))
                            .foregroundStyle(LMSColors.textTertiary)
                        Text("No applications found")
                            .font(LMSFont.headline)
                            .foregroundStyle(LMSColors.textPrimary)
                        Text(searchText.isEmpty ? "No records match this KPI category." : "Check spelling or search for another borrower.")
                            .font(LMSFont.subheadline)
                            .foregroundStyle(LMSColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    Spacer()
                } else {
                    List {
                        ForEach(filteredApplications, id: \.applicationId) { app in
                            Button {
                                selectedApplication = app
                            } label: {
                                ApplicationRowView(app: app)
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .padding(.horizontal, LMSSpacing.screenHorizontal)
                            .padding(.vertical, LMSSpacing.xs)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .lmsScreenBackground()
            .navigationTitle(kpiType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(LMSFont.button)
                    .foregroundStyle(LMSColors.brandNavy)
                }
            }
            .sheet(item: $selectedApplication) { app in
                AdminApplicationDetailSheet(app: app)
            }
        }
    }
}

private struct ApplicationRowView: View {
    let app: DBLoanApplication
    
    var initials: String {
        let name = app.formData.fullName
        let parts = name.components(separatedBy: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }
    
    var body: some View {
        HStack(spacing: LMSSpacing.md) {
            Text(initials)
                .font(LMSFont.headline)
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(LMSColors.brandNavy, in: Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(app.formData.fullName)
                        .font(LMSFont.callout)
                        .fontWeight(.semibold)
                        .foregroundStyle(LMSColors.textPrimary)
                    Spacer()
                    Text(formatCurrency(app.amountRequested))
                        .font(LMSFont.callout)
                        .fontWeight(.bold)
                        .foregroundStyle(LMSColors.textPrimary)
                }
                
                HStack {
                    Text("APP-\(app.applicationId.uuidString.prefix(6).uppercased())")
                        .font(LMSFont.caption.monospacedDigit())
                        .foregroundStyle(LMSColors.textSecondary)
                    Text("•")
                        .foregroundStyle(LMSColors.textTertiary)
                    Text(app.purpose.capitalized)
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textSecondary)
                        .lineLimit(1)
                    Spacer()
                    LMSStatusPill(
                        text: displayStatus(app.status),
                        style: statusStyle(app.status),
                        icon: statusIcon(app.status)
                    )
                }
            }
        }
        .padding(LMSSpacing.md)
        .lmsInsetGroupedCard()
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_IN")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "₹\(Int(value))"
    }
}

// MARK: - Search Bar Component
struct SearchBar: View {
    @Binding var text: String
    var placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(LMSColors.textTertiary)
            TextField(placeholder, text: $text)
                .font(LMSFont.body)
                .foregroundStyle(LMSColors.textPrimary)
            if !text.isEmpty {
                Button(action: { text = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(LMSColors.textTertiary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(LMSColors.surface)
        .cornerRadius(LMSRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.md)
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
        )
    }
}

// MARK: - Status Pill Mappers
func displayStatus(_ status: String) -> String {
    switch status.lowercased() {
    case "draft": return "Draft"
    case "submitted": return "Submitted"
    case "under_review", "under review": return "Under Review"
    case "document_verification", "document verification": return "Docs Verification"
    case "officer_review", "officer review", "loan_officer_review": return "Officer Review"
    case "manager_review", "manager review", "bank_manager_review": return "Manager Review"
    case "approved": return "Approved"
    case "rejected": return "Rejected"
    case "disbursed": return "Disbursed"
    default: return status.capitalized
    }
}

func statusStyle(_ status: String) -> LMSStatusPill.Style {
    switch status.lowercased() {
    case "approved", "disbursed": return .success
    case "rejected": return .error
    case "draft": return .neutral
    default: return .warning
    }
}

func statusIcon(_ status: String) -> String {
    switch status.lowercased() {
    case "approved", "disbursed": return "checkmark.circle.fill"
    case "rejected": return "xmark.circle.fill"
    case "draft": return "square.and.pencil"
    default: return "clock.fill"
    }
}

// Make DBLoanApplication Identifiable for sheet bindings
extension DBLoanApplication: Identifiable {
    public var id: UUID { applicationId }
}

enum KPIType: String, Identifiable, CaseIterable {
    case totalApplications = "Total Applications"
    case activeLoans = "Active Loans"
    case pendingApprovals = "Pending Approvals"
    case totalDisbursed = "Total Disbursed"
    
    var id: String { rawValue }
}
