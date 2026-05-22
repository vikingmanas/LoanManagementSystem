import SwiftUI

struct ManagerLoanApplication: Identifiable, Hashable {
    let id: UUID
    var applicationId: String
    var borrowerName: String
    var loanType: String
    var requestedAmount: Double
    var cibilScore: Int
    var submissionDate: String
    var status: String
    var reason: String
    var documents: [String] = ["Aadhar_Card.pdf", "Salary_Slips_Q1.pdf", "Bank_Statement_6M.pdf"]
}

struct BankManagerDashboardView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var authManager: AuthManager
    
    @State private var applications: [ManagerLoanApplication] = [
        ManagerLoanApplication(
            id: UUID(),
            applicationId: "APP-2024-0892",
            borrowerName: "Priya Sharma",
            loanType: "Home Loan",
            requestedAmount: 4_500_000,
            cibilScore: 785,
            submissionDate: "12 May 2026",
            status: "Sent to Manager",
            reason: "High-value loan require supervisor clearance."
        ),
        ManagerLoanApplication(
            id: UUID(),
            applicationId: "APP-2024-0932",
            borrowerName: "Meena Iyer",
            loanType: "Education Loan",
            requestedAmount: 1_200_000,
            cibilScore: 695,
            submissionDate: "19 May 2026",
            status: "Sent to Manager",
            reason: "CIBIL score is marginally under branch threshold."
        ),
        ManagerLoanApplication(
            id: UUID(),
            applicationId: "APP-2024-0801",
            borrowerName: "Deepak Rao",
            loanType: "Personal Loan",
            requestedAmount: 800_000,
            cibilScore: 680,
            submissionDate: "15 May 2026",
            status: "Needs Clarification",
            reason: "Requires co-applicant income certificate verification."
        ),
        ManagerLoanApplication(
            id: UUID(),
            applicationId: "APP-2024-0750",
            borrowerName: "Rohan Gupta",
            loanType: "Car Loan",
            requestedAmount: 900_000,
            cibilScore: 710,
            submissionDate: "10 May 2026",
            status: "Approved",
            reason: "Standard processing cleared by branch manager."
        ),
        ManagerLoanApplication(
            id: UUID(),
            applicationId: "APP-2024-0711",
            borrowerName: "Sunita Verma",
            loanType: "Personal Loan",
            requestedAmount: 500_000,
            cibilScore: 580,
            submissionDate: "05 May 2026",
            status: "Rejected",
            reason: "CIBIL score significantly below minimum threshold."
        )
    ]
    
    @State private var selectedApplication: ManagerLoanApplication? = nil
    @State private var showProfileSheet: Bool = false
    @State private var showApprovalAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var showAllApplications: Bool = false
    @State private var showBranchConfig: Bool = false
    @State private var showExportOptions: Bool = false
    @State private var isExporting: Bool = false
    @State private var showAuditLogs: Bool = false
    @State private var showNotifications: Bool = false
    
    @State private var notifications: [ManagerNotification] = [
        ManagerNotification(title: "New High Value Loan", message: "Loan #LN-4100 for ₹2.5 Cr requires your clearance.", timestamp: Date().addingTimeInterval(-1800), type: .alert),
        ManagerNotification(title: "Staff Performance Alert", message: "Rohan Gupta is nearing max capacity (9/10).", timestamp: Date().addingTimeInterval(-3600), type: .warning),
        ManagerNotification(title: "Weekly Summary Ready", message: "Your weekly branch performance report is ready to view.", timestamp: Date().addingTimeInterval(-86400), type: .info)
    ]
    
    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }
    
    @State private var staff: [BranchStaff] = [
        BranchStaff(name: "Aarav Patel", role: "Senior Loan Officer", activeCases: 12, maxCapacity: 15, rating: 4.8),
        BranchStaff(name: "Priya Sharma", role: "Loan Officer", activeCases: 8, maxCapacity: 15, rating: 4.5),
        BranchStaff(name: "Rohan Gupta", role: "Junior Loan Officer", activeCases: 5, maxCapacity: 10, rating: 4.2),
        BranchStaff(name: "Neha Singh", role: "Loan Officer", activeCases: 14, maxCapacity: 15, rating: 4.6)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 1. CUSTOM TOP NAVIGATION BAR
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Welcome Back, Manager 🏢")
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundColor(LMSColors.textPrimary)
                    
                    Text("Branch Manager · Branch: Bengaluru Central")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(LMSColors.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    HapticsManager.triggerImpact(style: .medium)
                    showNotifications = true
                }) {
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(LMSColors.surfaceElevated)
                            .frame(width: 38, height: 38)
                        Image(systemName: "bell.fill")
                            .foregroundColor(LMSColors.textSecondary)
                            .font(.system(size: 16))
                        
                        if unreadCount > 0 {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 10, height: 10)
                                .overlay(Circle().stroke(Color(UIColor.systemBackground), lineWidth: 2))
                                .offset(x: -2, y: 2)
                        }
                    }
                }
                .padding(.trailing, 8)
                
                Button(action: {
                    HapticsManager.triggerImpact(style: .medium)
                    showBranchConfig = true
                }) {
                    ZStack {
                        Circle()
                            .fill(LMSColors.surfaceElevated)
                            .frame(width: 38, height: 38)
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(LMSColors.textSecondary)
                            .font(.system(size: 16))
                    }
                }
                .padding(.trailing, 8)
                
                Button(action: {
                    HapticsManager.triggerImpact(style: .medium)
                    showProfileSheet = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#00C48C"))
                            .frame(width: 38, height: 38)
                        
                        Text("BM")
                            .font(.system(.footnote, design: .rounded).bold())
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color(hex: "#00C48C").opacity(0.3), radius: 6, x: 0, y: 3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(LMSColors.surface)
            
            Divider()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // 2. PORTFOLIO TRACKING & ANALYTICS
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Portfolio Tracking YTD")
                            .font(.system(.footnote, design: .rounded).bold())
                            .foregroundColor(LMSColors.textSecondary)
                            .padding(.horizontal, 16)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ManagerMetricCard(
                                    title: "TOTAL DISBURSED",
                                    value: "₹ 4.8 Cr",
                                    subtitle: "Goal: ₹ 6.0 Cr",
                                    accentColor: Color(hex: "#00C48C"),
                                    progress: 0.8
                                )
                                
                                ManagerMetricRingCard(
                                    title: "APPROVAL RATE",
                                    value: "92.4%",
                                    subtitle: "Target: >90%",
                                    accentColor: Color(hex: "#1A73E8"),
                                    progress: 0.924
                                )
                                
                                ManagerMetricCard(
                                    title: "CLEARANCE QUEUE",
                                    value: "\(applications.filter { $0.status == "Sent to Manager" || $0.status == "Needs Clarification" }.count) Loans",
                                    subtitle: "Supervisor action",
                                    accentColor: Color(hex: "#FFB300"),
                                    progress: 0.4
                                )
                                
                                ManagerMetricCard(
                                    title: "BRANCH NPL RATE",
                                    value: "0.45%",
                                    subtitle: "Risk level: Excellent",
                                    accentColor: Color(hex: "#FF4D4F"),
                                    progress: 0.05
                                )
                            }
                            .padding(.horizontal, 16)
                        }
                        
                        // Portfolio Distribution
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Portfolio Distribution")
                                .font(.system(.footnote, design: .rounded).bold())
                                .foregroundColor(LMSColors.textPrimary)
                            
                            HStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color(hex: "#00C48C"))
                                    .frame(width: UIScreen.main.bounds.width * 0.40)
                                Rectangle()
                                    .fill(Color(hex: "#1A73E8"))
                                    .frame(width: UIScreen.main.bounds.width * 0.30)
                                Rectangle()
                                    .fill(Color(hex: "#FFB300"))
                                    .frame(width: UIScreen.main.bounds.width * 0.15)
                                Rectangle()
                                    .fill(Color.gray.opacity(0.3))
                            }
                            .frame(height: 8)
                            .cornerRadius(4)
                            
                            HStack(spacing: 16) {
                                PortfolioLegendItem(color: Color(hex: "#00C48C"), title: "Home", percentage: "40%")
                                PortfolioLegendItem(color: Color(hex: "#1A73E8"), title: "Auto", percentage: "30%")
                                PortfolioLegendItem(color: Color(hex: "#FFB300"), title: "Edu", percentage: "15%")
                                PortfolioLegendItem(color: Color.gray.opacity(0.3), title: "Other", percentage: "15%")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                HapticsManager.triggerImpact(style: .medium)
                                showExportOptions = true
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Report")
                                }
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color(hex: "#34495E"))
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                HapticsManager.triggerImpact(style: .medium)
                                showAuditLogs = true
                            }) {
                                HStack {
                                    Image(systemName: "list.bullet.clipboard")
                                    Text("Audit Logs")
                                }
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundColor(Color.AppTheme.primary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.AppTheme.primary.opacity(0.12))
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    // 3. TEAM WORKLOAD DIRECTORY
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Team Workload Directory")
                            .font(.system(.footnote, design: .rounded).bold())
                            .foregroundColor(LMSColors.textSecondary)
                            .padding(.leading, 16)
                        
                        VStack(spacing: 0) {
                            ForEach(staff.indices, id: \.self) { index in
                                StaffWorkloadRow(staff: staff[index])
                                if index < staff.count - 1 {
                                    Divider()
                                        .padding(.leading, 56)
                                }
                            }
                        }
                        .background(LMSColors.surfaceElevated)
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                    }
                    .padding(.top, 12)
                    
                    // 4. PENDING SUPERVISOR ACTION QUEUE
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Applications Awaiting Clearance")
                                .font(.system(.footnote, design: .rounded).bold())
                                .foregroundColor(LMSColors.textSecondary)
                            
                            Spacer()
                            
                            Button(action: {
                                HapticsManager.triggerImpact(style: .light)
                                showAllApplications = true
                            }) {
                                Text("View All")
                                    .font(.system(.footnote, design: .rounded).bold())
                                    .foregroundColor(Color.AppTheme.primary)
                            }
                        }
                        .padding(.horizontal, 4)
                        
                        let pendingApps = applications.filter { $0.status == "Sent to Manager" || $0.status == "Needs Clarification" }
                        
                        if pendingApps.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(Color(hex: "#00C48C"))
                                
                                Text("No Pending Clearances")
                                    .font(.system(.subheadline, design: .rounded).bold())
                                
                                Text("All branch loan applications have been audited and resolved.")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(LMSColors.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .background(LMSColors.surfaceElevated)
                            .cornerRadius(16)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(pendingApps) { app in
                                    Button(action: {
                                        HapticsManager.triggerImpact(style: .medium)
                                        selectedApplication = app
                                    }) {
                                        HStack(spacing: 12) {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(app.status == "Sent to Manager" ? Color(hex: "#FFB300").opacity(0.12) : Color(hex: "#1A73E8").opacity(0.12))
                                                    .frame(width: 44, height: 44)
                                                
                                                Image(systemName: app.status == "Sent to Manager" ? "exclamationmark.shield.fill" : "questionmark.circle.fill")
                                                    .foregroundColor(app.status == "Sent to Manager" ? Color(hex: "#FFB300") : Color(hex: "#1A73E8"))
                                            }
                                            
                                            VStack(alignment: .leading, spacing: 3) {
                                                HStack {
                                                    Text(app.borrowerName)
                                                        .font(.system(.callout, design: .rounded).bold())
                                                        .foregroundColor(LMSColors.textPrimary)
                                                    
                                                    Spacer()
                                                    
                                                    Text("₹ \(Int(app.requestedAmount / 100_000)) Lakh")
                                                        .font(.system(.caption, design: .rounded).bold())
                                                        .foregroundColor(Color.AppTheme.primary)
                                                }
                                                
                                                HStack {
                                                    Text("\(app.loanType) · CIBIL: \(app.cibilScore)")
                                                        .font(.system(.caption, design: .rounded))
                                                        .foregroundColor(LMSColors.textSecondary)
                                                    
                                                    Spacer()
                                                    
                                                    Text(app.status)
                                                        .font(.system(size: 9, weight: .bold, design: .rounded))
                                                        .foregroundColor(app.status == "Sent to Manager" ? Color(hex: "#FFB300") : Color(hex: "#1A73E8"))
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(app.status == "Sent to Manager" ? Color(hex: "#FFB300").opacity(0.1) : Color(hex: "#1A73E8").opacity(0.1))
                                                        .cornerRadius(6)
                                                }
                                            }
                                        }
                                        .padding(.all, 14)
                                        .background(LMSColors.surfaceElevated)
                                        .cornerRadius(16)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    
                }
                .padding(.bottom, 24)
            }
            .background(LMSColors.background)
        }
        .sheet(item: $selectedApplication) { app in
            ManagerActionSheet(
                application: app,
                onApprove: { approvedApp in
                    withAnimation {
                        if let index = applications.firstIndex(where: { $0.id == approvedApp.id }) {
                            applications[index].status = "Approved"
                        }
                        alertMessage = "Application \(approvedApp.applicationId) for \(approvedApp.borrowerName) approved successfully!"
                        showApprovalAlert = true
                    }
                },
                onClarify: { clarifyApp in
                    withAnimation {
                        if let index = applications.firstIndex(where: { $0.id == clarifyApp.id }) {
                            applications[index].status = "Clarification Requested"
                        }
                    }
                },
                onReject: { rejectedApp in
                    withAnimation {
                        if let index = applications.firstIndex(where: { $0.id == rejectedApp.id }) {
                            applications[index].status = "Rejected"
                        }
                    }
                },
                onEscalate: { escalatedApp in
                    withAnimation {
                        if let index = applications.firstIndex(where: { $0.id == escalatedApp.id }) {
                            applications[index].status = "Escalated to Admin"
                        }
                    }
                }
            )
        }
        .sheet(isPresented: $showProfileSheet) {
            BankManagerProfileView()
        }
        .sheet(isPresented: $showAllApplications) {
            ManagerAllApplicationsView(applications: $applications)
        }
        .sheet(isPresented: $showBranchConfig) {
            BranchConfigurationView()
        }
        .sheet(isPresented: $showExportOptions) {
            ReportExportOptionsView(isExporting: $isExporting)
        }
        .sheet(isPresented: $showAuditLogs) {
            BranchAuditLogView()
        }
        .sheet(isPresented: $showNotifications) {
            ManagerNotificationsView(notifications: $notifications)
        }
        .overlay {
            if isExporting {
                ZStack {
                    Color.black.opacity(0.4).edgesIgnoringSafeArea(.all)
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        Text("Generating PDF Report...")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(LMSColors.surfaceElevated.opacity(0.1))
                    .cornerRadius(20)
                }
                .transition(.opacity)
            }
        }
        .alert(isPresented: $showApprovalAlert) {
            Alert(
                title: Text("Clearance Successful"),
                message: Text(alertMessage),
                dismissButton: .default(Text("Done"))
            )
        }
    }
}

