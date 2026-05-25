import Foundation

struct LoanOfficerMockData {
    typealias LoanApplication = OfficerLoanApplication
    typealias LoanType = OfficerLoanType
    typealias ApplicationStatus = OfficerApplicationStatus
    typealias DocumentStatus = OfficerDocumentStatus
    typealias DocumentType = OfficerDocumentType

    static let branchName = "Bengaluru"
    static let officerName = "Arjun"

    static func createApplications() -> [LoanApplication] {
        let calendar = Calendar.current
        let now = Date()

        let officerId = UUID()
        let borrower1 = UUID()
        let borrower2 = UUID()
        let borrower3 = UUID()
        let borrower4 = UUID()
        let borrower5 = UUID()
        let borrower6 = UUID()
        let borrower7 = UUID()
        let borrower8 = UUID()
        let borrower9 = UUID()
        let borrower10 = UUID()


        let docsPriya = [
            LoanDocument(id: UUID(), docType: .aadhaar, status: .reUploaded, uploadedDate: calendar.date(byAdding: .hour, value: -2, to: now), reviewedDate: nil),
            LoanDocument(id: UUID(), docType: .pan, status: .verified, uploadedDate: calendar.date(byAdding: .day, value: -10, to: now), reviewedDate: calendar.date(byAdding: .day, value: -8, to: now)),
            LoanDocument(id: UUID(), docType: .salarySlip, status: .verified, uploadedDate: calendar.date(byAdding: .day, value: -10, to: now), reviewedDate: calendar.date(byAdding: .day, value: -8, to: now))
        ]

        let docsRohit = [
            LoanDocument(id: UUID(), docType: .salarySlip, status: .uploaded, uploadedDate: calendar.date(byAdding: .hour, value: -5, to: now), reviewedDate: nil),
            LoanDocument(id: UUID(), docType: .pan, status: .verified, uploadedDate: calendar.date(byAdding: .day, value: -5, to: now), reviewedDate: calendar.date(byAdding: .day, value: -4, to: now)),
            LoanDocument(id: UUID(), docType: .aadhaar, status: .verified, uploadedDate: calendar.date(byAdding: .day, value: -5, to: now), reviewedDate: calendar.date(byAdding: .day, value: -4, to: now))
        ]

        let docsAnita = [
            LoanDocument(id: UUID(), docType: .gstCertificate, status: .uploaded, uploadedDate: calendar.date(byAdding: .hour, value: -1, to: now), reviewedDate: nil),
            LoanDocument(id: UUID(), docType: .pan, status: .verified, uploadedDate: calendar.date(byAdding: .hour, value: -4, to: now), reviewedDate: calendar.date(byAdding: .hour, value: -2, to: now))
        ]

        let docsSuresh = [
            LoanDocument(id: UUID(), docType: .pan, status: .verified, uploadedDate: calendar.date(byAdding: .day, value: -15, to: now), reviewedDate: calendar.date(byAdding: .day, value: -14, to: now)),
            LoanDocument(id: UUID(), docType: .aadhaar, status: .verified, uploadedDate: calendar.date(byAdding: .day, value: -15, to: now), reviewedDate: calendar.date(byAdding: .day, value: -14, to: now))
        ]

        let docsKavya = [
            LoanDocument(id: UUID(), docType: .bankStatement, status: .underReview, uploadedDate: calendar.date(byAdding: .hour, value: -3, to: now), reviewedDate: nil),
            LoanDocument(id: UUID(), docType: .pan, status: .verified, uploadedDate: calendar.date(byAdding: .day, value: -4, to: now), reviewedDate: calendar.date(byAdding: .day, value: -3, to: now))
        ]

        let docsRajan = [
            LoanDocument(id: UUID(), docType: .propertyDoc, status: .verified, uploadedDate: calendar.date(byAdding: .day, value: -6, to: now), reviewedDate: calendar.date(byAdding: .day, value: -5, to: now))
        ]

        let apps: [LoanApplication] = [

            LoanApplication(
                id: UUID(),
                applicationId: "APP-2024-0892",
                borrowerName: "Priya Sharma",
                borrowerId: borrower1,
                loanType: .home,
                requestedAmount: 4_500_000,
                status: .underReview,
                submittedDate: calendar.date(byAdding: .day, value: -12, to: now)!,
                lastUpdatedDate: calendar.date(byAdding: .hour, value: -2, to: now)!,
                assignedOfficerId: officerId,
                documents: docsPriya,
                notes: "Borrower uploaded their corrected Aadhaar card after previous copy was blurry.",
                branch: "Bengaluru East",
                cibilScore: 785,
                sentToManagerDate: calendar.date(byAdding: .day, value: -2, to: now),
                managerStatus: .underReview
            ),

            LoanApplication(
                id: UUID(),
                applicationId: "APP-2024-0914",
                borrowerName: "Rohit Mehta",
                borrowerId: borrower2,
                loanType: .personal,
                requestedAmount: 500_000,
                status: .pending,
                submittedDate: calendar.date(byAdding: .day, value: -5, to: now)!,
                lastUpdatedDate: calendar.date(byAdding: .hour, value: -5, to: now)!,
                assignedOfficerId: officerId,
                documents: docsRohit,
                notes: "Awaiting review of the freshly uploaded salary slip.",
                branch: "Bengaluru Central",
                cibilScore: 720,
                sentToManagerDate: nil,
                managerStatus: nil
            ),

            LoanApplication(
                id: UUID(),
                applicationId: "APP-2024-0925",
                borrowerName: "Anita Desai",
                borrowerId: borrower3,
                loanType: .business,
                requestedAmount: 2_500_000,
                status: .pending,
                submittedDate: calendar.date(byAdding: .day, value: -1, to: now)!,
                lastUpdatedDate: calendar.date(byAdding: .hour, value: -6, to: now)!,
                assignedOfficerId: officerId,
                documents: docsAnita,
                notes: "GST certificate pending from borrower. Handled initial verification.",
                branch: "Bengaluru South",
                cibilScore: 740,
                sentToManagerDate: nil,
                managerStatus: nil
            ),

            LoanApplication(
                id: UUID(),
                applicationId: "APP-2024-0711",
                borrowerName: "Suresh Kumar",
                borrowerId: borrower4,
                loanType: .vehicle,
                requestedAmount: 1_200_000,
                status: .onHold,
                submittedDate: calendar.date(byAdding: .day, value: -20, to: now)!,
                lastUpdatedDate: calendar.date(byAdding: .day, value: -4, to: now)!,
                assignedOfficerId: officerId,
                documents: docsSuresh,
                notes: "EMI missed. Contacted borrower to resolve.",
                branch: "Bengaluru North",
                cibilScore: 610,
                sentToManagerDate: nil,
                managerStatus: nil
            ),

            LoanApplication(
                id: UUID(),
                applicationId: "APP-2024-0830",
                borrowerName: "Kavya Nair",
                borrowerId: borrower5,
                loanType: .education,
                requestedAmount: 1_500_000,
                status: .underReview,
                submittedDate: calendar.date(byAdding: .day, value: -8, to: now)!,
                lastUpdatedDate: calendar.date(byAdding: .day, value: -1, to: now)!,
                assignedOfficerId: officerId,
                documents: docsKavya,
                notes: "Reviewing foreign university admission letter and bank statements.",
                branch: "Bengaluru West",
                cibilScore: 790,
                sentToManagerDate: nil,
                managerStatus: nil
            ),

            LoanApplication(
                id: UUID(),
                applicationId: "APP-2024-0610",
                borrowerName: "Rajan Pillai",
                borrowerId: borrower6,
                loanType: .home,
                requestedAmount: 8_500_000,
                status: .approved,
                submittedDate: calendar.date(byAdding: .day, value: -30, to: now)!,
                lastUpdatedDate: calendar.date(byAdding: .day, value: -5, to: now)!,
                assignedOfficerId: officerId,
                documents: docsRajan,
                notes: "Borrower has signed the consent. Proceeding to disbursement scheduling.",
                branch: "Bengaluru East",
                cibilScore: 810,
                sentToManagerDate: calendar.date(byAdding: .day, value: -6, to: now),
                managerStatus: .approved
            ),

            LoanApplication(
                id: UUID(),
                applicationId: "APP-2024-0754",
                borrowerName: "Kiran Joshi",
                borrowerId: borrower7,
                loanType: .business,
                requestedAmount: 2_500_000,
                status: .approved,
                submittedDate: calendar.date(byAdding: .day, value: -15, to: now)!,
                lastUpdatedDate: calendar.date(byAdding: .day, value: -4, to: now)!,
                assignedOfficerId: officerId,
                documents: [],
                notes: "Business extension loan. Approved by Manager.",
                branch: "Bengaluru North",
                cibilScore: 765,
                sentToManagerDate: calendar.date(byAdding: .day, value: -4, to: now),
                managerStatus: .approved
            ),

            LoanApplication(
                id: UUID(),
                applicationId: "APP-2024-0801",
                borrowerName: "Deepak Rao",
                borrowerId: borrower8,
                loanType: .personal,
                requestedAmount: 800_000,
                status: .underReview,
                submittedDate: calendar.date(byAdding: .day, value: -6, to: now)!,
                lastUpdatedDate: calendar.date(byAdding: .day, value: -1, to: now)!,
                assignedOfficerId: officerId,
                documents: [],
                notes: "Manager requested extra income declarations from co-applicant.",
                branch: "Bengaluru West",
                cibilScore: 680,
                sentToManagerDate: calendar.date(byAdding: .day, value: -1, to: now),
                managerStatus: .needsClarification
            ),

            LoanApplication(
                id: UUID(),
                applicationId: "APP-2024-0932",
                borrowerName: "Meena Iyer",
                borrowerId: borrower9,
                loanType: .education,
                requestedAmount: 1_200_000,
                status: .underReview,
                submittedDate: calendar.date(byAdding: .day, value: -2, to: now)!,
                lastUpdatedDate: now,
                assignedOfficerId: officerId,
                documents: [],
                notes: "Forwarded to Manager for exception approvals due to minor score dip.",
                branch: "Bengaluru Central",
                cibilScore: 695,
                sentToManagerDate: now,
                managerStatus: .underReview
            ),

            LoanApplication(
                id: UUID(),
                applicationId: "APP-2024-0511",
                borrowerName: "Arun Verma",
                borrowerId: borrower10,
                loanType: .vehicle,
                requestedAmount: 1_800_000,
                status: .disbursed,
                submittedDate: calendar.date(byAdding: .day, value: -45, to: now)!,
                lastUpdatedDate: calendar.date(byAdding: .day, value: -15, to: now)!,
                assignedOfficerId: officerId,
                documents: [],
                notes: "Disbursed. Fully verified.",
                branch: "Bengaluru East",
                cibilScore: 770,
                sentToManagerDate: calendar.date(byAdding: .day, value: -20, to: now),
                managerStatus: .approved
            ),

            LoanApplication(
                id: UUID(),
                applicationId: "APP-2024-0419",
                borrowerName: "Tara Sen",
                borrowerId: UUID(),
                loanType: .home,
                requestedAmount: 15_000_000,
                status: .rejected,
                submittedDate: calendar.date(byAdding: .day, value: -60, to: now)!,
                lastUpdatedDate: calendar.date(byAdding: .day, value: -50, to: now)!,
                assignedOfficerId: officerId,
                documents: [],
                notes: "High CIBIL write-off detected during bureau check.",
                branch: "Bengaluru South",
                cibilScore: 540,
                sentToManagerDate: nil,
                managerStatus: nil
            )
        ]

        return apps
    }

