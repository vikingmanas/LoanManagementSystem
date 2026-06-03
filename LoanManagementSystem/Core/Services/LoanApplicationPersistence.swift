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
    var documents: [BorrowerLoanDocumentItem]?
    var currentStage: String
    var stageHistory: [StoredStageEntry]
    var draftStepIndex: Int?
    var submittedAt: Date?
    var updatedAt: Date
    var assignedQueue: String?
    var assignedOfficerId: UUID?
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
    var preferredBranch: String?
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
    var selectedIdentityDoc: String?
    var selectedAddressDoc: String?
    var selectedIncomeDoc: String?
    var draftStepIndex: Int?
    var bankName: String?
    var bankAccountNumber: String?
    var bankIFSCCode: String?
    var bankRegisteredMobile: String?
    var monthlySalaryDeposited: String?
    var employmentJoiningDate: Date?
    var creditCardLimit: String?
    var savingsInvestments: String?
    var coApplicantMobile: String?
    var coApplicantPAN: String?
    var coApplicantAadhaar: String?
    var coApplicantIncome: String?
    var autoDebitConsent: Bool?
    var nomineeName: String?
    var nomineeRelation: String?
    var nomineeMobile: String?
    var referenceName: String?
    var referenceMobile: String?
    var emergencyContactName: String?
    var emergencyContactMobile: String?
    var signatureImageData: String?
    var signatureVerificationStatus: String?
    var liveVerificationCompleted: Bool?
    var liveVerificationReference: String?
    var selfieVerificationStatus: String?
    var acceptedTerms: Bool?
    var acceptedBureauConsent: Bool?
    var acceptedDebitConsent: Bool?
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

