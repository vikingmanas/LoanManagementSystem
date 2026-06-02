import SwiftUI
import UIKit
import Combine
import AVFoundation
import UniformTypeIdentifiers
@preconcurrency import Vision

private enum WizardNavigationDirection {
    case forward
    case backward
}

private enum DocumentUploadLifecycle: String {
    case idle
    case uploading
    case processing
    case success
    case failed
}

private struct DocumentOCRResult {
    let isValid: Bool
    let title: String
    let message: String
    let extractedDetails: [String: String]
    let fullName: String?
    let dateOfBirth: Date?
    let address: String?
}

private struct DocumentPreviewImage: Identifiable {
    let id = UUID()
    let title: String
    let image: UIImage
}

private struct MobileNumberValidator {
    static func sanitized(_ value: String) -> String {
        String(value.filter(\.isNumber).prefix(10))
    }

    static func message(for value: String, required: Bool = true) -> String? {
        if value.contains(where: { !$0.isNumber }) {
            return "Only numeric digits are allowed"
        }
        if value.count < 10 {
            return required || !value.isEmpty ? "Mobile number must contain 10 digits" : nil
        }
        if value.count > 10 {
            return "Mobile number cannot exceed 10 digits"
        }
        return nil
    }

    static func isValid(_ value: String, required: Bool = true) -> Bool {
        message(for: value, required: required) == nil
    }

    static func validationMessage(for value: String) -> String? {
        message(for: value)
    }

    static func sanitize(_ value: String) -> String {
        sanitized(value)
    }
}

// MARK: - Reusable UI Components for Wizard Form

private struct WizardFormSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(LMSFont.caption2.weight(.bold))
                .foregroundStyle(LMSColors.textSecondary)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content()
            }
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(LMSColors.separatorLight.opacity(0.4), lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(0.015), radius: 6, x: 0, y: 3)
        }
        .padding(.horizontal, 16)
    }
}

private struct WizardTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    var disableAutocapitalization: Bool = false
    var validationMessage: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(LMSFont.caption.weight(.semibold))
                .foregroundStyle(LMSColors.textSecondary)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(disableAutocapitalization ? .never : .words)
                .font(LMSFont.body.weight(.medium))
                .foregroundStyle(LMSColors.textPrimary)
                .padding(.vertical, 8)

            if let validationMessage {
                Text(validationMessage)
                    .font(LMSFont.caption2.weight(.semibold))
                    .foregroundStyle(LMSColors.coral)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct WizardMobileField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = "10 digit mobile number"
    var required: Bool = true

    private var validationMessage: String? {
        MobileNumberValidator.message(for: text, required: required)
    }

    var body: some View {
        WizardTextField(
            label: label,
            text: Binding(
                get: { text },
                set: { text = MobileNumberValidator.sanitized($0) }
            ),
            placeholder: placeholder,
            keyboardType: .numberPad,
            validationMessage: validationMessage
        )
    }
}

private struct WizardDateRow: View {
    let label: String
    @Binding var date: Date

