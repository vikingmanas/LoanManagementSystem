import SwiftUI

// MARK: - Navigation Route
private enum LoanApplicationRoute: Hashable {
    case overview(BorrowerLoanProduct)
    case combinedApplication
    case verificationResult
    case tracking(BorrowerLoanApplication)
}

// MARK: - Main Tab View
struct LoanApplicationTabView: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(spacing: 24) {
                    // MARK: Native Segmented Control
                    Picker("Loan Hub", selection: $viewModel.selectedSegment) {
                        ForEach(LoanHubSegment.allCases) { segment in
                            Text(segment.rawValue).tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    
                    Group {
                        switch viewModel.selectedSegment {
                        case .discover:
                            LoanDiscoveryContent(viewModel: viewModel) { product in
                                navigationPath.append(LoanApplicationRoute.overview(product))
                            }
                        case .applications:
                            BorrowerApplicationsContent(viewModel: viewModel) { application in
                                navigationPath.append(LoanApplicationRoute.tracking(application))
                            }
                        }
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
            .background(LMSColors.background)
            .navigationTitle("Loans")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: LoanApplicationRoute.self) { route in
                switch route {
                case .overview(let product):
                    LoanOverviewScreen(viewModel: viewModel, product: product) {
                        viewModel.startDraft(for: product)
                        navigationPath.append(LoanApplicationRoute.combinedApplication)
                    }
                case .combinedApplication:
                    CombinedApplicationScreen(viewModel: viewModel) {
                        viewModel.runBulkVerification()
                        navigationPath.append(LoanApplicationRoute.verificationResult)
                    }
                case .verificationResult:
                    DocumentVerificationResultView(viewModel: viewModel) {
                        if let _ = viewModel.submitCurrentApplication() {
                            navigationPath = NavigationPath()
                            viewModel.selectedSegment = .applications
                        }
                    }
                case .tracking(let application):
                    LoanApplicationTrackingScreen(viewModel: viewModel, application: application)
                }
            }
        }
    }
}

// MARK: - Discovery Content
private struct LoanDiscoveryContent: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let onSelectProduct: (BorrowerLoanProduct) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Select Your Loan")
                    .font(.headline)
                    .foregroundStyle(LMSColors.textPrimary)
                Text("Explore premium financial products with competitive rates.")
                    .font(.subheadline)
                    .foregroundStyle(LMSColors.textSecondary)
            }
            .padding(.horizontal, 16)

            // Loan Cards with substantial spacing
            VStack(spacing: 20) {
                ForEach(viewModel.products) { product in
                    LoanProductCard(product: product)
                        .onTapGesture {
                            onSelectProduct(product)
                        }
                }
            }
            .padding(.horizontal, 16)
        }
    }
}

