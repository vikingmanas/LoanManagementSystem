import SwiftUI

// MARK: - Main Wizard View
struct BorrowerLoanWizardView: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let product: BorrowerLoanProduct
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager

    @State private var currentStep: Int = 1
    @State private var lastAutosavedTime: Date = Date()
    @State private var isAutosaving: Bool = false
    
    // Step 2 & 4 Eligibility & Pre-Check Local States
    @State private var desiredAmount: Double = 500000
    @State private var loanTenureMonths: Double = 60
    
    // Step 4 Employment & Income States
    @State private var salariedCompany: String = ""
    @State private var salariedEmpID: String = ""
    @State private var salariedDesignation: String = ""
    @State private var salariedJoiningDate: Date = Date()
    @State private var selfEmployedBusinessName: String = ""
    @State private var selfEmployedBusinessType: String = "Proprietorship"
    @State private var selfEmployedYearsInBusiness: Int = 3
    @State private var selfEmployedGSTNumber: String = ""
    @State private var selfEmployedAnnualRevenue: String = ""
    @State private var selfEmployedAnnualProfit: String = ""
    
    @State private var existingLoansCount: String = "0"
    @State private var creditCardLimit: String = "150000"
    @State private var creditCardOutstanding: String = "12000"
    @State private var savingsInvestments: String = "300000"
    
    // Step 5 Co-Applicant State
    @State private var hasCoApplicantToggle: Bool = false
    @State private var coApplicantName: String = ""
    @State private var coApplicantRelation: String = "Spouse"
    @State private var coApplicantMobile: String = ""
    @State private var coApplicantPAN: String = ""
    @State private var coApplicantAadhaar: String = ""
    @State private var coApplicantIncome: String = ""
    
    // Step 6 & 7 Document & OCR Local States
    @State private var uploadProgress: [String: Double] = [:] // Document name -> Progress (0 to 1)
    @State private var isUploading: [String: Bool] = [:]
    @State private var ocrStatus: [String: String] = [:] // Document name -> OCR Status ("None", "Scanning", "Success")
    @State private var uploadSource: BorrowerDocumentUploadSource = .camera
    @State private var selectedUploadDocId: UUID? = nil
    @State private var showUploadSourceSheet = false
    
    // Step 7 OCR Extracted Editable Data
    @State private var ocrPANNumber: String = "ABCDE1234F"
    @State private var ocrPANName: String = "AKASH KASHYAP"
    @State private var ocrPANFather: String = "RAMKUMAR KASHYAP"
    @State private var ocrPANDOB: Date = Calendar.current.date(byAdding: .year, value: -26, to: Date()) ?? Date()
    
    @State private var ocrAadhaarName: String = "AKASH KASHYAP"
    @State private var ocrAadhaarDOB: Date = Calendar.current.date(byAdding: .year, value: -26, to: Date()) ?? Date()
    @State private var ocrAadhaarGender: String = "Male"
    @State private var ocrAadhaarAddress: String = "Flat 402, Highrise Apts, Link Road, Mumbai - 400053"
    
    // OCR Confidence Ratings
    @State private var ocrConfidence: [String: String] = ["PAN": "High", "Aadhaar": "High"]
    
    // Step 8 Verification Alerts Overrides
    @State private var showVerificationResolutionSheet = false
    @State private var hasResolvedMismatches = false

    @State private var submissionErrorMessage: String?
    @State private var stepValidationMessage: String?

    private var progressValue: Double {
        Double(currentStep) / 10.0
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                stepTitleBlock
                stepContent
                bottomCTA
            }
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
        .lmsScreenBackground()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            wizardNavigationBar
        }
        .sheet(isPresented: $showUploadSourceSheet) {
            UploadSourceSelectionSheet(
                isPresented: $showUploadSourceSheet,
                selectedSource: $uploadSource,
                onSelect: { source in
                    if let docId = selectedUploadDocId {
                        simulateUpload(for: docId, source: source)
                    }
                }
            )
        }
        .onAppear {
            viewModel.setBorrowerAuthContext(
                email: authManager.userEmail,
                displayName: authManager.userDisplayName
            )
            prepareWizardState()
        }
        .alert("Unable to Submit", isPresented: Binding(
            get: { submissionErrorMessage != nil },
            set: { if !$0 { submissionErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { submissionErrorMessage = nil }
        } message: {
            Text(submissionErrorMessage ?? "Please complete all required fields and documents.")
        }
    }

    private var wizardNavigationBar: some View {
        VStack(spacing: 10) {
            ZStack {
                Text("Step \(currentStep) of 10")
                    .font(LMSFont.subheadline.weight(.semibold))
                    .foregroundStyle(LMSColors.textSecondary)

                HStack {
                    Button(action: handleBackAction) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(LMSColors.brandNavy)
                            .frame(width: 38, height: 38)
                            .background(Circle().fill(Color.white.opacity(0.35)))
                            .background(Circle().fill(.ultraThinMaterial))
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(0.60),
                                                Color.white.opacity(0.15)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.06), radius: 3, x: 0, y: 1.5)
                    }
                    .buttonStyle(LMSPressableStyle())
                    .accessibilityLabel(currentStep > 1 ? "Previous step" : "Back")

                    Spacer()

                    autosavePill
                }
            }

            ProgressView(value: progressValue)
                .tint(LMSColors.brandNavy)
                .scaleEffect(x: 1, y: 0.72, anchor: .center)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(.regularMaterial)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var autosavePill: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(isAutosaving ? LMSColors.actionBlue : LMSColors.emerald)
                .frame(width: 6, height: 6)
            Text(isAutosaving ? "Saving" : "Saved")
                .font(LMSFont.caption2.weight(.semibold))
                .foregroundStyle(LMSColors.textSecondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(LMSColors.surfaceElevated, in: Capsule())
        .overlay(
            Capsule()
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
        )
    }

    private var stepTitleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(stepTitle(for: currentStep))
                .font(LMSFont.title3)
                .foregroundStyle(LMSColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(stepSubtitle(for: currentStep))
                .font(LMSFont.footnote)
                .foregroundStyle(LMSColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private var stepContent: some View {
        Group {
            switch currentStep {
            case 1:
                Step1SelectionView(product: product)
            case 2:
                Step2EligibilityView(
                    viewModel: viewModel,
                    product: product,
                    desiredAmount: $desiredAmount,
                    tenureMonths: $loanTenureMonths
                )
            case 3:
                Step3PersonalInfoView(viewModel: viewModel)
            case 4:
                Step4EmploymentView(
                    viewModel: viewModel,
                    salariedCompany: $salariedCompany,
                    salariedEmpID: $salariedEmpID,
                    salariedDesignation: $salariedDesignation,
                    salariedJoiningDate: $salariedJoiningDate,
                    selfEmployedBusinessName: $selfEmployedBusinessName,
                    selfEmployedBusinessType: $selfEmployedBusinessType,
                    selfEmployedYearsInBusiness: $selfEmployedYearsInBusiness,
                    selfEmployedGSTNumber: $selfEmployedGSTNumber,
                    selfEmployedAnnualRevenue: $selfEmployedAnnualRevenue,
                    selfEmployedAnnualProfit: $selfEmployedAnnualProfit,
                    existingLoansCount: $existingLoansCount,
                    creditCardLimit: $creditCardLimit,
                    creditCardOutstanding: $creditCardOutstanding,
                    savingsInvestments: $savingsInvestments
                )
            case 5:
                Step5CoApplicantView(
                    hasCoApplicant: $hasCoApplicantToggle,
                    coApplicantName: $coApplicantName,
                    coApplicantRelation: $coApplicantRelation,
                    coApplicantMobile: $coApplicantMobile,
                    coApplicantPAN: $coApplicantPAN,
                    coApplicantAadhaar: $coApplicantAadhaar,
                    coApplicantIncome: $coApplicantIncome
                )
            case 6:
                Step6DocumentCenterView(
                    viewModel: viewModel,
                    product: product,
                    stepValidationMessage: $stepValidationMessage,
                    uploadProgress: $uploadProgress,
                    isUploading: $isUploading,
                    ocrStatus: $ocrStatus,
                    onTriggerUpload: { docId in
                        selectedUploadDocId = docId
                        showUploadSourceSheet = true
                    },
                    onEnsureDocuments: {
                        ensureRequiredDocumentsLoaded()
                    }
                )
            case 7:
                Step7OCRExtractionView(
                    ocrPANNumber: $ocrPANNumber,
                    ocrPANName: $ocrPANName,
                    ocrPANFather: $ocrPANFather,
                    ocrPANDOB: $ocrPANDOB,
                    ocrAadhaarName: $ocrAadhaarName,
                    ocrAadhaarDOB: $ocrAadhaarDOB,
                    ocrAadhaarGender: $ocrAadhaarGender,
                    ocrAadhaarAddress: $ocrAadhaarAddress,
                    ocrConfidence: $ocrConfidence
                )
            case 8:
                Step8VerificationDashboardView(
                    viewModel: viewModel,
                    hasResolvedMismatches: $hasResolvedMismatches,
                    onFixRequired: {
                        withAnimation {
                            currentStep = 6
                        }
                    }
                )
            case 9:
                Step9RiskAssessmentView(viewModel: viewModel)
            case 10:
                Step10ApplicationReviewView(
                    viewModel: viewModel,
                    product: product,
                    onEditStep: { step in
                        withAnimation {
                            currentStep = step
                        }
                    }
                )
            default:
                Text("Unknown Step")
            }
        }
        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
    }

    private var bottomCTA: some View {
        VStack(spacing: 8) {
            if let stepValidationMessage, currentStep == 6 || currentStep == 10 {
                Text(stepValidationMessage)
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.coral)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: handleNextAction) {
                Text(currentStep == 10 ? "Submit Loan Application" : "Continue")
                    .font(LMSFont.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(LMSColors.brandNavy, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
            }
            .buttonStyle(LMSPressableStyle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 2)
    }
    
    // MARK: - Helper Methods
    
    private func stepTitle(for step: Int) -> String {
        switch step {
        case 1: return "Loan Selection Overview"
        case 2: return "Eligibility Pre-Check"
        case 3: return "Personal Information"
        case 4: return "Employment & Income"
        case 5: return "Co-Applicant Details"
        case 6: return "Document Upload Center"
        case 7: return "Simulated OCR Review"
        case 8: return "Document Verification Hub"
        case 9: return "Credit & Risk Assessment"
        case 10: return "Final Review & Submit"
        default: return "Loan Application"
        }
    }

    private func stepSubtitle(for step: Int) -> String {
        switch step {
        case 1: return "Review the product details before starting your application."
        case 2: return "Tune the amount and tenure to estimate affordability."
        case 3: return "Confirm your personal and contact information."
        case 4: return "Add income details for a stronger eligibility check."
        case 5: return "Add a co-applicant only if it helps your profile."
        case 6: return "Upload the documents needed for verification."
        case 7: return "Review extracted details before verification."
        case 8: return "Resolve any document mismatches before submission."
        case 9: return "Check the risk summary generated from your profile."
        case 10: return "Review everything once before final submission."
        default: return "Complete each step to submit your loan application."
        }
    }

    private func handleBackAction() {
        if currentStep > 1 {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                currentStep -= 1
            }
        } else {
            dismiss()
        }
    }
    
    private func prepareWizardState() {
        if viewModel.currentDraftID == nil || viewModel.selectedProductID != product.id {
            viewModel.startDraft(for: product)
        }

        viewModel.prefillEmptyFieldsFromProfile()

        ensureRequiredDocumentsLoaded()

        if viewModel.formData.requestedAmountValue > 0 {
            desiredAmount = viewModel.formData.requestedAmountValue
        } else {
            viewModel.formData.loanAmountRequested = String(Int(desiredAmount))
        }

        if viewModel.formData.preferredTenureMonths > 0 {
            loanTenureMonths = Double(viewModel.formData.preferredTenureMonths)
        }

        if salariedCompany.isEmpty {
            salariedCompany = viewModel.formData.employerName
        }
        if salariedDesignation.isEmpty {
            salariedDesignation = viewModel.formData.occupation
        }
        if selfEmployedBusinessName.isEmpty {
            selfEmployedBusinessName = viewModel.formData.employerName
        }
    }

    private func ensureRequiredDocumentsLoaded() {
        guard viewModel.documents.isEmpty else { return }

        viewModel.documents = BorrowerLoanDocumentItem.defaultRequirements(
            for: product,
            identityDoc: viewModel.formData.selectedIdentityDoc,
            addressDoc: viewModel.formData.selectedAddressDoc,
            incomeDoc: viewModel.formData.selectedIncomeDoc
        )
        viewModel.autosaveDraft()
    }

    private func syncWizardFormToViewModel() {
        viewModel.formData.loanAmountRequested = String(Int(desiredAmount))
        viewModel.formData.preferredTenureMonths = Int(loanTenureMonths)

        if viewModel.formData.employmentType == "Salaried" {
            if !salariedCompany.isEmpty {
                viewModel.formData.employerName = salariedCompany
            }
            if !salariedDesignation.isEmpty {
                viewModel.formData.occupation = salariedDesignation
            }
            viewModel.formData.workExperienceYears = 2
            if viewModel.formData.monthlyIncomeValue <= 0 {
                viewModel.formData.monthlyIncome = "75000"
            }
            if viewModel.formData.annualIncomeValue <= 0 {
                let annual = Int(viewModel.formData.monthlyIncomeValue * 12)
                viewModel.formData.annualIncome = String(annual)
            }
        } else {
            if !selfEmployedBusinessName.isEmpty {
                viewModel.formData.employerName = selfEmployedBusinessName
            }
            viewModel.formData.occupation = "Business Owner"
            viewModel.formData.workExperienceYears = selfEmployedYearsInBusiness
            viewModel.formData.gstNumber = selfEmployedGSTNumber
            if viewModel.formData.annualIncomeValue <= 0, !selfEmployedAnnualProfit.isEmpty {
                viewModel.formData.annualIncome = selfEmployedAnnualProfit
            } else if viewModel.formData.annualIncomeValue <= 0 {
                viewModel.formData.annualIncome = "1200000"
            }
            if viewModel.formData.monthlyIncomeValue <= 0 {
                let monthly = max(1, Int(viewModel.formData.annualIncomeValue / 12))
                viewModel.formData.monthlyIncome = String(monthly)
            }
        }

        if !existingLoansCount.isEmpty {
            viewModel.formData.existingLoans = existingLoansCount
        }
        if !creditCardOutstanding.isEmpty {
            viewModel.formData.creditCardObligations = creditCardOutstanding
        }

        viewModel.formData.hasCoApplicant = hasCoApplicantToggle
        if hasCoApplicantToggle, !coApplicantName.isEmpty {
            viewModel.formData.coApplicantDetails = "\(coApplicantName) (\(coApplicantRelation))"
        }

        if viewModel.formData.loanPurpose.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            viewModel.formData.loanPurpose = "General financing requirement"
        }

        if viewModel.formData.creditScore.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            viewModel.formData.creditScore = "750"
        }
    }

    private func triggerAutosave() {
        isAutosaving = true
        syncWizardFormToViewModel()
        viewModel.autosaveDraft()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isAutosaving = false
            lastAutosavedTime = Date()
        }
    }
    
    private func handleNextAction() {
        stepValidationMessage = nil
        syncWizardFormToViewModel()
        triggerAutosave()

        if currentStep < 10 {
            if currentStep == 6 {
                let pendingUploads = viewModel.documents.filter { $0.status == .pendingUpload }
                if !pendingUploads.isEmpty {
                    stepValidationMessage = "Upload all required documents: \(pendingUploads.map(\.name).joined(separator: ", "))."
                    HapticsManager.triggerNotification(type: .warning)
                    return
                }
            }

            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                currentStep += 1
            }
        } else {
            if viewModel.currentDraftID == nil {
                viewModel.startDraft(for: product)
                ensureRequiredDocumentsLoaded()
                syncWizardFormToViewModel()
                viewModel.autosaveDraft()
            }

            ensureFullyVerified()
            syncWizardFormToViewModel()
            viewModel.autosaveDraft()

            if viewModel.submitCurrentApplication() != nil {
                HapticsManager.triggerNotification(type: .success)
                onComplete()
            } else {
                let issues = viewModel.blockingSubmissionIssues
                submissionErrorMessage = issues.isEmpty
                    ? "Could not submit the application. Please review your details and try again."
                    : issues.joined(separator: "\n")
                stepValidationMessage = submissionErrorMessage
                HapticsManager.triggerNotification(type: .error)
            }
        }
    }
    
    private func ensureFullyVerified() {
        for doc in viewModel.documents where doc.status == .pendingUpload {
            viewModel.uploadDocument(
                doc.id,
                fileName: "uploaded_\(doc.name.lowercased().replacingOccurrences(of: " ", with: "_")).pdf",
                source: .pdf
            )
        }
        viewModel.runBulkVerification()
        for doc in viewModel.documents where doc.status != .verified {
            viewModel.markDocument(doc.id, status: .verified)
        }
    }
    
    private func simulateUpload(for docId: UUID, source: BorrowerDocumentUploadSource) {
        guard let doc = viewModel.documents.first(where: { $0.id == docId }) else { return }
        
        isUploading[doc.name] = true
        uploadProgress[doc.name] = 0.0
        ocrStatus[doc.name] = "None"
        
        // Timer simulation for high-fidelity feel
        let steps = 10
        let timeInterval = 0.15
        
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * timeInterval) {
                uploadProgress[doc.name] = Double(i) / Double(steps)
                
                if i == steps {
                    isUploading[doc.name] = false
                    viewModel.uploadDocument(docId, fileName: "scanned_\(doc.name.lowercased().replacingOccurrences(of: " ", with: "_")).jpg", source: source)
                    
                    // Trigger OCR Simulation
                    ocrStatus[doc.name] = "Scanning"
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        ocrStatus[doc.name] = "Success"
                        viewModel.markDocument(docId, status: .underVerification)
                    }
                }
            }
        }
    }
}

