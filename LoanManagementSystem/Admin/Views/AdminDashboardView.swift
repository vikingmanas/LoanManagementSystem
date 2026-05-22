import SwiftUI

struct AuditLogItem: Identifiable {
    let id = UUID()
    let timestamp: String
    let actor: String
    let action: String
    let type: LogType
    
    enum LogType {
        case info, warning, success, critical
        
        var color: Color {
            switch self {
            case .info: return Color(hex: "#1A73E8")
            case .warning: return Color(hex: "#FFB300")
            case .success: return Color(hex: "#00C48C")
            case .critical: return Color(hex: "#FF4D4F")
            }
        }
        
        var symbol: String {
            switch self {
            case .info: return "info.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .success: return "checkmark.circle.fill"
            case .critical: return "xmark.octagon.fill"
            }
        }
    }
}

struct AdminDashboardView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var authManager: AuthManager
    
    // Configurable Settings States
    @State private var homeLoanRate: Double = 8.5
    @State private var personalLoanRate: Double = 11.2
    @State private var businessLoanRate: Double = 13.5
    @State private var minCIBILThreshold: Double = 650
    
    // Audit logs mock database
    @State private var auditLogs: [AuditLogItem] = [
        AuditLogItem(timestamp: "09:41:02", actor: "SYS-CRON", action: "Completed database backup compaction routine.", type: .success),
        AuditLogItem(timestamp: "09:35:14", actor: "LO-ARJUN", action: "Uploaded salary slip for app reference APP-2024-0914.", type: .info),
        AuditLogItem(timestamp: "09:12:49", actor: "MGR-RAMAN", action: "Approved loan file clearance for APP-2024-0610 (₹85L).", type: .success),
        AuditLogItem(timestamp: "08:55:20", actor: "SECURE-AUTH", action: "Employee session expired for officer L2-RADHIKA.", type: .warning),
        AuditLogItem(timestamp: "08:44:03", actor: "SYS-API", action: "API endpoint latency spike: /loans/verify exceeded 450ms.", type: .warning),
        AuditLogItem(timestamp: "08:12:11", actor: "ADMIN-SYS", action: "Risk evaluation thresholds synced to local cache.", type: .info)
    ]
    
    @State private var logSearch: String = ""
    @State private var showProfileSheet: Bool = false
    @State private var showSaveAlert: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            
            // 1. TOP HEADER SECTION (Admin-styled deep dark layout)
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: "#FF4D4F"))
                            .frame(width: 8, height: 8)
                        
                        Text("SYSTEM ONLINE")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundStyle(Color(hex: "#FF4D4F"))
                    }
                    
                    Text("Astra Portal Admin 🛡️")
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                }
                
                Spacer()
                
                Button(action: {
                    HapticsManager.triggerImpact(style: .medium)
                    showProfileSheet = true
                }) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#0A2540"))
                            .frame(width: 38, height: 38)
                        
                        Text("AD")
                            .font(.system(.footnote, design: .rounded).bold())
                            .foregroundStyle(.white)
                    }
                    .shadow(color: Color(hex: "#0A2540").opacity(0.3), radius: 6, x: 0, y: 3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 12)
            .background(LMSColors.surface)
            
            Divider()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    
                    // 2. SYSTEM STATUS INDICATORS
                    VStack(alignment: .leading, spacing: 10) {
                        Text("System Operations")
                            .font(.system(.footnote, design: .rounded).bold())
                            .foregroundStyle(LMSColors.textSecondary)
                            .padding(.leading, 4)
                        
                        HStack(spacing: 12) {
                            AdminStatusCard(title: "SERVER HEALTH", value: "99.98%", symbol: "server.rack.fill", color: Color(hex: "#00C48C"))
                            AdminStatusCard(title: "STAFF ACTIVE", value: "14 User Sessions", symbol: "person.3.fill", color: Color(hex: "#1A73E8"))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    
                    // 3. EDITABLE CONFIGURATIONS PANEL
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Systemic Loan Rules (Global Config)")
                            .font(.system(.footnote, design: .rounded).bold())
                            .foregroundStyle(LMSColors.textSecondary)
                            .padding(.leading, 4)
                        
                        VStack(spacing: 16) {
                            // Home Loan Rate Slider
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Home Loan Rate")
                                        .font(.system(.footnote, design: .rounded).bold())
                                    Spacer()
                                    Text(String(format: "%.2f%%", homeLoanRate))
                                        .font(.system(.footnote, design: .monospaced).bold())
                                        .foregroundStyle(Color.AppTheme.primary)
                                }
                                Slider(value: $homeLoanRate, in: 5.0...15.0, step: 0.05)
                                    .tint(Color.AppTheme.primary)
                            }
                            
                            // Personal Loan Rate Slider
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Personal Loan Rate")
                                        .font(.system(.footnote, design: .rounded).bold())
                                    Spacer()
                                    Text(String(format: "%.2f%%", personalLoanRate))
                                        .font(.system(.footnote, design: .monospaced).bold())
                                        .foregroundStyle(Color.AppTheme.primary)
                                }
                                Slider(value: $personalLoanRate, in: 8.0...20.0, step: 0.05)
                                    .tint(Color.AppTheme.primary)
                            }
                            
                            // Business Loan Rate Slider
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Business Loan Rate")
                                        .font(.system(.footnote, design: .rounded).bold())
                                    Spacer()
                                    Text(String(format: "%.2f%%", businessLoanRate))
                                        .font(.system(.footnote, design: .monospaced).bold())
                                        .foregroundStyle(Color.AppTheme.primary)
                                }
                                Slider(value: $businessLoanRate, in: 10.0...25.0, step: 0.05)
                                    .tint(Color.AppTheme.primary)
                            }
                            
                            Divider()
                            
                            // CIBIL Threshold slider
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Minimum Approval CIBIL Threshold")
                                        .font(.system(.footnote, design: .rounded).bold())
                                    Spacer()
                                    Text("\(Int(minCIBILThreshold)) Score")
                                        .font(.system(.footnote, design: .monospaced).bold())
                                        .foregroundStyle(Color(hex: "#FFB300"))
                                }
                                Slider(value: $minCIBILThreshold, in: 300...900, step: 5)
                                    .tint(Color(hex: "#FFB300"))
                            }
                            
                            Button(action: {
                                HapticsManager.triggerImpact(style: .heavy)
                                // Add to logs
                                withAnimation {
                                    auditLogs.insert(
                                        AuditLogItem(
                                            timestamp: "NOW",
                                            actor: "ADMIN-SYS",
                                            action: "Updated loan configurations globally: Min CIBIL set to \(Int(minCIBILThreshold)).",
                                            type: .critical
                                        ),
                                        at: 0
                                    )
                                }
                                showSaveAlert = true
                            }) {
                                Text("Apply Global Configuration")
                                    .font(.system(.footnote, design: .rounded).weight(.bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 44)
                                    .background(Color.AppTheme.primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                        .padding(.all, 16)
                        .background(LMSColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.horizontal, 16)
                    
                    // 4. REAL-TIME AUDIT LOGS CONSOLE
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Live System Audit Logs")
                            .font(.system(.footnote, design: .rounded).bold())
                            .foregroundStyle(LMSColors.textSecondary)
                            .padding(.leading, 4)
                        
                        VStack(spacing: 0) {
                            // Search bar inside console
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(LMSColors.textSecondary)
                                
                                TextField("Filter system logs...", text: $logSearch)
                                    .font(.system(.caption, design: .monospaced))
                                
                                if !logSearch.isEmpty {
                                    Button(action: { logSearch = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundStyle(LMSColors.textSecondary)
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(LMSColors.surface.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .padding(.all, 10)
                            
                            // Audit list
                            VStack(spacing: 8) {
                                ForEach(filteredLogs) { log in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: log.type.symbol)
                                            .foregroundStyle(log.type.color)
                                            .font(LMSFont.caption2)
                                            .padding(.top, 2)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack {
                                                Text(log.actor)
                                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                                    .foregroundStyle(log.type.color)
                                                
                                                Spacer()
                                                
                                                Text(log.timestamp)
                                                    .font(.system(size: 8, design: .monospaced))
                                                    .foregroundStyle(LMSColors.textSecondary)
                                            }
                                            
                                            Text(log.action)
                                                .font(.system(size: 10, design: .monospaced))
                                                .foregroundStyle(LMSColors.textPrimary)
                                                .lineSpacing(2)
                                        }
                                    }
                                    .padding(.all, 8)
                                    .background(LMSColors.surface.opacity(0.4))
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.bottom, 12)
                        }
                        .background(LMSColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.horizontal, 16)
                    
                }
                .padding(.bottom, 24)
            }
            .background(LMSColors.background)
        }
        .sheet(isPresented: $showProfileSheet) {
            AdminProfileView()
        }
        .alert(isPresented: $showSaveAlert) {
            Alert(
                title: Text("Thresholds Updated"),
                message: Text("Global financial engine thresholds have been updated in active memory and broadcast to branch cache."),
                dismissButton: .default(Text("Acknowledge"))
            )
        }
    }
    
    // Filter helper
    private var filteredLogs: [AuditLogItem] {
        if logSearch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return auditLogs
        }
        return auditLogs.filter { log in
            log.action.lowercased().contains(logSearch.lowercased()) ||
            log.actor.lowercased().contains(logSearch.lowercased())
        }
    }
}