// MARK: - Premium Native Loan Card
private struct LoanProductCard: View {
    let product: BorrowerLoanProduct

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top Section: Icon and Title
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LMSColors.brandNavy.opacity(0.1))
                        .frame(width: 52, height: 52)
                    Image(systemName: product.type.iconName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(LMSColors.brandNavy)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(product.type.title)
                        .font(.headline)
                        .foregroundStyle(LMSColors.textPrimary)
                    Text(product.shortDescription)
                        .font(.caption)
                        .foregroundStyle(LMSColors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(LMSColors.textTertiary)
            }
            
            // Bottom Info Bar: High Contrast
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("INTEREST RATE")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                    Text(product.interestRateRange)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.brandNavy)
                }
                
                Spacer()
                Divider().frame(height: 24).padding(.horizontal, 12)
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("UP TO AMOUNT")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                    Text(product.maximumAmount.formattedAsINR())
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.textPrimary)
                }
                
                Spacer()
                Divider().frame(height: 24).padding(.horizontal, 12)
                Spacer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("DISBURSAL")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                    Text(product.estimatedProcessingTime)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.emerald)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(LMSColors.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(16)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Loan Overview Screen
private struct LoanOverviewScreen: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let product: BorrowerLoanProduct
    let onApply: () -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            // MARK: Professional Hero
            Section {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(LMSColors.brandNavy.opacity(0.1))
                            .frame(width: 88, height: 88)
                        Image(systemName: product.type.iconName)
                            .font(.system(size: 40, weight: .bold))
                            .foregroundStyle(LMSColors.brandNavy)
                    }

                    VStack(spacing: 6) {
                        Text(product.type.title)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(LMSColors.textPrimary)
                        Text(product.shortDescription)
                            .font(.subheadline)
                            .foregroundStyle(LMSColors.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            // MARK: Human-Centric Financial Logic
            Section {
                LabeledContent {
                    Text(product.maximumAmount.formattedAsINR())
                        .font(.headline)
                        .foregroundStyle(LMSColors.textPrimary)
                } label: {
                    Text("Maximum Eligibility")
                }
                
                LabeledContent {
                    Text(product.interestRateRange)
                        .font(.headline)
                        .foregroundStyle(LMSColors.brandNavy)
                } label: {
                    Text("Annual Interest Rate")
                }
                
                LabeledContent("Processing Fee", value: product.processingFees)
                LabeledContent("Processing Time", value: product.estimatedProcessingTime)
            } header: {
                Text("Financial Terms")
            } footer: {
                Text("Final interest rate and loan amount are subject to credit appraisal and internal bank policies.")
            }
            
            // MARK: EMI Calculator Preview
            Section {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text(calculateEstimatedEMI(amount: product.maximumAmount * 0.5, months: 60).formattedAsINR())
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(LMSColors.brandNavy)
                        Text("/ month")
                            .font(.subheadline)
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Representative Example")
                            .font(.caption.bold())
                            .foregroundStyle(LMSColors.textSecondary)
                        
                        Text("For a loan of \(Double(Int(product.maximumAmount * 0.5)).formattedAsINR()) at 10.5% p.a. for 60 months, your monthly EMI would be approximately as shown above. Total interest payable would be \((calculateEstimatedEMI(amount: product.maximumAmount * 0.5, months: 60) * 60 - (product.maximumAmount * 0.5)).formattedAsINR()).")
                            .font(.caption2)
                            .foregroundStyle(LMSColors.textSecondary)
                            .lineSpacing(2)
                    }
                }
                .padding(.vertical, 8)
            } header: {
                Text("Estimated Repayment")
            }

            // MARK: Key Features
            Section {
                ForEach(product.benefits, id: \.self) { benefit in
                    Label {
                        Text(benefit)
                            .font(.subheadline)
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(LMSColors.emerald)
                    }
                }
            } header: {
                Text("Why choose this loan?")
            }

            // MARK: Eligibility & Requirements
            Section {
                ForEach(product.eligibilityCriteria, id: \.self) { criterion in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle")
                            .font(.subheadline)
                            .foregroundStyle(LMSColors.brandNavy)
                            .padding(.top, 2)
                        Text(criterion)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 2)
                }
            } header: {
                Text("Eligibility Criteria")
            }

            Section {
                Button(action: onApply) {
                    HStack {
                        Spacer()
                        Text("Begin Application")
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        Spacer()
                    }
                }
                .listRowBackground(LMSColors.brandNavy)
            }
        }
        .navigationTitle("Loan Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func calculateEstimatedEMI(amount: Double, months: Int) -> Double {
        let annualRate: Double = 0.105
        let monthlyRate = annualRate / 12.0
        let numberOfPayments = Double(months)
        let emi = (amount * monthlyRate * pow(1 + monthlyRate, numberOfPayments)) / (pow(1 + monthlyRate, numberOfPayments) - 1)
        return emi.isNaN ? (amount / numberOfPayments) : emi
    }
}