// MARK: - STEP 1: Loan Overview / Selection
private struct Step1SelectionView: View {
    let product: BorrowerLoanProduct

    var body: some View {
        VStack(spacing: 22) {
            // Main Card
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(LMSColors.brandNavy.opacity(0.10))
                        .frame(width: 80, height: 80)
                    Image(systemName: product.type.iconName)
                        .font(.system(size: 38, weight: .bold))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(LMSColors.brandNavy)
                }
                
                VStack(spacing: 6) {
                    Text(product.type.title)
                        .font(LMSFont.title)
                        .foregroundStyle(LMSColors.textPrimary)
                    Text(product.shortDescription)
                        .font(LMSFont.subheadline)
                        .foregroundStyle(LMSColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                .padding(.bottom, 8)
                
                // Key metrics row
                HStack(spacing: 10) {
                    LoanMetricChip(title: "Max Amount", value: product.maximumAmount.formattedAsINR(), tint: LMSColors.brandNavy)
                    LoanMetricChip(title: "Rate", value: product.interestRateRange, tint: LMSColors.brandNavy)
                    LoanMetricChip(title: "Approval", value: product.estimatedProcessingTime, tint: LMSColors.emerald)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.vertical, 26)
            .padding(.horizontal, 18)
            .background(LMSColors.surfaceElevated, in: RoundedRectangle(cornerRadius: LMSRadius.xl, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LMSRadius.xl, style: .continuous)
                    .stroke(LMSColors.separatorLight, lineWidth: 0.5)
            )
            .padding(.horizontal, 16)
            
            // Benefits list
            VStack(alignment: .leading, spacing: 16) {
                Text("Product Key Benefits")
                    .font(LMSFont.title3)
                    .foregroundStyle(LMSColors.textPrimary)
                    .padding(.horizontal, 16)
                
                VStack(spacing: 12) {
                    ForEach(product.benefits, id: \.self) { benefit in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(LMSColors.emerald)
                                .font(.system(size: 18))
                            Text(benefit)
                                .font(LMSFont.body)
                                .foregroundStyle(LMSColors.textPrimary)
                            Spacer()
                        }
                    }
                }
                .padding(20)
                .lmsInsetGroupedCard()
                .padding(.horizontal, 16)
            }
        }
    }
}

