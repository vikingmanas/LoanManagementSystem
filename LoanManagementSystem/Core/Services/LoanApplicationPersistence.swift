import Foundation

struct StoredStageEntry: Codable {
    var stage: String
    var timestamp: Date
    var note: String
}

struct StoredLoanApplication: Codable {
    var id: UUID
    var applicationId: String?
    var productType: String
    var formData: StoredLoanFormData
    var currentStage: String
    var stageHistory: [StoredStageEntry]
    var submittedAt: Date?
    var updatedAt: Date
    var assignedQueue: String?
    var outstandingBalance: Double
    var upcomingEMI: Double
}

struct StoredLoanFormData: Codable {
    var fullName: String
    var dateOfBirth: Date
    var gender: String?
    var mobileNumber: String
    var emailAddress: String
    var address: String
    var occupation: String
    var employmentType: String
    var employerName: String
    var workExperienceYears: Int
    var monthlyIncome: String
    var annualIncome: String
    var existingLoans: String
    var existingEMIs: String
    var creditCardObligations: String
    var creditScore: String
    var loanAmountRequested: String
    var loanPurpose: String
    var repaymentPreference: String
    var preferredTenureMonths: Int
    var hasCoApplicant: Bool
    var coApplicantDetails: String
    var hasGuarantor: Bool
    var guarantorDetails: String
    var gstNumber: String
}

struct StoredDisbursementEvent: Codable {
    var id: UUID
    var applicationId: UUID
    var applicationNumber: String
    var borrowerEmail: String
    var borrowerName: String
    var amount: Double
    var accountNumber: String
    var referenceNumber: String
    var creditedAt: Date
}

enum LoanApplicationPersistence {
    private static let applicationsKey = "lms.centralLoanRepository.applications"
    private static let disbursementsKey = "lms.centralLoanRepository.disbursements"

    static func loadApplications() -> [BorrowerLoanApplication] {
        guard let data = UserDefaults.standard.data(forKey: applicationsKey),
              let stored = try? JSONDecoder().decode([StoredLoanApplication].self, from: data) else {
            return []
        }
        return stored.compactMap(restoreApplication)
    }

    static func saveApplications(_ applications: [BorrowerLoanApplication]) {
        let stored = applications.map(storeApplication)
        guard let data = try? JSONEncoder().encode(stored) else { return }
        UserDefaults.standard.set(data, forKey: applicationsKey)
    }

    static func loadDisbursements() -> [LoanDisbursementEvent] {
        guard let data = UserDefaults.standard.data(forKey: disbursementsKey),
              let stored = try? JSONDecoder().decode([StoredDisbursementEvent].self, from: data) else {
            return []
        }
        return stored.map {
            LoanDisbursementEvent(
                id: $0.id,
                applicationId: $0.applicationId,
                applicationNumber: $0.applicationNumber,
                borrowerEmail: $0.borrowerEmail,
                borrowerName: $0.borrowerName,
                amount: $0.amount,
                accountNumber: $0.accountNumber,
                referenceNumber: $0.referenceNumber,
                creditedAt: $0.creditedAt
            )
        }
    }

    static func saveDisbursements(_ events: [LoanDisbursementEvent]) {
        let stored = events.map {
            StoredDisbursementEvent(
                id: $0.id,
                applicationId: $0.applicationId,
                applicationNumber: $0.applicationNumber,
                borrowerEmail: $0.borrowerEmail,
                borrowerName: $0.borrowerName,
                amount: $0.amount,
                accountNumber: $0.accountNumber,
                referenceNumber: $0.referenceNumber,
                creditedAt: $0.creditedAt
            )
        }
        guard let data = try? JSONEncoder().encode(stored) else { return }
        UserDefaults.standard.set(data, forKey: disbursementsKey)
    }

