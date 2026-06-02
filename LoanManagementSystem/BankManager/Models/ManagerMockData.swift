import SwiftUI


enum ManagerMockData {

    static let managerName = "Ramanathan Swamy"
    static let managerInitials = "RS"
    static let branchName = "Bengaluru Central"
    static let branchCode = "BC-490"
    static let employeeId = "BM-490"


    static let officers: [ManagerOfficer] = [
        ManagerOfficer(
            id: UUID(uuidString: "A0000001-0000-0000-0000-000000000001")!,
            name: "Aarav Patel",
            role: "Senior Loan Officer",
            activeCases: 12,
            maxCapacity: 15,
            rating: 4.8,
            performance: 0.92,
            loansProcessedYTD: 156,
            approvalRate: 94.2
        ),
        ManagerOfficer(
            id: UUID(uuidString: "A0000001-0000-0000-0000-000000000002")!,
            name: "Priya Menon",
            role: "Loan Officer",
            activeCases: 8,
            maxCapacity: 15,
            rating: 4.5,
            performance: 0.87,
            loansProcessedYTD: 128,
            approvalRate: 91.5
        ),
        ManagerOfficer(
            id: UUID(uuidString: "A0000001-0000-0000-0000-000000000003")!,
            name: "Rohan Gupta",
            role: "Junior Loan Officer",
            activeCases: 5,
            maxCapacity: 10,
            rating: 4.2,
            performance: 0.78,
            loansProcessedYTD: 64,
            approvalRate: 88.0
        ),
        ManagerOfficer(
            id: UUID(uuidString: "A0000001-0000-0000-0000-000000000004")!,
            name: "Neha Singh",
            role: "Loan Officer",
            activeCases: 14,
            maxCapacity: 15,
            rating: 4.6,
            performance: 0.90,
            loansProcessedYTD: 142,
            approvalRate: 93.1
        )
    ]