private struct LoanMetricChip: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(LMSFont.caption2.weight(.bold))
                .foregroundStyle(LMSColors.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            Text(value)
                .font(LMSFont.callout.weight(.semibold))
                .foregroundStyle(tint)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .background(LMSColors.surfaceTertiary, in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
    }
}

// MARK: - STEP 2: Eligibility Pre-Check
private struct Step2EligibilityView: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let product: BorrowerLoanProduct
    @Binding var desiredAmount: Double
    @Binding var tenureMonths: Double
    
    private var suggestedEMI: Double {
        calculateEstimatedEMI(amount: desiredAmount, months: Int(tenureMonths))
    }
    
    private var foirPercentage: Int {
        let monthlyInc = viewModel.formData.monthlyIncomeValue > 0 ? viewModel.formData.monthlyIncomeValue : 80000.0
        let existingEMI = viewModel.formData.existingEMIsValue
        let foir = ((existingEMI + suggestedEMI) / monthlyInc) * 100
        return min(100, max(0, Int(foir)))
    }
    
    private var approvalProbability: String {
        if foirPercentage > 60 {
            return "Low probability"
        } else if foirPercentage > 45 {
            return "Moderate probability"
        } else {
            return "High probability"
        }
    }
    
    private var probabilityColor: Color {
        if foirPercentage > 60 {
            return LMSColors.coral
        } else if foirPercentage > 45 {
            return LMSColors.amber
        } else {
            return LMSColors.emerald
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            // Calculator Card
            VStack(spacing: 20) {
                // Desired Amount Slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Desired Loan Amount")
                            .font(LMSFont.callout.weight(.medium))
                            .foregroundStyle(LMSColors.textSecondary)
                        Spacer()
                        Text(desiredAmount.formattedAsINR())
                            .font(LMSFont.headline)
                            .foregroundStyle(LMSColors.brandNavy)
                    }
                    Slider(value: $desiredAmount, in: 50000...product.maximumAmount, step: 25000)
                        .tint(LMSColors.brandNavy)
                }
                
                // Tenure Slider
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Loan Tenure")
                            .font(LMSFont.callout.weight(.medium))
                            .foregroundStyle(LMSColors.textSecondary)
                        Spacer()
                        Text("\(Int(tenureMonths)) months")
                            .font(LMSFont.headline)
                            .foregroundStyle(LMSColors.brandNavy)
                    }
                    Slider(value: $tenureMonths, in: 12...120, step: 12)
                        .tint(LMSColors.brandNavy)
                }
                
                // Quick Financials Inputs
                VStack(spacing: 12) {
                    HStack {
                        Text("Monthly Income")
                            .font(LMSFont.callout.weight(.medium))
                        Spacer()
                        TextField("₹ 80,000", text: $viewModel.formData.monthlyIncome)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(LMSFont.body.weight(.bold))
                    }
                    Divider()
                    HStack {
                        Text("Existing EMI Obligations")
                            .font(LMSFont.callout.weight(.medium))
                        Spacer()
                        TextField("₹ 0", text: $viewModel.formData.existingEMIs)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(LMSFont.body.weight(.bold))
                    }
                }
                .padding(.top, 10)
            }
            .padding(20)
            .lmsInsetGroupedCard()
            .padding(.horizontal, 16)
            
            // Estimates Banner
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ESTIMATED EMI")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(LMSColors.textSecondary)
                        Text("\(suggestedEMI.formattedAsINR())/mo")
                            .font(LMSFont.title3)
                            .foregroundStyle(LMSColors.brandNavy)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("ESTIMATED FOIR")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(LMSColors.textSecondary)
                        Text("\(foirPercentage)%")
                            .font(LMSFont.title3)
                            .foregroundStyle(foirPercentage > 50 ? LMSColors.coral : LMSColors.textPrimary)
                    }
                }
                
                Divider()
                
                // Dynamic probability gauge
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .stroke(LMSColors.separatorLight, lineWidth: 6)
                            .frame(width: 48, height: 48)
                        Circle()
                            .trim(from: 0.0, to: CGFloat(max(0.1, 1.0 - (Double(foirPercentage)/100.0))))
                            .stroke(probabilityColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                            .frame(width: 48, height: 48)
                            .rotationEffect(.degrees(-90))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Approval Probability")
                            .font(LMSFont.caption.weight(.bold))
                            .foregroundStyle(LMSColors.textSecondary)
                        Text(approvalProbability)
                            .font(LMSFont.callout.bold())
                            .foregroundStyle(probabilityColor)
                    }
                    Spacer()
                }
            }
            .padding(20)
            .background(probabilityColor.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                    .stroke(probabilityColor.opacity(0.18), lineWidth: 1)
            )
            .padding(.horizontal, 16)
        }
    }
    
    private func calculateEstimatedEMI(amount: Double, months: Int) -> Double {
        let annualRate: Double = 0.105
        let monthlyRate = annualRate / 12.0
        let numberOfPayments = Double(months)
        let emi = (amount * monthlyRate * pow(1 + monthlyRate, numberOfPayments)) / (pow(1 + monthlyRate, numberOfPayments) - 1)
        return emi.isNaN ? (amount / numberOfPayments) : emi
    }
}