@MainActor
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
                preferredBranch: app.formData.preferredBranch,
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
                gstNumber: app.formData.gstNumber,
                selectedIdentityDoc: app.formData.selectedIdentityDoc,
                selectedAddressDoc: app.formData.selectedAddressDoc,
                selectedIncomeDoc: app.formData.selectedIncomeDoc,
                draftStepIndex: app.draftStepIndex,
                bankName: app.formData.bankName,
                bankAccountNumber: app.formData.bankAccountNumber,
                bankIFSCCode: app.formData.bankIFSCCode,
                bankRegisteredMobile: app.formData.bankRegisteredMobile,
                monthlySalaryDeposited: app.formData.monthlySalaryDeposited,
                employmentJoiningDate: app.formData.employmentJoiningDate,
                creditCardLimit: app.formData.creditCardLimit,
                savingsInvestments: app.formData.savingsInvestments,
                coApplicantMobile: app.formData.coApplicantMobile,
                coApplicantPAN: app.formData.coApplicantPAN,
                coApplicantAadhaar: app.formData.coApplicantAadhaar,
                coApplicantIncome: app.formData.coApplicantIncome,
                autoDebitConsent: app.formData.autoDebitConsent,
                nomineeName: app.formData.nomineeName,
                nomineeRelation: app.formData.nomineeRelation,
                nomineeMobile: app.formData.nomineeMobile,
                referenceName: app.formData.referenceName,
                referenceMobile: app.formData.referenceMobile,
                emergencyContactName: app.formData.emergencyContactName,
                emergencyContactMobile: app.formData.emergencyContactMobile,
                signatureImageData: app.formData.signatureImageData,
                signatureVerificationStatus: app.formData.signatureVerificationStatus,
                liveVerificationCompleted: app.formData.liveVerificationCompleted,
                liveVerificationReference: app.formData.liveVerificationReference,
                selfieVerificationStatus: app.formData.selfieVerificationStatus,
                acceptedTerms: app.formData.acceptedTerms,
                acceptedBureauConsent: app.formData.acceptedBureauConsent,
                acceptedDebitConsent: app.formData.acceptedDebitConsent
            ),
            documents: app.documents,
            currentStage: app.currentStage.rawValue,
            stageHistory: app.stageHistory.map {
                StoredStageEntry(stage: $0.stage.rawValue, timestamp: $0.timestamp, note: $0.note)
            },
            draftStepIndex: app.draftStepIndex,
            submittedAt: app.submittedAt,
            updatedAt: app.updatedAt,
            assignedQueue: app.assignedQueue,
            assignedOfficerId: app.assignedOfficerId,
            outstandingBalance: app.outstandingBalance,
            upcomingEMI: app.upcomingEMI
        )
    }

    private static func restoreApplication(_ stored: StoredLoanApplication) -> BorrowerLoanApplication? {
        guard let productType = BorrowerLoanProductType(rawValue: stored.productType),
              let currentStage = BorrowerApplicationStage(rawValue: stored.currentStage) else {
            return nil
        }
        
        let product = BorrowerLoanProduct.sampleProducts.first(where: { $0.type == productType }) ?? BorrowerLoanProduct.sampleProducts[0]
        
        let formData = BorrowerLoanFormData(
            fullName: stored.formData.fullName,
            dateOfBirth: stored.formData.dateOfBirth,
            gender: stored.formData.gender ?? "",
            mobileNumber: stored.formData.mobileNumber,
            emailAddress: stored.formData.emailAddress,
            address: stored.formData.address,
            preferredBranch: stored.formData.preferredBranch ?? "",
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
            gstNumber: stored.formData.gstNumber,
            selectedIdentityDoc: stored.formData.selectedIdentityDoc ?? "",
            selectedAddressDoc: stored.formData.selectedAddressDoc ?? "",
            selectedIncomeDoc: stored.formData.selectedIncomeDoc ?? "",
            draftStepIndex: stored.formData.draftStepIndex ?? 1,
            bankName: stored.formData.bankName ?? "",
            bankAccountNumber: stored.formData.bankAccountNumber ?? "",
            bankIFSCCode: stored.formData.bankIFSCCode ?? "",
            bankRegisteredMobile: stored.formData.bankRegisteredMobile ?? "",
            monthlySalaryDeposited: stored.formData.monthlySalaryDeposited ?? "",
            employmentJoiningDate: stored.formData.employmentJoiningDate,
            creditCardLimit: stored.formData.creditCardLimit ?? "",
            savingsInvestments: stored.formData.savingsInvestments ?? "",
            coApplicantMobile: stored.formData.coApplicantMobile ?? "",
            coApplicantPAN: stored.formData.coApplicantPAN ?? "",
            coApplicantAadhaar: stored.formData.coApplicantAadhaar ?? "",
            coApplicantIncome: stored.formData.coApplicantIncome ?? "",
            autoDebitConsent: stored.formData.autoDebitConsent ?? false,
            nomineeName: stored.formData.nomineeName ?? "",
            nomineeRelation: stored.formData.nomineeRelation ?? "",
            nomineeMobile: stored.formData.nomineeMobile ?? "",
            referenceName: stored.formData.referenceName ?? "",
            referenceMobile: stored.formData.referenceMobile ?? "",
            emergencyContactName: stored.formData.emergencyContactName ?? "",
            emergencyContactMobile: stored.formData.emergencyContactMobile ?? "",
            signatureImageData: stored.formData.signatureImageData ?? "",
            signatureVerificationStatus: stored.formData.signatureVerificationStatus ?? "",
            liveVerificationCompleted: stored.formData.liveVerificationCompleted ?? false,
            liveVerificationReference: stored.formData.liveVerificationReference ?? "",
            selfieVerificationStatus: stored.formData.selfieVerificationStatus ?? "",
            acceptedTerms: stored.formData.acceptedTerms ?? false,
            acceptedBureauConsent: stored.formData.acceptedBureauConsent ?? false,
            acceptedDebitConsent: stored.formData.acceptedDebitConsent ?? false
        )
        
        let stageHistory = stored.stageHistory.compactMap { entry -> BorrowerStageEntry? in
            guard let stage = BorrowerApplicationStage(rawValue: entry.stage) else { return nil }
            return BorrowerStageEntry(stage: stage, timestamp: entry.timestamp, note: entry.note)
        }
        
        return BorrowerLoanApplication(
            id: stored.id,
            applicationId: stored.applicationId,
            borrowerId: nil,
            product: product,
            formData: formData,
            documents: stored.documents ?? [],
            currentStage: currentStage,
            stageHistory: stageHistory,
            draftStepIndex: stored.draftStepIndex ?? 1,
            submittedAt: stored.submittedAt,
            updatedAt: stored.updatedAt,
            assignedQueue: stored.assignedQueue,
            assignedOfficerId: stored.assignedOfficerId,
            assignedOfficer: nil,
            outstandingBalance: stored.outstandingBalance,
            upcomingEMI: stored.upcomingEMI
        )
    }
}
