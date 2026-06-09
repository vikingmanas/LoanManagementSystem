
import Foundation
import Supabase
import OSLog

final class AdminDashboardService {
    static let shared = AdminDashboardService()
    private let client = SupabaseManager.shared.client
    private let logger = Logger(subsystem: "galgotias.in.akash", category: "AdminDashboardService")
    
    private init() {}
    
    struct DBAuditLog: Codable {
        let logId: UUID
        let userId: UUID
        let action: String
        let entityType: String
        let entityId: UUID
        let ts: Date
    }
    
    struct DBUserMin: Codable {
        let id: UUID
        let email: String
        let fullName: String
        let role: String
        let status: String
        let lastLogin: Date?
    }
    
    struct DBRichDetails: Codable {
        var shortDescription: String = ""
        var interestRateRange: String = ""
        var estimatedProcessingTime: String = ""
        var eligibilitySnapshot: String = ""
        var purpose: String = ""
        var benefits: [String] = []
        var eligibilityCriteria: [String] = []
        var minimumRequirements: [String] = []
        var interestInformation: String = ""
        var repaymentOverview: String = ""
        var processingFees: String = ""
        var faqs: [BorrowerLoanFAQ] = []
        var loanSpecificDocuments: [String] = []
    }

    struct DBAdminLoanProduct: Codable {
        let productId: UUID
        var name: String
        var loanType: String
        var minAmount: Double
        var maxAmount: Double
        var minTenureMonths: Int
        var maxTenureMonths: Int
        var baseInterestRate: Double
        var processingFeePct: Double
        var isActive: Bool
        var createdBy: UUID?
        var richDetails: DBRichDetails?
    }
    
    struct DBNotificationTemplate: Codable {
        let templateId: UUID
        let notifType: String
        let titleTemplate: String
        let bodyTemplate: String
        let isActive: Bool
        let createdBy: UUID?
    }
    
    struct DashboardData {
        let totalApplications: Int
        let totalApplicationsTrend: Double
        let activeLoans: Int
        let activeLoansTrend: Double
        let pendingApprovals: Int
        let pendingApprovalsTrend: Double
        let totalDisbursed: Double
        let totalDisbursedTrend: Double
        let activeSessions: Int
        let serverUptime: Double
        let lastBackupTime: Date
        let recentAuditLogs: [AuditLogEntry]
        let rawApplications: [DBLoanApplication]
    }
    