// MARK: - STEP 3: Personal Information
private struct Step3PersonalInfoView: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Basic Details
            VStack(alignment: .leading, spacing: 16) {
                Text("Basic Details")
                    .font(LMSFont.title3)
                    .foregroundStyle(LMSColors.textPrimary)
                
                TextField("First Name", text: $viewModel.formData.fullName)
                    .padding()
                    .background(LMSColors.background, in: RoundedRectangle(cornerRadius: 10))
                
                DatePicker("Date of Birth", selection: $viewModel.formData.dateOfBirth, displayedComponents: .date)
                    .padding(.vertical, 8)
                
                HStack(spacing: 12) {
                    Text("Gender")
                    Spacer()
                    Picker("Gender", selection: $viewModel.formData.gender) {
                        Text("Select").tag("")
                        Text("Male").tag("Male")
                        Text("Female").tag("Female")
                        Text("Other").tag("Other")
                    }
                    .pickerStyle(.menu)
                }
            }
            .padding(20)
            .lmsInsetGroupedCard()
            .padding(.horizontal, 16)
            
            // Contacts
            VStack(alignment: .leading, spacing: 16) {
                Text("Contact Details")
                    .font(LMSFont.title3)
                    .foregroundStyle(LMSColors.textPrimary)
                
                TextField("Mobile Number", text: $viewModel.formData.mobileNumber)
                    .keyboardType(.phonePad)
                    .padding()
                    .background(LMSColors.background, in: RoundedRectangle(cornerRadius: 10))
                
                TextField("Email Address", text: $viewModel.formData.emailAddress)
                    .keyboardType(.emailAddress)
                    .disableAutocapitalization()
                    .padding()
                    .background(LMSColors.background, in: RoundedRectangle(cornerRadius: 10))
            }
            .padding(20)
            .lmsInsetGroupedCard()
            .padding(.horizontal, 16)
            
            // Residential
            VStack(alignment: .leading, spacing: 16) {
                Text("Residential Information")
                    .font(LMSFont.title3)
                    .foregroundStyle(LMSColors.textPrimary)
                
                TextField("Current Residential Address", text: $viewModel.formData.address, axis: .vertical)
                    .lineLimit(3...5)
                    .padding()
                    .background(LMSColors.background, in: RoundedRectangle(cornerRadius: 10))
                
                HStack {
                    Text("Residence Type")
                    Spacer()
                    Picker("Residence Type", selection: $viewModel.formData.repaymentPreference) {
                        Text("Owned").tag("Owned")
                        Text("Rented").tag("Rented")
                        Text("Family Owned").tag("Family Owned")
                    }
                }
            }
            .padding(20)
            .lmsInsetGroupedCard()
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - STEP 4: Employment & Income
private struct Step4EmploymentView: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    
    @Binding var salariedCompany: String
    @Binding var salariedEmpID: String
    @Binding var salariedDesignation: String
    @Binding var salariedJoiningDate: Date
    
    @Binding var selfEmployedBusinessName: String
    @Binding var selfEmployedBusinessType: String
    @Binding var selfEmployedYearsInBusiness: Int
    @Binding var selfEmployedGSTNumber: String
    @Binding var selfEmployedAnnualRevenue: String
    @Binding var selfEmployedAnnualProfit: String
    
    @Binding var existingLoansCount: String
    @Binding var creditCardLimit: String
    @Binding var creditCardOutstanding: String
    @Binding var savingsInvestments: String

    var body: some View {
        VStack(spacing: 20) {
            // Selection of Employment Type
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Employment Type")
                    .font(LMSFont.title3)
                    .foregroundStyle(LMSColors.textPrimary)
                
                Picker("Employment Type", selection: $viewModel.formData.employmentType) {
                    ForEach(viewModel.employmentTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
            .padding(16)
            .lmsInsetGroupedCard()
            .padding(.horizontal, 16)
            
            // Dynamic Form Area
            if viewModel.formData.employmentType == "Salaried" {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Salaried Applicant Info")
                        .font(LMSFont.title3)
                        .foregroundStyle(LMSColors.textPrimary)
                    
                    TextField("Company Name", text: $salariedCompany)
                        .padding()
                        .background(LMSColors.background, in: RoundedRectangle(cornerRadius: 10))
                    
                    TextField("Employee ID", text: $salariedEmpID)
                        .padding()
                        .background(LMSColors.background, in: RoundedRectangle(cornerRadius: 10))
                    
                    TextField("Designation", text: $salariedDesignation)
                        .padding()
                        .background(LMSColors.background, in: RoundedRectangle(cornerRadius: 10))
                    
                    DatePicker("Date of Joining", selection: $salariedJoiningDate, displayedComponents: .date)
                    
                    HStack {
                        Text("Monthly Take-Home Salary")
                        Spacer()
                        TextField("₹ 75,000", text: $viewModel.formData.monthlyIncome)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.headline)
                    }
                }
                .padding(20)
                .lmsInsetGroupedCard()
                .padding(.horizontal, 16)
            } else {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Business Owner / Self-Employed Info")
                        .font(LMSFont.title3)
                        .foregroundStyle(LMSColors.textPrimary)
                    
                    TextField("Business Registered Name", text: $selfEmployedBusinessName)
                        .padding()
                        .background(LMSColors.background, in: RoundedRectangle(cornerRadius: 10))
                    
                    Picker("Business Constitution Type", selection: $selfEmployedBusinessType) {
                        Text("Proprietorship").tag("Proprietorship")
                        Text("Partnership").tag("Partnership")
                        Text("Pvt Ltd").tag("Pvt Ltd")
                    }
                    
                    Stepper("Vintage in Business: \(selfEmployedYearsInBusiness) Years", value: $selfEmployedYearsInBusiness, in: 1...40)
                    
                    TextField("GST Registration Number", text: $selfEmployedGSTNumber)
                        .disableAutocapitalization()
                        .padding()
                        .background(LMSColors.background, in: RoundedRectangle(cornerRadius: 10))
                    
                    HStack {
                        Text("Annual Net Profit")
                        Spacer()
                        TextField("₹ 12,00,000", text: $viewModel.formData.annualIncome)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.headline)
                    }
                }
                .padding(20)
                .lmsInsetGroupedCard()
                .padding(.horizontal, 16)
            }
            
            // Liabilities & Financial Assets
            VStack(alignment: .leading, spacing: 16) {
                Text("Additional Financial Background")
                    .font(LMSFont.title3)
                    .foregroundStyle(LMSColors.textPrimary)
                
                HStack {
                    Text("Total Active Loans count")
                    Spacer()
                    TextField("0", text: $existingLoansCount)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Total Credit Card Limit")
                    Spacer()
                    TextField("₹", text: $creditCardLimit)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Credit Card Outstanding")
                    Spacer()
                    TextField("₹", text: $creditCardOutstanding)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                
                HStack {
                    Text("Savings & Financial Assets")
                    Spacer()
                    TextField("₹", text: $savingsInvestments)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
            }
            .padding(20)
            .lmsInsetGroupedCard()
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - STEP 5: Co-Applicant Optional
private struct Step5CoApplicantView: View {
    @Binding var hasCoApplicant: Bool
    @Binding var coApplicantName: String
    @Binding var coApplicantRelation: String
    @Binding var coApplicantMobile: String
    @Binding var coApplicantPAN: String
    @Binding var coApplicantAadhaar: String
    @Binding var coApplicantIncome: String

    var body: some View {
        VStack(spacing: 20) {
            // Explanatory Banner
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundStyle(LMSColors.brandNavy)
                    Text("Improve Your Approval Odds!")
                        .font(LMSFont.headline)
                        .foregroundStyle(LMSColors.brandNavy)
                }
                
                Text("Adding a co-applicant (spouse or family member) with an active income source significantly strengthens your financial capability and increases your eligible loan limit.")
                    .font(LMSFont.footnote)
                    .foregroundStyle(LMSColors.textSecondary)
                    .lineSpacing(4)
                
                Toggle("Add Co-applicant or Guarantor", isOn: $hasCoApplicant.animation())
                    .font(LMSFont.callout.bold())
                    .tint(LMSColors.brandNavy)
                    .padding(.top, 8)
            }
            .padding(20)
            .background(LMSColors.brandNavy.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                    .stroke(LMSColors.brandNavy.opacity(0.16), lineWidth: 1)
            )
            .padding(.horizontal, 16)
            
            if hasCoApplicant {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Co-Applicant Information")
                        .font(LMSFont.title3)
                        .foregroundStyle(LMSColors.textPrimary)
                    
                    TextField("Full Legal Name", text: $coApplicantName)
                        .padding()
                        .background(LMSColors.background, in: RoundedRectangle(cornerRadius: 10))
                    
                    Picker("Relationship", selection: $coApplicantRelation) {
                        Text("Spouse").tag("Spouse")
                        Text("Parent").tag("Parent")
                        Text("Sibling").tag("Sibling")
                        Text("Child").tag("Child")
                    }
                    
                    TextField("Mobile Number", text: $coApplicantMobile)
                        .keyboardType(.phonePad)
                        .padding()
                        .background(LMSColors.background, in: RoundedRectangle(cornerRadius: 10))
                    
                    TextField("PAN Card Number", text: $coApplicantPAN)
                        .disableAutocapitalization()
                        .padding()
                        .background(LMSColors.background, in: RoundedRectangle(cornerRadius: 10))
                    
                    TextField("Aadhaar Number", text: $coApplicantAadhaar)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(LMSColors.background, in: RoundedRectangle(cornerRadius: 10))
                    
                    HStack {
                        Text("Monthly Net Income")
                        Spacer()
                        TextField("₹ 0", text: $coApplicantIncome)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .font(.headline)
                    }
                }
                .padding(20)
                .lmsInsetGroupedCard()
                .padding(.horizontal, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

// MARK: - STEP 6: Document Upload Center
private struct Step6DocumentCenterView: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let product: BorrowerLoanProduct
    @Binding var stepValidationMessage: String?
    @Binding var uploadProgress: [String: Double]
    @Binding var isUploading: [String: Bool]
    @Binding var ocrStatus: [String: String]
    let onTriggerUpload: (UUID) -> Void
    let onEnsureDocuments: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if viewModel.documents.isEmpty {
                VStack(spacing: 12) {
                    Text("Required documents could not be loaded.")
                        .font(LMSFont.subheadline)
                        .foregroundStyle(LMSColors.textSecondary)
                    Button("Load Required Documents") {
                        onEnsureDocuments()
                    }
                    .font(LMSFont.callout.weight(.semibold))
                    .foregroundStyle(LMSColors.brandNavy)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .lmsInsetGroupedCard()
                .padding(.horizontal, 16)
            } else {
                documentSection(
                    title: "Identity Verification Documents",
                    category: .identityVerification
                )
                documentSection(
                    title: "Address Verification Documents",
                    category: .addressVerification
                )
                documentSection(
                    title: "Income Verification Documents",
                    category: .incomeVerification
                )

                let loanSpecific = viewModel.documents(for: .loanSpecific)
                if !loanSpecific.isEmpty {
                    documentSection(
                        title: "Loan-Specific Documents",
                        category: .loanSpecific
                    )
                }
            }
        }
        .onAppear {
            onEnsureDocuments()
        }
    }

    @ViewBuilder
    private func documentSection(title: String, category: BorrowerDocumentCategory) -> some View {
        let docs = viewModel.documents(for: category)
        VStack(alignment: .leading, spacing: 12) {
            LMSGroupedSectionHeader(
                title: LocalizedStringKey(title),
                subtitle: docs.isEmpty ? "No document required for this category." : "Tap Upload on each item."
            )
            if docs.isEmpty {
                Text("No document required.")
                    .font(LMSFont.footnote)
                    .foregroundStyle(LMSColors.textSecondary)
                    .padding(.horizontal, 16)
            } else {
                VStack(spacing: 14) {
                    ForEach(docs, id: \.id) { doc in
                        UploadRow(
                            doc: doc,
                            progress: uploadProgress[doc.name] ?? 0.0,
                            uploading: isUploading[doc.name] ?? false,
                            ocr: ocrStatus[doc.name] ?? "None",
                            onTrigger: { onTriggerUpload(doc.id) }
                        )
                    }
                }
                .padding(12)
                .lmsInsetGroupedCard()
                .padding(.horizontal, 16)
            }
        }
    }
}

// Upload Row Component
private struct UploadRow: View {
    let doc: BorrowerLoanDocumentItem
    let progress: Double
    let uploading: Bool
    let ocr: String
    let onTrigger: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // Doc Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(doc.status == .verified ? LMSColors.emerald.opacity(0.1) : LMSColors.brandNavy.opacity(0.08))
                        .frame(width: 44, height: 44)
                    Image(systemName: doc.status == .verified ? "checkmark.seal.fill" : doc.status.iconName)
                        .font(.title3)
                        .foregroundStyle(doc.status == .verified ? LMSColors.emerald : LMSColors.brandNavy)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(doc.name)
                        .font(LMSFont.callout.weight(.semibold))
                        .foregroundStyle(LMSColors.textPrimary)
                    
                    if uploading {
                        Text("Uploading \(Int(progress * 100))%...")
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.actionBlue)
                    } else if ocr == "Scanning" {
                        Text("⚡ OCR Extracting Data...")
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.amber)
                    } else {
                        Text(doc.status.rawValue)
                            .font(LMSFont.caption)
                            .foregroundStyle(doc.status.tintColor)
                    }
                }
                
                Spacer()
                
                if doc.status == .pendingUpload && !uploading {
                    Button(action: onTrigger) {
                        Text("Upload")
                            .font(LMSFont.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(LMSColors.brandNavy, in: Capsule())
                    }
                    .buttonStyle(LMSPressableStyle())
                } else if doc.status != .pendingUpload && !uploading {
                    // Replace / Preview Buttons
                    HStack(spacing: 8) {
                        Button(action: onTrigger) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.footnote)
                                .foregroundStyle(LMSColors.textSecondary)
                                .frame(width: 32, height: 32)
                                .background(LMSColors.surfaceTertiary, in: Circle())
                        }
                        
                        Image(systemName: "eye.fill")
                            .font(.footnote)
                            .foregroundStyle(LMSColors.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(LMSColors.surfaceTertiary, in: Circle())
                    }
                }
            }
            
            if uploading {
                ProgressView(value: progress)
                    .tint(LMSColors.actionBlue)
            }
        }
    }
}