// MARK: - Admin Status Card
struct AdminStatusCard: View {
    let title: String
    let value: String
    let symbol: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: symbol)
                    .font(LMSFont.footnote)
                    .foregroundStyle(color)
                
                Spacer()
                
                Text(title)
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
            }
            
            Text(value)
                .font(.system(.headline, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(LMSColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

// MARK: - Admin Profile View
struct AdminProfileView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Admin Header
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "#0A2540"), Color(hex: "#234B75")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                            
                            Text("AD")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Superuser Administrator")
                                .font(.system(.title3, design: .rounded).bold())
                            
                            Text("Securities Operations Principal")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(Color(hex: "#0A2540"))
                            
                            Text("National HQ · (Node ID: ADM-01)")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(LMSColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 16)
                    
                    // Detail list
                    VStack(alignment: .leading, spacing: 12) {
                        Text("National System Node")
                            .font(.system(.caption, design: .rounded).bold())
                            .foregroundStyle(LMSColors.textSecondary)
                            .padding(.leading, 20)
                        
                        VStack(spacing: 0) {
                            ProfileDetailRow(label: "SECURITY PERM", value: "Root Access Level 5")
                            Divider().padding(.leading, 16)
                            ProfileDetailRow(label: "SYSTEM NODES", value: "8 Operational Clusters")
                            Divider().padding(.leading, 16)
                            ProfileDetailRow(label: "ENCRYPTION STATUS", value: "AES-256 Active")
                        }
                        .background(LMSColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, 16)
                    }
                    
                    // Logout button
                    Button(action: {
                        HapticsManager.triggerImpact(style: .medium)
                        dismiss()
                        appState.logout()
                        authManager.signOut()
                    }) {
                        Text("Sign Out Admin Console")
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundStyle(Color.AppTheme.error)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.AppTheme.error.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.horizontal, 16)
                    
                }
                .padding(.vertical, 16)
            }
            .background(LMSColors.surface)
            .navigationTitle("Admin Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AdminDashboardView()
        .previewAdminEnvironment()
}