    static func createActivityFeed() -> [ActivityFeedItem] {
        let calendar = Calendar.current
        let now = Date()

        return [
            ActivityFeedItem(
                id: UUID(),
                borrowerName: "Priya Sharma",
                applicationId: "APP-2024-0892",
                loanType: "Home Loan",
                eventType: .documentReUploaded,
                eventDescription: "Re-uploaded Aadhaar Card (3rd attempt) — Please review.",
                timestamp: calendar.date(byAdding: .minute, value: -15, to: now)!,
                isRead: false,
                requiresAction: true,
                actionType: .reviewDocument
            ),
            ActivityFeedItem(
                id: UUID(),
                borrowerName: "Rohit Mehta",
                applicationId: "APP-2024-0914",
                loanType: "Personal Loan",
                eventType: .queryRaised,
                eventDescription: "Query: \"When will my loan be disbursed?\"",
                timestamp: calendar.date(byAdding: .hour, value: -1, to: now)!,
                isRead: false,
                requiresAction: true,
                actionType: .replyQuery
            ),
            ActivityFeedItem(
                id: UUID(),
                borrowerName: "Anita Desai",
                applicationId: "APP-2024-0925",
                loanType: "Business Loan",
                eventType: .applicationSubmitted,
                eventDescription: "New application submitted (Business Loan ₹25L) — Pending initial review.",
                timestamp: calendar.date(byAdding: .hour, value: -3, to: now)!,
                isRead: false,
                requiresAction: true,
                actionType: .verifyApplication
            ),
            ActivityFeedItem(
                id: UUID(),
                borrowerName: "Suresh Kumar",
                applicationId: "APP-2024-0711",
                loanType: "Vehicle Loan",
                eventType: .emiOverdue,
                eventDescription: "EMI of ₹18,500 overdue by 4 days.",
                timestamp: calendar.date(byAdding: .hour, value: -12, to: now)!,
                isRead: false,
                requiresAction: true,
                actionType: .viewEMIAlert
            ),
            ActivityFeedItem(
                id: UUID(),
                borrowerName: "Kavya Nair",
                applicationId: "APP-2024-0830",
                loanType: "Education Loan",
                eventType: .documentUploaded,
                eventDescription: "Uploaded all 6 pending documents.",
                timestamp: calendar.date(byAdding: .day, value: -1, to: now)!,
                isRead: true,
                requiresAction: true,
                actionType: .reviewDocument
            ),
            ActivityFeedItem(
                id: UUID(),
                borrowerName: "Rajan Pillai",
                applicationId: "APP-2024-0610",
                loanType: "Home Loan",
                eventType: .consentGiven,
                eventDescription: "E-signed loan consent form.",
                timestamp: calendar.date(byAdding: .day, value: -2, to: now)!,
                isRead: true,
                requiresAction: false,
                actionType: nil
            )
        ]
    }
}