    var body: some View {
        HStack {
            Text(label)
                .font(LMSFont.body.weight(.semibold))
                .foregroundStyle(LMSColors.textPrimary)
            
            Spacer()
            
            DatePicker("", selection: $date, displayedComponents: .date)
                .labelsHidden()
                .tint(LMSColors.brandNavy)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct WizardPickerRow<Option: Hashable>: View {
    let label: String
    @Binding var selection: Option
    let options: [Option]
    let titleTransform: (Option) -> String

    var body: some View {
        HStack {
            Text(label)
                .font(LMSFont.body.weight(.semibold))
                .foregroundStyle(LMSColors.textPrimary)
            
            Spacer()
            
            Picker(label, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(titleTransform(option)).tag(option)
                }
            }
            .pickerStyle(.menu)
            .tint(LMSColors.brandNavy)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct WizardToggleRow: View {
    let label: String
    let subtitle: String?
    @Binding var isOn: Bool

    init(label: String, subtitle: String? = nil, isOn: Binding<Bool>) {
        self.label = label
        self.subtitle = subtitle
        self._isOn = isOn
    }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(LMSFont.body.weight(.semibold))
                    .foregroundStyle(LMSColors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textSecondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(LMSColors.brandNavy)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct WizardInlineValueRow: View {
    let label: String
    let value: String
    var valueColor: Color = LMSColors.textPrimary

    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(LMSFont.body)
                .foregroundStyle(LMSColors.textSecondary)
            Spacer()
            Text(value)
                .font(LMSFont.body.bold())
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

private struct FormDivider: View {
    var body: some View {
        Divider()
            .padding(.leading, 16)
            .background(LMSColors.surface)
    }
}

// MARK: - Main Wizard View Overhaul
struct BorrowerLoanWizardView: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let product: BorrowerLoanProduct
    let onComplete: () -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @EnvironmentObject private var authManager: AuthManager

    @State private var currentStep: Int = 1
    @State private var navigationDirection: WizardNavigationDirection = .forward
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
    @State private var selfEmployedBusinessType: String = ""
    @State private var selfEmployedYearsInBusiness: Int = 1
    @State private var selfEmployedGSTNumber: String = ""
    @State private var selfEmployedAnnualRevenue: String = ""
    @State private var selfEmployedAnnualProfit: String = ""
    
    @State private var existingLoansCount: String = ""
    @State private var creditCardLimit: String = ""
    @State private var creditCardOutstanding: String = ""
    @State private var savingsInvestments: String = ""
    
    // Step 5 Bank Details, Step 8 Nominee & References
    @State private var hasCoApplicantToggle: Bool = false
    @State private var coApplicantName: String = ""
    @State private var coApplicantRelation: String = ""
    @State private var coApplicantMobile: String = ""
    @State private var coApplicantPAN: String = ""
    @State private var coApplicantAadhaar: String = ""
    @State private var coApplicantIncome: String = ""
    @State private var bankName: String = ""
    @State private var bankAccountNumber: String = ""
    @State private var bankIFSCCode: String = ""
    @State private var monthlySalaryDeposited: String = ""
    @State private var autoDebitConsent: Bool = false
    @State private var nomineeName: String = ""
    @State private var bankRegisteredMobile: String = ""
    @State private var nomineeMobile: String = ""
    
    // Step 6 & 7 Document & OCR Local States
    @State private var uploadProgress: [String: Double] = [:] // Document name -> Progress (0 to 1)
    @State private var isUploading: [String: Bool] = [:]
    @State private var ocrStatus: [String: String] = [:] // Document name -> OCR Status ("None", "Scanning", "Success")
    @State private var uploadLifecycle: [UUID: DocumentUploadLifecycle] = [:]
    @State private var documentThumbnails: [UUID: UIImage] = [:]
    @State private var documentUploadDates: [UUID: Date] = [:]
    @State private var documentFailureReasons: [UUID: String] = [:]
    @State private var documentExtractedDetails: [UUID: [String: String]] = [:]
    @State private var uploadSource: BorrowerDocumentUploadSource = .camera
    @State private var selectedUploadDocId: UUID? = nil
    @State private var showUploadSourceSheet = false
    @State private var showDocumentImagePicker = false
    @State private var showDocumentFileImporter = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var previewImage: DocumentPreviewImage?
    
    // Step 7 OCR Extracted Editable Data -> Repurposed for Nominee / Photo
    @State private var ocrPANNumber: String = ""
    @State private var ocrPANName: String = ""
    @State private var ocrPANFather: String = ""
    @State private var ocrPANDOB: Date = Calendar.current.date(byAdding: .year, value: -26, to: Date()) ?? Date()
    
    @State private var ocrAadhaarName: String = ""
    @State private var ocrAadhaarDOB: Date = Calendar.current.date(byAdding: .year, value: -26, to: Date()) ?? Date()
    @State private var ocrAadhaarGender: String = ""
    @State private var ocrAadhaarAddress: String = ""
    
    // OCR Confidence Ratings
    @State private var ocrConfidence: [String: String] = [:]
    @State private var signatureImage: UIImage?
    @State private var isSignatureEmpty = true
    @State private var liveVerificationCompleted = false
    @State private var liveVerificationReference: String?
    @State private var showLiveVerification = false
    
    // Step 8 Verification Alerts Overrides
    @State private var showVerificationResolutionSheet = false
    @State private var hasResolvedMismatches = false

    // Step 10 Consent & Submission
    @State private var acceptTerms = false
    @State private var acceptBureau = false
    @State private var acceptDebit = false

    @State private var submissionErrorMessage: String?
    @State private var stepValidationMessage: String?

    private var progressValue: Double {
        Double(currentStep) / 10.0
    }

    private var localDraftAutosaveToken: String {
        [
            "\(desiredAmount)",
            "\(loanTenureMonths)",
            salariedCompany,
            salariedEmpID,
            salariedDesignation,
            "\(salariedJoiningDate.timeIntervalSince1970)",
            selfEmployedBusinessName,
            selfEmployedBusinessType,
            "\(selfEmployedYearsInBusiness)",
            selfEmployedGSTNumber,
            selfEmployedAnnualRevenue,
            selfEmployedAnnualProfit,
            existingLoansCount,
            creditCardLimit,
            creditCardOutstanding,
            savingsInvestments,
            "\(hasCoApplicantToggle)",
            coApplicantName,
            coApplicantRelation,
            coApplicantMobile,
            coApplicantPAN,
            coApplicantAadhaar,
            coApplicantIncome,
            bankName,
            bankAccountNumber,
            bankIFSCCode,
            bankRegisteredMobile,
            monthlySalaryDeposited,
            "\(autoDebitConsent)",
            nomineeName,
            nomineeMobile,
            ocrPANFather,
            ocrPANNumber,
            "\(signatureImage != nil)",
            "\(isSignatureEmpty)",
            "\(liveVerificationCompleted)",
            liveVerificationReference ?? "",
            "\(acceptTerms)",
            "\(acceptBureau)",
            "\(acceptDebit)"
        ].joined(separator: "|")
    }

    var body: some View {
        ScrollView {
            VStack(spacing: LMSSpacing.lg) {
                // New compact Loan Context Chip below navigation bar
                LoanContextChip(product: product, amount: desiredAmount, interestRate: product.interestRateRange)
                
                stepContent
                inlineContinueCTA
            }
            .padding(.top, 12)
            .padding(.bottom, 28)
        }
        .lmsScreenBackground()
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            wizardNavigationBar
        }
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    guard value.translation.width > 80, abs(value.translation.height) < 60 else { return }
                    handleBackAction()
                }
        )
        .sheet(isPresented: $showUploadSourceSheet) {
            UploadSourceSelectionSheet(
                isPresented: $showUploadSourceSheet,
                selectedSource: $uploadSource,
                onSelect: { source in
                    if let docId = selectedUploadDocId {
                        if source == .pdf {
                            uploadSource = source
                            showDocumentFileImporter = true
                        } else {
                            beginDocumentSelection(for: docId, source: source)
                        }
                    }
                }
            )
        }
        .fileImporter(
            isPresented: $showDocumentFileImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            if let docId = selectedUploadDocId {
                processSelectedDocumentFile(result, for: docId)
            }
        }
        .fullScreenCover(isPresented: $showDocumentImagePicker) {
            DocumentImagePicker(sourceType: imagePickerSourceType) { image in
                showDocumentImagePicker = false
                if let docId = selectedUploadDocId {
                    processSelectedDocumentImage(image, for: docId, source: uploadSource)
                }
            } onCancel: {
                showDocumentImagePicker = false
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showLiveVerification) {
            LiveFaceVerificationView { reference in
                liveVerificationReference = reference
                liveVerificationCompleted = true
                showLiveVerification = false
                HapticsManager.triggerNotification(type: .success)
            } onCancel: {
                showLiveVerification = false
            }
            .ignoresSafeArea()
        }
        .sheet(item: $previewImage) { preview in
            NavigationStack {
                Image(uiImage: preview.image)
                    .resizable()
                    .scaledToFit()
                    .padding()
                    .background(Color.black.opacity(0.92))
                    .navigationTitle(preview.title)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { previewImage = nil }
                        }
                    }
            }
        }
        .onAppear {
            viewModel.setBorrowerAuthContext(
                email: authManager.userEmail ?? "",
                displayName: authManager.userDisplayName
            )
            prepareWizardState()
        }
        .onChange(of: currentStep) { _, newStep in
            viewModel.updateDraftStep(newStep)
        }
        .onChange(of: viewModel.formData) { _, _ in
            scheduleAutosaveIndicator()
            viewModel.autosaveDraft()
        }
        .onChange(of: localDraftAutosaveToken) { _, _ in
            triggerAutosave()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .inactive || phase == .background {
                persistCurrentDraftImmediately()
            }
        }
        .onDisappear {
            persistCurrentDraftImmediately()
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
        VStack(spacing: 8) {
            HStack {
                Button(action: handleBackAction) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                        Text("Back")
                            .font(LMSFont.body)
                    }
                    .foregroundStyle(LMSColors.brandNavy)
                }
                .accessibilityLabel(currentStep > 1 ? "Previous step" : "Back")
                
                Spacer()
                
                VStack(spacing: 1) {
                    Text(navigationTitle(for: currentStep))
                        .font(LMSFont.subheadline.weight(.semibold))
                        .foregroundStyle(LMSColors.textPrimary)
                        .lineLimit(1)
                    Text("Step \(currentStep) of 10")
                        .font(LMSFont.caption2.weight(.medium))
                        .foregroundStyle(LMSColors.textSecondary)
                }
                
                Spacer()
                
                autosavePill
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 6)
            
            ProgressView(value: progressValue)
                .tint(LMSColors.brandNavy)
                .scaleEffect(x: 1, y: 0.5, anchor: .center)
                .animation(.easeInOut(duration: 0.28), value: progressValue)
                .padding(.horizontal, 16)
        }
        .background(.background)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }

    private var autosavePill: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isAutosaving ? LMSColors.actionBlue : LMSColors.emerald)
                .frame(width: 5, height: 5)
            Text(autosaveStatusText)
                .font(LMSFont.caption2.weight(.medium))
                .foregroundStyle(LMSColors.textSecondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(LMSColors.surfaceTertiary, in: Capsule())
    }

    private var autosaveStatusText: String {
        if isAutosaving { return "Saving..." }
        guard let savedAt = viewModel.lastDraftSavedAt ?? Optional(lastAutosavedTime) else {
            return "Saved"
        }
        let elapsed = max(0, Int(Date().timeIntervalSince(savedAt)))
        if elapsed < 5 { return "Draft Updated" }
        if elapsed < 60 { return "Last Saved: \(elapsed)s ago" }
        return "Last Saved: \(elapsed / 60)m ago"
    }

    @ViewBuilder
    private var stepContent: some View {
        Group {
            switch currentStep {
            case 1:
                Step1OverviewView(product: product)
            case 2:
                Step2EligibilityCheckView(
                    viewModel: viewModel,
                    product: product,
                    desiredAmount: $desiredAmount,
                    tenureMonths: $loanTenureMonths
                )
            case 3:
                Step3PersonalInfoOverhaulView(viewModel: viewModel)
            case 4:
                Step4EmploymentOverhaulView(
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
                Step5BankDetailsView(
                    bankName: $bankName,
                    accountNo: $bankAccountNumber,
                    ifscCode: $bankIFSCCode,
                    registeredMobile: $bankRegisteredMobile,
                    monthlySalaryDeposited: $monthlySalaryDeposited,
                    autoDebitConsent: $autoDebitConsent
                )
            case 6:
                Step6DocumentCenterOverhaulView(
                    viewModel: viewModel,
                    product: product,
                    stepValidationMessage: $stepValidationMessage,
                    uploadProgress: $uploadProgress,
                    isUploading: $isUploading,
                    ocrStatus: $ocrStatus,
                    uploadLifecycle: uploadLifecycle,
                    thumbnails: documentThumbnails,
                    uploadDates: documentUploadDates,
                    failureReasons: documentFailureReasons,
                    extractedDetails: documentExtractedDetails,
                    onTriggerUpload: { docId in
                        selectedUploadDocId = docId
                        showUploadSourceSheet = true
                    },
                    onViewDocument: { doc in
                        if let image = documentThumbnails[doc.id] {
                            previewImage = DocumentPreviewImage(title: doc.name, image: image)
                        }
                    },
                    onEnsureDocuments: {
                        ensureRequiredDocumentsLoaded()
                    }
                )
            case 7:
                Step7SignaturePhotoView(
                    signatureImage: $signatureImage,
                    isSignatureEmpty: $isSignatureEmpty,
                    liveVerificationCompleted: $liveVerificationCompleted,
                    onStartLiveVerification: {
                        showLiveVerification = true
                    }
                )
            case 8:
                Step8NomineeReferencesView(
                    nomineeName: $nomineeName,
                    nomineeRelation: $coApplicantRelation,
                    nomineeMobile: $nomineeMobile,
                    refName: $ocrPANFather,
                    refPhone: $ocrPANNumber
                )
            case 9:
                Step9ReviewOverhaulView(
                    viewModel: viewModel,
                    product: product,
                    onEditStep: { step in
                        withAnimation {
                            currentStep = step
                        }
                    }
                )
            case 10:
                Step10TermsConsentView(
                    viewModel: viewModel,
                    product: product,
                    acceptTerms: $acceptTerms,
                    acceptBureau: $acceptBureau,
                    acceptDebit: $acceptDebit
                )
            default:
                Text("Unknown Step")
            }
        }
        .id(currentStep)
        .transition(stepTransition)
        .animation(.smooth(duration: 0.32), value: currentStep)
    }

    private var stepTransition: AnyTransition {
        switch navigationDirection {
        case .forward:
            return .asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            )
        case .backward:
            return .asymmetric(
                insertion: .move(edge: .leading).combined(with: .opacity),
                removal: .move(edge: .trailing).combined(with: .opacity)
            )
        }
    }

    private var inlineContinueCTA: some View {
        VStack(spacing: 8) {
            if let stepValidationMessage {
                Text(stepValidationMessage)
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.coral)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: handleNextAction) {
                Text(currentStep == 10 ? "Submit Application" : "Continue")
                    .font(LMSFont.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(
                        isCurrentStepActionDisabled ? LMSColors.brandNavy.opacity(0.35) : LMSColors.brandNavy,
                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                    )
            }
            .disabled(isCurrentStepActionDisabled)
            .buttonStyle(LMSPressableStyle())
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private var isCurrentStepActionDisabled: Bool {
        guard currentStep == 10 else { return false }
        return !isStep10ReadyForSubmission
    }

    private var isStep10ReadyForSubmission: Bool {
        isLoanPurposeValid && acceptTerms && acceptBureau && acceptDebit
    }

    private var isLoanPurposeValid: Bool {
        let count = viewModel.formData.loanPurpose.trimmingCharacters(in: .whitespacesAndNewlines).count
        return count >= 10 && count <= 500
    }
    
    // MARK: - Helper Methods
    
    private func navigationTitle(for step: Int) -> String {
        switch step {
        case 1: return "Overview"
        case 2: return "Eligibility Plan"
        case 3: return "Personal Details"
        case 4: return "Employment Info"
        case 5: return "Bank Details"
        case 6: return "Documents Setup"
        case 7: return "Signature & Selfie"
        case 8: return "Nominee & Contact"
        case 9: return "Review Details"
        case 10: return "Consent & Submit"
        default: return "Loan Wizard"
        }
    }

    private func handleBackAction() {
        if currentStep > 1 {
            navigationDirection = .backward
            withAnimation(.smooth(duration: 0.32)) {
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
        currentStep = min(max(viewModel.currentStepIndex, 1), 10)

        ensureRequiredDocumentsLoaded()
        hydrateWizardStateFromFormData()
    }

    private func ensureRequiredDocumentsLoaded() {
        guard viewModel.documents.isEmpty else {
            viewModel.normalizeDuplicateDocumentRequirements()
            return
        }

        viewModel.documents = BorrowerLoanDocumentItem.defaultRequirements(
            for: product,
            identityDoc: viewModel.formData.selectedIdentityDoc,
            addressDoc: viewModel.formData.selectedAddressDoc,
            incomeDoc: viewModel.formData.selectedIncomeDoc
        )
        viewModel.normalizeDuplicateDocumentRequirements(autosave: false)
        viewModel.autosaveDraft()
    }

    private func hydrateWizardStateFromFormData() {
        if viewModel.formData.requestedAmountValue > 0 {
            desiredAmount = viewModel.formData.requestedAmountValue
        } else {
            viewModel.formData.loanAmountRequested = String(Int(desiredAmount))
        }

        if viewModel.formData.preferredTenureMonths > 0 {
            loanTenureMonths = Double(viewModel.formData.preferredTenureMonths)
        }

        if !viewModel.formData.employerName.isEmpty {
            if viewModel.formData.employmentType == "Salaried" {
                salariedCompany = viewModel.formData.employerName
            } else {
                selfEmployedBusinessName = viewModel.formData.employerName
            }
        }
        if !viewModel.formData.occupation.isEmpty {
            salariedDesignation = viewModel.formData.occupation
        }
        if viewModel.formData.workExperienceYears > 0 {
            selfEmployedYearsInBusiness = viewModel.formData.workExperienceYears
        }
        if !viewModel.formData.gstNumber.isEmpty {
            selfEmployedGSTNumber = viewModel.formData.gstNumber
        }
        if !viewModel.formData.existingLoans.isEmpty {
            existingLoansCount = viewModel.formData.existingLoans
        }
        if !viewModel.formData.creditCardObligations.isEmpty {
            creditCardOutstanding = viewModel.formData.creditCardObligations
        }
        if let joiningDate = viewModel.formData.employmentJoiningDate {
            salariedJoiningDate = joiningDate
        }
        creditCardLimit = viewModel.formData.creditCardLimit
        savingsInvestments = viewModel.formData.savingsInvestments

        bankName = viewModel.formData.bankName
        bankAccountNumber = viewModel.formData.bankAccountNumber
        bankIFSCCode = viewModel.formData.bankIFSCCode
        bankRegisteredMobile = viewModel.formData.bankRegisteredMobile
        monthlySalaryDeposited = viewModel.formData.monthlySalaryDeposited
        autoDebitConsent = viewModel.formData.autoDebitConsent

        hasCoApplicantToggle = viewModel.formData.hasCoApplicant
        if viewModel.formData.hasCoApplicant, !viewModel.formData.coApplicantDetails.isEmpty {
            let details = viewModel.formData.coApplicantDetails
            if let openParen = details.lastIndex(of: "("),
               let closeParen = details.lastIndex(of: ")"),
               openParen < closeParen {
                coApplicantName = String(details[..<openParen]).trimmingCharacters(in: .whitespacesAndNewlines)
                coApplicantRelation = String(details[details.index(after: openParen)..<closeParen])
            } else {
                coApplicantName = details
            }
        }
        coApplicantMobile = viewModel.formData.coApplicantMobile
        coApplicantPAN = viewModel.formData.coApplicantPAN
        coApplicantAadhaar = viewModel.formData.coApplicantAadhaar
        coApplicantIncome = viewModel.formData.coApplicantIncome

        nomineeName = viewModel.formData.nomineeName
        if !viewModel.formData.nomineeRelation.isEmpty {
            coApplicantRelation = viewModel.formData.nomineeRelation
        }
        nomineeMobile = viewModel.formData.nomineeMobile
        ocrPANFather = viewModel.formData.referenceName
        ocrPANNumber = viewModel.formData.referenceMobile

        acceptTerms = viewModel.formData.acceptedTerms
        acceptBureau = viewModel.formData.acceptedBureauConsent
        acceptDebit = viewModel.formData.acceptedDebitConsent
        liveVerificationCompleted = viewModel.formData.liveVerificationCompleted
        liveVerificationReference = viewModel.formData.liveVerificationReference.isEmpty ? nil : viewModel.formData.liveVerificationReference
        if !viewModel.formData.signatureImageData.isEmpty,
           let data = Data(base64Encoded: viewModel.formData.signatureImageData),
           let image = UIImage(data: data) {
            signatureImage = image
            isSignatureEmpty = false
        }
    }

    private func syncWizardFormToViewModel() {
        viewModel.formData.loanAmountRequested = String(Int(desiredAmount))
        viewModel.formData.preferredTenureMonths = Int(loanTenureMonths)
        viewModel.formData.draftStepIndex = currentStep

        if viewModel.formData.employmentType == "Salaried" {
            if !salariedCompany.isEmpty {
                viewModel.formData.employerName = salariedCompany
            }
            if !salariedDesignation.isEmpty {
                viewModel.formData.occupation = salariedDesignation
            }
            let years = Calendar.current.dateComponents([.year], from: salariedJoiningDate, to: Date()).year ?? 0
            viewModel.formData.workExperienceYears = max(0, years)
            viewModel.formData.employmentJoiningDate = salariedJoiningDate
            if viewModel.formData.annualIncomeValue <= 0, viewModel.formData.monthlyIncomeValue > 0 {
                let annual = Int(viewModel.formData.monthlyIncomeValue * 12)
                viewModel.formData.annualIncome = annual > 0 ? String(annual) : ""
            }
        } else {
            if !selfEmployedBusinessName.isEmpty {
                viewModel.formData.employerName = selfEmployedBusinessName
            }
            if !selfEmployedBusinessType.isEmpty {
                viewModel.formData.occupation = selfEmployedBusinessType
            }
            viewModel.formData.workExperienceYears = selfEmployedYearsInBusiness
            viewModel.formData.gstNumber = selfEmployedGSTNumber
            if viewModel.formData.annualIncomeValue <= 0, !selfEmployedAnnualProfit.isEmpty {
                viewModel.formData.annualIncome = selfEmployedAnnualProfit
            }
            if viewModel.formData.monthlyIncomeValue <= 0, viewModel.formData.annualIncomeValue > 0 {
                let monthly = max(1, Int(viewModel.formData.annualIncomeValue / 12))
                viewModel.formData.monthlyIncome = viewModel.formData.annualIncomeValue > 0 ? String(monthly) : ""
            }
        }

        if !existingLoansCount.isEmpty {
            viewModel.formData.existingLoans = existingLoansCount
        }
        if !creditCardOutstanding.isEmpty {
            viewModel.formData.creditCardObligations = creditCardOutstanding
        }
        viewModel.formData.creditCardLimit = creditCardLimit
        viewModel.formData.savingsInvestments = savingsInvestments
        viewModel.formData.bankName = bankName
        viewModel.formData.bankAccountNumber = bankAccountNumber
        viewModel.formData.bankIFSCCode = bankIFSCCode
        viewModel.formData.bankRegisteredMobile = bankRegisteredMobile
        viewModel.formData.monthlySalaryDeposited = monthlySalaryDeposited
        viewModel.formData.autoDebitConsent = autoDebitConsent

        viewModel.formData.hasCoApplicant = hasCoApplicantToggle
        if hasCoApplicantToggle, !coApplicantName.isEmpty {
            viewModel.formData.coApplicantDetails = "\(coApplicantName) (\(coApplicantRelation))"
        }
        viewModel.formData.coApplicantMobile = coApplicantMobile
        viewModel.formData.coApplicantPAN = coApplicantPAN
        viewModel.formData.coApplicantAadhaar = coApplicantAadhaar
        viewModel.formData.coApplicantIncome = coApplicantIncome
        viewModel.formData.nomineeName = nomineeName
        viewModel.formData.nomineeRelation = coApplicantRelation
        viewModel.formData.nomineeMobile = nomineeMobile
        viewModel.formData.referenceName = ocrPANFather
        viewModel.formData.referenceMobile = ocrPANNumber
        viewModel.formData.emergencyContactName = ocrPANFather
        viewModel.formData.emergencyContactMobile = ocrPANNumber
        viewModel.formData.liveVerificationCompleted = liveVerificationCompleted
        viewModel.formData.liveVerificationReference = liveVerificationReference ?? ""
        if let signatureImage,
           let data = signatureImage.pngData() {
            viewModel.formData.signatureImageData = data.base64EncodedString()
        }
        viewModel.formData.acceptedTerms = acceptTerms
        viewModel.formData.acceptedBureauConsent = acceptBureau
        viewModel.formData.acceptedDebitConsent = acceptDebit

    }

    private func persistCurrentDraftImmediately() {
        syncWizardFormToViewModel()
        viewModel.updateDraftStep(currentStep)
        viewModel.flushAutosave()
        isAutosaving = false
        lastAutosavedTime = Date()
    }

    private func triggerAutosave() {
        isAutosaving = true
        syncWizardFormToViewModel()
        viewModel.autosaveDraft()
        scheduleAutosaveIndicator()
    }

    private func scheduleAutosaveIndicator() {
        isAutosaving = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            isAutosaving = false
            lastAutosavedTime = viewModel.lastDraftSavedAt ?? Date()
        }
    }
    
    private func handleNextAction() {
        stepValidationMessage = nil
        syncWizardFormToViewModel()
        triggerAutosave()

        if currentStep < 10 {
            if let validationMessage = validationMessageForCurrentStep() {
                stepValidationMessage = validationMessage
                HapticsManager.triggerNotification(type: .warning)
                return
            }

            if currentStep == 6 {
                let unuploadedDocuments = viewModel.documents.filter { $0.status == .pendingUpload }
                if !unuploadedDocuments.isEmpty {
                    stepValidationMessage = "Upload all required documents: \(unuploadedDocuments.map(\.name).joined(separator: ", "))."
                    HapticsManager.triggerNotification(type: .warning)
                    return
                }
            }

            navigationDirection = .forward
            withAnimation(.smooth(duration: 0.32)) {
                currentStep += 1
            }
        } else {
            if let validationMessage = validationMessageForCurrentStep() {
                stepValidationMessage = validationMessage
                HapticsManager.triggerNotification(type: .warning)
                return
            }

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

    private func validationMessageForCurrentStep() -> String? {
        switch currentStep {
        case 3:
            if let mobileValidation = MobileNumberValidator.validationMessage(for: viewModel.formData.mobileNumber) {
                return mobileValidation
            }
            if let addressValidation = viewModel.validationMessage(for: .address) {
                return addressValidation
            }
            return viewModel.validationMessage(for: .preferredBranch)
        case 5:
            return MobileNumberValidator.validationMessage(for: bankRegisteredMobile)
        case 7:
            if !liveVerificationCompleted {
                return "Please complete live facial verification"
            }
            if isSignatureEmpty || signatureImage == nil {
                return "Please provide your signature"
            }
            return nil
        case 8:
            if let nomineeValidation = MobileNumberValidator.validationMessage(for: nomineeMobile) {
                return nomineeValidation
            }
            return MobileNumberValidator.validationMessage(for: ocrPANNumber)
        case 10:
            if !isLoanPurposeValid {
                return "Please provide the purpose of the loan."
            }
            if !acceptTerms || !acceptBureau || !acceptDebit {
                return "Please accept all consent checklist items."
            }
            return nil
        default:
            return nil
        }
    }
    
    private func ensureFullyVerified() {
        viewModel.runBulkVerification()
    }
    
    private func beginDocumentSelection(for docId: UUID, source: BorrowerDocumentUploadSource) {
        selectedUploadDocId = docId
        uploadSource = source
        imagePickerSourceType = source == .camera && UIImagePickerController.isSourceTypeAvailable(.camera)
            ? .camera
            : .photoLibrary
        showDocumentImagePicker = true
    }

    private func processSelectedDocumentImage(_ image: UIImage, for docId: UUID, source: BorrowerDocumentUploadSource) {
        guard let doc = viewModel.documents.first(where: { $0.id == docId }) else { return }

        HapticsManager.triggerImpact(style: .medium)
        documentThumbnails[docId] = image
        documentFailureReasons[docId] = nil
        documentExtractedDetails[docId] = [:]
        uploadLifecycle[docId] = .uploading
        isUploading[doc.name] = true
        uploadProgress[doc.name] = 0.0
        ocrStatus[doc.name] = "None"

        let steps = 10
        let timeInterval = 0.06
        for i in 1...steps {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * timeInterval) {
                uploadProgress[doc.name] = Double(i) / Double(steps)
                if i == steps {
                    isUploading[doc.name] = false
                    uploadLifecycle[docId] = .processing
                    ocrStatus[doc.name] = "Scanning"
                    viewModel.uploadDocument(docId, fileName: imageFileName(for: doc), source: source, image: image)
                    viewModel.markDocument(docId, status: .underVerification)

                    Task {
                        let ocr = await recognizeText(in: image)
                        let result = validateDocument(doc, recognizedText: ocr.text, confidence: ocr.confidence)
                        await MainActor.run {
                            applyOCRResult(result, to: doc, image: image)
                        }
                    }
                }
            }
        }
    }

    private func imageFileName(for doc: BorrowerLoanDocumentItem) -> String {
        let normalized = doc.name
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
        return "\(normalized)_\(Int(Date().timeIntervalSince1970)).jpg"
    }

    private func processSelectedDocumentFile(_ result: Result<[URL], Error>, for docId: UUID) {
        guard let doc = viewModel.documents.first(where: { $0.id == docId }) else { return }

        do {
            guard let url = try result.get().first else { return }
            let didAccess = url.startAccessingSecurityScopedResource()
            defer {
                if didAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            let data = try Data(contentsOf: url)
            guard !data.isEmpty else {
                documentFailureReasons[docId] = "The selected PDF is empty. Choose a valid document."
                uploadLifecycle[docId] = .failed
                viewModel.markDocument(docId, status: .rejected)
                return
            }

            HapticsManager.triggerImpact(style: .medium)
            documentFailureReasons[docId] = nil
            documentExtractedDetails[docId] = [
                "Document": doc.name,
                "File": url.lastPathComponent,
                "Size": ByteCountFormatter.string(fromByteCount: Int64(data.count), countStyle: .file)
            ]
            uploadLifecycle[docId] = .uploading
            isUploading[doc.name] = true
            uploadProgress[doc.name] = 0.0
            ocrStatus[doc.name] = "Manual Review"

            let steps = 8
            for i in 1...steps {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                    uploadProgress[doc.name] = Double(i) / Double(steps)
                    if i == steps {
                        isUploading[doc.name] = false
                        uploadLifecycle[docId] = .success
                        documentUploadDates[docId] = Date()
                        viewModel.uploadDocument(
                            docId,
                            fileName: pdfFileName(for: doc, originalName: url.lastPathComponent),
                            source: .pdf,
                            fileData: data,
                            contentType: "application/pdf",
                            fileExtension: "pdf"
                        )
                        viewModel.markDocument(docId, status: .uploaded)
                        triggerAutosave()
                        HapticsManager.triggerNotification(type: .success)
                    }
                }
            }
        } catch {
            documentFailureReasons[docId] = "Unable to read the selected PDF. Please try another file."
            uploadLifecycle[docId] = .failed
            viewModel.markDocument(docId, status: .rejected)
            HapticsManager.triggerNotification(type: .error)
        }
    }

    private func pdfFileName(for doc: BorrowerLoanDocumentItem, originalName: String) -> String {
        let normalized = doc.name
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "_")
        let originalBase = originalName
            .replacingOccurrences(of: ".pdf", with: "", options: [.caseInsensitive])
            .filter { $0.isLetter || $0.isNumber || $0 == "_" || $0 == "-" }
        let suffix = originalBase.isEmpty ? "\(Int(Date().timeIntervalSince1970))" : originalBase
        return "\(normalized)_\(suffix).pdf"
    }

    private func recognizeText(in image: UIImage) async -> (text: String, confidence: Float) {
        guard let cgImage = image.cgImage else { return ("", 0) }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let candidates = observations.compactMap { $0.topCandidates(1).first }
                let text = candidates.map(\.string).joined(separator: "\n")
                let confidence = candidates.isEmpty
                    ? 0
                    : candidates.map(\.confidence).reduce(0, +) / Float(candidates.count)
                continuation.resume(returning: (text, confidence))
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-IN", "en-US"]

            DispatchQueue.global(qos: .userInitiated).async {
                let handler = VNImageRequestHandler(cgImage: cgImage, orientation: CGImagePropertyOrientation(image.imageOrientation), options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(returning: ("", 0))
                }
            }
        }
    }

    private func validateDocument(_ doc: BorrowerLoanDocumentItem, recognizedText text: String, confidence: Float) -> DocumentOCRResult {
        let normalized = text.lowercased()
        let name = doc.name.lowercased()

        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || confidence < 0.18 {
            return DocumentOCRResult(
                isValid: false,
                title: "Document Not Readable",
                message: "The image is blurry or text could not be detected. Please upload a clear document image.",
                extractedDetails: ["OCR Confidence": confidenceLabel(confidence)],
                fullName: nil,
                dateOfBirth: nil,
                address: nil
            )
        }

        if name.contains("aadhaar") || name.contains("aadhar") {
            return validateAadhaar(text: text, normalized: normalized, confidence: confidence)
        } else if name.contains("pan") {
            return validatePAN(text: text, normalized: normalized, confidence: confidence)
        } else if name.contains("salary") || name.contains("payslip") {
            return validateKeywordDocument(
                title: "Salary Slip",
                invalidTitle: "Invalid Salary Slip",
                invalidMessage: "The uploaded file does not appear to be a salary slip. Please upload a clear payslip image.",
                text: text,
                normalized: normalized,
                confidence: confidence,
                keywords: ["salary", "payslip", "pay slip", "net pay", "gross", "earnings", "deductions", "employee"]
            )
        } else if name.contains("bank statement") || name.contains("bank statements") {
            return validateKeywordDocument(
                title: "Bank Statement",
                invalidTitle: "Invalid Bank Statement",
                invalidMessage: "The uploaded file does not appear to be a bank statement. Please upload a clear statement image.",
                text: text,
                normalized: normalized,
                confidence: confidence,
                keywords: ["statement", "account number", "transaction", "debit", "credit", "balance", "ifsc"]
            )
        } else if name.contains("utility") {
            return validateKeywordDocument(
                title: "Utility Bill",
                invalidTitle: "Invalid Address Document",
                invalidMessage: "The uploaded file does not appear to be a valid utility bill. Please upload a clear bill with address details.",
                text: text,
                normalized: normalized,
                confidence: confidence,
                keywords: ["bill", "electricity", "water", "gas", "consumer", "address", "amount due"]
            )
        }

        return validateKeywordDocument(
            title: doc.name,
            invalidTitle: "Invalid Document",
            invalidMessage: "The uploaded file does not match the selected document type. Please upload the required document.",
            text: text,
            normalized: normalized,
            confidence: confidence,
            keywords: [doc.name.lowercased()]
        )
    }

    private func validateAadhaar(text: String, normalized: String, confidence: Float) -> DocumentOCRResult {
        let aadhaarNumber = firstMatch(in: text, pattern: #"(?<!\d)(\d{4}\s?\d{4}\s?\d{4})(?!\d)"#)
        let hasKeyword = normalized.contains("government of india") || normalized.contains("aadhaar") || normalized.contains("aadhar") || normalized.contains("uidai")
        let isValid = confidence >= 0.24 && (hasKeyword || aadhaarNumber != nil)

        guard isValid else {
            return DocumentOCRResult(
                isValid: false,
                title: "Invalid Aadhaar Document",
                message: "The uploaded file does not appear to be a valid Aadhaar card. Please upload a clear Aadhaar image.",
                extractedDetails: ["OCR Confidence": confidenceLabel(confidence)],
                fullName: nil,
                dateOfBirth: nil,
                address: nil
            )
        }

        let dob = extractDate(from: text)
        let fullName = extractLikelyName(from: text, excluding: ["government", "india", "aadhaar", "uidai", "male", "female"])
        let masked = aadhaarNumber.map(maskAadhaar) ?? "Detected"
        var details = [
            "Document": "Aadhaar Card",
            "Aadhaar Number": masked,
            "OCR Confidence": confidenceLabel(confidence)
        ]
        if let fullName { details["Full Name"] = fullName }
        if let dob { details["DOB"] = dob.formattedAsDDMMMYYYY() }

        return DocumentOCRResult(
            isValid: true,
            title: "Document Verified",
            message: "We extracted the following details. Please verify.",
            extractedDetails: details,
            fullName: fullName,
            dateOfBirth: dob,
            address: extractAddress(from: text)
        )
    }

    private func validatePAN(text: String, normalized: String, confidence: Float) -> DocumentOCRResult {
        let pan = firstMatch(in: text.uppercased(), pattern: #"[A-Z]{5}[0-9]{4}[A-Z]"#)
        let hasKeyword = normalized.contains("income tax") || normalized.contains("permanent account") || normalized.contains("भारत सरकार")
        let isValid = confidence >= 0.22 && (hasKeyword || pan != nil)

        guard isValid else {
            return DocumentOCRResult(
                isValid: false,
                title: "Invalid PAN Document",
                message: "The uploaded file does not appear to be a valid PAN card. Please upload a clear PAN image.",
                extractedDetails: ["OCR Confidence": confidenceLabel(confidence)],
                fullName: nil,
                dateOfBirth: nil,
                address: nil
            )
        }

        let dob = extractDate(from: text)
        let fullName = extractLikelyName(from: text, excluding: ["income", "tax", "department", "government", "india", "permanent", "account", "number"])
        var details = [
            "Document": "PAN Card",
            "PAN": pan ?? "Detected",
            "OCR Confidence": confidenceLabel(confidence)
        ]
        if let fullName { details["Full Name"] = fullName }
        if let dob { details["DOB"] = dob.formattedAsDDMMMYYYY() }

        return DocumentOCRResult(
            isValid: true,
            title: "Document Verified",
            message: "We extracted the following details. Please verify.",
            extractedDetails: details,
            fullName: fullName,
            dateOfBirth: dob,
            address: nil
        )
    }

    private func validateKeywordDocument(
        title: String,
        invalidTitle: String,
        invalidMessage: String,
        text: String,
        normalized: String,
        confidence: Float,
        keywords: [String]
    ) -> DocumentOCRResult {
        let hits = keywords.filter { normalized.contains($0) }
        let isValid = confidence >= 0.20 && !hits.isEmpty

        return DocumentOCRResult(
            isValid: isValid,
            title: isValid ? "Document Uploaded" : invalidTitle,
            message: isValid ? "We extracted the following details. Please verify." : invalidMessage,
            extractedDetails: [
                "Document": title,
                "Matched Signals": hits.isEmpty ? "None" : hits.joined(separator: ", "),
                "OCR Confidence": confidenceLabel(confidence)
            ],
            fullName: nil,
            dateOfBirth: nil,
            address: extractAddress(from: text)
        )
    }

    private func applyOCRResult(_ result: DocumentOCRResult, to doc: BorrowerLoanDocumentItem, image: UIImage) {
        ocrStatus[doc.name] = result.isValid ? "Success" : "Failed"
        uploadLifecycle[doc.id] = result.isValid ? .success : .failed
        documentExtractedDetails[doc.id] = result.extractedDetails

        if result.isValid {
            documentUploadDates[doc.id] = Date()
            documentFailureReasons[doc.id] = nil
            viewModel.markDocument(doc.id, status: .uploaded)

            if let fullName = result.fullName,
               !fullName.isEmpty,
               !BorrowerLoanFormData.isMockValue(fullName) {
                viewModel.formData.fullName = fullName
                ocrAadhaarName = fullName
                ocrPANName = fullName
            }
            if let dateOfBirth = result.dateOfBirth {
                viewModel.formData.dateOfBirth = dateOfBirth
                ocrAadhaarDOB = dateOfBirth
                ocrPANDOB = dateOfBirth
            }
            if let address = result.address, !address.isEmpty, viewModel.formData.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                viewModel.formData.address = address
                ocrAadhaarAddress = address
            }
            triggerAutosave()
            HapticsManager.triggerNotification(type: .success)
        } else {
            documentFailureReasons[doc.id] = result.message
            viewModel.markDocument(doc.id, status: .rejected)
            HapticsManager.triggerNotification(type: .error)
        }
    }

    private func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range),
              let matchRange = Range(match.range, in: text) else { return nil }
        return String(text[matchRange])
    }

    private func maskAadhaar(_ raw: String) -> String {
        let digits = raw.filter(\.isNumber)
        guard digits.count >= 4 else { return "XXXX XXXX XXXX" }
        return "XXXX XXXX \(digits.suffix(4))"
    }

    private func confidenceLabel(_ confidence: Float) -> String {
        switch confidence {
        case 0.72...: return "High"
        case 0.40..<0.72: return "Medium"
        default: return "Low"
        }
    }

    private func extractDate(from text: String) -> Date? {
        guard let raw = firstMatch(in: text, pattern: #"(?<!\d)(\d{2}[/-]\d{2}[/-]\d{4})(?!\d)"#) else { return nil }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_IN")
        for format in ["dd/MM/yyyy", "dd-MM-yyyy"] {
            formatter.dateFormat = format
            if let date = formatter.date(from: raw) {
                return date
            }
        }
        return nil
    }

    private func extractLikelyName(from text: String, excluding blockedWords: [String]) -> String? {
        let blocked = Set(blockedWords)
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { line in
                let lower = line.lowercased()
                let words = lower.components(separatedBy: .whitespaces)
                return line.count >= 5 &&
                    line.count <= 36 &&
                    !line.contains(where: \.isNumber) &&
                    !words.contains(where: blocked.contains)
            }
        return lines.first
    }

    private func extractAddress(from text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)
        guard let addressIndex = lines.firstIndex(where: { $0.localizedCaseInsensitiveContains("address") }) else { return nil }
        let addressLines = lines.dropFirst(addressIndex + 1).prefix(3)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return addressLines.isEmpty ? nil : addressLines.joined(separator: ", ")
    }
}

// MARK: - Premium UI Components

private struct LoanContextChip: View {
    let product: BorrowerLoanProduct
    let amount: Double
    let interestRate: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: product.type.iconName)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(LMSColors.brandNavy)
            
            Text(product.type.title)
                .font(LMSFont.caption.weight(.bold))
                .foregroundStyle(LMSColors.textPrimary)
            
            Text("•")
                .foregroundStyle(LMSColors.textTertiary)
            
            Text(amount.formattedAsINR())
                .font(LMSFont.caption.weight(.semibold))
                .foregroundStyle(LMSColors.brandNavy)
            
            Text("•")
                .foregroundStyle(LMSColors.textTertiary)
            
            Text(interestRate)
                .font(LMSFont.caption.weight(.semibold))
                .foregroundStyle(LMSColors.emerald)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(LMSColors.surface, in: Capsule())
        .overlay(
            Capsule()
                .stroke(LMSColors.separatorLight.opacity(0.4), lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - STEP 1: Overview
private struct Step1OverviewView: View {
    let product: BorrowerLoanProduct

    var body: some View {
        VStack(spacing: LMSSpacing.lg) {
            VStack(alignment: .center, spacing: 8) {
                Text(product.type.title)
                    .font(LMSFont.title.weight(.bold))
                    .foregroundStyle(LMSColors.brandNavy)
                
                Text(product.shortDescription)
                    .font(LMSFont.body)
                    .foregroundStyle(LMSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(.top, 16)
            
            WizardFormSection(title: "Loan Information") {
                WizardInlineValueRow(label: "Maximum Available Limit", value: product.maximumAmount.formattedAsINR(), valueColor: LMSColors.brandNavy)
                FormDivider()
                WizardInlineValueRow(label: "Estimated Processing Time", value: product.estimatedProcessingTime)
                FormDivider()
                WizardInlineValueRow(label: "Interest Rates", value: product.interestRateRange, valueColor: LMSColors.emerald)
            }
            
            WizardFormSection(title: "Product Benefits") {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(product.benefits, id: \.self) { benefit in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(LMSColors.emerald)
                                .font(.system(size: 16))
                            Text(benefit)
                                .font(LMSFont.body)
                                .foregroundStyle(LMSColors.textPrimary)
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
        }
    }
}

// MARK: - STEP 2: Eligibility Check
private struct Step2EligibilityCheckView: View {
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

    private var recommendationText: String {
        if foirPercentage > 60 {
            return "Your EMI is relatively high compared to income. Consider increasing tenure or reducing the loan amount."
        } else if foirPercentage > 45 {
            return "This looks workable, but a slightly longer tenure may improve comfort and approval strength."
        } else {
            return "Your estimated EMI appears comfortable against your income profile."
        }
    }

    var body: some View {
        VStack(spacing: LMSSpacing.lg) {
            WizardFormSection(title: "Configure Plan") {
                VStack(spacing: 20) {
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
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    
                    Divider()
                    
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
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
                }
            }
            
            WizardFormSection(title: "Monthly Income & Obligations") {
                HStack {
                    Text("Monthly Income")
                        .font(LMSFont.body.weight(.semibold))
                        .foregroundStyle(LMSColors.textPrimary)
                    Spacer()
                    TextField("₹ 80,000", text: $viewModel.formData.monthlyIncome)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .font(LMSFont.body.weight(.bold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                
                FormDivider()
                
                HStack {
                    Text("Existing EMIs")
                        .font(LMSFont.body.weight(.semibold))
                        .foregroundStyle(LMSColors.textPrimary)
                    Spacer()
                    TextField("₹ 0", text: $viewModel.formData.existingEMIs)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .font(LMSFont.body.weight(.bold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
            
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ESTIMATED EMI")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(LMSColors.textSecondary)
                        Text("\(suggestedEMI.formattedAsINR())/mo")
                            .font(LMSFont.title3.weight(.bold))
                            .foregroundStyle(LMSColors.brandNavy)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("ESTIMATED FOIR")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundStyle(LMSColors.textSecondary)
                        Text("\(foirPercentage)%")
                            .font(LMSFont.title3.weight(.bold))
                            .foregroundStyle(foirPercentage > 50 ? LMSColors.coral : LMSColors.textPrimary)
                    }
                }
                
                Divider()
                
                HStack(spacing: 12) {
                    Circle()
                        .trim(from: 0.0, to: CGFloat(max(0.1, 1.0 - (Double(foirPercentage)/100.0))))
                        .stroke(probabilityColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .frame(width: 44, height: 44)
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.25), value: foirPercentage)
                        .overlay(
                            Text("\(100 - foirPercentage)%")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(probabilityColor)
                        )
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Approval: \(approvalProbability)")
                            .font(LMSFont.caption.weight(.bold))
                            .foregroundStyle(probabilityColor)
                        Text(recommendationText)
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.textSecondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .padding(16)
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
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

// MARK: - STEP 3: Personal Details
private struct Step3PersonalInfoOverhaulView: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    
    var body: some View {
        VStack(spacing: LMSSpacing.lg) {
            WizardFormSection(title: "Primary Profile") {
                WizardTextField(label: "Full Name", text: $viewModel.formData.fullName, placeholder: "Enter legal name")
                FormDivider()
                WizardDateRow(label: "Date of Birth", date: $viewModel.formData.dateOfBirth)
                FormDivider()
                WizardPickerRow(label: "Gender", selection: $viewModel.formData.gender, options: ["", "Male", "Female", "Other"]) { option in
                    option.isEmpty ? "Select Gender" : option
                }
            }
            
            WizardFormSection(title: "Contact Credentials") {
                WizardMobileField(label: "Mobile Number", text: $viewModel.formData.mobileNumber)
                FormDivider()
                WizardTextField(label: "Email Address", text: $viewModel.formData.emailAddress, placeholder: "yourname@domain.com", keyboardType: .emailAddress, disableAutocapitalization: true)
            }
            
            WizardFormSection(title: "Residence Information") {
                WizardTextField(label: "Current Address", text: $viewModel.formData.address, placeholder: "Door No, Building, Street Address")
                FormDivider()
                WizardPickerRow(
                    label: "Application Branch",
                    selection: $viewModel.formData.preferredBranch,
                    options: [""] + viewModel.branchesList.map(\.name)
                ) { option in
                    option.isEmpty ? "Select Branch" : option
                }
                FormDivider()
                WizardPickerRow(label: "Residence Ownership", selection: $viewModel.formData.repaymentPreference, options: ["Owned", "Rented", "Family Owned"]) { $0 }
            }
        }
    }
}

// MARK: - STEP 4: Employment & Income
private struct Step4EmploymentOverhaulView: View {
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
        VStack(spacing: LMSSpacing.lg) {
            // Segmented selection
            Picker("Employment Type", selection: $viewModel.formData.employmentType) {
                ForEach(viewModel.employmentTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            
            if viewModel.formData.employmentType == "Salaried" {
                WizardFormSection(title: "Salary Details") {
                    WizardTextField(label: "Employer Company Name", text: $salariedCompany, placeholder: "Enter employer name")
                    FormDivider()
                    WizardTextField(label: "Employee ID (Optional)", text: $salariedEmpID, placeholder: "Enter employee ID")
                    FormDivider()
                    WizardTextField(label: "Designation", text: $salariedDesignation, placeholder: "Enter designation")
                    FormDivider()
                    WizardDateRow(label: "Date of Joining", date: $salariedJoiningDate)
                    FormDivider()
                    WizardTextField(label: "Monthly Net Take-home", text: $viewModel.formData.monthlyIncome, placeholder: "Monthly income", keyboardType: .numberPad)
                }
            } else {
                WizardFormSection(title: "Business Details") {
                    WizardTextField(label: "Business Registered Name", text: $selfEmployedBusinessName, placeholder: "Enter registered business name")
                    FormDivider()
                    WizardPickerRow(label: "Business Entity Type", selection: $selfEmployedBusinessType, options: ["", "Proprietorship", "Partnership", "Pvt Ltd"]) { option in
                        option.isEmpty ? "Select Entity Type" : option
                    }
                    FormDivider()
                    HStack {
                        Text("Years in Business")
                            .font(LMSFont.body.weight(.semibold))
                            .foregroundStyle(LMSColors.textPrimary)
                        Spacer()
                        Stepper("\(selfEmployedYearsInBusiness) Years", value: $selfEmployedYearsInBusiness, in: 1...40)
                            .tint(LMSColors.brandNavy)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    FormDivider()
                    WizardTextField(label: "GST Registration No. (Optional)", text: $selfEmployedGSTNumber, placeholder: "Enter GST registration number", disableAutocapitalization: true)
                    FormDivider()
                    WizardTextField(label: "Net Annual Profit", text: $viewModel.formData.annualIncome, placeholder: "Annual profit", keyboardType: .numberPad)
                }
            }
            
            WizardFormSection(title: "Obligations & Assets") {
                WizardTextField(label: "Total Active Loans", text: $existingLoansCount, placeholder: "Number of active loans", keyboardType: .numberPad)
                FormDivider()
                WizardTextField(label: "Total Credit Card Limit", text: $creditCardLimit, placeholder: "Credit card limit", keyboardType: .numberPad)
                FormDivider()
                WizardTextField(label: "Credit Card Outstanding Balance", text: $creditCardOutstanding, placeholder: "Outstanding balance", keyboardType: .numberPad)
                FormDivider()
                WizardTextField(label: "Savings & Investments Worth", text: $savingsInvestments, placeholder: "Savings and investments", keyboardType: .numberPad)
            }
        }
    }
}

// MARK: - STEP 5: Bank Details View
private struct Step5BankDetailsView: View {
    @Binding var bankName: String
    @Binding var accountNo: String
    @Binding var ifscCode: String
    @Binding var registeredMobile: String
    @Binding var monthlySalaryDeposited: String
    @Binding var autoDebitConsent: Bool

    var body: some View {
        VStack(spacing: LMSSpacing.lg) {
            WizardFormSection(title: "Primary Bank Account") {
                WizardTextField(label: "Bank Name", text: $bankName, placeholder: "HDFC Bank, ICICI Bank, etc.")
                FormDivider()
                WizardTextField(label: "Account Number", text: $accountNo, placeholder: "12 to 18 Digit number", keyboardType: .numberPad)
                FormDivider()
                WizardTextField(label: "IFSC Code", text: $ifscCode, placeholder: "IFSC code", disableAutocapitalization: true)
            }
            
            WizardFormSection(title: "Salary Account details") {
                WizardMobileField(label: "Registered Mobile Number", text: $registeredMobile)
                FormDivider()
                WizardTextField(label: "Average Monthly Balance / Salary Deposited", text: $monthlySalaryDeposited, placeholder: "Monthly amount", keyboardType: .numberPad)
            }
            
            WizardFormSection(title: "e-Mandate / Auto-debit") {
                WizardToggleRow(
                    label: "Authorize Auto-Debit (e-Mandate)",
                    subtitle: "Authorize automatic repayment deduction from this bank account for seamless billing.",
                    isOn: $autoDebitConsent
                )
            }
        }
    }
}

// MARK: - STEP 6: Document Center
private struct Step6DocumentCenterOverhaulView: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let product: BorrowerLoanProduct
    @Binding var stepValidationMessage: String?
    @Binding var uploadProgress: [String: Double]
    @Binding var isUploading: [String: Bool]
    @Binding var ocrStatus: [String: String]
    let uploadLifecycle: [UUID: DocumentUploadLifecycle]
    let thumbnails: [UUID: UIImage]
    let uploadDates: [UUID: Date]
    let failureReasons: [UUID: String]
    let extractedDetails: [UUID: [String: String]]
    let onTriggerUpload: (UUID) -> Void
    let onViewDocument: (BorrowerLoanDocumentItem) -> Void
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
                .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 16)
            } else {
                documentSection(
                    title: "Identity Credentials",
                    category: .identityVerification
                )
                documentSection(
                    title: "Address Credentials",
                    category: .addressVerification
                )
                documentSection(
                    title: "Income Credentials",
                    category: .incomeVerification
                )

                let loanSpecific = viewModel.documents(for: .loanSpecific)
                if !loanSpecific.isEmpty {
                    documentSection(
                        title: "Loan Specific Files",
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
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(LMSFont.caption2.weight(.bold))
                .foregroundStyle(LMSColors.textSecondary)
                .padding(.horizontal, 20)
            
            VStack(spacing: 0) {
                if docs.isEmpty {
                    Text("No document required.")
                        .font(LMSFont.footnote)
                        .foregroundStyle(LMSColors.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                } else {
                    ForEach(Array(docs.enumerated()), id: \.element.id) { index, doc in
                        UploadRow(
                            doc: doc,
                            progress: uploadProgress[doc.name] ?? 0.0,
                            lifecycle: uploadLifecycle[doc.id] ?? .idle,
                            thumbnail: thumbnails[doc.id],
                            uploadDate: uploadDates[doc.id] ?? doc.uploadDate,
                            failureReason: failureReasons[doc.id],
                            extractedDetails: extractedDetails[doc.id] ?? [:],
                            uploading: isUploading[doc.name] ?? false,
                            ocr: ocrStatus[doc.name] ?? "None",
                            onTrigger: { onTriggerUpload(doc.id) },
                            onView: { onViewDocument(doc) }
                        )
                        
                        if index < docs.count - 1 {
                            FormDivider()
                        }
                    }
                }
            }
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(LMSColors.separatorLight.opacity(0.4), lineWidth: 0.8)
            )
            .padding(.horizontal, 16)
        }
    }
}

// Upload Row Component
private struct UploadRow: View {
    let doc: BorrowerLoanDocumentItem
    let progress: Double
    let lifecycle: DocumentUploadLifecycle
    let thumbnail: UIImage?
    let uploadDate: Date?
    let failureReason: String?
    let extractedDetails: [String: String]
    let uploading: Bool
    let ocr: String
    let onTrigger: () -> Void
    let onView: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                documentIcon
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(doc.name)
                        .font(LMSFont.callout.weight(.semibold))
                        .foregroundStyle(LMSColors.textPrimary)
                    
                    if lifecycle == .uploading || uploading {
                        Text("Uploading document…")
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.actionBlue)
                    } else if lifecycle == .processing || ocr == "Scanning" {
                        Text("Verifying document…")
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.amber)
                    } else if lifecycle == .success || doc.status == .uploaded || doc.status == .verified {
                        Text(doc.status == .verified ? "Verified Successfully" : "Uploaded Successfully")
                            .font(LMSFont.caption)
                            .foregroundStyle(doc.status == .verified ? LMSColors.emerald : LMSColors.actionBlue)
                    } else if lifecycle == .failed || doc.status == .rejected || doc.status == .requiresResubmission {
                        Text(failureReason ?? doc.status.rawValue)
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.coral)
                            .lineLimit(2)
                    } else {
                        Text(doc.status.rawValue)
                            .font(LMSFont.caption)
                            .foregroundStyle(doc.status.tintColor)
                    }
                }
                
                Spacer()
                
                if doc.status == .pendingUpload && !uploading && lifecycle != .processing {
                    Button(action: onTrigger) {
                        Text("Upload")
                            .font(LMSFont.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(LMSColors.brandNavy, in: Capsule())
                    }
                    .buttonStyle(LMSPressableStyle())
                } else if lifecycle == .uploading || lifecycle == .processing || uploading {
                    ProgressView()
                        .tint(lifecycle == .processing ? LMSColors.amber : LMSColors.actionBlue)
                } else if doc.status != .pendingUpload {
                    HStack(spacing: 8) {
                        Button(action: onTrigger) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.footnote)
                                .foregroundStyle(LMSColors.textSecondary)
                                .frame(width: 28, height: 28)
                                .background(LMSColors.surfaceTertiary, in: Circle())
                        }
                        
                        Button(action: onView) {
                            Image(systemName: "eye.fill")
                                .font(.footnote)
                                .foregroundStyle(LMSColors.textSecondary)
                                .frame(width: 28, height: 28)
                                .background(LMSColors.surfaceTertiary, in: Circle())
                        }
                        .disabled(thumbnail == nil)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            if lifecycle == .uploading || uploading {
                ProgressView(value: progress)
                    .tint(LMSColors.actionBlue)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            } else if lifecycle == .processing || ocr == "Scanning" {
                ProgressView()
                    .tint(LMSColors.amber)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
            }

            if lifecycle == .success || doc.status == .uploaded || doc.status == .verified {
                verifiedPreview
            } else if lifecycle == .failed || doc.status == .rejected || doc.status == .requiresResubmission {
                failurePreview
            }
        }
    }

    @ViewBuilder
    private var documentIcon: some View {
        if let thumbnail {
            Image(uiImage: thumbnail)
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(statusColor.opacity(0.35), lineWidth: 1)
                )
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(statusColor.opacity(0.1))
                    .frame(width: 42, height: 42)
                Image(systemName: statusIcon)
                    .font(.title3)
                    .foregroundStyle(statusColor)
            }
        }
    }

    private var verifiedPreview: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(
                    doc.status == .verified ? "Document Verified" : "Document Uploaded",
                    systemImage: doc.status == .verified ? "checkmark.seal.fill" : "arrow.up.doc.fill"
                )
                .font(LMSFont.caption.weight(.bold))
                .foregroundStyle(doc.status == .verified ? LMSColors.emerald : LMSColors.actionBlue)
                Spacer()
                if let uploadDate {
                    Text(uploadDate.formattedAsDDMMMYYYY())
                        .font(LMSFont.caption2)
                        .foregroundStyle(LMSColors.textSecondary)
                }
            }

            if !extractedDetails.isEmpty {
                Text("We extracted the following details. Please verify.")
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)

                ForEach(extractedDetails.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    HStack {
                        Text(key)
                            .font(LMSFont.caption2)
                            .foregroundStyle(LMSColors.textSecondary)
                        Spacer()
                        Text(value)
                            .font(LMSFont.caption2.weight(.semibold))
                            .foregroundStyle(LMSColors.textPrimary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                }
            }

            HStack(spacing: 10) {
                Button("Replace", action: onTrigger)
                    .font(LMSFont.caption.weight(.bold))
                Button("View Document", action: onView)
                    .font(LMSFont.caption.weight(.bold))
                    .disabled(thumbnail == nil)
            }
            .foregroundStyle(LMSColors.brandNavy)
        }
        .padding(12)
        .background((doc.status == .verified ? LMSColors.emerald : LMSColors.actionBlue).opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke((doc.status == .verified ? LMSColors.emerald : LMSColors.actionBlue).opacity(0.18), lineWidth: 0.8)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var failurePreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Verification Failed", systemImage: "xmark.octagon.fill")
                .font(LMSFont.caption.weight(.bold))
                .foregroundStyle(LMSColors.coral)
            Text(failureReason ?? "The uploaded file does not match the selected document type. Please try again with a clear image.")
                .font(LMSFont.caption)
                .foregroundStyle(LMSColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button("Retry Upload", action: onTrigger)
                .font(LMSFont.caption.weight(.bold))
                .foregroundStyle(LMSColors.brandNavy)
        }
        .padding(12)
        .background(LMSColors.coral.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(LMSColors.coral.opacity(0.18), lineWidth: 0.8)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    private var statusIcon: String {
        switch lifecycle {
        case .uploading: return "arrow.up.doc.fill"
        case .processing: return "viewfinder"
        case .success: return "arrow.up.doc.fill"
        case .failed: return "xmark.octagon.fill"
        case .idle: return doc.status == .verified ? "checkmark.seal.fill" : (doc.status == .uploaded ? "arrow.up.doc.fill" : doc.status.iconName)
        }
    }

    private var statusColor: Color {
        switch lifecycle {
        case .uploading: return LMSColors.actionBlue
        case .processing: return LMSColors.amber
        case .success: return LMSColors.actionBlue
        case .failed: return LMSColors.coral
        case .idle: return doc.status == .verified ? LMSColors.emerald : (doc.status == .uploaded ? LMSColors.actionBlue : doc.status.tintColor)
        }
    }
}

// MARK: - STEP 7: Signature & Selfie View
private struct Step7SignaturePhotoView: View {
    @Binding var signatureImage: UIImage?
    @Binding var isSignatureEmpty: Bool
    @Binding var liveVerificationCompleted: Bool
    let onStartLiveVerification: () -> Void
    @State private var signatureCanvasID = UUID()

    var body: some View {
        VStack(spacing: LMSSpacing.lg) {
            VStack(alignment: .center, spacing: 8) {
                Image(systemName: "face.id")
                    .font(.system(size: 40))
                    .foregroundStyle(LMSColors.brandNavy)
                Text("Verification Proofs")
                    .font(LMSFont.title3.weight(.bold))
                    .foregroundStyle(LMSColors.textPrimary)
                Text("Complete a live face check and draw your signature to finish identity verification.")
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            WizardFormSection(title: "Live Selfie Status") {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(LMSColors.surfaceTertiary)
                            .frame(width: 54, height: 54)
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.title2)
                            .foregroundStyle(liveVerificationCompleted ? LMSColors.emerald : LMSColors.textTertiary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Live Facial Verification")
                            .font(LMSFont.body.weight(.semibold))
                            .foregroundStyle(LMSColors.textPrimary)
                        Text(liveVerificationCompleted ? "Live verification completed" : "Record a 10 second live face check")
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.textSecondary)
                    }

                    Spacer()

                    if liveVerificationCompleted {
                        Text("Verified")
                            .font(LMSFont.caption.weight(.bold))
                            .foregroundStyle(LMSColors.emerald)
                    } else {
                        Button("Start") {
                            onStartLiveVerification()
                        }
                        .font(LMSFont.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(LMSColors.brandNavy, in: Capsule())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }

            WizardFormSection(title: "Digital Signature") {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Draw Signature")
                                .font(LMSFont.body.weight(.semibold))
                                .foregroundStyle(LMSColors.textPrimary)
                            Text("Will be embedded in loan contract")
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "signature")
                            .font(.title3)
                            .foregroundStyle(LMSColors.brandNavy)
                    }

                    SignatureCanvasView(
                        signatureImage: $signatureImage,
                        isEmpty: $isSignatureEmpty,
                        canvasID: signatureCanvasID
                    )
                    .frame(height: 150)
                    .background(LMSColors.surfaceTertiary, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(isSignatureEmpty ? LMSColors.coral.opacity(0.35) : LMSColors.separatorLight, lineWidth: 1)
                    )

                    if isSignatureEmpty {
                        Text("Please provide your signature")
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.coral)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    HStack {
                        Button("Clear Signature") {
                            signatureCanvasID = UUID()
                            signatureImage = nil
                            isSignatureEmpty = true
                        }
                        .font(LMSFont.caption.weight(.bold))
                        .foregroundStyle(LMSColors.coral)

                        Spacer()

                        Button("Redraw Signature") {
                            signatureCanvasID = UUID()
                            signatureImage = nil
                            isSignatureEmpty = true
                        }
                        .font(LMSFont.caption.weight(.bold))
                        .foregroundStyle(LMSColors.brandNavy)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
    }
}

private struct SignatureCanvasView: UIViewRepresentable {
    @Binding var signatureImage: UIImage?
    @Binding var isEmpty: Bool
    let canvasID: UUID

    func makeUIView(context: Context) -> SignatureCanvasUIView {
        let view = SignatureCanvasUIView()
        view.onChange = { image, empty in
            signatureImage = image
            isEmpty = empty
        }
        return view
    }

    func updateUIView(_ uiView: SignatureCanvasUIView, context: Context) {
        if context.coordinator.canvasID != canvasID {
            context.coordinator.canvasID = canvasID
            uiView.clear()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(canvasID: canvasID)
    }

    final class Coordinator {
        var canvasID: UUID
        init(canvasID: UUID) {
            self.canvasID = canvasID
        }
    }
}

private final class SignatureCanvasUIView: UIView {
    var onChange: ((UIImage?, Bool) -> Void)?
    private var lines: [[CGPoint]] = []
    private var currentLine: [CGPoint] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isMultipleTouchEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentLine = touches.compactMap { $0.location(in: self) }
        setNeedsDisplay()
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentLine.append(contentsOf: touches.map { $0.location(in: self) })
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        currentLine.append(contentsOf: touches.map { $0.location(in: self) })
        if currentLine.count > 1 {
            lines.append(currentLine)
        }
        currentLine = []
        setNeedsDisplay()
        onChange?(renderImage(), lines.isEmpty)
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setStrokeColor(UIColor.label.cgColor)
        context.setLineWidth(3)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        for line in lines + [currentLine] where line.count > 1 {
            context.beginPath()
            context.move(to: line[0])
            for point in line.dropFirst() {
                context.addLine(to: point)
            }
            context.strokePath()
        }
    }

    func clear() {
        lines = []
        currentLine = []
        setNeedsDisplay()
        onChange?(nil, true)
    }

    private func renderImage() -> UIImage? {
        guard !lines.isEmpty else { return nil }
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { _ in
            drawHierarchy(in: bounds, afterScreenUpdates: true)
        }
    }
}

private struct LiveFaceVerificationView: View {
    let onComplete: (String) -> Void
    let onCancel: () -> Void
    @StateObject private var camera = LiveFaceCameraController()

    var body: some View {
        ZStack {
            LiveFaceCameraPreview(session: camera.session)
                .ignoresSafeArea()

            VStack {
                HStack {
                    Button("Cancel", action: onCancel)
                        .font(LMSFont.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(12)
                        .background(.black.opacity(0.45), in: Capsule())
                    Spacer()
                    Label("Recording...", systemImage: "record.circle.fill")
                        .font(LMSFont.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(10)
                        .background(.red.opacity(0.75), in: Capsule())
                }
                .padding()

                Spacer()

                RoundedRectangle(cornerRadius: 120, style: .continuous)
                    .stroke(camera.faceDetected ? LMSColors.emerald : LMSColors.coral, lineWidth: 3)
                    .frame(width: 230, height: 300)
                    .overlay(alignment: .top) {
                        Text(camera.faceDetected ? "Keep face inside frame" : "Face not detected")
                            .font(LMSFont.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(8)
                            .background(.black.opacity(0.50), in: Capsule())
                            .padding(.top, -38)
                    }

                Spacer()

                VStack(spacing: 8) {
                    Text(camera.statusText)
                        .font(LMSFont.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text(String(format: "%02d", camera.remainingSeconds))
                        .font(.system(size: 52, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                .padding(.bottom, 44)
            }
        }
        .background(Color.black)
        .onAppear {
            camera.start { success in
                if success {
                    onComplete("LIVE-\(Int(Date().timeIntervalSince1970))")
                }
            }
        }
        .onDisappear {
            camera.stop()
        }
        .alert("Face not detected. Please try again.", isPresented: $camera.showFailureAlert) {
            Button("Try Again") {
                camera.restart()
            }
            Button("Cancel", role: .cancel, action: onCancel)
        }
    }
}

private struct LiveFaceCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}

private final class LiveFaceCameraController: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    @Published var remainingSeconds = 10
    @Published var faceDetected = false
    @Published var statusText = "Recording..."
    @Published var showFailureAlert = false
    private var timer: Timer?
    private var detectedFrames = 0
    private var totalFrames = 0
    private var completion: ((Bool) -> Void)?

    func start(completion: @escaping (Bool) -> Void) {
        self.completion = completion
        configureSessionIfNeeded()
        detectedFrames = 0
        totalFrames = 0
        remainingSeconds = 10
        showFailureAlert = false
        DispatchQueue.global(qos: .userInitiated).async {
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
        startTimer()
    }

    func restart() {
        start(completion: completion ?? { _ in })
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.stopRunning()
            }
        }
    }

    private func configureSessionIfNeeded() {
        guard session.inputs.isEmpty else { return }
        session.beginConfiguration()
        session.sessionPreset = .medium
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
           let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
        }
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "live-face-verification"))
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        session.commitConfiguration()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] timer in
            guard let self else { return }
            self.remainingSeconds -= 1
            if self.remainingSeconds <= 0 {
                timer.invalidate()
                let success = self.totalFrames > 0 && Double(self.detectedFrames) / Double(self.totalFrames) > 0.35
                self.stop()
                if success {
                    self.statusText = "Verified"
                    self.completion?(true)
                } else {
                    self.statusText = "Face not detected"
                    self.showFailureAlert = true
                }
            }
        }
    }

    nonisolated func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let request = VNDetectFaceRectanglesRequest { [weak self] request, _ in
            let hasFace = !(request.results as? [VNFaceObservation] ?? []).isEmpty
            Task { @MainActor in
                guard let self else { return }
                self.totalFrames += 1
                if hasFace {
                    self.detectedFrames += 1
                }
                self.faceDetected = hasFace
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .leftMirrored, options: [:]).perform([request])
    }
}

// MARK: - STEP 8: Nominee & References View
private struct Step8NomineeReferencesView: View {
    @Binding var nomineeName: String
    @Binding var nomineeRelation: String
    @Binding var nomineeMobile: String
    
    @Binding var refName: String
    @Binding var refPhone: String

    var body: some View {
        VStack(spacing: LMSSpacing.lg) {
            WizardFormSection(title: "Nominee Information") {
                WizardTextField(label: "Full Name", text: $nomineeName, placeholder: "Nominee's full legal name")
                FormDivider()
                WizardPickerRow(label: "Relationship", selection: $nomineeRelation, options: ["", "Spouse", "Parent", "Sibling", "Child"]) { option in
                    option.isEmpty ? "Select Relationship" : option
                }
                FormDivider()
                WizardMobileField(label: "Mobile Number", text: $nomineeMobile)
            }
            
            WizardFormSection(title: "Emergency Reference Contact") {
                WizardTextField(label: "Reference Full Name", text: $refName, placeholder: "Friend or colleague name")
                FormDivider()
                WizardMobileField(label: "Reference Mobile Number", text: $refPhone)
            }
        }
    }
}

// MARK: - STEP 9: Review Details View
private struct Step9ReviewOverhaulView: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let product: BorrowerLoanProduct
    let onEditStep: (Int) -> Void

    var body: some View {
        VStack(spacing: LMSSpacing.lg) {
            VStack(alignment: .center, spacing: 8) {
                ZStack {
                    Circle()
                        .stroke(LMSColors.emerald.opacity(0.15), lineWidth: 6)
                        .frame(width: 56, height: 56)
                    Circle()
                        .trim(from: 0, to: 0.98)
                        .stroke(LMSColors.emerald, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                    
                    Text("98%")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.emerald)
                }
                
                Text("Verification Ready!")
                    .font(LMSFont.title3.weight(.bold))
                    .foregroundStyle(LMSColors.brandNavy)
                Text("Please confirm the details below match your expectations.")
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            WizardFormSection(title: "Loan Preferences") {
                WizardInlineValueRow(label: "Selected Product", value: product.type.title)
                FormDivider()
                WizardInlineValueRow(label: "Requested Limit", value: viewModel.formData.requestedAmountValue.formattedAsINR(), valueColor: LMSColors.brandNavy)
                FormDivider()
                WizardInlineValueRow(label: "Tenure Period", value: "\(viewModel.formData.preferredTenureMonths) Months")
            }
            
            WizardFormSection(title: "Personal Profile") {
                WizardInlineValueRow(label: "Full Name", value: viewModel.formData.fullName)
                FormDivider()
                WizardInlineValueRow(label: "Date of Birth", value: viewModel.formData.dateOfBirth.formattedAsDDMMMYYYY())
                FormDivider()
                WizardInlineValueRow(label: "Contact Email", value: viewModel.formData.emailAddress)
                FormDivider()
                WizardInlineValueRow(label: "Application Branch", value: viewModel.formData.preferredBranch.isEmpty ? "Not selected" : viewModel.formData.preferredBranch)
            }
            
            WizardFormSection(title: "Employment Credentials") {
                WizardInlineValueRow(label: "Employment Type", value: viewModel.formData.employmentType)
                FormDivider()
                WizardInlineValueRow(label: "Company / Employer", value: viewModel.formData.employerName)
                FormDivider()
                WizardInlineValueRow(label: "Net Income", value: viewModel.formData.monthlyIncomeValue.formattedAsINR())
            }
        }
    }
}

// MARK: - STEP 10: Consent & Terms
private struct Step10TermsConsentView: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let product: BorrowerLoanProduct
    @Binding var acceptTerms: Bool
    @Binding var acceptBureau: Bool
    @Binding var acceptDebit: Bool

    private let maxPurposeLength = 500

    var body: some View {
        VStack(spacing: LMSSpacing.lg) {
            VStack(alignment: .center, spacing: 8) {
                Image(systemName: "text.badge.checkmark")
                    .font(.system(size: 40))
                    .foregroundStyle(LMSColors.brandNavy)
                
                Text("Agreement & Submission")
                    .font(LMSFont.title3.weight(.bold))
                    .foregroundStyle(LMSColors.textPrimary)
                
                Text("Verify the final conditions. Submitting starts instant processing.")
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            loanPurposeSection
            
            WizardFormSection(title: "Consent Checklist") {
                WizardToggleRow(label: "Accept Terms & Conditions", subtitle: "I agree to terms, processing regulations, and verification policies.", isOn: $acceptTerms)
                FormDivider()
                WizardToggleRow(label: "Bureau Verification Consent", subtitle: "I permit inquiry of my credit bureau logs (CIBIL/Equifax) for verification.", isOn: $acceptBureau)
                FormDivider()
                WizardToggleRow(label: "Auto-Debit Agreement", subtitle: "I consent to repayments auto-deducting monthly per configuration.", isOn: $acceptDebit)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Premium Fintech Security Assured", systemImage: "shield.safebox.fill")
                    .font(LMSFont.caption.weight(.bold))
                    .foregroundStyle(LMSColors.emerald)
                Text("All connections are encrypted with Bank-grade AES-256 standard and strict compliance norms.")
                    .font(.system(size: 10))
                    .foregroundStyle(LMSColors.textSecondary)
            }
            .padding(14)
            .background(LMSColors.emerald.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(LMSColors.emerald.opacity(0.14), lineWidth: 0.8)
            )
            .padding(.horizontal, 16)
        }
    }

    private var loanPurposeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("LOAN PURPOSE")
                .font(LMSFont.caption2.weight(.bold))
                .foregroundStyle(LMSColors.textSecondary)
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Loan Purpose")
                        .font(LMSFont.body.weight(.semibold))
                        .foregroundStyle(LMSColors.textPrimary)
                    Text("Tell us why you are applying for this loan.")
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textSecondary)
                }

                TextEditor(text: Binding(
                    get: { viewModel.formData.loanPurpose },
                    set: { newValue in
                        viewModel.formData.loanPurpose = String(newValue.prefix(maxPurposeLength))
                        viewModel.autosaveDraft()
                    }
                ))
                .font(LMSFont.body)
                .foregroundStyle(LMSColors.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 120)
                .padding(10)
                .background(LMSColors.surfaceTertiary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(alignment: .topLeading) {
                    if viewModel.formData.loanPurpose.isEmpty {
                        Text("Home renovation\nMedical expenses\nEducation fees\nBusiness expansion\nDebt consolidation\nVehicle purchase")
                            .font(LMSFont.body)
                            .foregroundStyle(LMSColors.textTertiary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }

                Text("\(viewModel.formData.loanPurpose.count) / \(maxPurposeLength)")
                    .font(LMSFont.caption2.weight(.medium))
                    .foregroundStyle(viewModel.formData.loanPurpose.count > maxPurposeLength ? LMSColors.coral : LMSColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(16)
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(LMSColors.separatorLight.opacity(0.4), lineWidth: 0.8)
            )
            .shadow(color: Color.black.opacity(0.015), radius: 6, x: 0, y: 3)
        }
        .padding(.horizontal, 16)
    }
}


// MARK: - Upload Source Selection Sheet
private struct UploadSourceSelectionSheet: View {
    @Binding var isPresented: Bool
    @Binding var selectedSource: BorrowerDocumentUploadSource
    let onSelect: (BorrowerDocumentUploadSource) -> Void

    var body: some View {
        VStack(spacing: LMSSpacing.lg) {
            Text("Select Document Source")
                .font(LMSFont.title3)
                .foregroundStyle(LMSColors.textPrimary)
                .padding(.top, 18)
            
            VStack(spacing: LMSSpacing.sm) {
                ForEach(BorrowerDocumentUploadSource.mobileSources, id: \.self) { source in
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
                            VStack(alignment: .leading, spacing: 2) {
                                Text(source.rawValue)
                                    .font(LMSFont.callout.weight(.semibold))
                                    .foregroundStyle(LMSColors.textPrimary)
                                Text(source.sourceDescription)
                                    .font(LMSFont.caption)
                                    .foregroundStyle(LMSColors.textSecondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(LMSColors.textTertiary)
                        }
                        .padding(LMSSpacing.md)
                        .background(LMSColors.surfaceElevated, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                    }
                    .buttonStyle(LMSPressableStyle())
                }
            }
            .padding(.horizontal, 16)
            
            Spacer()
        }
        .presentationDetents([.height(250)])
        .presentationDragIndicator(.visible)
        .background(.regularMaterial)
    }
}

private struct DocumentImagePicker: UIViewControllerRepresentable {
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: (UIImage) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onImagePicked: onImagePicked, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(sourceType) ? sourceType : .photoLibrary
        picker.mediaTypes = ["public.image"]
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let onImagePicked: (UIImage) -> Void
        let onCancel: () -> Void

        init(onImagePicked: @escaping (UIImage) -> Void, onCancel: @escaping () -> Void) {
            self.onImagePicked = onImagePicked
            self.onCancel = onCancel
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                onImagePicked(image)
            } else {
                onCancel()
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onCancel()
        }
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up:
            self = .up
        case .upMirrored:
            self = .upMirrored
        case .down:
            self = .down
        case .downMirrored:
            self = .downMirrored
        case .left:
            self = .left
        case .leftMirrored:
            self = .leftMirrored
        case .right:
            self = .right
        case .rightMirrored:
            self = .rightMirrored
        @unknown default:
            self = .up
        }
    }
}

// MARK: - Preview Support
#Preview("Loan Wizard") {
    EmptyView()
}