// MARK: - Analytics Metric Cards
struct ManagerMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let accentColor: Color
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(LMSColors.textSecondary)
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(LMSColors.textPrimary)
            
            VStack(alignment: .leading, spacing: 6) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule().frame(width: geometry.size.width, height: 4)
                            .foregroundColor(accentColor.opacity(0.2))
                        Capsule().frame(width: geometry.size.width * progress, height: 4)
                            .foregroundColor(accentColor)
                    }
                }
                .frame(height: 4)
                
                Text(subtitle)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(accentColor)
            }
        }
        .padding(16)
        .frame(width: 160)
        .background(LMSColors.surfaceElevated)
        .cornerRadius(16)
    }
}

struct ManagerMetricRingCard: View {
    let title: String
    let value: String
    let subtitle: String
    let accentColor: Color
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(LMSColors.textSecondary)
            
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(accentColor.opacity(0.2), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                .frame(width: 40, height: 40)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(LMSColors.textPrimary)
                    Text(subtitle)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(accentColor)
                }
            }
        }
        .padding(16)
        .frame(width: 180)
        .background(LMSColors.surfaceElevated)
        .cornerRadius(16)
    }
}

struct PortfolioLegendItem: View {
    let color: Color
    let title: String
    let percentage: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text("\(title) \(percentage)")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(LMSColors.textSecondary)
        }
    }
}