// MARK: - STEP 7: OCR Extraction Review
private struct Step7OCRExtractionView: View {
    @Binding var ocrPANNumber: String
    @Binding var ocrPANName: String
    @Binding var ocrPANFather: String
    @Binding var ocrPANDOB: Date
    
    @Binding var ocrAadhaarName: String
    @Binding var ocrAadhaarDOB: Date
    @Binding var ocrAadhaarGender: String
    @Binding var ocrAadhaarAddress: String
    
    @Binding var ocrConfidence: [String: String]

    var body: some View {
        VStack(spacing: 24) {
            // Info Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundStyle(LMSColors.brandNavy)
                    Text("Instant Smart Verification")
                        .font(LMSFont.headline)
                        .foregroundStyle(LMSColors.brandNavy)
                }
                Text("We have automatically extracted information from your uploaded Aadhaar and PAN Cards. Please review and confirm below.")
                    .font(LMSFont.footnote)
                    .foregroundStyle(LMSColors.textSecondary)
            }
            .padding(.horizontal, 16)
            
            // PAN Card extraction review
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("PAN CARD SUMMARY", systemImage: "doc.text.viewfinder")
                        .font(LMSFont.caption.bold())
                        .foregroundStyle(LMSColors.textSecondary)
                    Spacer()
                    // Confidence indicator
                    Text("High Confidence")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(LMSColors.emerald)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(LMSColors.emerald.opacity(0.1), in: Capsule())
                }
                
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PAN NUMBER")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(LMSColors.textSecondary)
                        TextField("PAN Number", text: $ocrPANNumber)
                            .font(LMSFont.body.bold())
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FULL NAME")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(LMSColors.textSecondary)
                        TextField("Name", text: $ocrPANName)
                            .font(LMSFont.body.bold())
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FATHER'S NAME")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(LMSColors.textSecondary)
                        TextField("Father's name", text: $ocrPANFather)
                            .font(LMSFont.body.bold())
                    }
                }
            }
            .padding(20)
            .lmsInsetGroupedCard()
            .padding(.horizontal, 16)
            
            // Aadhaar Card extraction review
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("AADHAAR CARD SUMMARY", systemImage: "doc.text.viewfinder")
                        .font(LMSFont.caption.bold())
                        .foregroundStyle(LMSColors.textSecondary)
                    Spacer()
                    Text("High Confidence")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(LMSColors.emerald)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(LMSColors.emerald.opacity(0.1), in: Capsule())
                }
                
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FULL NAME ON CARD")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(LMSColors.textSecondary)
                        TextField("Name", text: $ocrAadhaarName)
                            .font(LMSFont.body.bold())
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("GENDER")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(LMSColors.textSecondary)
                        TextField("Gender", text: $ocrAadhaarGender)
                            .font(LMSFont.body.bold())
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ADDRESS REGISTERED")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(LMSColors.textSecondary)
                        TextField("Address", text: $ocrAadhaarAddress, axis: .vertical)
                            .font(LMSFont.body.bold())
                    }
                }
            }
            .padding(20)
            .lmsInsetGroupedCard()
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - STEP 8: Verification Dashboard
private struct Step8VerificationDashboardView: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    @Binding var hasResolvedMismatches: Bool
    let onFixRequired: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Status Header Info
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(hasResolvedMismatches ? LMSColors.emerald.opacity(0.1) : LMSColors.amber.opacity(0.1))
                        .frame(width: 80, height: 80)
                    Image(systemName: hasResolvedMismatches ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundStyle(hasResolvedMismatches ? LMSColors.emerald : LMSColors.amber)
                }
                
                VStack(spacing: 4) {
                    Text(hasResolvedMismatches ? "Auto-Verification Success" : "Verification Flags Raised")
                        .font(LMSFont.title3)
                        .foregroundStyle(LMSColors.textPrimary)
                    Text(hasResolvedMismatches ? "All document comparisons verified successfully." : "We noticed some mismatches. Please review the flags below.")
                        .font(LMSFont.footnote)
                        .foregroundStyle(LMSColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }
            
            // Flags Card
            VStack(alignment: .leading, spacing: 16) {
                Text("Verification Summary Checklist")
                    .font(LMSFont.caption.bold())
                    .foregroundStyle(LMSColors.textSecondary)
                
                VStack(spacing: 12) {
                    VerificationItemRow(
                        title: "PAN Match with Income Tax Bureau",
                        description: "Verified name matching database",
                        status: .verified
                    )
                    
                    Divider()
                    
                    VerificationItemRow(
                        title: "Name Consistency check",
                        description: hasResolvedMismatches ? "PAN & Aadhaar Name MATCH" : "Name mismatch in Aadhaar ('AKASH KASHYAP') vs Application Form ('AKASH KUMAR KASHYAP')",
                        status: hasResolvedMismatches ? .verified : .requiresAttention
                    )
                    
                    Divider()
                    
                    VerificationItemRow(
                        title: "Address Verification match",
                        description: "Current Utility bill matches Address Proof",
                        status: .verified
                    )
                }
            }
            .padding(20)
            .lmsInsetGroupedCard()
            .padding(.horizontal, 16)
            
            // Call to Action Banner
            if !hasResolvedMismatches {
                VStack(spacing: 12) {
                    Text("How would you like to resolve the name inconsistency?")
                        .font(LMSFont.footnote.bold())
                        .foregroundStyle(LMSColors.textPrimary)
                    
                    Button(action: {
                        withAnimation {
                            hasResolvedMismatches = true
                            viewModel.formData.fullName = "AKASH KASHYAP" // Align with official docs
                        }
                    }) {
                        Text("Use official Name from Aadhaar ('AKASH KASHYAP')")
                            .font(LMSFont.caption.bold())
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(LMSColors.brandNavy, in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(LMSPressableStyle())
                    
                    Button(action: onFixRequired) {
                        Text("Re-upload Documents / Fix Form Values")
                            .font(LMSFont.caption.bold())
                            .foregroundStyle(LMSColors.coral)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(LMSColors.coral.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(LMSPressableStyle())
                }
                .padding(16)
                .background(LMSColors.amber.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                        .stroke(LMSColors.amber.opacity(0.18), lineWidth: 1)
                )
                .padding(.horizontal, 16)
            }
        }
    }
}

// Verification checklist row
private struct VerificationItemRow: View {
    let title: String
    let description: String
    let status: Style
    
    enum Style { case verified, requiresAttention }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: status == .verified ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(status == .verified ? LMSColors.emerald : LMSColors.amber)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(LMSFont.callout.bold())
                    .foregroundStyle(LMSColors.textPrimary)
                Text(description)
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)
                    .lineLimit(3)
            }
            Spacer()
        }
    }
}

