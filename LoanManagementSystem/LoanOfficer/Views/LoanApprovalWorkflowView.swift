import SwiftUI

// MARK: - Toast Model
struct ToastState: Identifiable {
    let id = UUID()
    let message: String
    let style: ToastStyle
}

enum ToastStyle {
    case success
    case error
    case info
}

struct LoanApprovalWorkflowView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    
    @State private var searchQuery: String = ""
    @State private var selectedStatusFilter: StatusFilter = .all
    @State private var selectedSortOption: SortOption = .newest
    @State private var isAnimating = false
    
    // Bottom Sheet States
    @State private var selectedAppForApproval: OfficerLoanApplication? = nil
    @State private var selectedAppForRejection: OfficerLoanApplication? = nil
    @State private var selectedAppForVerification: OfficerLoanApplication? = nil
    
    // Toast notification state
    @State private var toast: ToastState? = nil
    
    enum StatusFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case pending = "Pending"
        case approved = "Approved"
        case rejected = "Rejected"
        case verRequired = "Verification Required"
        
        var id: String { self.rawValue }
    }
    
    enum SortOption: String, CaseIterable, Identifiable {
        case newest = "Newest First"
        case oldest = "Oldest First"
        case amountDesc = "Amount: High to Low"
        case amountAsc = "Amount: Low to High"
        case creditScoreDesc = "Credit Score: High to Low"
        
        var id: String { self.rawValue }
    }
    
    var body: some View {
        ZStack {
            LMSColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Search, Sort & Filter Header
                headerView
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: LMSSpacing.xl) {
                        // 1. Analytics Summary Row (Horizontal Carousel/Row)
                        analyticsSummaryRow
                            .padding(.top, LMSSpacing.md)
                        
                        // Queue Title
                        HStack {
                            Text("Active Review Queue")
                                .font(LMSFont.title3)
                                .foregroundStyle(LMSColors.textPrimary)
                            Spacer()
                            Text("\(filteredAndSortedApplications.count) applications")
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                        .padding(.horizontal, LMSSpacing.screenHorizontal)
                        
                        // 2. Active Review Cards
                        if filteredAndSortedApplications.isEmpty {
                            emptyStateView
                                .padding(.top, 40)
                        } else {
                            LazyVStack(spacing: LMSSpacing.lg) {
                                ForEach(Array(filteredAndSortedApplications.enumerated()), id: \.element.id) { index, app in
                                    LoanApplicationCard(
                                        application: app,
                                        onApprove: {
                                            HapticsManager.triggerImpact(style: .medium)
                                            selectedAppForApproval = app
                                        },
                                        onReject: {
                                            HapticsManager.triggerImpact(style: .medium)
                                            selectedAppForRejection = app
                                        },
                                        onVerify: {
                                            HapticsManager.triggerImpact(style: .medium)
                                            selectedAppForVerification = app
                                        }
                                    )
                                    .offset(y: isAnimating ? 0 : 50)
                                    .opacity(isAnimating ? 1 : 0)
                                    .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(Double(index) * 0.08), value: isAnimating)
                                }
                            }
                            .padding(.horizontal, LMSSpacing.screenHorizontal)
                        }
                    }
                    .padding(.bottom, LMSSpacing.xxxl)
                }
            }
            
            // Toast Notification Overlay
            if let toastState = toast {
                VStack {
                    toastOverlay(state: toastState)
                        .padding(.top, 10)
                    Spacer()
                }
                .zIndex(99)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .navigationTitle("Loan Review")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            isAnimating = true
        }
        .sheet(item: $selectedAppForApproval) { app in
            ApprovalBottomSheet(
                application: app,
                viewModel: viewModel,
                onSuccess: { message in
                    showToast(message: message, style: .success)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedAppForRejection) { app in
            RejectionSheetView(
                application: app,
                viewModel: viewModel,
                onSuccess: { message in
                    showToast(message: message, style: .error)
                }
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .sheet(item: $selectedAppForVerification) { app in
            VerificationDetailSheet(
                application: app,
                viewModel: viewModel,
                onSuccess: { message in
                    showToast(message: message, style: .info)
                }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: LMSSpacing.md) {
            // Search Bar & Sort Dropdown
            HStack(spacing: LMSSpacing.md) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(LMSColors.textSecondary)
                    TextField("Search borrower, loan ID or type...", text: $searchQuery)
                        .font(LMSFont.body)
                        .foregroundStyle(LMSColors.textPrimary)
                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(LMSColors.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, LMSSpacing.md)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: LMSRadius.md)
                        .fill(LMSColors.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: LMSRadius.md)
                        .stroke(LMSColors.separatorLight, lineWidth: 0.5)
                )
                
                // Sort Menu
                Menu {
                    Picker("Sort By", selection: $selectedSortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .font(.body)
                        Text("Sort")
                            .font(LMSFont.caption.weight(.semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(LMSColors.surface)
                    .foregroundStyle(LMSColors.textSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: LMSRadius.md)
                            .stroke(LMSColors.separatorLight, lineWidth: 0.5)
                    )
                }
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)
            
            // Custom horizontal list for filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LMSSpacing.sm) {
                    ForEach(StatusFilter.allCases) { filter in
                        Button(action: {
                            HapticsManager.triggerImpact(style: .light)
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedStatusFilter = filter
                            }
                        }) {
                            Text(filter.rawValue)
                                .font(LMSFont.caption.weight(.semibold))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(selectedStatusFilter == filter ? LMSColors.brandNavy : LMSColors.surface)
                                )
                                .foregroundStyle(selectedStatusFilter == filter ? .white : LMSColors.textSecondary)
                                .overlay(
                                    Capsule()
                                        .stroke(selectedStatusFilter == filter ? Color.clear : LMSColors.separatorLight, lineWidth: 0.5)
                                )
                        }
                    }
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)
            }
        }
        .padding(.vertical, LMSSpacing.sm)
        .background(LMSColors.surfaceElevated)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 3)
    }
    
    private var filteredAndSortedApplications: [OfficerLoanApplication] {
        var list = viewModel.applications.filter { app in
            // Search filter
            let matchesSearch = searchQuery.isEmpty ||
                app.borrowerName.localizedCaseInsensitiveContains(searchQuery) ||
                app.applicationId.localizedCaseInsensitiveContains(searchQuery) ||
                app.loanType.rawValue.localizedCaseInsensitiveContains(searchQuery)
            
            // Status filter mapping
            let matchesStatus: Bool
            switch selectedStatusFilter {
            case .all:
                matchesStatus = true
            case .pending:
                matchesStatus = app.status == .pending || app.status == .underReview || app.status == .applied
            case .approved:
                matchesStatus = app.status == .approved || app.status == .disbursed || app.status == .verificationCompleted
            case .rejected:
                matchesStatus = app.status == .rejected || app.status == .documentsRejected
            case .verRequired:
                matchesStatus = app.status == .documentsPending || app.status == .finalApprovalPending || app.status == .sentToManager
            }
            
            return matchesSearch && matchesStatus
        }
        
        // Sorting logic
        switch selectedSortOption {
        case .newest:
            list.sort { $0.submittedDate > $1.submittedDate }
        case .oldest:
            list.sort { $0.submittedDate < $1.submittedDate }
        case .amountDesc:
            list.sort { $0.requestedAmount > $1.requestedAmount }
        case .amountAsc:
            list.sort { $0.requestedAmount < $1.requestedAmount }
        case .creditScoreDesc:
            list.sort { ($0.cibilScore ?? 0) > ($1.cibilScore ?? 0) }
        }
        
        return list
    }
    
    private var analyticsSummaryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LMSSpacing.md) {
                // Pending Count Card
                let pendingCount = viewModel.applications.filter { $0.status == .pending || $0.status == .underReview || $0.status == .applied }.count
                let totalCount = max(viewModel.applications.count, 1)
                AnalyticsCardView(
                    title: "Pending Reviews",
                    value: "\(pendingCount)",
                    trend: "+4 new today",
                    icon: "clock.fill",
                    tint: LMSColors.amber,
                    progress: Double(pendingCount) / Double(totalCount)
                )
                
                // Approved Count Card
                let approvedCount = viewModel.applications.filter { $0.status == .approved || $0.status == .disbursed || $0.status == .verificationCompleted }.count
                AnalyticsCardView(
                    title: "Approved",
                    value: "\(approvedCount)",
                    trend: "98% payout rate",
                    icon: "checkmark.shield.fill",
                    tint: LMSColors.emerald,
                    progress: Double(approvedCount) / Double(totalCount)
                )
                
                // Rejected Count Card
                let rejectedCount = viewModel.applications.filter { $0.status == .rejected || $0.status == .documentsRejected }.count
                AnalyticsCardView(
                    title: "Rejected",
                    value: "\(rejectedCount)",
                    trend: "-2% decline rate",
                    icon: "xmark.shield.fill",
                    tint: LMSColors.coral,
                    progress: Double(rejectedCount) / Double(totalCount)
                )
                
                // Verification Requests
                let pendingDocsCount = viewModel.applications.filter { $0.status == .documentsPending || $0.status == .sentToManager }.count
                AnalyticsCardView(
                    title: "Verification Req.",
                    value: "\(pendingDocsCount)",
                    trend: "Awaiting KYC",
                    icon: "doc.text.magnifyingglass",
                    tint: LMSColors.actionBlue,
                    progress: Double(pendingDocsCount) / Double(totalCount)
                )
                
                // Total Loan Amount
                let totalSanctioned = viewModel.applications.reduce(0.0) { $0 + $1.requestedAmount }
                AnalyticsCardView(
                    title: "Total Portfolio Size",
                    value: CurrencyFormatter.shared.format(totalSanctioned),
                    trend: "Total under reviews",
                    icon: "indianrupeesign.circle.fill",
                    tint: Color.purple,
                    progress: 1.0
                )
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: LMSSpacing.md) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 48))
                .foregroundStyle(LMSColors.emerald)
            
            Text("Clear Review Queue")
                .font(LMSFont.title3)
            
            Text("No applications are matching the selected filter criteria right now.")
                .font(LMSFont.caption)
                .foregroundStyle(LMSColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: LMSRadius.lg)
                .fill(LMSColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.lg)
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
        )
        .padding(.horizontal, LMSSpacing.screenHorizontal)
    }
    
    private func showToast(message: String, style: ToastStyle) {
        HapticsManager.triggerNotification(type: style == .success ? .success : .error)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            toast = ToastState(message: message, style: style)
        }
        
        // Auto-dismiss toast
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                if toast?.message == message {
                    toast = nil
                }
            }
        }
    }
    
    private func toastOverlay(state: ToastState) -> some View {
        HStack(spacing: 12) {
            Image(systemName: state.style == .success ? "checkmark.circle.fill" : (state.style == .error ? "exclamationmark.circle.fill" : "info.circle.fill"))
                .font(.title3)
                .foregroundStyle(state.style == .success ? LMSColors.emerald : (state.style == .error ? LMSColors.coral : LMSColors.actionBlue))
            
            Text(state.message)
                .font(LMSFont.body.weight(.bold))
                .foregroundStyle(LMSColors.textPrimary)
            
            Spacer()
        }
        .padding()
        .background(
            Capsule()
                .fill(LMSColors.surface)
                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
        )
        .overlay(
            Capsule()
                .stroke(state.style == .success ? LMSColors.emerald.opacity(0.4) : (state.style == .error ? LMSColors.coral.opacity(0.4) : LMSColors.actionBlue.opacity(0.4)), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

// MARK: - Reusable UI Components

struct AnalyticsCardView: View {
    let title: String
    let value: String
    let trend: String
    let icon: String
    let tint: Color
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(tint.gradient, in: Circle())
                    .shadow(color: tint.opacity(0.3), radius: 6)
                
                Spacer()
                
                // Progress Circle
                ZStack {
                    Circle()
                        .stroke(tint.opacity(0.12), lineWidth: 3.5)
                        .frame(width: 28, height: 28)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(progress))
                        .stroke(tint, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                        .frame(width: 28, height: 28)
                        .rotationEffect(.degrees(-90))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title3.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(LMSColors.textPrimary)
                
                Text(title)
                    .font(LMSFont.caption.weight(.semibold))
                    .foregroundStyle(LMSColors.textPrimary.opacity(0.8))
                
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 8, weight: .bold))
                    Text(trend)
                        .font(LMSFont.caption2.weight(.bold))
                }
                .foregroundStyle(tint)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(tint.opacity(0.08), in: Capsule())
            }
        }
        .padding(LMSSpacing.md)
        .frame(width: 155, height: 142, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: LMSRadius.lg)
                .fill(LMSColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.lg)
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.02), radius: 6, x: 0, y: 3)
    }
}

