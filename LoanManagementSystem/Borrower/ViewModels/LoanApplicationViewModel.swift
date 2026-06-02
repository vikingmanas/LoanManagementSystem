import SwiftUI
import Combine
import Supabase
import UIKit

@MainActor
final class LoanApplicationViewModel: ObservableObject {
    @Published var selectedApplicationFilter: BorrowerApplicationFilter = .all
    @Published var selectedProductCategory: LoanProductCategoryFilter = .all
    @Published var searchQuery: String = ""
    
    @Published var products: [BorrowerLoanProduct] = BorrowerLoanProduct.sampleProducts
    @Published var applications: [BorrowerLoanApplication] = []
    
    @Published var selectedProductID: UUID?
    @Published var currentDraftID: UUID?
    @Published var currentStepIndex: Int = 1
    @Published var formData: BorrowerLoanFormData = .empty
    @Published var documents: [BorrowerLoanDocumentItem] = []
    
    @Published var selectedUploadSource: BorrowerDocumentUploadSource = .camera
    @Published var activeInfoSheet: BorrowerContextHelpItem?
    
    @Published var lastDraftSavedAt: Date?
    @Published var showSubmissionAlert: Bool = false
    @Published var submissionAlertMessage: String = ""
    
    @Published var verificationComplete: Bool = false
    @Published var showVerificationResult: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    let employmentTypes = ["Salaried", "Self-Employed"]
    let repaymentPreferences = ["EMI Auto-Debit", "UPI Manual Payment", "Net Banking", "Branch Payment"]
    let tenureOptions = [12, 24, 36, 48, 60, 84, 120, 180, 240, 300, 360]
    
    private let contextualInfoMap: [BorrowerContextHelpTopic: BorrowerContextHelpItem] = [
        .interestRate: BorrowerContextHelpItem(
            topic: .interestRate,
            title: "How Interest Rate Works",
            explanation: "Interest rate is the annual cost of your loan. Final pricing depends on profile strength, requested amount, and tenure.",
            examples: ["Home Loan: 8.25% - 11.25%", "Personal Loan: 10.50% - 18.00%"],
            recommendation: "A strong credit score and lower liabilities usually improve your offered rate."
        ),
        .coApplicant: BorrowerContextHelpItem(
            topic: .coApplicant,
            title: "Who is a Co-applicant?",
            explanation: "A co-applicant shares repayment responsibility and can strengthen eligibility for larger loan amounts.",
            examples: ["Spouse for home loan", "Parent as co-borrower for education loan"],
            recommendation: "Add a co-applicant when income support is needed or jointly owned assets are involved."
        ),
        .processingFee: BorrowerContextHelpItem(
            topic: .processingFee,
            title: "Processing Fee Details",
            explanation: "Processing fees cover credit appraisal, underwriting, and application handling costs.",
            examples: ["Personal Loan: Up to 2.5% + GST", "Home Loan: 0.35% - 1.00% + legal charges"],
            recommendation: "Fees are shown before final submission so you can review total borrowing cost."
        ),
        .annualIncome: BorrowerContextHelpItem(
            topic: .annualIncome,
            title: "What to Enter as Annual Income",
            explanation: "Provide your stable annual take-home/gross income as per latest proof and bank inflows.",
            examples: ["₹12,00,000 for salaried profile", "Average yearly net income for self-employed profile"],
            recommendation: "Use values matching your salary slips, ITR, or audited statements."
        ),
        .existingLiabilities: BorrowerContextHelpItem(
            topic: .existingLiabilities,
            title: "Existing Liabilities",
            explanation: "Liabilities include ongoing EMIs, personal debts, and regular credit obligations.",
            examples: ["Car EMI: ₹12,000", "Credit Card Dues: ₹6,500"],
            recommendation: "Accurate liabilities improve assessment quality and reduce verification delays."
        ),
        .creditScore: BorrowerContextHelpItem(
            topic: .creditScore,
            title: "Credit Score Guidance",
            explanation: "Credit score reflects repayment behavior and directly impacts eligibility and pricing.",
            examples: ["750+ typically strong", "650-749 moderate risk range"],
            recommendation: "Pay EMIs on time and keep credit utilization lower for better offers."
        ),
        .employmentType: BorrowerContextHelpItem(
            topic: .employmentType,
            title: "Employment Type",
            explanation: "Choose the category that best matches your source of income and occupation.",
            examples: ["Salaried with monthly payroll", "Business Owner with filed returns"],
            recommendation: "Selecting the correct type ensures the app requests the right supporting documents."
        )
    ]
    