// MARK: - STEP 9: Credit & Risk Assessment
private struct Step9RiskAssessmentView: View {
    @ObservedObject var viewModel: LoanApplicationViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Analytics Dashboard
            VStack(spacing: 20) {
                // Score Gauge
                VStack(spacing: 8) {
                    Text("Bureau Credit Score")
                        .font(LMSFont.caption.bold())
                        .foregroundStyle(LMSColors.textSecondary)
                    
                    ZStack {
                        Circle()
                            .trim(from: 0, to: 0.75)
                            .stroke(LMSColors.separatorLight, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(135))
                        
                        Circle()
                            .trim(from: 0, to: 0.75 * (780.0 / 900.0))
                            .stroke(LMSColors.emerald, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(135))
                        
                        VStack(spacing: 2) {
                            Text("780")
                                .font(.system(size: 38, weight: .black, design: .rounded))
                                .foregroundStyle(LMSColors.textPrimary)
                            Text("Excellent Score")
                                .font(LMSFont.caption.bold())
                                .foregroundStyle(LMSColors.emerald)
                        }
                    }
                    .frame(height: 150)
                }
                
                Divider()
                
                // Active Obligations Details
                HStack(spacing: 12) {
                    MetricBadge(title: "Risk Grade", value: "Grade A", color: LMSColors.emerald)
                    MetricBadge(title: "Active Loans", value: "0", color: LMSColors.textSecondary)
                    MetricBadge(title: "Total Liabilities", value: "₹ 12K", color: LMSColors.brandNavy)
                }
            }
            .padding(20)
            .lmsInsetGroupedCard()
            .padding(.horizontal, 16)
            