// MARK: - Combined Application Screen
private struct CombinedApplicationScreen: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let onVerify: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var activeUploadDocument: BorrowerLoanDocumentItem? = nil

    var body: some View {
        Form {
            Section {
                TextField("Full Name", text: $viewModel.formData.fullName)
                DatePicker("Date of Birth", selection: $viewModel.formData.dateOfBirth, displayedComponents: .date)
                TextField("Mobile Number", text: $viewModel.formData.mobileNumber)
                    .keyboardType(.phonePad)
                TextField("Email Address", text: $viewModel.formData.emailAddress)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                TextField("Current Address", text: $viewModel.formData.address, axis: .vertical)
                    .lineLimit(3...5)
            } header: {
                Text("Personal Information")
            }

            Section {
                if viewModel.formData.employmentType == "Self-Employed" || viewModel.formData.employmentType == "Business Owner" {
                    TextField("Designation/Role", text: $viewModel.formData.occupation)
                    Picker("Employment Type", selection: $viewModel.formData.employmentType) {
                        ForEach(viewModel.employmentTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    TextField("Business Name", text: $viewModel.formData.employerName)
                    Stepper("Business Vintage: \(viewModel.formData.workExperienceYears) years", value: $viewModel.formData.workExperienceYears, in: 0...50)
                    TextField("GST Number", text: $viewModel.formData.gstNumber)
                        .textInputAutocapitalization(.characters)
                } else {
                    TextField("Occupation", text: $viewModel.formData.occupation)
                    Picker("Employment Type", selection: $viewModel.formData.employmentType) {
                        ForEach(viewModel.employmentTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                    TextField("Employer Name", text: $viewModel.formData.employerName)
                    Stepper("Experience: \(viewModel.formData.workExperienceYears) years", value: $viewModel.formData.workExperienceYears, in: 0...50)
                }
            } header: {
                Text("Professional Details")
            }

            Section {
                HStack {
                    Text("Monthly Income")
                    Spacer()
                    TextField("₹", text: $viewModel.formData.monthlyIncome)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Annual Income")
                    Spacer()
                    TextField("₹", text: $viewModel.formData.annualIncome)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                HStack {
                    Text("Existing EMIs")
                    Spacer()
                    TextField("₹", text: $viewModel.formData.existingEMIs)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
            } header: {
                Text("Financial Context")
            }

            Section {
                HStack {
                    Text("Requested Amount")
                    Spacer()
                    TextField("₹", text: $viewModel.formData.loanAmountRequested)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                }
                TextField("Loan Purpose", text: $viewModel.formData.loanPurpose, axis: .vertical)
                    .lineLimit(2...4)
                
                Picker("Tenure", selection: $viewModel.formData.preferredTenureMonths) {
                    ForEach(viewModel.tenureOptions, id: \.self) { months in
                        Text("\(months) months").tag(months)
                    }
                }
            } header: {
                Text("Loan Requirements")
            }

            ForEach(BorrowerDocumentCategory.allCases) { category in
                if category == .loanSpecific {
                    let categoryDocs = viewModel.documents(for: category)
                    if !categoryDocs.isEmpty {
                        Section {
                            ForEach(categoryDocs, id: \.id) { document in
                                DocumentRow(document: document) {
                                    activeUploadDocument = document
                                }
                            }
                        } header: {
                            Text(category.rawValue)
                        }
                    }
                } else {
                    Section {
                        Picker("Select Document", selection: Binding(
                            get: { viewModel.selectedDocumentType(for: category) },
                            set: { viewModel.changeDocumentType(for: category, to: $0) }
                        )) {
                            ForEach(viewModel.availableDocumentTypes(for: category), id: \.self) { docType in
                                Text(docType).tag(docType)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        if let document = viewModel.document(for: category) {
                            DocumentRow(document: document) {
                                activeUploadDocument = document
                            }
                        }
                    } header: {
                        Text(category.rawValue)
                    }
                }
            }

            Section {
                Button(action: onVerify) {
                    HStack {
                        Spacer()
                        Text("Verify & Continue")
                            .fontWeight(.bold)
                        Spacer()
                    }
                }
                .disabled(viewModel.formCompletionRatio < 0.8)
            }
        }
        .navigationTitle("Application")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeUploadDocument) { document in
            DocumentUploadSheet(documentName: document.name) { fileName, source in
                viewModel.uploadDocument(document.id, fileName: fileName, source: source)
            }
        }
    }
}

// MARK: - Document Row
private struct DocumentRow: View {
    let document: BorrowerLoanDocumentItem
    let onUpload: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(document.name)
                    .font(.body)
                Text(document.status.rawValue)
                    .font(.caption)
                    .foregroundStyle(document.status.tintColor)
            }
            Spacer()
            
            if document.status == .pendingUpload || document.status == .rejected {
                Button("Upload") {
                    onUpload()
                }
                .font(.subheadline.bold())
            } else {
                Image(systemName: document.status.iconName)
                    .foregroundStyle(document.status.tintColor)
            }
        }
    }
}

// MARK: - Document Verification Result View
private struct DocumentVerificationResultView: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let onSubmit: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var activeUploadDocument: BorrowerLoanDocumentItem? = nil

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: viewModel.allDocumentsVerified ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(viewModel.allDocumentsVerified ? .green : .orange)
                    
                    Text(viewModel.allDocumentsVerified ? "Verification Successful" : "Attention Required")
                        .font(.title2.weight(.bold))
                    
                    Text(viewModel.allDocumentsVerified ? "Your documents have been verified. You can now submit your application." : "Some documents could not be automatically verified. Please review the results below.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
            .listRowBackground(Color.clear)

            Section {
                ForEach(viewModel.documents, id: \.id) { doc in
                    DocumentRow(document: doc) {
                        activeUploadDocument = doc
                    }
                }
            } header: {
                Text("Document Status")
            }

            Section {
                Button(action: onSubmit) {
                    HStack {
                        Spacer()
                        Text("Submit Final Application")
                            .fontWeight(.bold)
                        Spacer()
                    }
                }
                .disabled(!viewModel.canSubmitApplication)
            } footer: {
                if !viewModel.canSubmitApplication {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Please resolve the following issues before submitting:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(LMSColors.coral)
                            .padding(.bottom, 2)
                        
                        ForEach(viewModel.blockingSubmissionIssues, id: \.self) { issue in
                            HStack(alignment: .top, spacing: 4) {
                                Text("•")
                                Text(issue)
                            }
                            .font(.system(size: 10))
                            .foregroundStyle(LMSColors.coral.opacity(0.85))
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Verification")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeUploadDocument) { document in
            DocumentUploadSheet(documentName: document.name) { fileName, source in
                viewModel.uploadDocument(document.id, fileName: fileName, source: source)
                viewModel.runBulkVerification()
            }
        }
    }
}

// MARK: - Applications Content
private struct BorrowerApplicationsContent: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let onSelectApplication: (BorrowerLoanApplication) -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Metrics Section
            HStack(spacing: 12) {
                MetricBadge(title: "Active", value: "\(viewModel.dashboardMetrics.activeApplications)", color: .blue)
                MetricBadge(title: "Approved", value: "\(viewModel.dashboardMetrics.approvedLoans)", color: .green)
                MetricBadge(title: "Drafts", value: "\(viewModel.dashboardMetrics.draftApplications)", color: .gray)
            }
            .padding(.horizontal, 16)

            // Application Rows with spacing
            VStack(alignment: .leading, spacing: 12) {
                if !viewModel.draftApplications.isEmpty {
                    Text("DRAFTS")
                        .font(.caption.bold())
                        .foregroundStyle(LMSColors.textSecondary)
                        .padding(.horizontal, 16)
                    
                    ForEach(viewModel.draftApplications) { app in
                        ApplicationCard(application: app)
                            .onTapGesture { onSelectApplication(app) }
                    }
                    .padding(.horizontal, 16)
                }

                Text("RECENT APPLICATIONS")
                    .font(.caption.bold())
                    .foregroundStyle(LMSColors.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                ForEach(viewModel.filteredSubmittedApplications) { app in
                    ApplicationCard(application: app)
                        .onTapGesture { onSelectApplication(app) }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

struct MetricBadge: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.secondary.opacity(0.1), lineWidth: 0.5))
    }
}

private struct ApplicationCard: View {
    let application: BorrowerLoanApplication

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label(application.product.type.title, systemImage: application.product.type.iconName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(LMSColors.textPrimary)
                Spacer()
                Text(application.currentStage.rawValue)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(application.currentStage.tintColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(application.currentStage.tintColor.opacity(0.1), in: Capsule())
            }

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(application.displayIdentifier)
                        .font(.caption.monospaced())
                        .foregroundStyle(LMSColors.textSecondary)
                    if let submittedAt = application.submittedAt {
                        Text("Last Update: \(submittedAt.formattedAsDDMMMYYYY())")
                            .font(.system(size: 10))
                            .foregroundStyle(LMSColors.textTertiary)
                    }
                }
                Spacer()
                if application.formData.requestedAmountValue > 0 {
                    Text(application.formData.requestedAmountValue.formattedAsINR())
                        .font(.headline)
                        .foregroundStyle(LMSColors.brandNavy)
                }
            }
        }
        .padding(16)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
        )
    }
}