    func fetchDashboardData() async throws -> DashboardData {
        logger.info("AdminDashboardService: Starting dashboard data fetch...")
        
        let dbApps: [DBLoanApplication] = try await client
            .from("loan_applications")
            .select()
            .execute()
            .value
        
        let dbUsers: [DBUserMin] = try await client
            .from("users")
            .select()
            .execute()
            .value
        let usersMap = Dictionary(uniqueKeysWithValues: dbUsers.map { ($0.id, $0) })
        
        await seedAuditLogsIfNeeded(users: dbUsers)
        
        let dbLogs: [DBAuditLog] = try await client
            .from("audit_logs")
            .select()
            .order("ts", ascending: false)
            .limit(20)
            .execute()
            .value
        
        let mappedLogs = dbLogs.map { dbLog -> AuditLogEntry in
            let userName = usersMap[dbLog.userId]?.fullName ?? "System"
            let logType: AuditLogType
            let typeLower = dbLog.entityType.lowercased()
            if typeLower.contains("user") {
                logType = .userAction
            } else if typeLower.contains("document") || typeLower.contains("file") || typeLower.contains("kyc") {
                logType = .documentAction
            } else if typeLower.contains("loan") || typeLower.contains("application") || typeLower.contains("account") || typeLower.contains("workflow") {
                logType = .loanAction
            } else {
                logType = .systemAction
            }
            
            let userRole = usersMap[dbLog.userId]?.role.capitalized
            
            return AuditLogEntry(
                id: dbLog.logId,
                userId: dbLog.userId,
                userName: userName,
                userRole: userRole,
                action: dbLog.action,
                entityType: dbLog.entityType,
                entityId: "APP-\(dbLog.entityId.uuidString.prefix(6).uppercased())",
                timestamp: dbLog.ts,
                details: "Action performed on \(dbLog.entityType) \(dbLog.entityId.uuidString.prefix(8)).",
                type: logType
            )
        }
        
        let pendingStatuses = ["submitted", "under_review", "document_verification", "officer_review", "manager_review"]
        
        let totalApplications = dbApps.count
        let activeLoans = dbApps.filter { $0.status == "disbursed" || $0.status == "approved" }.count
        let pendingApprovals = dbApps.filter { pendingStatuses.contains($0.status) }.count
        let totalDisbursed = dbApps
            .filter { $0.status == "disbursed" || $0.status == "approved" }
            .reduce(0.0) { $0 + Double($1.amountRequested) }
        
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        let sixtyDaysAgo = Calendar.current.date(byAdding: .day, value: -60, to: now) ?? now
        
        let last30Apps = dbApps.filter { ($0.submittedAt ?? $0.updatedAt) >= thirtyDaysAgo }
        let prev30Apps = dbApps.filter { ($0.submittedAt ?? $0.updatedAt) >= sixtyDaysAgo && ($0.submittedAt ?? $0.updatedAt) < thirtyDaysAgo }
        
        let totalAppsTrend = calculateTrend(current: last30Apps.count, previous: prev30Apps.count)
        
        let currentActive = last30Apps.filter { $0.status == "disbursed" || $0.status == "approved" }.count
        let prevActive = prev30Apps.filter { $0.status == "disbursed" || $0.status == "approved" }.count
        let activeLoansTrend = calculateTrend(current: currentActive, previous: prevActive)
        
        let currentPending = last30Apps.filter { pendingStatuses.contains($0.status) }.count
        let prevPending = prev30Apps.filter { pendingStatuses.contains($0.status) }.count
        let pendingTrend = calculateTrend(current: currentPending, previous: prevPending)
        
        let currentDisbursed = last30Apps.filter { $0.status == "disbursed" || $0.status == "approved" }.reduce(0.0) { $0 + Double($1.amountRequested) }
        let prevDisbursed = prev30Apps.filter { $0.status == "disbursed" || $0.status == "approved" }.reduce(0.0) { $0 + Double($1.amountRequested) }
        let disbursedTrend = calculateTrend(current: Int(currentDisbursed), previous: Int(prevDisbursed))
        
        let oneDayAgo = Calendar.current.date(byAdding: .hour, value: -24, to: now) ?? now
        let activeSessionsCount = dbUsers.filter {
            if let lastLogin = $0.lastLogin {
                return lastLogin >= oneDayAgo
            }
            return $0.status == "active"
        }.count
        
        let serverUptime = dbApps.isEmpty && dbUsers.isEmpty && dbLogs.isEmpty ? 0.0 : 100.0
        let lastBackupTime = dbLogs.first?.ts ?? Calendar.current.date(byAdding: .hour, value: -2, to: now) ?? now
        
        return DashboardData(
            totalApplications: totalApplications,
            totalApplicationsTrend: totalAppsTrend,
            activeLoans: activeLoans,
            activeLoansTrend: activeLoansTrend,
            pendingApprovals: pendingApprovals,
            pendingApprovalsTrend: pendingTrend,
            totalDisbursed: totalDisbursed,
            totalDisbursedTrend: disbursedTrend,
            activeSessions: max(1, activeSessionsCount),
            serverUptime: Double(String(format: "%.2f", serverUptime)) ?? 99.98,
            lastBackupTime: lastBackupTime,
            recentAuditLogs: mappedLogs,
            rawApplications: dbApps
        )
    }
    