// MARK: - Metric Box Helper
struct ManagerMetricBox: View {
    let title: String
    let value: String
    let subtitle: String
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(LMSColors.textSecondary)
                Spacer()
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
            
            Text(value)
                .font(.system(.title2, design: .rounded).bold())
                .foregroundColor(LMSColors.textPrimary)
            
            Text(subtitle)
                .font(.system(size: 9))
                .foregroundColor(LMSColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(LMSColors.surfaceElevated)
        .cornerRadius(16)
    }
}

// MARK: - Clearance Action Sheet
struct ManagerActionSheet: View {
    let application: ManagerLoanApplication
    var onApprove: (ManagerLoanApplication) -> Void
    var onClarify: (ManagerLoanApplication) -> Void
    var onReject: (ManagerLoanApplication) -> Void
    var onEscalate: (ManagerLoanApplication) -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                
                // Loan File Header
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 48))
                        .foregroundColor(Color.AppTheme.primary)
                        .padding(.bottom, 4)
                    
                    Text(application.borrowerName)
                        .font(LMSFont.title.bold())
                    
                    Text("FILE ID: \(application.applicationId)")
                        .font(LMSFont.caption.bold())
                        .foregroundColor(LMSColors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(LMSColors.textSecondary.opacity(0.15))
                        .cornerRadius(6)
                }
                .padding(.top, 20)
                
                // Details Grid
                VStack(spacing: 0) {
                    DetailItemRow(label: "LOAN PORTFOLIO", value: application.loanType)
                    Divider()
                    DetailItemRow(label: "REQUESTED LIMIT", value: "₹ \(CurrencyFormatter.shared.format(application.requestedAmount))")
                    Divider()
                    DetailItemRow(label: "CIBIL RATING", value: "\(application.cibilScore) (\(application.cibilScore > 750 ? "Excellent" : "Fair"))")
                    Divider()
                    DetailItemRow(label: "DATE SUBMITTED", value: application.submissionDate)
                }
                .background(LMSColors.surfaceElevated)
                .cornerRadius(16)
                
                // Documents section
                VStack(alignment: .leading, spacing: 10) {
                    Text("BORROWER DOCUMENTS")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(LMSColors.textSecondary)
                        .padding(.leading, 4)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(application.documents, id: \.self) { doc in
                                VStack(spacing: 8) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(Color(hex: "#1A73E8").opacity(0.1))
                                            .frame(width: 54, height: 54)
                                        
                                        Image(systemName: "doc.richtext.fill")
                                            .foregroundColor(Color(hex: "#1A73E8"))
                                            .font(.system(size: 24))
                                    }
                                    
                                    Text(doc)
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .foregroundColor(LMSColors.textPrimary)
                                        .frame(width: 72)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(2)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
                
                // Officer Remarks Box
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .foregroundColor(Color.AppTheme.primary)
                        Text("OFFICER REMARKS")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(LMSColors.textSecondary)
                    }
                    
                    HStack(alignment: .top, spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.gray.opacity(0.2))
                                .frame(width: 32, height: 32)
                            Text("LO")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(LMSColors.textPrimary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Assigned Loan Officer")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(LMSColors.textPrimary)
                            Text(application.reason)
                                .font(.system(.footnote, design: .rounded))
                                .foregroundColor(LMSColors.textPrimary)
                                .lineSpacing(4)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(Color(hex: "#FFB300").opacity(0.08))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(hex: "#FFB300").opacity(0.2), lineWidth: 1)
                )
                
                Spacer()
                
                // Decision Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        HapticsManager.triggerImpact(style: .heavy)
                        onApprove(application)
                        dismiss()
                    }) {
                        Text("Approve & Disburse Clearance")
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color(hex: "#00C48C"))
                            .cornerRadius(14)
                    }
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            HapticsManager.triggerImpact(style: .medium)
                            onReject(application)
                            dismiss()
                        }) {
                            Text("Reject")
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundColor(Color.AppTheme.error)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.AppTheme.error.opacity(0.12))
                                .cornerRadius(14)
                        }
                        
                        Button(action: {
                            HapticsManager.triggerImpact(style: .medium)
                            onEscalate(application)
                            dismiss()
                        }) {
                            Text("Escalate")
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundColor(Color(hex: "#9C27B0"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color(hex: "#9C27B0").opacity(0.12))
                                .cornerRadius(14)
                        }
                    }
                    
                    Button(action: {
                        HapticsManager.triggerImpact(style: .medium)
                        onClarify(application)
                        dismiss()
                    }) {
                        Text("Request Officer Clarification")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundColor(Color.AppTheme.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Color.AppTheme.primary.opacity(0.12))
                            .cornerRadius(14)
                    }
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
            .navigationTitle("Clearance Review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct DetailItemRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(LMSColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundColor(LMSColors.textPrimary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
}