struct LoanApplicationStatusBadge: View {
    let status: OfficerApplicationStatus
    
    var body: some View {
        let text: String
        let color: Color
        
        switch status {
        case .pending, .applied:
            text = "Pending"
            color = LMSColors.amber
        case .underReview:
            text = "Under Review"
            color = LMSColors.actionBlue
        case .approved:
            text = "Approved"
            color = LMSColors.emerald
        case .rejected:
            text = "Rejected"
            color = LMSColors.coral
        case .disbursed:
            text = "Disbursed"
            color = LMSColors.teal
        case .onHold, .documentsPending:
            text = "Verification Req."
            color = LMSColors.actionBlue
        case .documentsRejected:
            text = "Docs Rejected"
            color = LMSColors.coral
        case .verificationCompleted:
            text = "KYC Verified"
            color = LMSColors.emerald
        case .sentToManager, .finalApprovalPending:
            text = "Final Review"
            color = LMSColors.brandNavy
        }
        
        return Text(text)
            .font(LMSFont.caption2.weight(.bold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(color.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .stroke(color.opacity(0.2), lineWidth: 0.5)
            )
            .shadow(color: color.opacity(0.2), radius: 3)
    }
}

struct RiskIndicatorView: View {
    let cibilScore: Int
    
    private var scoreColor: Color {
        if cibilScore >= 750 { return LMSColors.emerald }
        else if cibilScore >= 650 { return LMSColors.amber }
        else { return LMSColors.coral }
    }
    
    private var riskText: String {
        if cibilScore >= 750 { return "Low Risk" }
        else if cibilScore >= 650 { return "Medium Risk" }
        else { return "High Risk" }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text("CIBIL Score:")
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textSecondary)
                    Text("\(cibilScore)")
                        .font(LMSFont.caption.weight(.bold))
                        .foregroundStyle(scoreColor)
                }
                
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(LMSColors.textTertiary.opacity(0.2))
                        .frame(height: 5)
                    
                    let pct = CGFloat(max(cibilScore - 300, 0)) / 600.0
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                LinearGradient(colors: [scoreColor.opacity(0.6), scoreColor], startPoint: .leading, endPoint: .trailing)
                            )
                            .frame(width: geo.size.width * min(max(pct, 0.05), 1.0), height: 5)
                    }
                    .frame(height: 5)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Risk pill capsule
            HStack(spacing: 4) {
                Circle()
                    .fill(scoreColor)
                    .frame(width: 6, height: 6)
                Text(riskText)
                    .font(LMSFont.caption.weight(.bold))
                    .foregroundStyle(scoreColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(scoreColor.opacity(0.08), in: Capsule())
            .overlay(
                Capsule()
                    .stroke(scoreColor.opacity(0.18), lineWidth: 0.5)
            )
        }
    }
}