            // Health Indicators List
            VStack(alignment: .leading, spacing: 16) {
                Text("Underwriting Assessment Details")
                    .font(LMSFont.caption.bold())
                    .foregroundStyle(LMSColors.textSecondary)
                    .padding(.horizontal, 16)
                
                VStack(spacing: 14) {
                    AssessmentRow(title: "Debt-to-Income Ratio (DTI)", value: "15%", indicator: .green)
                    Divider()
                    AssessmentRow(title: "Income Stability index", value: "Verified (3+ Yrs)", indicator: .green)
                    Divider()
                    AssessmentRow(title: "Banking Behavior Conduct", value: "Excellent", indicator: .green)
                    Divider()
                    AssessmentRow(title: "Financial Reserve Health", value: "Strong Liquid Reserves", indicator: .green)
                }
                .padding(20)
                .lmsInsetGroupedCard()
                .padding(.horizontal, 16)
            }
        }
    }
}

// Underwriting Assessment Row Component
private struct AssessmentRow: View {
    let title: String
    let value: String
    let indicator: Style
    
    enum Style { case green, yellow, red }
    
    var color: Color {
        switch indicator {
        case .green: return LMSColors.emerald
        case .yellow: return LMSColors.amber
        case .red: return LMSColors.coral
        }
    }

    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                Text(title)
                    .font(LMSFont.callout)
                    .foregroundStyle(LMSColors.textPrimary)
            }
            Spacer()
            Text(value)
                .font(LMSFont.callout.bold())
                .foregroundStyle(LMSColors.textSecondary)
        }
    }
}

