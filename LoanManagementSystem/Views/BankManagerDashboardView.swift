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
        )
    ]
    
    @State private var selectedApplication: ManagerLoanApplication? = nil
    @State private var showProfileSheet: Bool = false
    @State private var showApprovalAlert: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 1. CUSTOM TOP NAVIGATION BAR
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Welcome Back, Manager 🏢")
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundColor(.primary)
                    
                    Text("Branch Manager · Branch: Bengaluru Central")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
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
            .background(Color(.systemBackground))
            
            Divider()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // 2. ANALYTICS KPI GRID
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Branch Operations YTD")
                            .font(.system(.footnote, design: .rounded).bold())
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                        
                        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                            GridRow {
                                ManagerMetricBox(
                                    title: "BRANCH DISBURSEMENT",
                                    value: "₹ 4.8 Cr",
                                    subtitle: "Goal: ₹ 6.0 Cr",
                                    accentColor: Color(hex: "#00C48C")
                                )
                                ManagerMetricBox(
                                    title: "APPROVAL RATIO",
                                    value: "92.4%",
                                    subtitle: "Target: >90%",
                                    accentColor: Color(hex: "#1A73E8")
                                )
                            }
                            GridRow {
                                ManagerMetricBox(
                                    title: "クリア QUEUE",
                                    value: "\(applications.filter { $0.status == "Sent to Manager" }.count) Loans",
                                    subtitle: "Supervisor action",
                                    accentColor: Color(hex: "#FFB300")
                                )
                                ManagerMetricBox(
                                    title: "BRANCH NPL RATE",
                                    value: "0.45%",
                                    subtitle: "Risk level: Excellent",
                                    accentColor: Color(hex: "#FF4D4F")
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    // 3. PENDING SUPERVISOR ACTION QUEUE
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Applications Awaiting Clearance")
                            .font(.system(.footnote, design: .rounded).bold())
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                        
                        if applications.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 44))
                                    .foregroundColor(Color(hex: "#00C48C"))
                                
                                Text("No Pending Clearances")
                                    .font(.system(.subheadline, design: .rounded).bold())
                                
                                Text("All branch loan applications have been audited and resolved.")
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 32)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(16)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(applications) { app in
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
                                                        .foregroundColor(.primary)
                                                    
                                                    Spacer()
                                                    
                                                    Text("₹ \(Int(app.requestedAmount / 100_000)) Lakh")
                                                        .font(.system(.caption, design: .rounded).bold())
                                                        .foregroundColor(Color.AppTheme.primary)
                                                }
                                                
                                                HStack {
                                                    Text("\(app.loanType) · CIBIL: \(app.cibilScore)")
                                                        .font(.system(.caption, design: .rounded))
                                                        .foregroundColor(.secondary)
                                                    
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
                                        .background(Color(.secondarySystemBackground))
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
            .background(Color(.systemGroupedBackground))
        }
        .sheet(item: $selectedApplication) { app in
            ManagerActionSheet(
                application: app,
                onApprove: { approvedApp in
                    withAnimation {
                        applications.removeAll { $0.id == approvedApp.id }
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
                }
            )
        }
        .sheet(isPresented: $showProfileSheet) {
            BankManagerProfileView()
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
                    .foregroundColor(.secondary)
                Spacer()
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 8, height: 8)
            }
            
            Text(value)
                .font(.system(.title2, design: .rounded).bold())
                .foregroundColor(.primary)
            
            Text(subtitle)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Clearance Action Sheet
struct ManagerActionSheet: View {
    let application: ManagerLoanApplication
    var onApprove: (ManagerLoanApplication) -> Void
    var onClarify: (ManagerLoanApplication) -> Void
    
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
                        .font(.title2.bold())
                    
                    Text("FILE ID: \(application.applicationId)")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.15))
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
                .background(Color(.secondarySystemBackground))
                .cornerRadius(16)
                
                // Referral Reason Box
                VStack(alignment: .leading, spacing: 8) {
                    Text("REFERRAL JUSTIFICATION")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    Text(application.reason)
                        .font(.system(.footnote, design: .rounded))
                        .foregroundColor(.primary)
                        .lineSpacing(4)
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
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundColor(.primary)
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
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(20)
                    .padding(.horizontal, 16)
                    
                    // Operations details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Operational Authority")
                            .font(.system(.caption, design: .rounded).bold())
                            .foregroundColor(.secondary)
                            .padding(.leading, 20)
                        
                        VStack(spacing: 0) {
                            ProfileDetailRow(label: "SIGNATURE LIMIT", value: "₹ 5.0 Cr")
                            Divider().padding(.leading, 16)
                            ProfileDetailRow(label: "STAFF STRENGTH", value: "18 Employees")
                            Divider().padding(.leading, 16)
                            ProfileDetailRow(label: "BRANCH RATING", value: "A+ Audit Class")
                        }
                        .background(Color(.secondarySystemBackground))
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
            .background(Color(.systemBackground))
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