    static let applicants: [ManagerApplicant] = [
        ManagerApplicant(
            id: UUID(uuidString: "B0000001-0000-0000-0000-000000000001")!,
            applicationId: "APP-2026-0892",
            borrowerName: "Priya Sharma",
            borrowerInitials: "PS",
            loanType: .home,
            requestedAmount: 4_500_000,
            cibilScore: 785,
            status: .sentToManager,
            riskLevel: .low,
            assignedOfficer: "Aarav Patel",
            assignedOfficerId: UUID(uuidString: "A0000001-0000-0000-0000-000000000001")!,
            submissionDate: Date().addingTimeInterval(-86400 * 3),
            documents: sampleDocumentsComplete,
            officerRemarks: "High-value loan requires supervisor clearance. All documents verified, CIBIL score excellent. Recommend approval.",
            managerRemarks: "",
            verificationProgress: 1.0,
            tenure: 240,
            interestRate: 8.65
        ),
        ManagerApplicant(
            id: UUID(uuidString: "B0000001-0000-0000-0000-000000000002")!,
            applicationId: "APP-2026-0932",
            borrowerName: "Meena Iyer",
            borrowerInitials: "MI",
            loanType: .education,
            requestedAmount: 1_200_000,
            cibilScore: 695,
            status: .sentToManager,
            riskLevel: .medium,
            assignedOfficer: "Priya Menon",
            assignedOfficerId: UUID(uuidString: "A0000001-0000-0000-0000-000000000002")!,
            submissionDate: Date().addingTimeInterval(-86400 * 1),
            documents: sampleDocumentsPending,
            officerRemarks: "CIBIL score marginally under branch threshold. Income verification cleared. Co-applicant (parent) has strong financial profile.",
            managerRemarks: "",
            verificationProgress: 0.85,
            tenure: 60,
            interestRate: 9.25
        ),
        ManagerApplicant(
            id: UUID(uuidString: "B0000001-0000-0000-0000-000000000003")!,
            applicationId: "APP-2026-0801",
            borrowerName: "Deepak Rao",
            borrowerInitials: "DR",
            loanType: .personal,
            requestedAmount: 800_000,
            cibilScore: 680,
            status: .needsClarification,
            riskLevel: .medium,
            assignedOfficer: "Rohan Gupta",
            assignedOfficerId: UUID(uuidString: "A0000001-0000-0000-0000-000000000003")!,
            submissionDate: Date().addingTimeInterval(-86400 * 5),
            documents: sampleDocumentsMixed,
            officerRemarks: "Requires co-applicant income certificate verification. Awaiting re-upload of bank statement.",
            managerRemarks: "Please verify co-applicant income source and provide updated ITR.",
            verificationProgress: 0.65,
            tenure: 36,
            interestRate: 12.50
        ),
        ManagerApplicant(
            id: UUID(uuidString: "B0000001-0000-0000-0000-000000000004")!,
            applicationId: "APP-2026-0750",
            borrowerName: "Rohan Kapoor",
            borrowerInitials: "RK",
            loanType: .vehicle,
            requestedAmount: 900_000,
            cibilScore: 710,
            status: .approved,
            riskLevel: .low,
            assignedOfficer: "Aarav Patel",
            assignedOfficerId: UUID(uuidString: "A0000001-0000-0000-0000-000000000001")!,
            submissionDate: Date().addingTimeInterval(-86400 * 10),
            documents: sampleDocumentsComplete,
            officerRemarks: "Standard processing cleared. All verifications passed.",
            managerRemarks: "Approved. Proceed with disbursement.",
            verificationProgress: 1.0,
            tenure: 60,
            interestRate: 9.75
        ),
        ManagerApplicant(
            id: UUID(uuidString: "B0000001-0000-0000-0000-000000000005")!,
            applicationId: "APP-2026-0711",
            borrowerName: "Sunita Verma",
            borrowerInitials: "SV",
            loanType: .personal,
            requestedAmount: 500_000,
            cibilScore: 580,
            status: .rejected,
            riskLevel: .high,
            assignedOfficer: "Neha Singh",
            assignedOfficerId: UUID(uuidString: "A0000001-0000-0000-0000-000000000004")!,
            submissionDate: Date().addingTimeInterval(-86400 * 12),
            documents: sampleDocumentsMixed,
            officerRemarks: "CIBIL score significantly below minimum threshold. Multiple delinquencies noted in credit history.",
            managerRemarks: "Rejected due to poor credit profile. Advised to clear existing obligations.",
            verificationProgress: 0.50,
            tenure: 24,
            interestRate: 14.50
        ),
        ManagerApplicant(
            id: UUID(uuidString: "B0000001-0000-0000-0000-000000000006")!,
            applicationId: "APP-2026-0965",
            borrowerName: "Ananya Reddy",
            borrowerInitials: "AR",
            loanType: .home,
            requestedAmount: 7_500_000,
            cibilScore: 810,
            status: .sentToManager,
            riskLevel: .low,
            assignedOfficer: "Neha Singh",
            assignedOfficerId: UUID(uuidString: "A0000001-0000-0000-0000-000000000004")!,
            submissionDate: Date().addingTimeInterval(-86400 * 0.5),
            documents: sampleDocumentsComplete,
            officerRemarks: "Premium high-value home loan. Excellent CIBIL and income. Property valuation completed. Strong recommendation for approval.",
            managerRemarks: "",
            verificationProgress: 0.95,
            tenure: 300,
            interestRate: 8.45
        ),
        ManagerApplicant(
            id: UUID(uuidString: "B0000001-0000-0000-0000-000000000007")!,
            applicationId: "APP-2026-0988",
            borrowerName: "Vikram Joshi",
            borrowerInitials: "VJ",
            loanType: .business,
            requestedAmount: 2_500_000,
            cibilScore: 620,
            status: .escalated,
            riskLevel: .critical,
            assignedOfficer: "Priya Menon",
            assignedOfficerId: UUID(uuidString: "A0000001-0000-0000-0000-000000000002")!,
            submissionDate: Date().addingTimeInterval(-86400 * 7),
            documents: sampleDocumentsMixed,
            officerRemarks: LoanEscalationNote.officer(name: "Priya Menon", reason: "GST filings inconsistent with declared turnover. Potential fraud indicators detected."),
            managerRemarks: "Escalated to Admin for fraud investigation.",
            verificationProgress: 0.40,
            tenure: 48,
            interestRate: 15.00,
            escalatedAt: Date().addingTimeInterval(-86400 * 2)
        ),
        ManagerApplicant(
            id: UUID(uuidString: "B0000001-0000-0000-0000-000000000008")!,
            applicationId: "APP-2026-0944",
            borrowerName: "Kavitha Nair",
            borrowerInitials: "KN",
            loanType: .education,
            requestedAmount: 800_000,
            cibilScore: 740,
            status: .disbursed,
            riskLevel: .low,
            assignedOfficer: "Rohan Gupta",
            assignedOfficerId: UUID(uuidString: "A0000001-0000-0000-0000-000000000003")!,
            submissionDate: Date().addingTimeInterval(-86400 * 20),
            documents: sampleDocumentsComplete,
            officerRemarks: "Education loan for MS program at IIT Bombay. All verifications clear. Moratorium period applied.",
            managerRemarks: "Approved and disbursed.",
            verificationProgress: 1.0,
            tenure: 84,
            interestRate: 8.90
        )
    ]