// MARK: - Loan Application Tracking Screen
private struct LoanApplicationTrackingScreen: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let application: BorrowerLoanApplication
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                VStack(spacing: 20) {
                    HStack(spacing: 20) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(LMSColors.brandNavy.opacity(0.1))
                                .frame(width: 64, height: 64)
                            Image(systemName: application.product.type.iconName)
                                .font(.title)
                                .foregroundStyle(LMSColors.brandNavy)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(application.product.type.title)
                                .font(.headline)
                            Text(application.displayIdentifier)
                                .font(.caption.monospaced())
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        ProgressView(value: viewModel.progressValue(for: application))
                            .tint(application.currentStage.tintColor)
                        
                        HStack {
                            Text("Current Progress")
                                .font(.caption2)
                                .foregroundStyle(LMSColors.textSecondary)
                            Spacer()
                            Text(application.currentStage.rawValue)
                                .font(.caption2.bold())
                                .foregroundStyle(application.currentStage.tintColor)
                        }
                    }
                }
                .padding(.vertical, 12)
            }

            Section {
                let stages = viewModel.timelineStages(for: application)
                ForEach(stages, id: \.self) { stage in
                    TimelineRow(
                        stage: stage.rawValue,
                        date: viewModel.stageTimestamp(for: stage, application: application),
                        isCompleted: isStageCompleted(stage, current: application.currentStage, stages: stages),
                        isCurrent: stage == application.currentStage
                    )
                }
            } header: {
                Text("Status Timeline")
            }

            Section {
                LabeledContent("Requested Amount", value: application.formData.requestedAmountValue.formattedAsINR())
                LabeledContent("Tenure", value: "\(application.formData.preferredTenureMonths) months")
                if let submittedAt = application.submittedAt {
                    LabeledContent("Submitted On", value: submittedAt.formattedAsDDMMMYYYY())
                }
                LabeledContent("Processing Fee", value: application.product.processingFees)
            } header: {
                Text("Application Details")
            }
        }
        .navigationTitle("Tracking")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func isStageCompleted(_ stage: BorrowerApplicationStage, current: BorrowerApplicationStage, stages: [BorrowerApplicationStage]) -> Bool {
        guard let currentIndex = stages.firstIndex(of: current),
              let stageIndex = stages.firstIndex(of: stage) else { return false }
        return stageIndex < currentIndex
    }
}

private struct TimelineRow: View {
    let stage: String
    let date: Date?
    let isCompleted: Bool
    let isCurrent: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(spacing: 0) {
                Circle()
                    .fill(isCompleted ? LMSColors.emerald : (isCurrent ? LMSColors.brandNavy : Color(.systemGray4)))
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(Color(.systemGray4).opacity(0.5))
                    .frame(width: 1.5, height: 28)
            }
            .padding(.top, 4)

            VStack(alignment: .leading, spacing: 2) {
                Text(stage)
                    .font(.system(size: 14, weight: isCurrent ? .bold : .regular))
                    .foregroundStyle(isCurrent ? .primary : .secondary)
                if let date = date {
                    Text(date.formattedAsDDMMMYYYY())
                        .font(.system(size: 11))
                        .foregroundStyle(LMSColors.textTertiary)
                }
            }
            Spacer()
        }
        .listRowSeparator(.hidden)
    }
}