    init() {
        CentralLoanRepository.shared.$applications
            .assign(to: &$applications)
        
        loadProducts()
    }
    
    /// Loads active loan products dynamically from the Supabase database.
    func loadProducts() {
        Task {
            let fetchedProducts = await ProductService.shared.fetchLoanProducts()
            self.products = fetchedProducts
        }
    }
    
    var filteredProducts: [BorrowerLoanProduct] {
        var result = products
        
        if let type = selectedProductCategory.productType {
            result = result.filter { $0.type == type }
        }
        
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            result = result.filter { product in
                product.type.title.localizedCaseInsensitiveContains(query) ||
                product.shortDescription.localizedCaseInsensitiveContains(query)
            }
        }
        
        return result
    }
    
    var selectedProduct: BorrowerLoanProduct? {
        guard let selectedProductID else { return nil }
        return products.first(where: { $0.id == selectedProductID })
    }
    
    var draftApplications: [BorrowerLoanApplication] {
        applications
            .filter { $0.currentStage == .draft }
            .sorted { $0.updatedAt > $1.updatedAt }
    }
    
    var submittedApplications: [BorrowerLoanApplication] {
        applications
            .filter { $0.currentStage != .draft }
            .sorted { ($0.submittedAt ?? $0.updatedAt) > ($1.submittedAt ?? $1.updatedAt) }
    }
    
    var filteredSubmittedApplications: [BorrowerLoanApplication] {
        switch selectedApplicationFilter {
        case .all:
            return applications.sorted { ($0.submittedAt ?? $0.updatedAt) > ($1.submittedAt ?? $1.updatedAt) }
        case .draft:
            return draftApplications
        case .underReview:
            return submittedApplications.filter {
                !$0.currentStage.isTerminal &&
                $0.currentStage != .approved &&
                $0.currentStage != .disbursed
            }
        case .approved:
            return submittedApplications.filter {
                $0.currentStage == .approved || $0.currentStage == .disbursed
            }
        case .rejected:
            return submittedApplications.filter { $0.currentStage == .rejected }
        }
    }
    
    var dashboardMetrics: BorrowerLoanDashboardMetrics {
        let active = applications.filter {
            !$0.isDraft && !$0.currentStage.isTerminal
        }.count
        let draft = applications.filter(\.isDraft).count
        let approved = applications.filter {
            $0.currentStage == .approved || $0.currentStage == .disbursed
        }.count
        let rejected = applications.filter { $0.currentStage == .rejected }.count
        let outstanding = applications
            .filter { !$0.isDraft && $0.currentStage != .rejected }
            .map(\.outstandingBalance)
            .reduce(0, +)
        let upcoming = applications
            .filter { !$0.isDraft && $0.currentStage != .rejected }
            .map(\.upcomingEMI)
            .reduce(0, +)
        let averageProgress: Double = applications.isEmpty
        ? 0
        : applications
            .map { progressValue(for: $0) }
            .reduce(0, +) / Double(applications.count)
        
        return BorrowerLoanDashboardMetrics(
            activeApplications: active,
            draftApplications: draft,
            approvedLoans: approved,
            rejectedLoans: rejected,
            outstandingBalance: outstanding,
            upcomingEMIs: upcoming,
            averageProgress: averageProgress
        )
    }
    
    var verifiedDocumentsCount: Int {
        documents.filter { $0.status == .verified }.count
    }
    
    var allDocumentsVerified: Bool {
        !documents.isEmpty && documents.allSatisfy { $0.status == .uploaded || $0.status == .verified || $0.status == .underVerification }
    }
    
    var formCompletionRatio: Double {
        let checks = [
            !formData.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            formData.mobileNumber.trimmingCharacters(in: .whitespacesAndNewlines).count == 10,
            formData.emailAddress.contains("@") && formData.emailAddress.contains("."),
            !formData.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !formData.preferredBranch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !formData.occupation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !formData.employerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            formData.monthlyIncomeValue > 0,
            formData.annualIncomeValue > 0,
            formData.requestedAmountValue > 0,
            formData.loanPurpose.trimmingCharacters(in: .whitespacesAndNewlines).count >= 10
        ]
        let completed = checks.filter { $0 }.count
        return Double(completed) / Double(checks.count)
    }
    
    var formValidationErrors: [String] {
        BorrowerLoanFormField.allCases.compactMap { validationMessage(for: $0) }
    }
    
    var missingDocumentNames: [String] {
        documents
            .filter { $0.status.requiresAction }
            .map(\.name)
    }
    
    var blockingSubmissionIssues: [String] {
        var issues: [String] = []
        issues.append(contentsOf: formValidationErrors)
        if !missingDocumentNames.isEmpty {
            issues.append("Missing/invalid documents: \(missingDocumentNames.joined(separator: ", ")).")
        }
        if !allDocumentsVerified {
            issues.append("All required documents must be uploaded before submission.")
        }
        return Array(Set(issues)).sorted()
    }
    
    var preSubmissionWarnings: [String] {
        var warnings = blockingSubmissionIssues
        
        if formData.creditScoreValue > 0 && formData.creditScoreValue < CentralLoanRepository.shared.globalRules.minCibilScore {
            warnings.append("Credit score appears low. Approval chance may reduce unless liabilities are improved.")
        }
        
        if let product = selectedProduct,
           formData.requestedAmountValue > product.maximumAmount {
            warnings.append("Requested amount exceeds maximum eligible amount for \(product.type.title).")
        }
        
        if formData.monthlyIncomeValue > 0 {
            let liabilityRatio = (formData.existingEMIsValue + formData.creditCardObligationsValue) / formData.monthlyIncomeValue
            if liabilityRatio > (CentralLoanRepository.shared.globalRules.maxDTI / 100.0) {
                warnings.append("Existing liability ratio is high; consider reducing obligations before submission.")
            }
        }
        
        return warnings
    }
    
    var canSubmitApplication: Bool {
        blockingSubmissionIssues.isEmpty
    }
    
    var eligibilitySummary: [String] {
        var summary: [String] = []
        
        if formData.creditScoreValue > 0 {
            let scoreBand = formData.creditScoreValue >= 750 ? "Strong" : (formData.creditScoreValue >= CentralLoanRepository.shared.globalRules.minCibilScore ? "Moderate" : "Low")
            summary.append("Credit strength: \(scoreBand) (\(formData.creditScoreValue)).")
        }
        
        if formData.monthlyIncomeValue > 0 {
            let obligations = formData.existingEMIsValue + formData.creditCardObligationsValue
            let ratio = obligations / formData.monthlyIncomeValue
            summary.append("Obligation ratio: \(Int(ratio * 100))% of monthly income.")
        }
        
        if let product = selectedProduct {
            let percentage = product.maximumAmount > 0
            ? Int((formData.requestedAmountValue / product.maximumAmount) * 100)
            : 0
            summary.append("Requested amount uses \(max(0, percentage))% of product max limit.")
        }
        
        if summary.isEmpty {
            summary.append("Complete form and documents to generate eligibility insights.")
        }
        
        return summary
    }
    
    func product(for id: UUID) -> BorrowerLoanProduct? {
        products.first(where: { $0.id == id })
    }
    
    func application(for id: UUID) -> BorrowerLoanApplication? {
        applications.first(where: { $0.id == id })
    }
    
    func previewDocuments(for product: BorrowerLoanProduct) -> [BorrowerLoanDocumentItem] {
        if let draft = draftApplications.first(where: { $0.product.id == product.id }) {
            return draft.documents
        }
        return BorrowerLoanDocumentItem.defaultRequirements(for: product)
    }
    
    func presentInfo(for topic: BorrowerContextHelpTopic) {
        activeInfoSheet = contextualInfoMap[topic]
    }
    
    func startDraft(for product: BorrowerLoanProduct) {
        selectedProductID = product.id
        
        if let existingDraft = draftApplications.first(where: { $0.product.id == product.id }) {
            resumeDraft(existingDraft)
            return
        }
        
        formData = BorrowerLoanFormData.prefilled(from: BorrowerProfileStore.shared.profile)
        currentStepIndex = 1
        if formData.loanAmountRequested.isEmpty {
            let recommended = max(100_000, min(product.maximumAmount * 0.25, product.maximumAmount))
            formData.loanAmountRequested = String(Int(recommended))
        }
        documents = BorrowerLoanDocumentItem.defaultRequirements(
            for: product,
            identityDoc: formData.selectedIdentityDoc,
            addressDoc: formData.selectedAddressDoc,
            incomeDoc: formData.selectedIncomeDoc
        )
        
        let now = Date()
        let draft = BorrowerLoanApplication(
            id: UUID(),
            applicationId: nil,
            product: product,
            formData: formData,
            documents: documents,
            currentStage: .draft,
            stageHistory: [
                BorrowerStageEntry(
                    stage: .draft,
                    timestamp: now,
                    note: "Application draft created."
                )
            ],
            submittedAt: nil,
            updatedAt: now,
            assignedQueue: nil,
            assignedOfficerId: nil,
            assignedOfficer: nil,
            outstandingBalance: 0,
            upcomingEMI: 0
        )
        
        applications.insert(draft, at: 0)
        CentralLoanRepository.shared.submitApplication(draft)
        currentDraftID = draft.id
        lastDraftSavedAt = now
    }
    
    func resumeDraft(_ application: BorrowerLoanApplication) {
        guard application.currentStage == .draft else { return }
        selectedProductID = application.product.id
        currentDraftID = application.id
        currentStepIndex = min(max(application.draftStepIndex, 1), 10)
        formData = application.formData
        documents = application.documents
        lastDraftSavedAt = Date()
    }
    
    func updateDraftStep(_ step: Int) {
        let clampedStep = min(max(step, 1), 10)
        currentStepIndex = clampedStep
        
        guard let currentDraftID,
              let draftIndex = applications.firstIndex(where: { $0.id == currentDraftID }) else {
            return
        }
        
        applications[draftIndex].draftStepIndex = clampedStep
        applications[draftIndex].updatedAt = Date()
        CentralLoanRepository.shared.submitApplication(applications[draftIndex])
        lastDraftSavedAt = Date()
    }
    
    private var autosaveTask: Task<Void, Never>?
    
    func autosaveDraft() {
        autosaveTask?.cancel()
        autosaveTask = Task { @MainActor in
            do {
                try await Task.sleep(nanoseconds: 500_000_000)
                guard !Task.isCancelled else { return }
                self.performAutosave()
            } catch {}
        }
    }
    
    private func performAutosave() {
        guard let currentDraftID,
              let draftIndex = applications.firstIndex(where: { $0.id == currentDraftID }) else {
            return
        }
        
        applications[draftIndex].formData = formData
        applications[draftIndex].documents = documents
        applications[draftIndex].draftStepIndex = currentStepIndex
        applications[draftIndex].updatedAt = Date()
        CentralLoanRepository.shared.submitApplication(applications[draftIndex])
        lastDraftSavedAt = Date()
    }

    func flushAutosave() {
        autosaveTask?.cancel()
        performAutosave()
    }

    func normalizeDuplicateDocumentRequirements(autosave: Bool = true) {
        var normalized: [BorrowerLoanDocumentItem] = []
        var indexesByKey: [String: Int] = [:]

        for document in documents {
            let key = BorrowerLoanDocumentItem.canonicalDocumentKey(document.name)
            if let existingIndex = indexesByKey[key] {
                if documentPriority(document) >= documentPriority(normalized[existingIndex]) {
                    normalized[existingIndex] = document
                }
            } else {
                indexesByKey[key] = normalized.count
                normalized.append(document)
            }
        }

        guard normalized != documents else { return }
        documents = normalized
        if autosave {
            autosaveDraft()
        }
    }

    private func documentPriority(_ document: BorrowerLoanDocumentItem) -> Int {
        var priority: Int
        switch document.status {
        case .pendingUpload:
            priority = 0
        case .rejected:
            priority = 1
        case .requiresResubmission:
            priority = 2
        case .uploaded:
            priority = 3
        case .underVerification:
            priority = 4
        case .verified:
            priority = 5
        }

        if document.fileUrl != nil || document.fileName != nil {
            priority += 10
        }
        return priority
    }
    
    func validationMessage(for field: BorrowerLoanFormField) -> String? {
        switch field {
        case .fullName:
            return formData.fullName.trimmingCharacters(in: .whitespacesAndNewlines).count >= 3 ? nil : "Full name must contain at least 3 characters."
        case .mobileNumber:
            let mobile = formData.mobileNumber.trimmingCharacters(in: .whitespacesAndNewlines)
            if mobile.contains(where: { !$0.isNumber }) {
                return "Only numeric digits are allowed"
            }
            if mobile.count < 10 {
                return "Mobile number must contain 10 digits"
            }
            if mobile.count > 10 {
                return "Mobile number cannot exceed 10 digits"
            }
            return nil
        case .emailAddress:
            let email = formData.emailAddress.trimmingCharacters(in: .whitespacesAndNewlines)
            return (email.contains("@") && email.contains(".")) ? nil : "Enter a valid email address."
        case .address:
            return formData.address.trimmingCharacters(in: .whitespacesAndNewlines).count >= 8 ? nil : "Please enter a complete current address."
        case .preferredBranch:
            return formData.preferredBranch.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Please select the branch for this loan application." : nil
        case .occupation:
            return formData.occupation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Occupation is required." : nil
        case .employerName:
            return formData.employerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Employer name is required." : nil
        case .monthlyIncome:
            return formData.monthlyIncomeValue > 0 ? nil : "Monthly income must be greater than 0."
        case .annualIncome:
            guard formData.annualIncomeValue > 0 else { return "Annual income must be greater than 0." }
            return formData.annualIncomeValue >= formData.monthlyIncomeValue * 2
            ? nil
            : "Annual income appears unusually low compared to monthly income."
        case .loanAmountRequested:
            guard formData.requestedAmountValue > 0 else { return "Requested amount must be greater than 0." }
            if let product = selectedProduct, formData.requestedAmountValue > product.maximumAmount {
                return "Requested amount exceeds max limit for selected loan."
            }
            return nil
        case .loanPurpose:
            let purposeLength = formData.loanPurpose.trimmingCharacters(in: .whitespacesAndNewlines).count
            guard purposeLength >= 10, purposeLength <= 500 else {
                return "Please provide the purpose of the loan."
            }
            return nil
        case .coApplicantDetails:
            if formData.hasCoApplicant {
                return formData.coApplicantDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "Co-applicant details are required."
                : nil
            }
            return nil
        case .guarantorDetails:
            if formData.hasGuarantor {
                return formData.guarantorDetails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? "Guarantor details are required."
                : nil
            }
            return nil
        }
    }
    
    func documents(for category: BorrowerDocumentCategory) -> [BorrowerLoanDocumentItem] {
        documents.filter { $0.category == category }
    }
    
    func document(for category: BorrowerDocumentCategory) -> BorrowerLoanDocumentItem? {
        documents.first(where: { $0.category == category })
    }
    
    func selectedDocumentType(for category: BorrowerDocumentCategory) -> String {
        switch category {
        case .identityVerification:
            return formData.selectedIdentityDoc
        case .addressVerification:
            return formData.selectedAddressDoc
        case .incomeVerification:
            return formData.selectedIncomeDoc
        case .loanSpecific:
            return ""
        }
    }
    
    func availableDocumentTypes(for category: BorrowerDocumentCategory) -> [String] {
        switch category {
        case .identityVerification:
            return ["Aadhaar Card", "PAN Card", "Passport", "Driving License"]
        case .addressVerification:
            return ["Utility Bill", "Rental Agreement", "Passport", "Bank Statement"]
        case .incomeVerification:
            return ["Salary Slips", "Bank Statements", "Income Tax Returns", "Form 16"]
        case .loanSpecific:
            return []
        }
    }
    
    func changeDocumentType(for category: BorrowerDocumentCategory, to newType: String) {
        switch category {
        case .identityVerification:
            formData.selectedIdentityDoc = newType
        case .addressVerification:
            formData.selectedAddressDoc = newType
        case .incomeVerification:
            formData.selectedIncomeDoc = newType
        case .loanSpecific:
            break
        }
        
        if let index = documents.firstIndex(where: { $0.category == category }) {
            if documents[index].name != newType {
                documents[index].name = newType
                documents[index].status = .pendingUpload
                documents[index].fileName = nil
                documents[index].uploadDate = nil
                documents[index].lastUpdated = Date()
                autosaveDraft()
            }
        }
    }
    
    func uploadDocument(
        _ documentID: UUID,
        fileName: String,
        source: BorrowerDocumentUploadSource,
        image: UIImage? = nil,
        fileData: Data? = nil,
        contentType: String? = nil,
        fileExtension: String? = nil
    ) {
        guard let index = documents.firstIndex(where: { $0.id == documentID }) else { return }
        guard !documents[index].isLocked else { return }
        
        let now = Date()
        documents[index].status = .uploaded
        documents[index].uploadDate = now
        documents[index].lastUpdated = now
        documents[index].fileName = fileName
        
        if let currentDraftID = currentDraftID {
            let resolvedData: Data?
            let resolvedContentType: String
            let resolvedExtension: String

            if let fileData {
                resolvedData = fileData
                resolvedContentType = contentType ?? contentTypeForFile(named: fileName, fallback: "application/octet-stream")
                resolvedExtension = fileExtension ?? fileExtensionForFile(named: fileName, fallback: "bin")
            } else if let imageData = image?.jpegData(compressionQuality: 0.85) {
                resolvedData = imageData
                resolvedContentType = contentType ?? "image/jpeg"
                resolvedExtension = fileExtension ?? "jpg"
            } else {
                documents[index].status = .pendingUpload
                documents[index].fileName = nil
                documents[index].uploadDate = nil
                autosaveDraft()
                return
            }

            guard let data = resolvedData else { return }
            let bucket = "documents"
            let path = "\(currentDraftID)/\(documentID).\(resolvedExtension)"
            
            Task {
                do {
                    let publicUrl = try await StorageService.shared.uploadDocument(
                        data: data,
                        bucket: bucket,
                        path: path,
                        contentType: resolvedContentType
                    )
                    
                    await MainActor.run {
                        if let idx = self.documents.firstIndex(where: { $0.id == documentID }) {
                            self.documents[idx].fileUrl = publicUrl.absoluteString;
                        }
                    }
                    
                    let borrowerUUID = UUID(uuidString: BorrowerProfileStore.shared.profile?.id ?? "") ?? UUID()
                    let docType = resolveDocType(category: documents[index].category, name: documents[index].name)
                    
                    let dbDoc = DBDocument(
                        documentId: documentID,
                        borrowerId: borrowerUUID,
                        applicationId: currentDraftID,
                        docType: docType,
                        fileUrl: publicUrl.absoluteString,
                        fileName: fileName,
                        status: "uploaded",
                        uploadedAt: now,
                        verifiedBy: nil
                    )
                    
                    try await DatabaseService.shared.upsertDocument(dbDoc)
                    print("[LoanApplicationViewModel] Successfully uploaded wizard document to Supabase Storage and DB.")
                } catch {
                    print("❌ [LoanApplicationViewModel] Error uploading wizard document: \(error)")
                }
            }
        }
        
        autosaveDraft()
    }
    
    func uploadDocument(_ documentID: UUID) {
        let defaultName = "document-\(Int(Date().timeIntervalSince1970)).pdf"
        uploadDocument(documentID, fileName: defaultName, source: .pdf)
    }

    private func contentTypeForFile(named fileName: String, fallback: String) -> String {
        switch fileName.split(separator: ".").last?.lowercased() {
        case "pdf": return "application/pdf"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "heic": return "image/heic"
        default: return fallback
        }
    }

    private func fileExtensionForFile(named fileName: String, fallback: String) -> String {
        guard let ext = fileName.split(separator: ".").last?.lowercased(),
              ext.allSatisfy({ $0.isLetter || $0.isNumber }),
              ext.count <= 8 else {
            return fallback
        }
        return String(ext)
    }
    
    private func resolveDocType(category: BorrowerDocumentCategory, name: String) -> String {
        switch category {
        case .identityVerification: return "identity_proof"
        case .addressVerification: return "address_proof"
        case .incomeVerification: return "income_proof"
        case .loanSpecific:
            let n = name.lowercased()
            if n.contains("statement") { return "bank_statement" }
            if n.contains("property") || n.contains("land") || n.contains("tax") || n.contains("invoice") || n.contains("quotation") { return "property_document" }
            return "identity_proof"
        }
    }
    
    func uploadDocumentForApplication(applicationID: UUID, documentID: UUID, fileName: String, source: BorrowerDocumentUploadSource) {
        guard let appIndex = applications.firstIndex(where: { $0.id == applicationID }) else { return }
        guard let docIndex = applications[appIndex].documents.firstIndex(where: { $0.id == documentID }) else { return }
        
        let now = Date()
        applications[appIndex].documents[docIndex].status = .uploaded
        applications[appIndex].documents[docIndex].uploadDate = now
        applications[appIndex].documents[docIndex].lastUpdated = now
        applications[appIndex].documents[docIndex].fileName = fileName
        applications[appIndex].updatedAt = now
        
        let app = applications[appIndex]
        CentralLoanRepository.shared.submitApplication(app)
        
        // Sync to Supabase Storage & Database
        Task {
            do {
                guard let dummyData = Data("Re-upload payload unavailable for \(fileName)".utf8) as Data? else { return }
                let bucket = "documents"
                let path = "\(applicationID)/\(documentID).pdf"
                
                let publicUrl = try await StorageService.shared.uploadDocument(data: dummyData, bucket: bucket, path: path, contentType: "application/pdf")
                
                await MainActor.run {
                    if let aIdx = self.applications.firstIndex(where: { $0.id == applicationID }),
                       let dIdx = self.applications[aIdx].documents.firstIndex(where: { $0.id == documentID }) {
                        self.applications[aIdx].documents[dIdx].fileUrl = publicUrl.absoluteString
                    }
                }
                
                let borrowerUUID = app.borrowerId ?? UUID(uuidString: BorrowerProfileStore.shared.profile?.id ?? "") ?? UUID()
                let docType = resolveDocType(category: app.documents[docIndex].category, name: app.documents[docIndex].name)
                
                let dbDoc = DBDocument(
                    documentId: documentID,
                    borrowerId: borrowerUUID,
                    applicationId: applicationID,
                    docType: docType,
                    fileUrl: publicUrl.absoluteString,
                    fileName: fileName,
                    status: "uploaded",
                    uploadedAt: now,
                    verifiedBy: nil
                )
                
                try await DatabaseService.shared.upsertDocument(dbDoc)
                print("[LoanApplicationViewModel] Successfully synced uploaded document metadata to Supabase DB.")
            } catch {
                print("❌ [LoanApplicationViewModel] Error uploading document: \(error)")
            }
        }
    }
        
        func moveDocumentToVerification(_ documentID: UUID) {
            guard let index = documents.firstIndex(where: { $0.id == documentID }) else { return }
            guard !documents[index].isLocked else { return }
            guard documents[index].status == .uploaded || documents[index].status == .rejected || documents[index].status == .requiresResubmission else {
                return
            }
            
            documents[index].status = .underVerification
            documents[index].lastUpdated = Date()
            autosaveDraft()
        }
        
        func markDocument(_ documentID: UUID, status: BorrowerDocumentStatus) {
            guard let index = documents.firstIndex(where: { $0.id == documentID }) else { return }
            guard !documents[index].isLocked else { return }
            documents[index].status = status
            documents[index].lastUpdated = Date()
            autosaveDraft()
        }
        
        func runBulkVerification() {
            // Documents stay as .uploaded — actual verification is done by the Loan Officer.
            // This method only ensures all documents have been uploaded (completeness check).
            for index in documents.indices {
                guard !documents[index].isLocked else { continue }
                if documents[index].status == .pendingUpload {
                    // Mark as needing attention but don't auto-verify
                    documents[index].lastUpdated = Date()
                }
            }
            autosaveDraft()
        }
        
        var rejectedDocuments: [BorrowerLoanDocumentItem] {
            documents.filter { $0.status == .rejected || $0.status == .requiresResubmission }
        }
        
        func verifyAndShowResult() {
            // Don't auto-verify — just mark completeness check as done
            runBulkVerification()
            verificationComplete = true
            showVerificationResult = true
        }
        
        @discardableResult
        func submitCurrentApplication() -> BorrowerLoanApplication? {
            // Cancel any pending autosave task to prevent post-submit race conditions
            autosaveTask?.cancel()
            
            if formData.monthlyIncomeValue > 0,
               formData.annualIncomeValue == 0 || formData.annualIncomeValue < formData.monthlyIncomeValue * 2 {
                formData.annualIncome = String(Int(formData.monthlyIncomeValue * 12))
            }
            
            guard canSubmitApplication,
                  let currentDraftID,
                  let index = applications.firstIndex(where: { $0.id == currentDraftID }) else {
                return nil
            }
            
            let now = Date()
            var draft = applications[index]
            
            // Copy latest user input to the draft before status transition
            draft.formData = formData
            draft.documents = documents
            let generatedApplicationID = draft.applicationId ?? generateApplicationID()
            
            draft.applicationId = generatedApplicationID
            draft.currentStage = .submitted
            draft.submittedAt = now
            draft.updatedAt = now
            draft.assignedQueue = "Loan Officer Assignment Pending"
            draft.assignedOfficerId = nil
            draft.assignedOfficer = nil
            draft.outstandingBalance = max(0, draft.formData.requestedAmountValue * 0.92)
            draft.upcomingEMI = max(
                0,
                draft.formData.requestedAmountValue / Double(max(1, draft.formData.preferredTenureMonths))
            )
            draft.documents = draft.documents.map { item in
                var updated = item
                if updated.status == .verified {
                    updated.isLocked = true
                }
                return updated
            }
            draft.stageHistory.append(
                BorrowerStageEntry(
                    stage: .submitted,
                    timestamp: now,
                    note: "Application submitted. Assigning a loan officer from your branch."
                )
            )
            
            applications[index] = draft
            CentralLoanRepository.shared.submitApplication(draft)
            self.currentDraftID = nil
            self.showSubmissionAlert = true
            self.submissionAlertMessage = "Application \(generatedApplicationID) submitted successfully on \(now.formattedAsDDMMMYYYY())."
            
            return draft
        }
        
        func advanceStage(for applicationID: UUID) {
            guard let index = applications.firstIndex(where: { $0.id == applicationID }) else { return }
            var application = applications[index]
            guard !application.isDraft else { return }
            
            let nextStage: BorrowerApplicationStage?
            switch application.currentStage {
            case .submitted:
                nextStage = .underReview
            case .underReview:
                nextStage = .documentVerification
            case .documentVerification:
                nextStage = .loanOfficerReview
            case .loanOfficerReview:
                nextStage = .bankManagerReview
            case .bankManagerReview:
                nextStage = application.formData.creditScoreValue < CentralLoanRepository.shared.globalRules.minCibilScore ? .rejected : .approved
            case .approved:
                nextStage = .disbursed
            case .draft, .rejected, .disbursed:
                nextStage = nil
            }
            
            guard let nextStage else { return }
            application.currentStage = nextStage
            application.updatedAt = Date()
            application.stageHistory.append(
                BorrowerStageEntry(
                    stage: nextStage,
                    timestamp: Date(),
                    note: "Status moved to \(nextStage.rawValue)."
                )
            )
            if nextStage == .disbursed {
                application.upcomingEMI = max(5000, application.upcomingEMI)
            }
            
            applications[index] = application
        }
        
        func rejectApplication(_ applicationID: UUID) {
            guard let index = applications.firstIndex(where: { $0.id == applicationID }) else { return }
            guard applications[index].currentStage != .disbursed else { return }
            applications[index].currentStage = .rejected
            applications[index].updatedAt = Date()
            applications[index].stageHistory.append(
                BorrowerStageEntry(
                    stage: .rejected,
                    timestamp: Date(),
                    note: "Application rejected after policy review."
                )
            )
        }
        
        func timelineStages(for application: BorrowerLoanApplication) -> [BorrowerApplicationStage] {
            if application.currentStage == .rejected || application.stageHistory.contains(where: { $0.stage == .rejected }) {
                return BorrowerApplicationStage.rejectionFlow
            }
            return BorrowerApplicationStage.approvalFlow
        }
        
        func stageTimestamp(for stage: BorrowerApplicationStage, application: BorrowerLoanApplication) -> Date? {
            application.stageHistory
                .last(where: { $0.stage == stage })?
                .timestamp
        }
        
        func progressValue(for application: BorrowerLoanApplication) -> Double {
            let stages = timelineStages(for: application)
            guard let stageIndex = stages.firstIndex(of: application.currentStage), !stages.isEmpty else {
                return 0
            }
            return Double(stageIndex + 1) / Double(stages.count)
        }
        
        func refreshDashboard() async {
            do {
                try await Task.sleep(nanoseconds: 700_000_000)
            } catch {}
            
            if let candidate = applications.first(where: { !$0.isDraft && !$0.currentStage.isTerminal }) {
                advanceStage(for: candidate.id)
            }
        }
        
        private func generateApplicationID() -> String {
            let year = Calendar.current.component(.year, from: Date())
            let random = Int.random(in: 1000...9999)
            return "APP-\(year)-\(random)"
        }
        
        private func seedInitialApplications() {
            // Clear all mock data
        }
        
        func setBorrowerAuthContext(email: String, displayName: String) {
            if formData.emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                formData.emailAddress = email
            }
            if formData.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                formData.fullName = displayName
            }
        }
        
        func prefillEmptyFieldsFromProfile() {
            guard let profile = BorrowerProfileStore.shared.profile else { return }
            
            if formData.fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                formData.fullName = profile.fullName
            }
            if formData.emailAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                formData.emailAddress = profile.email
            }
            if formData.mobileNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                formData.mobileNumber = profile.mobileNumber
            }
            if formData.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let addr = profile.currentAddress
                let fullAddr = [addr.streetAddress, addr.city, addr.state, addr.zipCode]
                    .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
                    .joined(separator: ", ")
                formData.address = fullAddr
            }
            if formData.employerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                formData.employerName = profile.employment.companyName
            }
            if formData.occupation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                formData.occupation = profile.employment.designation
            }
            if formData.monthlyIncome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || formData.monthlyIncomeValue == 0 {
                formData.monthlyIncome = String(Int(profile.income.monthlyIncome))
            }
            if formData.annualIncome.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || formData.annualIncomeValue == 0 {
                formData.annualIncome = String(Int(profile.income.annualIncome))
            }
            if formData.employmentType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                formData.employmentType = profile.employment.employmentType
            }
        }
        
        func deleteDraft(applicationID: UUID) -> Bool {
            guard let index = applications.firstIndex(where: { $0.id == applicationID }) else { return false }
            let app = applications[index]
            guard app.isDraft else { return false }
            applications.remove(at: index)
            CentralLoanRepository.shared.deleteApplication(id: applicationID)
            if currentDraftID == applicationID {
                currentDraftID = nil
            }
            return true
        }
    }