    private static let sampleDocumentsComplete: [ManagerDocument] = [
        ManagerDocument(id: UUID(), name: "Aadhaar Card", type: "Identity", status: .verified),
        ManagerDocument(id: UUID(), name: "PAN Card", type: "Identity", status: .verified),
        ManagerDocument(id: UUID(), name: "Salary Slips (Q1)", type: "Income", status: .verified),
        ManagerDocument(id: UUID(), name: "Bank Statement (6M)", type: "Financial", status: .verified),
        ManagerDocument(id: UUID(), name: "Property Valuation", type: "Collateral", status: .verified)
    ]

    private static let sampleDocumentsPending: [ManagerDocument] = [
        ManagerDocument(id: UUID(), name: "Aadhaar Card", type: "Identity", status: .verified),
        ManagerDocument(id: UUID(), name: "PAN Card", type: "Identity", status: .verified),
        ManagerDocument(id: UUID(), name: "Admission Letter", type: "Education", status: .verified),
        ManagerDocument(id: UUID(), name: "Co-Applicant ITR", type: "Income", status: .pending),
        ManagerDocument(id: UUID(), name: "Fee Structure", type: "Education", status: .pending)
    ]

    private static let sampleDocumentsMixed: [ManagerDocument] = [
        ManagerDocument(id: UUID(), name: "Aadhaar Card", type: "Identity", status: .verified),
        ManagerDocument(id: UUID(), name: "PAN Card", type: "Identity", status: .verified),
        ManagerDocument(id: UUID(), name: "Bank Statement", type: "Financial", status: .rejected),
        ManagerDocument(id: UUID(), name: "Salary Slips", type: "Income", status: .reUploaded),
        ManagerDocument(id: UUID(), name: "ITR (2 Years)", type: "Income", status: .pending)
    ]





    static let branchOverview = BranchOverview(
        name: "Bengaluru Central",
        code: "BC-490",
        region: "South Karnataka",
        staffCount: 18,
        activeLoanCount: 247,
        totalDisbursed: 48_000_000,
        totalRecovered: 46_944_000,
        nplRate: 0.45,
        auditRating: "A+",
        monthlyTarget: 60_000_000
    )


    static let notifications: [ManagerNotificationItem] = [
        ManagerNotificationItem(
            id: UUID(), title: "High Value Loan Pending",
            message: "APP-2026-0965 for ₹75L (Ananya Reddy) requires your clearance.",
            timestamp: Date().addingTimeInterval(-1800), type: .alert, isRead: false,
            relatedApplicantId: UUID(uuidString: "B0000001-0000-0000-0000-000000000006")
        ),
        ManagerNotificationItem(
            id: UUID(), title: "Officer Capacity Alert",
            message: "Neha Singh is at 93% capacity (14/15 cases). Consider redistribution.",
            timestamp: Date().addingTimeInterval(-3600), type: .warning, isRead: false
        ),
        ManagerNotificationItem(
            id: UUID(), title: "Weekly Report Ready",
            message: "Your weekly branch performance report has been generated.",
            timestamp: Date().addingTimeInterval(-86400), type: .info, isRead: false
        ),
        ManagerNotificationItem(
            id: UUID(), title: "Fraud Alert Escalated",
            message: "APP-2026-0988 (Vikram Joshi) flagged for potential fraud. Escalated to Admin.",
            timestamp: Date().addingTimeInterval(-172800), type: .alert, isRead: true
        ),
        ManagerNotificationItem(
            id: UUID(), title: "Disbursement Completed",
            message: "APP-2026-0944 (Kavitha Nair) — ₹8L education loan successfully disbursed.",
            timestamp: Date().addingTimeInterval(-259200), type: .success, isRead: true
        )
    ]