    private static func storeApplication(_ app: BorrowerLoanApplication) -> StoredLoanApplication {
        StoredLoanApplication(
            id: app.id,
            applicationId: app.applicationId,
            productType: app.product.type.rawValue,
            formData: StoredLoanFormData(
                fullName: app.formData.fullName,
                dateOfBirth: app.formData.dateOfBirth,
                gender: app.formData.gender,
                mobileNumber: app.formData.mobileNumber,
                emailAddress: app.formData.emailAddress,
                address: app.formData.address,
                occupation: app.formData.occupation,
                employmentType: app.formData.employmentType,
                employerName: app.formData.employerName,
                workExperienceYears: app.formData.workExperienceYears,
                monthlyIncome: app.formData.monthlyIncome,
                annualIncome: app.formData.annualIncome,
                existingLoans: app.formData.existingLoans,
                existingEMIs: app.formData.existingEMIs,
                creditCardObligations: app.formData.creditCardObligations,
                creditScore: app.formData.creditScore,
                loanAmountRequested: app.formData.loanAmountRequested,
                loanPurpose: app.formData.loanPurpose,
                repaymentPreference: app.formData.repaymentPreference,
                preferredTenureMonths: app.formData.preferredTenureMonths,
                hasCoApplicant: app.formData.hasCoApplicant,
                coApplicantDetails: app.formData.coApplicantDetails,
                hasGuarantor: app.formData.hasGuarantor,
                guarantorDetails: app.formData.guarantorDetails,
                gstNumber: app.formData.gstNumber
            ),
            currentStage: app.currentStage.rawValue,
            stageHistory: app.stageHistory.map {
                StoredStageEntry(stage: $0.stage.rawValue, timestamp: $0.timestamp, note: $0.note)
            },
            submittedAt: app.submittedAt,
            updatedAt: app.updatedAt,
            assignedQueue: app.assignedQueue,
            outstandingBalance: app.outstandingBalance,
            upcomingEMI: app.upcomingEMI
        )
    }

    private static func restoreApplication(_ stored: StoredLoanApplication) -> BorrowerLoanApplication? {
        guard let stage = BorrowerApplicationStage(rawValue: stored.currentStage),
              let productType = BorrowerLoanProductType(rawValue: stored.productType),
              let product = BorrowerLoanProduct.sampleProducts.first(where: { $0.type == productType })
                ?? BorrowerLoanProduct.sampleProducts.first else {
            return nil
        }

        let formData = BorrowerLoanFormData(
            fullName: stored.formData.fullName,
            dateOfBirth: stored.formData.dateOfBirth,
            gender: stored.formData.gender ?? "",
            mobileNumber: stored.formData.mobileNumber,
            emailAddress: stored.formData.emailAddress,
            address: stored.formData.address,
            occupation: stored.formData.occupation,
            employmentType: stored.formData.employmentType,
            employerName: stored.formData.employerName,
            workExperienceYears: stored.formData.workExperienceYears,
            monthlyIncome: stored.formData.monthlyIncome,
            annualIncome: stored.formData.annualIncome,
            existingLoans: stored.formData.existingLoans,
            existingEMIs: stored.formData.existingEMIs,
            creditCardObligations: stored.formData.creditCardObligations,
            creditScore: stored.formData.creditScore,
            loanAmountRequested: stored.formData.loanAmountRequested,
            loanPurpose: stored.formData.loanPurpose,
            repaymentPreference: stored.formData.repaymentPreference,
            preferredTenureMonths: stored.formData.preferredTenureMonths,
            hasCoApplicant: stored.formData.hasCoApplicant,
            coApplicantDetails: stored.formData.coApplicantDetails,
            hasGuarantor: stored.formData.hasGuarantor,
            guarantorDetails: stored.formData.guarantorDetails,
            gstNumber: stored.formData.gstNumber
        )

        let history = stored.stageHistory.compactMap { entry -> BorrowerStageEntry? in
            guard let historyStage = BorrowerApplicationStage(rawValue: entry.stage) else { return nil }
            return BorrowerStageEntry(stage: historyStage, timestamp: entry.timestamp, note: entry.note)
        }

        return BorrowerLoanApplication(
            id: stored.id,
            applicationId: stored.applicationId,
            product: product,
            formData: formData,
            documents: BorrowerLoanDocumentItem.defaultRequirements(for: product),
            currentStage: stage,
            stageHistory: history.isEmpty ? [BorrowerStageEntry(stage: stage, timestamp: stored.updatedAt, note: "Restored application")] : history,
            submittedAt: stored.submittedAt,
            updatedAt: stored.updatedAt,
            assignedQueue: stored.assignedQueue,
            outstandingBalance: stored.outstandingBalance,
            upcomingEMI: stored.upcomingEMI
        )
    }
}
