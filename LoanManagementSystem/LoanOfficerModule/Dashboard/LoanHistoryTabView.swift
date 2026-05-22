import SwiftUI
import UIKit

struct ScrollOffsetPreferenceKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: effect)
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
}

struct LoanHistoryTabView: View {
    typealias LoanApplication = OfficerLoanApplication
    typealias LoanType = OfficerLoanType
    typealias ApplicationStatus = OfficerApplicationStatus
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    
    @State private var selectedFilter: FilterOption = .all
    @State private var showingExportAlert = false
    @State private var activeDetailApp: LoanApplication? = nil
    @State private var alertMessage = ""
    @State private var scrollOffset: CGFloat = 0
    
    enum FilterOption: String, CaseIterable, Identifiable {
        case all = "All"
        case pending = "Pending"
        case underReview = "Under Review"
        case inReview = "In Review"
        case approved = "Approved"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Main content List
            List {
                // Hidden scroll position tracker
                Color.clear
                    .frame(height: 1)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: geo.frame(in: .named("listCoordinateSpace")).minY
                                )
                        }
                    )
                
                // Safe Area Spacer (height of sticky navigation bar)
                Spacer()
                    .frame(height: 96)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                
                // 1. Large Header (Registry & Subtitle)
                VStack(alignment: .leading, spacing: 6) {
                    Text("Registry")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text("Good Morning, Arjun 👋")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .padding(.bottom, 20)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .opacity(scrollOffset < -20 ? max(0, 1 + (scrollOffset + 20) / 30) : 1)
                
                // Sticky Section containing Search Bar and Filter System!
                Section(header: searchAndFilterHeader) {
                    // 2. Record count (Subtle, elegant)
                    HStack {
                        Text("Showing \(localFilteredApplications.count) of \(viewModel.totalApplications) loans")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    
                    // 3. Loan Record Rows or Empty State
                    if localFilteredApplications.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 44))
                                .foregroundColor(.secondary.opacity(0.6))
                                .padding(.top, 40)
                            
                            Text("No Loans Found")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                            
                            Text("Try adjusting your filters or search terms.")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(localFilteredApplications) { app in
                            LoanHistoryRow(
                                app: app,
                                onView: {
                                    activeDetailApp = app
                                },
                                onCall: {
                                    alertMessage = "Calling borrower \(app.borrowerName) at verified registration number..."
                                    showingExportAlert = true
                                },
                                onFlag: {
                                    alertMessage = "Flagged application \(app.applicationId) for compliance audit."
                                    showingExportAlert = true
                                }
                            )
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color(.systemBackground))
                            .listRowSeparator(.visible, edges: .bottom)
                            .listRowSeparatorTint(Color.primary.opacity(0.05))
                        }
                    }
                }
            }
            .listStyle(.plain)
            .background(Color(.systemBackground))
            .coordinateSpace(name: "listCoordinateSpace")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            .refreshable {
                await viewModel.fetchDashboardData()
            }
            
            // Translucent Floating Top Navigation Bar
            stickyNavigationBar
        }
        .sheet(item: $activeDetailApp) { app in
            LoanApplicationReviewDetailView(applicationId: app.applicationId, viewModel: viewModel)
        }
        .alert(isPresented: $showingExportAlert) {
            Alert(
                title: Text("System Alert"),
                message: Text(alertMessage.isEmpty ? "Export action triggered." : alertMessage),
                dismissButton: .default(Text("OK")) {
                    alertMessage = ""
                }
            )
        }
        // Coordinate sync with deep links from overview tab
        .onChange(of: viewModel.historyFilter) { _, newStatus in
            if let status = newStatus {
                switch status {
                case .pending, .applied, .documentsPending:
                    selectedFilter = .pending
                case .underReview:
                    selectedFilter = .underReview
                case .sentToManager, .finalApprovalPending, .verificationCompleted:
                    selectedFilter = .inReview
                case .approved, .disbursed:
                    selectedFilter = .approved
                default:
                    selectedFilter = .all
                }
            } else {
                selectedFilter = .all
            }
        }
    }
    
    // local applications filter mapping
    private var localFilteredApplications: [OfficerLoanApplication] {
        var list = viewModel.filteredApplications
        
        switch selectedFilter {
        case .all:
            break
        case .pending:
            list = list.filter { $0.status == .pending || $0.status == .applied || $0.status == .documentsPending }
        case .underReview:
            list = list.filter { $0.status == .underReview }
        case .inReview:
            list = list.filter { $0.status == .sentToManager || $0.status == .finalApprovalPending || $0.status == .verificationCompleted }
        case .approved:
            list = list.filter { $0.status == .approved || $0.status == .disbursed }
        }
        
        return list
    }
    
    // Translucent Floating Top Navigation Bar
    private var stickyNavigationBar: some View {
        let fadeProgress: CGFloat
        let threshold: CGFloat = 40
        if scrollOffset < 0 {
            fadeProgress = min(1, -scrollOffset / threshold)
        } else {
            fadeProgress = 0
        }
        
        return VStack(spacing: 0) {
            HStack {
                Spacer()
                
                // Collapsed dynamic title centered
                Text("Registry")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .opacity(fadeProgress)
                    .scaleEffect(0.9 + (fadeProgress * 0.1))
                
                Spacer()
            }
            .overlay(
                // Bell + Profile group aligned on the right
                HStack(spacing: 10) {
                    // Bell Button with notification badge and circular glass backdrop
                    Button(action: {
                        HapticsManager.triggerImpact(style: .light)
                        alertMessage = "Opening secure notifications feed console..."
                        showingExportAlert = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(.systemBackground).opacity(0.85))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
                                )
                            
                            Image(systemName: "bell.fill")
                                .font(.system(size: 15))
                                .foregroundColor(.primary)
                            
                            // Badge
                            Circle()
                                .fill(Color.red)
                                .frame(width: 7, height: 7)
                                .offset(x: 5, y: -5)
                        }
                    }
                    
                    // Profile Avatar Button with initials and subtle glass border
                    Button(action: {
                        HapticsManager.triggerImpact(style: .medium)
                        alertMessage = "Opening secure officer profile options..."
                        showingExportAlert = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    gradient: Gradient(colors: [Color.blue.opacity(0.55), Color.blue]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                                )
                            
                            Text("AK")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.trailing, 16),
                alignment: .trailing
            )
            .frame(height: 52)
            .padding(.top, 44) // Account for safe area
            .background(
                VisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
                    .opacity(fadeProgress > 0 ? 1 : 0)
                    .edgesIgnoringSafeArea(.top)
            )
            
            Divider()
                .opacity(fadeProgress)
        }
    }
    
    // Header containing search and filter chips that natively sticks to the top of list
    private var searchAndFilterHeader: some View {
        VStack(spacing: 16) {
            // 1. Full-Width Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary.opacity(0.8))
                    .font(.system(size: 16, weight: .semibold))
                
                TextField("Search loans, customers, application ID", text: $viewModel.historySearchQuery)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundColor(.primary)
                    .autocorrectionDisabled()
                
                if !viewModel.historySearchQuery.isEmpty {
                    Button(action: {
                        viewModel.historySearchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 15))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.systemBackground).opacity(0.65))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
            )
            .padding(.horizontal, 16)
            
            // 2. Horizontally Scrollable Filter Cards Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(FilterOption.allCases, id: \.self) { option in
                        FilterChip(
                            title: option.rawValue,
                            isSelected: selectedFilter == option
                        ) {
                            HapticsManager.triggerImpact(style: .light)
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                selectedFilter = option
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
        .padding(.vertical, 12)
        .background(
            VisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
                .edgesIgnoringSafeArea(.horizontal)
        )
        .overlay(
            VStack {
                Spacer()
                Divider()
            }
        )
    }
}

// Gorgeous Custom Pill Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(isSelected ? Color.blue : Color(.systemGray6))
                )
                .foregroundColor(isSelected ? .white : .secondary)
                .scaleEffect(isSelected ? 1.02 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