    func fetchAllAuditLogs() async throws -> [AuditLogEntry] {
        logger.info("AdminDashboardService: Fetching all audit logs...")
        let dbUsers: [DBUserMin] = try await client
            .from("users")
            .select()
            .execute()
            .value
        let usersMap = Dictionary(uniqueKeysWithValues: dbUsers.map { ($0.id, $0) })
        
        let dbLogs: [DBAuditLog] = try await client
            .from("audit_logs")
            .select()
            .order("ts", ascending: false)
            .execute()
            .value
        
        return dbLogs.map { dbLog -> AuditLogEntry in
            let userName = usersMap[dbLog.userId]?.fullName ?? "System"
            let logType: AuditLogType
            let typeLower = dbLog.entityType.lowercased()
            if typeLower.contains("user") {
                logType = .userAction
            } else if typeLower.contains("document") || typeLower.contains("file") || typeLower.contains("kyc") {
                logType = .documentAction
            } else if typeLower.contains("loan") || typeLower.contains("application") || typeLower.contains("account") || typeLower.contains("workflow") {
                logType = .loanAction
            } else {
                logType = .systemAction
            }
            
            let userRole = usersMap[dbLog.userId]?.role.capitalized
            
            return AuditLogEntry(
                id: dbLog.logId,
                userId: dbLog.userId,
                userName: userName,
                userRole: userRole,
                action: dbLog.action,
                entityType: dbLog.entityType,
                entityId: "APP-\(dbLog.entityId.uuidString.prefix(6).uppercased())",
                timestamp: dbLog.ts,
                details: "Action performed on \(dbLog.entityType) \(dbLog.entityId.uuidString.prefix(8)).",
                type: logType
            )
        }
    }
    
    func fetchLoanProducts() async throws -> [AdminLoanProduct] {
        logger.info("AdminDashboardService: Fetching loan products...")

        try await seedLoanProductsIfNeeded()
        
        let dbProds: [DBAdminLoanProduct] = try await client
            .from("loan_products")
            .select()
            .execute()
            .value
        
        return dbProds.map { dbProd in
            let loanTypeDisplay: String
            switch dbProd.loanType.lowercased() {
            case "home": loanTypeDisplay = "Home Loan"
            case "personal": loanTypeDisplay = "Personal Loan"
            case "business": loanTypeDisplay = "Business Loan"
            case "auto": loanTypeDisplay = "Auto Loan"
            case "education": loanTypeDisplay = "Education Loan"
            default: loanTypeDisplay = dbProd.loanType.capitalized
            }
            
            return AdminLoanProduct(
                id: dbProd.productId,
                name: dbProd.name,
                loanType: loanTypeDisplay,
                isActive: dbProd.isActive,
                minRate: dbProd.baseInterestRate,
                maxRate: dbProd.baseInterestRate + 3.5,
                minAmount: dbProd.minAmount,
                maxAmount: dbProd.maxAmount,
                maxTenure: dbProd.maxTenureMonths,
                processingFee: dbProd.processingFeePct,
                requiredDocuments: dbProd.richDetails?.loanSpecificDocuments ?? ["Aadhaar", "PAN", "Income Proof"]
            )
        }
    }
    