struct LoanSummaryRow: View {
    let label: String
    let value: String
    let iconName: String
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: iconName)
                    .font(.body)
                    .foregroundStyle(LMSColors.textSecondary)
                    .frame(width: 24, height: 24)
                
                Text(label)
                    .font(LMSFont.body)
                    .foregroundStyle(LMSColors.textSecondary)
                
                Spacer()
                
                Text(value)
                    .font(LMSFont.body.weight(.bold))
                    .foregroundStyle(LMSColors.textPrimary)
            }
            .padding(.vertical, 14)
            
            Divider()
                .foregroundStyle(LMSColors.separatorLight)
        }
    }
}

struct LoanApplicationCard: View {
    let application: OfficerLoanApplication
    var onApprove: () -> Void
    var onReject: () -> Void
    var onVerify: () -> Void
    
    @State private var isPressed = false
    
    private var cibilScoreValue: Int {
        application.cibilScore ?? 750
    }
    
    private var sparklinePoints: [Double] {
        let seed = Double(cibilScoreValue % 50)
        return [60.0 + seed, 65.0 - seed, 70.0 + seed, 68.0, 75.0 + seed, 82.0 + seed/2, 85.0 + seed]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            // Top Section: Avatar, ID, Status
            HStack(spacing: 12) {
                OfficerAvatar(name: application.borrowerName, tint: application.loanType.themeColor)
                    .shadow(color: application.loanType.themeColor.opacity(0.2), radius: 6)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(application.borrowerName)
                        .font(LMSFont.headline.weight(.semibold))
                        .foregroundStyle(LMSColors.textPrimary)
                    
                    HStack(spacing: 6) {
                        Text(application.loanType.rawValue)
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.textSecondary)
                        
                        Circle()
                            .fill(LMSColors.textTertiary)
                            .frame(width: 3, height: 3)
                        
                        Text(application.applicationId)
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.textTertiary)
                    }
                }
                
                Spacer()
                
                LoanApplicationStatusBadge(status: application.status)
            }
            
            Divider()
                .foregroundStyle(LMSColors.separatorLight)
            
            // Financial & Sparkline Section
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Requested Amount")
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textSecondary)
                    Text(CurrencyFormatter.shared.format(application.requestedAmount))
                        .font(LMSFont.title.weight(.bold))
                        .foregroundStyle(LMSColors.brandNavy)
                }
                
                Spacer()
                
                // History Sparkline view
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Credit History")
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textSecondary)
                    OfficerSparklineView(points: sparklinePoints, color: cibilScoreValue >= 750 ? LMSColors.emerald : (cibilScoreValue >= 650 ? LMSColors.amber : LMSColors.coral))
                        .frame(width: 90, height: 30)
                }
            }
            
            // Risk & Credit Segment
            RiskIndicatorView(cibilScore: cibilScoreValue)
                .padding(.top, 4)
            
            // Bottom Action buttons
            if application.status == .pending || application.status == .underReview || application.status == .documentsPending || application.status == .applied {
                HStack(spacing: LMSSpacing.md) {
                    // Reject
                    Button(action: onReject) {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text("Reject")
                        }
                        .font(LMSFont.caption.weight(.semibold))
                        .foregroundStyle(LMSColors.coral)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: LMSRadius.sm)
                                .fill(LMSColors.coral.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: LMSRadius.sm)
                                .stroke(LMSColors.coral.opacity(0.2), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Verify Docs
                    Button(action: onVerify) {
                        HStack {
                            Image(systemName: "doc.text.magnifyingglass")
                            Text("Verify Docs")
                        }
                        .font(LMSFont.caption.weight(.semibold))
                        .foregroundStyle(LMSColors.actionBlue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: LMSRadius.sm)
                                .fill(LMSColors.actionBlue.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: LMSRadius.sm)
                                .stroke(LMSColors.actionBlue.opacity(0.2), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Approve
                    Button(action: onApprove) {
                        HStack {
                            Image(systemName: "checkmark.shield")
                            Text("Approve")
                        }
                        .font(LMSFont.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: LMSRadius.sm)
                                .fill(
                                    LinearGradient(colors: [LMSColors.emerald, LMSColors.emeraldDark], startPoint: .top, endPoint: .bottom)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 6)
            } else {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(LMSColors.textSecondary)
                    Text("No actions available for this application state.")
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textSecondary)
                    Spacer()
                }
                .padding(.top, 6)
            }
        }
        .padding(LMSSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: LMSRadius.lg)
                .fill(LMSColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.lg)
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

struct OfficerSparklineView: View {
    var points: [Double]
    var color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard points.count > 1 else { return }
                let width = geometry.size.width
                let height = geometry.size.height
                let minVal = points.min() ?? 0
                let maxVal = points.max() ?? 1
                let range = maxVal - minVal == 0 ? 1 : maxVal - minVal
                
                let stepX = width / CGFloat(points.count - 1)
                
                let startY = height - CGFloat((points[0] - minVal) / range) * height
                path.move(to: CGPoint(x: 0, y: startY))
                
                for i in 1..<points.count {
                    let x = CGFloat(i) * stepX
                    let y = height - CGFloat((points[i] - minVal) / range) * height
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(
                LinearGradient(colors: [color, color.opacity(0.5)], startPoint: .leading, endPoint: .trailing),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
            .background(
                Path { path in
                    guard points.count > 1 else { return }
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let minVal = points.min() ?? 0
                    let maxVal = points.max() ?? 1
                    let range = maxVal - minVal == 0 ? 1 : maxVal - minVal
                    let stepX = width / CGFloat(points.count - 1)
                    
                    path.move(to: CGPoint(x: 0, y: height))
                    let startY = height - CGFloat((points[0] - minVal) / range) * height
                    path.addLine(to: CGPoint(x: 0, y: startY))
                    
                    for i in 1..<points.count {
                        let x = CGFloat(i) * stepX
                        let y = height - CGFloat((points[i] - minVal) / range) * height
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [color.opacity(0.15), color.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            )
        }
    }
}

// MARK: - Bottom Sheets

struct ApprovalBottomSheet: View {
    let application: OfficerLoanApplication
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onSuccess: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedInterestRate: Double = 10.5
    @State private var selectedTenure: Int = 36
    @State private var internalRemarks: String = ""
    @State private var hasAcceptedTerms: Bool = false
    @State private var isApproved = false
    
    private var monthlyEMI: Double {
        let principal = application.requestedAmount
        let annualRate = selectedInterestRate
        let months = Double(selectedTenure)
        
        let monthlyRate = annualRate / 12 / 100
        if monthlyRate == 0 { return principal / months }
        let emi = (principal * monthlyRate * pow(1 + monthlyRate, months)) / (pow(1 + monthlyRate, months) - 1)
        return emi
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LMSSpacing.xl) {
                    if isApproved {
                        // Success Confirmation Visual
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LMSColors.emerald.opacity(0.1))
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(LMSColors.emerald)
                            }
                            .scaleEffect(isApproved ? 1.0 : 0.5)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: isApproved)
                            
                            Text("Sanction Authorized!")
                                .font(.title3.weight(.bold))
                                .fontDesign(.rounded)
                            
                            Text("The disbursement event has been registered, and OD Account \(application.applicationId) is provisioned successfully.")
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                            
                            Button(action: {
                                onSuccess("Application Sanctioned: \(application.borrowerName)")
                                dismiss()
                            }) {
                                Text("Done")
                                    .font(LMSFont.button)
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: LMSRadius.md)
                                            .fill(LMSColors.brandNavy)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 30)
                    } else {
                        HStack(spacing: 12) {
                            OfficerAvatar(name: application.borrowerName, tint: application.loanType.themeColor)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(application.borrowerName)
                                    .font(LMSFont.headline)
                                Text("Application ID: \(application.applicationId)")
                                    .font(LMSFont.caption)
                                    .foregroundStyle(LMSColors.textSecondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.md))
                        .overlay(RoundedRectangle(cornerRadius: LMSRadius.md).stroke(LMSColors.separatorLight, lineWidth: 0.5))
                        
                        VStack(alignment: .leading, spacing: LMSSpacing.md) {
                            Text("SANCTION CONFIGURATION")
                                .font(LMSFont.caption.weight(.bold))
                                .foregroundStyle(LMSColors.textSecondary)
                            
                            LoanSummaryRow(label: "Requested Amount", value: CurrencyFormatter.shared.format(application.requestedAmount), iconName: "indianrupeesign.circle")
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Annual Interest Rate")
                                        .font(LMSFont.subheadline)
                                        .foregroundStyle(LMSColors.textSecondary)
                                    Spacer()
                                    Text(String(format: "%.2f %%", selectedInterestRate))
                                        .font(LMSFont.body.weight(.bold))
                                        .foregroundStyle(LMSColors.brandNavy)
                                }
                                
                                Slider(value: $selectedInterestRate, in: 8.5...15.0, step: 0.1)
                                    .tint(LMSColors.brandNavy)
                            }
                            .padding(.vertical, 4)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Repayment Tenure")
                                        .font(LMSFont.subheadline)
                                        .foregroundStyle(LMSColors.textSecondary)
                                    Spacer()
                                    Text("\(selectedTenure) Months")
                                        .font(LMSFont.body.weight(.bold))
                                        .foregroundStyle(LMSColors.brandNavy)
                                }
                                
                                Picker("Tenure", selection: $selectedTenure) {
                                    Text("12M").tag(12)
                                    Text("24M").tag(24)
                                    Text("36M").tag(36)
                                    Text("48M").tag(48)
                                    Text("60M").tag(60)
                                    Text("84M").tag(84)
                                }
                                .pickerStyle(.segmented)
                            }
                            .padding(.vertical, 4)
                        }
                        
                        VStack(spacing: 8) {
                            Text("ESTIMATED MONTHLY INSTALLMENT (EMI)")
                                .font(LMSFont.caption.weight(.bold))
                                .foregroundStyle(.white.opacity(0.8))
                            
                            Text(CurrencyFormatter.shared.format(monthlyEMI))
                                .font(Font.system(.title, design: .rounded).weight(.black))
                                .foregroundStyle(.white)
                            
                            Text("Calculated on monthly compounding reducing balance")
                                .font(LMSFont.caption)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(LMSSpacing.lg)
                        .background(
                            RoundedRectangle(cornerRadius: LMSRadius.lg)
                                .fill(
                                    LinearGradient(colors: [LMSColors.brandNavy, LMSColors.brandNavyLight], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                        )
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("OFFICER REMARKS (OPTIONAL)")
                                .font(LMSFont.caption.weight(.bold))
                                .foregroundStyle(LMSColors.textSecondary)
                            
                            TextField("Enter internal sanction notes or conditions...", text: $internalRemarks, axis: .vertical)
                                .lineLimit(3...5)
                                .padding()
                                .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.sm))
                                .overlay(RoundedRectangle(cornerRadius: LMSRadius.sm).stroke(LMSColors.separator, lineWidth: 0.5))
                        }
                        
                        Toggle(isOn: $hasAcceptedTerms) {
                            Text("I verify that all credit assessments are compliant with regulatory lending rules & internal bank guidelines.")
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: LMSColors.emerald))
                        
                        Button(action: {
                            HapticsManager.triggerNotification(type: .success)
                            viewModel.approveApplication(id: application.id, remarks: internalRemarks.isEmpty ? "Lending terms approved. Sanctioned." : internalRemarks)
                            withAnimation(.spring()) {
                                isApproved = true
                            }
                        }) {
                            Text("Confirm Loan Sanction")
                                .font(LMSFont.button)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: LMSRadius.md)
                                        .fill(hasAcceptedTerms ? LinearGradient(colors: [LMSColors.emerald, LMSColors.emeraldDark], startPoint: .top, endPoint: .bottom) : LinearGradient(colors: [Color.gray.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                                )
                        }
                        .disabled(!hasAcceptedTerms)
                        .buttonStyle(.plain)
                        .padding(.bottom, LMSSpacing.xl)
                    }
                }
                .padding()
            }
            .navigationTitle("Approve Application")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct RejectionSheetView: View {
    let application: OfficerLoanApplication
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onSuccess: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedReasons: Set<String> = []
    @State private var internalRemarks: String = ""
    
    let reasonsOptions = [
        "Low Credit Score (CIBIL)",
        "Insufficient Repayment Capacity",
        "Document Discrepancies",
        "Unstable Employment History",
        "High Existing Debt Burden",
        "Fraud Scan Alert Triggered",
        "Collateral Valuation Mismatch"
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LMSSpacing.xl) {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.title2)
                            .foregroundStyle(LMSColors.coral)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rejecting Loan Application")
                                .font(LMSFont.headline)
                            Text("This action is final and will notify \(application.borrowerName) with the reason details.")
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                    }
                    .padding()
                    .background(LMSColors.coral.opacity(0.08), in: RoundedRectangle(cornerRadius: LMSRadius.md))
                    .overlay(RoundedRectangle(cornerRadius: LMSRadius.md).stroke(LMSColors.coral.opacity(0.2), lineWidth: 0.5))
                    
                    VStack(alignment: .leading, spacing: LMSSpacing.md) {
                        Text("SELECT REJECTION REASONS")
                            .font(LMSFont.caption.weight(.bold))
                            .foregroundStyle(LMSColors.textSecondary)
                        
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
                            ForEach(reasonsOptions, id: \.self) { reason in
                                let isSelected = selectedReasons.contains(reason)
                                Button(action: {
                                    HapticsManager.triggerImpact(style: .light)
                                    if isSelected {
                                        selectedReasons.remove(reason)
                                    } else {
                                        selectedReasons.insert(reason)
                                    }
                                }) {
                                    Text(reason)
                                        .font(LMSFont.caption.weight(.semibold))
                                        .padding(.vertical, 10)
                                        .padding(.horizontal, 6)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: LMSRadius.sm)
                                                .fill(isSelected ? LMSColors.coral : LMSColors.surface)
                                        )
                                        .foregroundStyle(isSelected ? .white : LMSColors.textSecondary)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: LMSRadius.sm)
                                                .stroke(isSelected ? Color.clear : LMSColors.separatorLight, lineWidth: 0.5)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("INTERNAL DECISION NOTES (REQUIRED)")
                            .font(LMSFont.caption.weight(.bold))
                            .foregroundStyle(LMSColors.textSecondary)
                        
                        TextField("Provide a detailed reason explanation for this rejection decision...", text: $internalRemarks, axis: .vertical)
                            .lineLimit(4...6)
                            .padding()
                            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.sm))
                            .overlay(RoundedRectangle(cornerRadius: LMSRadius.sm).stroke(LMSColors.separator, lineWidth: 0.5))
                    }
                    
                    Button(action: {
                        HapticsManager.triggerNotification(type: .error)
                        let reasonsString = selectedReasons.joined(separator: ", ")
                        let finalRemarks = "Rejected due to: [\(reasonsString)]. Remarks: \(internalRemarks)"
                        viewModel.rejectApplication(id: application.id, remarks: finalRemarks)
                        onSuccess("Application Rejected: \(application.borrowerName)")
                        dismiss()
                    }) {
                        Text("Confirm Permanent Rejection")
                            .font(LMSFont.button)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: LMSRadius.md)
                                    .fill(!internalRemarks.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !selectedReasons.isEmpty ? LMSColors.coral : Color.gray.opacity(0.5))
                            )
                    }
                    .disabled(internalRemarks.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedReasons.isEmpty)
                    .buttonStyle(.plain)
                    .padding(.bottom, LMSSpacing.xl)
                }
                .padding()
            }
            .navigationTitle("Reject Application")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct VerificationDetailSheet: View {
    let application: OfficerLoanApplication
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onSuccess: (String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var checkedDocuments: Set<UUID> = []
    @State private var showingDocViewer: LoanDocument? = nil
    
    // Accordion Expansion states
    @State private var isRiskScanExpanded = true
    @State private var isDocCheckExpanded = true
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: LMSSpacing.xl) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("BORROWER IDENTITY & KYC COMPLIANCE")
                            .font(LMSFont.caption.weight(.bold))
                            .foregroundStyle(LMSColors.textSecondary)
                        
                        Text(application.borrowerName)
                            .font(LMSFont.title)
                            .foregroundStyle(LMSColors.textPrimary)
                        
                        Text("CIBIL Index: \(application.cibilScore ?? 750) · Branch: \(application.branch)")
                            .font(LMSFont.subheadline)
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                    
                    // Risk Scan Accordion
                    VStack(alignment: .leading, spacing: 0) {
                        Button(action: {
                            withAnimation(.spring()) {
                                isRiskScanExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Label("AUTOMATED RISK BUREAU SCAN", systemImage: "sparkles")
                                    .font(LMSFont.caption.weight(.bold))
                                    .foregroundStyle(LMSColors.textSecondary)
                                Spacer()
                                Image(systemName: isRiskScanExpanded ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(LMSColors.textSecondary)
                            }
                            .padding()
                            .background(LMSColors.surface)
                        }
                        .buttonStyle(.plain)
                        
                        if isRiskScanExpanded {
                            VStack(spacing: 0) {
                                bureauCheckRow(title: "National Identity Aadhaar/PAN Match", score: "99% Match")
                                Divider().padding(.leading, 40)
                                bureauCheckRow(title: "CRA Credit Registry Address Verification", score: "96% Valid")
                                Divider().padding(.leading, 40)
                                bureauCheckRow(title: "PEP, AML & Global Sanctions Database", score: "Clear")
                                Divider().padding(.leading, 40)
                                bureauCheckRow(title: "Internal Negative & Defaulter Check", score: "No Matches")
                            }
                            .background(LMSColors.surface)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg))
                    .overlay(RoundedRectangle(cornerRadius: LMSRadius.lg).stroke(LMSColors.separatorLight, lineWidth: 0.5))
                    
                    // Document checklist accordion
                    VStack(alignment: .leading, spacing: 0) {
                        Button(action: {
                            withAnimation(.spring()) {
                                isDocCheckExpanded.toggle()
                            }
                        }) {
                            HStack {
                                Label("KYC UPLOADED DOCUMENTS CHECKLIST", systemImage: "doc.plaintext.fill")
                                    .font(LMSFont.caption.weight(.bold))
                                    .foregroundStyle(LMSColors.textSecondary)
                                Spacer()
                                Image(systemName: isDocCheckExpanded ? "chevron.up" : "chevron.down")
                                    .foregroundStyle(LMSColors.textSecondary)
                            }
                            .padding()
                            .background(LMSColors.surface)
                        }
                        .buttonStyle(.plain)
                        
                        if isDocCheckExpanded {
                            if application.documents.isEmpty {
                                ContentUnavailableView("No Documents Uploaded", systemImage: "doc.text")
                                    .padding()
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(application.documents) { doc in
                                        let isChecked = checkedDocuments.contains(doc.id) || doc.status == .verified
                                        HStack(spacing: 12) {
                                            Button(action: {
                                                HapticsManager.triggerImpact(style: .medium)
                                                if isChecked {
                                                    checkedDocuments.remove(doc.id)
                                                } else {
                                                    checkedDocuments.insert(doc.id)
                                                }
                                            }) {
                                                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                                                    .font(.title3)
                                                    .foregroundStyle(isChecked ? LMSColors.emerald : LMSColors.textTertiary)
                                            }
                                            .buttonStyle(.plain)
                                            
                                            Image(systemName: doc.docType.symbol)
                                                .foregroundStyle(doc.docType.iconColor)
                                                .frame(width: 32, height: 32)
                                                .background(doc.docType.iconColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(doc.docType.rawValue)
                                                    .font(LMSFont.body.weight(.semibold))
                                                    .foregroundStyle(LMSColors.textPrimary)
                                                Text(doc.status.rawValue)
                                                    .font(LMSFont.caption)
                                                    .foregroundStyle(doc.status.themeColor)
                                            }
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                showingDocViewer = doc
                                            }) {
                                                Text("Preview")
                                                    .font(LMSFont.caption.weight(.semibold))
                                                    .foregroundStyle(LMSColors.actionBlue)
                                                    .padding(.horizontal, 10)
                                                    .padding(.vertical, 5)
                                                    .background(LMSColors.actionBlue.opacity(0.08), in: Capsule())
                                            }
                                            .buttonStyle(.plain)
                                        }
                                        .padding()
                                        
                                        if doc.id != application.documents.last?.id {
                                            Divider().padding(.leading, 56)
                                        }
                                    }
                                }
                                .background(LMSColors.surface)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg))
                    .overlay(RoundedRectangle(cornerRadius: LMSRadius.lg).stroke(LMSColors.separatorLight, lineWidth: 0.5))
                    
                    // Actions row: Verified, Re-upload, Escalate
                    HStack(spacing: LMSSpacing.md) {
                        // Escalate
                        Button(action: {
                            HapticsManager.triggerNotification(type: .error)
                            onSuccess("Case Escalated to Supervisor")
                            dismiss()
                        }) {
                            Text("Escalate")
                                .font(LMSFont.caption.weight(.bold))
                                .foregroundStyle(LMSColors.coral)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LMSColors.coral.opacity(0.08), in: RoundedRectangle(cornerRadius: LMSRadius.md))
                                .overlay(RoundedRectangle(cornerRadius: LMSRadius.md).stroke(LMSColors.coral.opacity(0.2), lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                        
                        // Mark Verified
                        Button(action: {
                            HapticsManager.triggerNotification(type: .success)
                            
                            for doc in application.documents {
                                if checkedDocuments.contains(doc.id) && doc.status != .verified {
                                    viewModel.updateDocumentStatus(applicationId: application.applicationId, docId: doc.id, newStatus: .verified)
                                }
                            }
                            
                            viewModel.updateApplicationStatus(applicationId: application.applicationId, newStatus: .verificationCompleted)
                            
                            onSuccess("KYC Verification Completed for \(application.borrowerName)")
                            dismiss()
                        }) {
                            Text("Mark Verified")
                                .font(LMSFont.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: LMSRadius.md)
                                        .fill(
                                            LinearGradient(colors: [LMSColors.brandNavy, LMSColors.brandNavyLight], startPoint: .top, endPoint: .bottom)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.bottom, LMSSpacing.xl)
                }
                .padding()
            }
            .navigationTitle("Document Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(item: $showingDocViewer) { doc in
                DocumentViewerSheet(doc: doc)
            }
        }
    }
    
    private func bureauCheckRow(title: String, score: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(LMSColors.emerald)
                .frame(width: 24, height: 24)
            
            Text(title)
                .font(LMSFont.subheadline)
                .foregroundStyle(LMSColors.textPrimary)
            
            Spacer()
            
            Text(score)
                .font(LMSFont.caption.weight(.bold))
                .foregroundStyle(LMSColors.emerald)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(LMSColors.emerald.opacity(0.08), in: Capsule())
        }
        .padding()
    }
}

struct DocumentViewerSheet: View {
    let doc: LoanDocument
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                Image(systemName: doc.docType.symbol)
                    .font(.system(size: 70))
                    .foregroundStyle(doc.docType.iconColor)
                    .padding()
                
                Text(doc.docType.rawValue)
                    .font(LMSFont.headline)
                
                Text("Verification Reference File: MOCK-DOC-\(doc.id.uuidString.prefix(6)).pdf")
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)
                    .padding(.bottom, 30)
                
                VStack(spacing: 12) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 260, height: 15)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 260, height: 15)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 180, height: 15)
                }
                .padding(30)
                .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.03), radius: 5)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(LMSColors.background)
            .navigationTitle(doc.docType.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Dismiss") { dismiss() }
                }
            }
        }
    }
}