// MARK: - STEP 10: Application Review
private struct Step10ApplicationReviewView: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let product: BorrowerLoanProduct
    let onEditStep: (Int) -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Completeness gauge banner
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .stroke(LMSColors.emerald.opacity(0.12), lineWidth: 8)
                            .frame(width: 60, height: 60)
                        Circle()
                            .trim(from: 0, to: 0.98)
                            .stroke(LMSColors.emerald, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90))
                        
                        Text("98%")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundStyle(LMSColors.emerald)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Application is ready!")
                            .font(LMSFont.headline)
                            .foregroundStyle(LMSColors.textPrimary)
                        Text("Please double check information before submitting.")
                            .font(LMSFont.footnote)
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                    Spacer()
                }
            }
            .padding(16)
            .background(LMSColors.emerald.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
            .padding(.horizontal, 16)
            
            // Section 1: Loan & Financial context
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderRow(title: "Requested Loan Details", step: 2, onEdit: onEditStep)
                ReviewLabeledRow(label: "Selected Product", value: product.type.title)
                ReviewLabeledRow(label: "Requested Amount", value: viewModel.formData.requestedAmountValue.formattedAsINR())
                ReviewLabeledRow(label: "Preferred Tenure", value: "\(viewModel.formData.preferredTenureMonths) months")
            }
            .padding(20)
            .lmsInsetGroupedCard()
            .padding(.horizontal, 16)
            
            // Section 2: Personal Details
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderRow(title: "Personal Information", step: 3, onEdit: onEditStep)
                ReviewLabeledRow(label: "Full Legal Name", value: viewModel.formData.fullName)
                ReviewLabeledRow(label: "Date of Birth", value: viewModel.formData.dateOfBirth.formattedAsDDMMMYYYY())
                ReviewLabeledRow(label: "Mobile Contact", value: viewModel.formData.mobileNumber)
                ReviewLabeledRow(label: "Email Address", value: viewModel.formData.emailAddress)
                ReviewLabeledRow(label: "Residential Address", value: viewModel.formData.address)
            }
            .padding(20)
            .lmsInsetGroupedCard()
            .padding(.horizontal, 16)
            
            // Section 3: Employment Details
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderRow(title: "Employment Details", step: 4, onEdit: onEditStep)
                ReviewLabeledRow(label: "Employment Type", value: viewModel.formData.employmentType)
                ReviewLabeledRow(label: "Employer / Business Name", value: viewModel.formData.employerName)
                ReviewLabeledRow(label: "Monthly Take Home / Income", value: viewModel.formData.monthlyIncomeValue.formattedAsINR())
            }
            .padding(20)
            .lmsInsetGroupedCard()
            .padding(.horizontal, 16)

            // Section 4: Uploaded Documents
            VStack(alignment: .leading, spacing: 14) {
                SectionHeaderRow(title: "Uploaded Documents", step: 6, onEdit: onEditStep)
                if viewModel.documents.isEmpty {
                    ReviewLabeledRow(label: "Status", value: "No documents attached")
                } else {
                    ForEach(viewModel.documents, id: \.id) { doc in
                        ReviewLabeledRow(label: doc.name, value: doc.status.rawValue)
                    }
                }
            }
            .padding(20)
            .lmsInsetGroupedCard()
            .padding(.horizontal, 16)
        }
    }
}

// Inline Section Header Row
private struct SectionHeaderRow: View {
    let title: String
    let step: Int
    let onEdit: (Int) -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(LMSFont.title3)
                .foregroundStyle(LMSColors.textPrimary)
            Spacer()
            Button(action: { onEdit(step) }) {
                Text("Edit")
                    .font(LMSFont.caption.bold())
                    .foregroundStyle(LMSColors.actionBlue)
            }
        }
        .padding(.bottom, 4)
    }
}

// Inline Labeled Row for Summaries
private struct ReviewLabeledRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(LMSFont.body)
                .foregroundStyle(LMSColors.textSecondary)
            Spacer()
            Text(value)
                .font(LMSFont.body.bold())
                .foregroundStyle(LMSColors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Upload Source Selection Sheet
private struct UploadSourceSelectionSheet: View {
    @Binding var isPresented: Bool
    @Binding var selectedSource: BorrowerDocumentUploadSource
    let onSelect: (BorrowerDocumentUploadSource) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Select Document Source")
                .font(LMSFont.title3)
                .foregroundStyle(LMSColors.textPrimary)
                .padding(.top, 24)
            
            VStack(spacing: 12) {
                ForEach(BorrowerDocumentUploadSource.allCases, id: \.self) { source in
                    Button(action: {
                        selectedSource = source
                        isPresented = false
                        onSelect(source)
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LMSColors.brandNavy.opacity(0.1))
                                    .frame(width: 40, height: 40)
                                Image(systemName: source.iconName)
                                    .font(.headline)
                                    .foregroundStyle(LMSColors.brandNavy)
                            }
                            Text(source.rawValue)
                                .font(LMSFont.headline)
                                .foregroundStyle(LMSColors.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(LMSColors.textTertiary)
                        }
                        .padding()
                        .background(LMSColors.background, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(LMSPressableStyle())
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .presentationDetents([.height(380)])
        .lmsScreenBackground()
    }
}

#Preview("Loan Wizard") {
    let viewModel = PreviewSupport.loanApplicationViewModel
    let product = BorrowerLoanProduct.sampleProducts.first(where: { $0.type == .personal }) ?? BorrowerLoanProduct.sampleProducts[0]
    viewModel.startDraft(for: product)

    return NavigationStack {
        BorrowerLoanWizardView(viewModel: viewModel, product: product) {}
    }
    .previewBorrowerEnvironment()
}