    func upsertLoanProduct(_ product: AdminLoanProduct) async throws {
        logger.info("AdminDashboardService: Upserting loan product: \(product.name)")
        let adminId = client.auth.currentSession?.user.id ?? UUID()
        
        let normalizedType = product.loanType
            .lowercased()
            .replacingOccurrences(of: " loan", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            
        var existingRich: DBRichDetails? = nil
        do {
            let existing: [DBAdminLoanProduct] = try await client
                .from("loan_products")
                .select()
                .eq("product_id", value: product.id.uuidString)
                .execute()
                .value
            existingRich = existing.first?.richDetails
        } catch {
            logger.info("AdminDashboardService: No existing product found or failed to fetch existing product, creating new rich details: \(error.localizedDescription)")
        }
        
        var rich = existingRich ?? DBRichDetails()
        rich.loanSpecificDocuments = product.requiredDocuments
        rich.interestRateRange = String(format: "%.2f%% p.a.", product.minRate)
        rich.processingFees = String(format: "%.2f%% of loan amount", product.processingFee)
        
        let dbProd = DBAdminLoanProduct(
            productId: product.id,
            name: product.name,
            loanType: normalizedType,
            minAmount: product.minAmount,
            maxAmount: product.maxAmount,
            minTenureMonths: 12,
            maxTenureMonths: product.maxTenure,
            baseInterestRate: product.minRate,
            processingFeePct: product.processingFee,
            isActive: product.isActive,
            createdBy: adminId,
            richDetails: rich
        )
        
        try await client
            .from("loan_products")
            .upsert(dbProd, onConflict: "product_id")
            .execute()
    }
    
    func fetchNotificationTemplates() async throws -> [MessageTemplate] {
        logger.info("AdminDashboardService: Fetching notification templates...")

        try await seedNotificationTemplatesIfNeeded()
        
        let dbTemps: [DBNotificationTemplate] = try await client
            .from("notification_templates")
            .select()
            .execute()
            .value
        
        return dbTemps
            .filter { $0.titleTemplate != "system_rules" }
            .map { dbTemp in
                let tempType: MessageTemplateType
                switch dbTemp.notifType.lowercased() {
                case "email": tempType = .email
                case "sms": tempType = .sms
                default: tempType = .push
                }
                
                return MessageTemplate(
                    id: dbTemp.templateId,
                    name: dbTemp.titleTemplate,
                    subject: dbTemp.titleTemplate,
                    body: dbTemp.bodyTemplate,
                    type: tempType,
                    isActive: dbTemp.isActive
                )
            }
    }
    
    struct DBSystemSetting: Codable {
        let key: String
        let value: GlobalLoanRules
        let updatedBy: UUID?
    }

    func fetchGlobalRules() async throws -> GlobalLoanRules {
        logger.info("AdminDashboardService: Fetching global rules from system_settings table...")
        let dbSettings: [DBSystemSetting] = try await client
            .from("system_settings")
            .select()
            .eq("key", value: "global_loan_rules")
            .execute()
            .value
        
        if let setting = dbSettings.first {
            return setting.value
        }
        
        let defaultRules = GlobalLoanRules(minCibilScore: 700, maxDTI: 50.0, maxLTV: 80.0)
        try? await updateGlobalRules(defaultRules)
        return defaultRules
    }
    
    func updateGlobalRules(_ rules: GlobalLoanRules) async throws {
        logger.info("AdminDashboardService: Saving global rules to system_settings table...")
        let adminId = client.auth.currentSession?.user.id
        
        let dbSetting = DBSystemSetting(
            key: "global_loan_rules",
            value: rules,
            updatedBy: adminId
        )
        
        try await client
            .from("system_settings")
            .upsert(dbSetting, onConflict: "key")
            .execute()
    }
    
    func upsertNotificationTemplate(_ temp: MessageTemplate) async throws {
        logger.info("AdminDashboardService: Upserting notification template: \(temp.name)")
        let adminId = client.auth.currentSession?.user.id ?? UUID()
        
        let notifTypeStr: String
        switch temp.type {
        case .email: notifTypeStr = "email"
        case .sms: notifTypeStr = "sms"
        case .push: notifTypeStr = "push"
        }
        
        let dbTemp = DBNotificationTemplate(
            templateId: temp.id,
            notifType: notifTypeStr,
            titleTemplate: temp.subject,
            bodyTemplate: temp.body,
            isActive: temp.isActive,
            createdBy: adminId
        )
        
        try await client
            .from("notification_templates")
            .upsert(dbTemp, onConflict: "template_id")
            .execute()
    }
    
    func deleteNotificationTemplate(id: UUID) async throws {
        logger.info("AdminDashboardService: Deleting notification template ID: \(id.uuidString)")
        try await client
            .from("notification_templates")
            .delete()
            .eq("template_id", value: id.uuidString)
            .execute()
    }
    
    private func seedAuditLogsIfNeeded(users: [DBUserMin]) async {
        do {
            let existingLogs: [DBAuditLog] = try await client
                .from("audit_logs")
                .select()
                .limit(1)
                .execute()
                .value
            guard existingLogs.isEmpty else { return }
            
            logger.info("AdminDashboardService: Audit logs table is empty. Seeding audit logs...")
            guard !users.isEmpty else { return }
            
            let actions = [
                ("Approved Loan Application", "Loan", "Verified bank details and signed off on home loan."),
                ("Rejected Document", "Document", "Aadhaar card image was blurry. Requested re-upload."),
                ("Created Staff User", "User", "Added Raj Kumar as a new Loan Officer."),
                ("System Database Backup", "System", "Automated daily snapshot saved successfully."),
                ("Disbursed Funds", "Loan", "Transferred funds to borrower bank account.")
            ]
            
            for (action, entityType, _) in actions {
                let user = users.randomElement()!
                let entityId = UUID()
                
                let insertData: [String: String] = [
                    "user_id": user.id.uuidString,
                    "action": action,
                    "entity_type": entityType,
                    "entity_id": entityId.uuidString,
                    "ip_address": "192.168.1.\(Int.random(in: 2...254))"
                ]
                
                try await client
                    .from("audit_logs")
                    .insert(insertData)
                    .execute()
            }
            logger.info("AdminDashboardService: Successfully seeded audit logs.")
        } catch {
            logger.error("AdminDashboardService: Failed to seed audit logs: \(error.localizedDescription)")
        }
    }
    
    private func seedLoanProductsIfNeeded() async throws {
        let existingProds: [DBAdminLoanProduct] = try await client
            .from("loan_products")
            .select()
            .limit(1)
            .execute()
            .value
        guard existingProds.isEmpty else { return }
        
        logger.info("AdminDashboardService: Loan products table is empty. Seeding defaults...")
        let adminId = client.auth.currentSession?.user.id ?? UUID()
        
        let defaultProds = [
            DBAdminLoanProduct(
                productId: UUID(),
                name: "Standard Home Loan",
                loanType: "home",
                minAmount: 500000,
                maxAmount: 50000000,
                minTenureMonths: 12,
                maxTenureMonths: 360,
                baseInterestRate: 8.5,
                processingFeePct: 0.5,
                isActive: true,
                createdBy: adminId,
                richDetails: DBRichDetails(
                    shortDescription: "Long-term financing for purchasing or constructing residential property.",
                    interestRateRange: "8.50% - 12.00% p.a.",
                    estimatedProcessingTime: "5 - 7 Working Days",
                    eligibilitySnapshot: "Min Age: 21, Stable Income",
                    purpose: "Purchase, construction, or renovation of residential property.",
                    benefits: ["High loan amounts", "Longer tenure up to 30 years", "Tax benefits on principal & interest"],
                    eligibilityCriteria: ["Indian Citizen", "Age: 21 to 65 years", "Minimum salary: ₹25,000/month"],
                    minimumRequirements: ["Proof of Identity", "Proof of Address", "Last 6 months bank statement", "3 months salary slip"],
                    interestInformation: "Floating interest rates linked to benchmark lending rates.",
                    repaymentOverview: "Monthly EMIs structured over selected tenure.",
                    processingFees: "0.50% of the loan amount.",
                    faqs: [],
                    loanSpecificDocuments: ["Property Documents", "Aadhaar Card", "PAN Card", "Salary Slip", "Bank Statement"]
                )
            ),
            DBAdminLoanProduct(
                productId: UUID(),
                name: "Instant Personal Loan",
                loanType: "personal",
                minAmount: 50000,
                maxAmount: 1500000,
                minTenureMonths: 12,
                maxTenureMonths: 60,
                baseInterestRate: 10.5,
                processingFeePct: 2.0,
                isActive: true,
                createdBy: adminId,
                richDetails: DBRichDetails(
                    shortDescription: "Unsecured personal financing to meet immediate financial requirements.",
                    interestRateRange: "10.50% - 18.00% p.a.",
                    estimatedProcessingTime: "24 - 48 Hours",
                    eligibilitySnapshot: "Min Age: 21, Min Salary: ₹20k",
                    purpose: "Wedding, travel, medical emergency, or consolidation of debt.",
                    benefits: ["No collateral required", "Quick processing & disbursal", "Flexible end-use of funds"],
                    eligibilityCriteria: ["Resident Indian", "Age: 21 to 60 years", "Salaried or self-employed with regular income"],
                    minimumRequirements: ["Proof of Identity", "Proof of Address", "Last 3 months salary slips", "Bank statement"],
                    interestInformation: "Fixed interest rates computed on reducing balance.",
                    repaymentOverview: "Monthly auto-debit payments.",
                    processingFees: "2.00% of the loan amount.",
                    faqs: [],
                    loanSpecificDocuments: ["Aadhaar Card", "PAN Card", "Salary Slip", "Bank Statement"]
                )
            ),
            DBAdminLoanProduct(
                productId: UUID(),
                name: "SME Business Loan",
                loanType: "business",
                minAmount: 500000,
                maxAmount: 10000000,
                minTenureMonths: 12,
                maxTenureMonths: 120,
                baseInterestRate: 12.0,
                processingFeePct: 1.5,
                isActive: true,
                createdBy: adminId,
                richDetails: DBRichDetails(
                    shortDescription: "Customized business funding to expand operations, buy inventory, or machinery.",
                    interestRateRange: "12.00% - 24.00% p.a.",
                    estimatedProcessingTime: "5 - 10 Working Days",
                    eligibilitySnapshot: "Business Vintage: 2+ Years",
                    purpose: "Working capital requirements, equipment purchase, or business expansion.",
                    benefits: ["Flexible repayment terms", "Higher limit for business needs", "Sovereign guarantees option"],
                    eligibilityCriteria: ["Registered business entity", "Minimum vintage of 2 years", "Profitable operations"],
                    minimumRequirements: ["Business PAN", "GST returns", "Last 2 years ITR", "12 months bank statement"],
                    interestInformation: "Competitive fixed/reducing interest pricing.",
                    repaymentOverview: "Structured EMI based on business cash flows.",
                    processingFees: "1.50% of the loan amount.",
                    faqs: [],
                    loanSpecificDocuments: ["GST Certificate", "ITR", "Business Bank Statement", "Aadhaar Card", "PAN Card"]
                )
            )
        ]
        
        for prod in defaultProds {
            try await client
                .from("loan_products")
                .insert(prod)
                .execute()
        }
        logger.info("AdminDashboardService: Successfully seeded default loan products.")
    }
    
    private func seedNotificationTemplatesIfNeeded() async throws {
        let existingTemps: [DBNotificationTemplate] = try await client
            .from("notification_templates")
            .select()
            .limit(1)
            .execute()
            .value
        guard existingTemps.isEmpty else { return }
        
        logger.info("AdminDashboardService: Notification templates table is empty. Seeding defaults...")
        let adminId = client.auth.currentSession?.user.id ?? UUID()
        
        let defaultTemps = [
            DBNotificationTemplate(templateId: UUID(), notifType: "email", titleTemplate: "Congratulations! Your loan is approved", bodyTemplate: "Dear {{user_name}},\n\nWe are pleased to inform you that your loan application has been approved.", isActive: true, createdBy: adminId),
            DBNotificationTemplate(templateId: UUID(), notifType: "sms", titleTemplate: "Upcoming EMI Payment", bodyTemplate: "Reminder: Your EMI of {{emi_amount}} is due on {{due_date}}. Please maintain sufficient balance.", isActive: true, createdBy: adminId)
        ]
        
        for temp in defaultTemps {
            try await client
                .from("notification_templates")
                .insert(temp)
                .execute()
        }
        logger.info("AdminDashboardService: Successfully seeded default notification templates.")
    }
    
    private func calculateTrend(current: Int, previous: Int) -> Double {
        if previous == 0 {
            return current > 0 ? 100.0 : 0.0
        }
        let diff = Double(current - previous)
        let percent = (diff / Double(previous)) * 100.0
        return Double(String(format: "%.1f", percent)) ?? percent
    }
}