    static let conversations: [ManagerChatConversation] = [
        ManagerChatConversation(
            id: UUID(), officerUserId: UUID(), officerName: "Aarav Patel", officerInitials: "AP",
            officerRole: "Senior Loan Officer",
            lastMessage: "Priya Sharma's property valuation report has been uploaded.",
            timestamp: Date().addingTimeInterval(-1200), unreadCount: 2, isPinned: true,
            priority: .high,
            messages: [
                ManagerChatMessage(id: UUID(), senderName: "Aarav Patel", text: "Good morning sir. I've completed the verification for APP-2026-0892.", timestamp: Date().addingTimeInterval(-7200), isFromManager: false, isSystemMessage: false),
                ManagerChatMessage(id: UUID(), senderName: "System", text: "APP-2026-0892 (Priya Sharma) submitted for your clearance.", timestamp: Date().addingTimeInterval(-3600), isFromManager: false, isSystemMessage: true),
                ManagerChatMessage(id: UUID(), senderName: "Ramanathan Swamy", text: "Good. Has the property valuation been uploaded?", timestamp: Date().addingTimeInterval(-2400), isFromManager: true, isSystemMessage: false),
                ManagerChatMessage(id: UUID(), senderName: "Aarav Patel", text: "Priya Sharma's property valuation report has been uploaded.", timestamp: Date().addingTimeInterval(-1200), isFromManager: false, isSystemMessage: false)
            ]
        ),
        ManagerChatConversation(
            id: UUID(), officerUserId: UUID(), officerName: "Priya Menon", officerInitials: "PM",
            officerRole: "Loan Officer",
            lastMessage: "Escalation for Vikram Joshi's case — GST discrepancy found.",
            timestamp: Date().addingTimeInterval(-3600), unreadCount: 1, isPinned: false,
            priority: .urgent,
            messages: [
                ManagerChatMessage(id: UUID(), senderName: "Priya Menon", text: "Sir, I need to escalate APP-2026-0988. Found major GST discrepancies.", timestamp: Date().addingTimeInterval(-7200), isFromManager: false, isSystemMessage: false),
                ManagerChatMessage(id: UUID(), senderName: "Ramanathan Swamy", text: "What kind of discrepancies?", timestamp: Date().addingTimeInterval(-5400), isFromManager: true, isSystemMessage: false),
                ManagerChatMessage(id: UUID(), senderName: "Priya Menon", text: "Escalation for Vikram Joshi's case — GST discrepancy found.", timestamp: Date().addingTimeInterval(-3600), isFromManager: false, isSystemMessage: false)
            ]
        ),
        ManagerChatConversation(
            id: UUID(), officerUserId: UUID(), officerName: "Rohan Gupta", officerInitials: "RG",
            officerRole: "Junior Loan Officer",
            lastMessage: "Kavitha Nair's disbursement has been processed.",
            timestamp: Date().addingTimeInterval(-86400), unreadCount: 0, isPinned: false,
            priority: .normal,
            messages: [
                ManagerChatMessage(id: UUID(), senderName: "Rohan Gupta", text: "Sir, Kavitha Nair's education loan has been processed.", timestamp: Date().addingTimeInterval(-172800), isFromManager: false, isSystemMessage: false),
                ManagerChatMessage(id: UUID(), senderName: "Ramanathan Swamy", text: "Good work, Rohan. Make sure the moratorium terms are clearly communicated.", timestamp: Date().addingTimeInterval(-90000), isFromManager: true, isSystemMessage: false),
                ManagerChatMessage(id: UUID(), senderName: "Rohan Gupta", text: "Kavitha Nair's disbursement has been processed.", timestamp: Date().addingTimeInterval(-86400), isFromManager: false, isSystemMessage: false)
            ]
        ),
        ManagerChatConversation(
            id: UUID(), officerUserId: UUID(), officerName: "Neha Singh", officerInitials: "NS",
            officerRole: "Loan Officer",
            lastMessage: "Ananya Reddy's home loan file is ready for your review.",
            timestamp: Date().addingTimeInterval(-600), unreadCount: 3, isPinned: true,
            priority: .high,
            messages: [
                ManagerChatMessage(id: UUID(), senderName: "Neha Singh", text: "Sir, I'm submitting APP-2026-0965 for your review. Premium home loan case.", timestamp: Date().addingTimeInterval(-3600), isFromManager: false, isSystemMessage: false),
                ManagerChatMessage(id: UUID(), senderName: "System", text: "APP-2026-0965 (Ananya Reddy) submitted for your clearance.", timestamp: Date().addingTimeInterval(-1800), isFromManager: false, isSystemMessage: true),
                ManagerChatMessage(id: UUID(), senderName: "Neha Singh", text: "Ananya Reddy's home loan file is ready for your review.", timestamp: Date().addingTimeInterval(-600), isFromManager: false, isSystemMessage: false)
            ]
        )
    ]



    static let monthlyDisbursements: [(String, Double)] = [
        ("Jan", 62), ("Feb", 78), ("Mar", 85), ("Apr", 72), ("May", 94), ("Jun", 88)
    ]

    static let loanDistribution: [(String, Double, Color)] = [
        ("Home", 40, LMSColors.emerald),
        ("Auto", 22, LMSColors.actionBlue),
        ("Personal", 18, LMSColors.teal),
        ("Education", 12, LMSColors.amber),
        ("Business", 8, Color.purple)
    ]

    static let approvalStats: (approved: Int, rejected: Int, pending: Int) = (
        approved: 187, rejected: 15, pending: 45
    )
}