// MARK: - Manager Profile View
struct BankManagerProfileView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Profile Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "#00C48C"), Color(hex: "#009E70")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                            
                            Text("BM")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Ramanathan Swamy")
                                .font(.system(.title3, design: .rounded).bold())
                            
                            Text("Principal Branch Manager")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundColor(Color(hex: "#00C48C"))
                            
                            Text("Bengaluru Central Branch (ID: BM-490)")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(LMSColors.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(LMSColors.surfaceElevated)
                    .cornerRadius(20)
                    .padding(.horizontal, 16)
                    
                    // Operations details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Operational Authority")
                            .font(.system(.caption, design: .rounded).bold())
                            .foregroundColor(LMSColors.textSecondary)
                            .padding(.leading, 20)
                        
                        VStack(spacing: 0) {
                            ProfileDetailRow(label: "SIGNATURE LIMIT", value: "₹ 5.0 Cr")
                            Divider().padding(.leading, 16)
                            ProfileDetailRow(label: "STAFF STRENGTH", value: "18 Employees")
                            Divider().padding(.leading, 16)
                            ProfileDetailRow(label: "BRANCH RATING", value: "A+ Audit Class")
                        }
                        .background(LMSColors.surfaceElevated)
                        .cornerRadius(16)
                        .padding(.horizontal, 16)
                    }
                    
                    // Logout button
                    Button(action: {
                        HapticsManager.triggerImpact(style: .medium)
                        dismiss()
                        appState.logout()
                        authManager.signOut()
                    }) {
                        Text("Sign Out of Portal")
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundColor(Color.AppTheme.error)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.AppTheme.error.opacity(0.08))
                            .cornerRadius(16)
                    }
                    .padding(.horizontal, 16)
                    
                }
                .padding(.vertical, 16)
            }
            .background(LMSColors.surface)
            .navigationTitle("Manager Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Branch Configuration View
struct BranchConfigurationView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var homeLoanLimit: Double = 50_000_000
    @State private var autoLoanLimit: Double = 15_000_000
    @State private var eduLoanLimit: Double = 25_000_000
    @State private var minimumCibilScore: Double = 650
    @State private var showSaveAlert: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Portfolio Maximum Caps")) {
                    HStack {
                        Text("Home Loan")
                        Spacer()
                        Text("₹ \(CurrencyFormatter.shared.format(homeLoanLimit))")
                            .foregroundColor(LMSColors.textSecondary)
                    }
                    Slider(value: $homeLoanLimit, in: 1_000_000...100_000_000, step: 1_000_000)
                        .accentColor(Color(hex: "#00C48C"))
                    
                    HStack {
                        Text("Auto Loan")
                        Spacer()
                        Text("₹ \(CurrencyFormatter.shared.format(autoLoanLimit))")
                            .foregroundColor(LMSColors.textSecondary)
                    }
                    Slider(value: $autoLoanLimit, in: 500_000...30_000_000, step: 500_000)
                        .accentColor(Color(hex: "#1A73E8"))
                    
                    HStack {
                        Text("Education Loan")
                        Spacer()
                        Text("₹ \(CurrencyFormatter.shared.format(eduLoanLimit))")
                            .foregroundColor(LMSColors.textSecondary)
                    }
                    Slider(value: $eduLoanLimit, in: 1_000_000...50_000_000, step: 500_000)
                        .accentColor(Color(hex: "#FFB300"))
                }
                
                Section(header: Text("Risk & Compliance"), footer: Text("Applications falling below this CIBIL score will be automatically rejected or escalated to Admin.")) {
                    HStack {
                        Text("Minimum CIBIL Score")
                        Spacer()
                        Text("\(Int(minimumCibilScore))")
                            .foregroundColor(LMSColors.textSecondary)
                    }
                    Slider(value: $minimumCibilScore, in: 300...900, step: 10)
                        .accentColor(Color.AppTheme.primary)
                }
                
                Section {
                    Button(action: {
                        HapticsManager.triggerImpact(style: .medium)
                        showSaveAlert = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            dismiss()
                        }
                    }) {
                        Text("Save Branch Configuration")
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.AppTheme.primary)
                }
            }
            .navigationTitle("Branch Configuration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .alert(isPresented: $showSaveAlert) {
                Alert(
                    title: Text("Settings Saved"),
                    message: Text("Branch configuration has been successfully updated."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

// MARK: - Report Export Options View
struct ReportExportOptionsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isExporting: Bool
    
    @State private var selectedReportType: String = "Monthly Performance"
    @State private var selectedFormat: String = "PDF Document"
    let reportTypes = ["Monthly Performance", "NPL Status", "Disbursement Log", "Supervisor Action Queue"]
    let formats = ["PDF Document", "CSV Spreadsheet"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Report Details")) {
                    Picker("Report Type", selection: $selectedReportType) {
                        ForEach(reportTypes, id: \.self) {
                            Text($0)
                        }
                    }
                    
                    Picker("Export Format", selection: $selectedFormat) {
                        ForEach(formats, id: \.self) {
                            Text($0)
                        }
                    }
                }
                
                Section {
                    Button(action: {
                        HapticsManager.triggerImpact(style: .medium)
                        dismiss()
                        
                        // Simulate export delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation {
                                isExporting = true
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation {
                                    isExporting = false
                                }
                                HapticsManager.triggerNotification(type: .success)
                            }
                        }
                    }) {
                        Text("Export Now")
                            .font(.system(.body, design: .rounded).weight(.bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .listRowBackground(Color.AppTheme.primary)
                }
            }
            .navigationTitle("Export Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Branch Staff Models and Views
struct BranchStaff: Identifiable {
    let id = UUID()
    let name: String
    let role: String
    let activeCases: Int
    let maxCapacity: Int
    let rating: Double
    
    var initials: String {
        let components = name.components(separatedBy: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))"
        }
        return String(name.prefix(2)).uppercased()
    }
    
    var capacityPercentage: Double {
        return Double(activeCases) / Double(maxCapacity)
    }
    
    var capacityColor: Color {
        if capacityPercentage > 0.85 { return Color.AppTheme.error }
        if capacityPercentage > 0.60 { return Color(hex: "#FFB300") }
        return Color(hex: "#00C48C")
    }
}

struct StaffWorkloadRow: View {
    let staff: BranchStaff
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.AppTheme.primary.opacity(0.1))
                    .frame(width: 40, height: 40)
                
                Text(staff.initials)
                    .font(.system(.footnote, design: .rounded).weight(.bold))
                    .foregroundColor(Color.AppTheme.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(staff.name)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundColor(LMSColors.textPrimary)
                
                Text(staff.role)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(LMSColors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .foregroundColor(Color(hex: "#FFB300"))
                        .font(.system(size: 10))
                    Text(String(format: "%.1f", staff.rating))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                }
                
                HStack(spacing: 6) {
                    Text("\(staff.activeCases)/\(staff.maxCapacity) Cases")
                        .font(.system(.caption2, design: .rounded).weight(.medium))
                        .foregroundColor(LMSColors.textSecondary)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Capsule().frame(width: geometry.size.width, height: 4)
                                .foregroundColor(staff.capacityColor.opacity(0.2))
                            Capsule().frame(width: geometry.size.width * staff.capacityPercentage, height: 4)
                                .foregroundColor(staff.capacityColor)
                        }
                    }
                    .frame(width: 32, height: 4)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(LMSColors.surfaceElevated)
    }
}

// MARK: - Audit Logs Models and Views
struct AuditLogEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let action: String
    let user: String
    let severity: Severity
    
    enum Severity {
        case info, success, warning, critical
        
        var color: Color {
            switch self {
            case .info: return Color(hex: "#1A73E8")
            case .success: return Color(hex: "#00C48C")
            case .warning: return Color(hex: "#FFB300")
            case .critical: return Color(hex: "#FF4D4F")
            }
        }
        
        var icon: String {
            switch self {
            case .info: return "info.circle.fill"
            case .success: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .critical: return "xmark.octagon.fill"
            }
        }
    }
}

struct BranchAuditLogView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var events: [AuditLogEvent] = [
        AuditLogEvent(timestamp: Date().addingTimeInterval(-600), action: "Priya Sharma approved Loan #LN-4091", user: "Priya Sharma", severity: .success),
        AuditLogEvent(timestamp: Date().addingTimeInterval(-3600), action: "Branch Configuration updated: Home Loan Limit to ₹5.0 Cr", user: "Ramanathan Swamy", severity: .info),
        AuditLogEvent(timestamp: Date().addingTimeInterval(-7200), action: "Neha Singh escalated Loan #LN-3822 (High Risk)", user: "Neha Singh", severity: .critical),
        AuditLogEvent(timestamp: Date().addingTimeInterval(-14400), action: "Aarav Patel requested clarification on Loan #LN-4100", user: "Aarav Patel", severity: .warning),
        AuditLogEvent(timestamp: Date().addingTimeInterval(-86400), action: "Generated Monthly Performance PDF Report", user: "Ramanathan Swamy", severity: .info),
        AuditLogEvent(timestamp: Date().addingTimeInterval(-90000), action: "Rohan Gupta approved Loan #LN-3990", user: "Rohan Gupta", severity: .success)
    ]
    
    var body: some View {
        NavigationStack {
            List(events) { event in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: event.severity.icon)
                        .foregroundColor(event.severity.color)
                        .font(.system(size: 20))
                        .padding(.top, 2)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.action)
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundColor(LMSColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack {
                            Text(event.user)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(LMSColors.textSecondary)
                            Spacer()
                            Text(event.timestamp, style: .time)
                                .font(.system(.caption2, design: .rounded).bold())
                                .foregroundColor(LMSColors.textSecondary)
                            Text(event.timestamp, style: .date)
                                .font(.system(.caption2, design: .rounded))
                                .foregroundColor(LMSColors.textSecondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .listStyle(.plain)
            .navigationTitle("Branch Audit Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Notification Models and Views
struct ManagerNotification: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let timestamp: Date
    let type: NotificationType
    var isRead: Bool = false
    
    enum NotificationType {
        case alert, warning, info
        
        var icon: String {
            switch self {
            case .alert: return "exclamationmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .info: return "info.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .alert: return Color.AppTheme.error
            case .warning: return Color(hex: "#FFB300")
            case .info: return Color(hex: "#1A73E8")
            }
        }
    }
}

struct ManagerNotificationsView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var notifications: [ManagerNotification]
    
    var body: some View {
        NavigationStack {
            List {
                ForEach($notifications) { $notification in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: notification.type.icon)
                            .foregroundColor(notification.type.color)
                            .font(.system(size: 24))
                            .padding(.top, 4)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(notification.title)
                                .font(.system(.headline, design: .rounded))
                                .foregroundColor(notification.isRead ? .secondary : .primary)
                            
                            Text(notification.message)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(notification.isRead ? .secondary : .primary)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            Text(notification.timestamp, style: .relative)
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(LMSColors.textSecondary)
                                .padding(.top, 2)
                        }
                        Spacer()
                        if !notification.isRead {
                            Circle()
                                .fill(Color.AppTheme.primary)
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.vertical, 4)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            notification.isRead = true
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Mark All Read") {
                        withAnimation {
                            for i in notifications.indices {
                                notifications[i].isRead = true
                            }
                        }
                    }
                    .font(.system(.body, design: .rounded))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(.body, design: .rounded).bold())
                }
            }
        }
    }
}
