import SwiftUI

// MARK: - Loans Tab (Marketplace only — no applications here)

struct LoanApplicationTabView: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var tabRouter: BorrowerTabRouter
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            LoansMarketplaceView(
                viewModel: viewModel,
                onProductDetail: { product in
                    navigationPath.append(LoanApplicationRoute.productDetail(product))
                },
                onApply: { product in
                    viewModel.startDraft(for: product)
                    navigationPath.append(LoanApplicationRoute.applicationWizard(product))
                }
            )
            .background(LMSColors.background)
            .navigationTitle("Loans")
            .navigationBarTitleDisplayMode(.large)
            .task(id: authManager.userEmail) {
                viewModel.setBorrowerAuthContext(
                    email: authManager.userEmail ?? "",
                    displayName: authManager.userDisplayName
                )
            }
            .navigationDestination(for: LoanApplicationRoute.self) { route in
                switch route {
                case .productDetail(let product):
                    LoanProductDetailView(product: product) {
                        viewModel.startDraft(for: product)
                        navigationPath.append(LoanApplicationRoute.applicationWizard(product))
                    }
                case .applicationWizard(let product):
                    BorrowerLoanWizardView(viewModel: viewModel, product: product) {
                        navigationPath = NavigationPath()
                        tabRouter.select(.applications)
                    }
                    .environmentObject(authManager)
                case .tracking(let application):
                    LoanApplicationTrackingScreen(
                        viewModel: viewModel,
                        application: application,
                        onResume: {
                            viewModel.resumeDraft(application)
                            navigationPath.append(LoanApplicationRoute.applicationWizard(application.product))
                        },
                        onDelete: {
                            if viewModel.deleteDraft(applicationID: application.id),
                               !navigationPath.isEmpty {
                                navigationPath.removeLast()
                            }
                        }
                    )
                }
            }
        }
    }
}

// MARK: - Legacy discovery (kept for reference — superseded by LoansMarketplaceView)
#if false
private struct LoanDiscoveryContent: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let onSelectProduct: (BorrowerLoanProduct) -> Void

    var body: some View {
        VStack(spacing: 14) {
            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(LMSColors.brandNavy)
                    .font(.system(size: 15, weight: .semibold))
                
                TextField("Search loans...", text: $viewModel.searchQuery)
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(LMSColors.textPrimary)
                    .autocorrectionDisabled()
                
                if !viewModel.searchQuery.isEmpty {
                    Button(action: {
                        viewModel.searchQuery = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(LMSColors.textSecondary)
                            .font(.system(size: 16))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(LMSColors.separatorLight, lineWidth: 0.5)
            )
            .padding(.bottom, 6)

            if viewModel.filteredProducts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundStyle(LMSColors.brandNavy)
                        .symbolRenderingMode(.hierarchical)
                        .padding(.top, 24)
                    
                    Text("No Loans Found")
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundColor(LMSColors.textPrimary)
                    
                    Text("We couldn't find any loans matching \"\(viewModel.searchQuery)\". Try searching for other terms like 'home', 'personal', or 'gold'.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(LMSColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.vertical, 20)
            } else {
                ForEach(viewModel.filteredProducts) { product in
                    LoanProductCard(product: product)
                        .onTapGesture {
                            onSelectProduct(product)
                        }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

// MARK: - Premium Native Loan Card
private struct LoanProductCard: View {
    let product: BorrowerLoanProduct

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: product.type.iconName)
                    .font(.system(size: 21, weight: .bold))
                    .foregroundStyle(LMSColors.brandNavy)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 46, height: 46)
                    .background(LMSColors.brandNavy.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(product.type.title)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(LMSColors.textPrimary)
                        .lineLimit(1)

                    Text(product.shortDescription)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 8)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(LMSColors.textTertiary)
                    .padding(.top, 4)
            }

            HStack(spacing: 8) {
                LoanProductMetricChip(
                    title: "Amount",
                    value: product.maximumAmount.formattedAsCompactINR(),
                    icon: "indianrupeesign.circle.fill",
                    tint: LMSColors.textPrimary
                )

                LoanProductMetricChip(
                    title: "Rate",
                    value: product.interestRateRange,
                    icon: "percent",
                    tint: LMSColors.brandNavy
                )

                LoanProductMetricChip(
                    title: "Time",
                    value: product.estimatedProcessingTime,
                    icon: "clock.fill",
                    tint: LMSColors.emerald
                )
            }
            .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
            )
        .shadow(color: Color.black.opacity(0.035), radius: 10, x: 0, y: 5)
        .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct LoanProductMetricChip: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(tint)
                Text(title.uppercased())
                    .font(.system(size: 8, weight: .black, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
            }

            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(tint)
                .lineLimit(2)
                .minimumScaleFactor(0.78)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(LMSColors.background.opacity(0.55), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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

    @State private var draftPendingDeletion: BorrowerLoanApplication?
    @State private var showDeleteDraftConfirmation = false

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    MetricBadge(title: "Active", value: "\(viewModel.dashboardMetrics.activeApplications)", color: .blue)
                    MetricBadge(title: "Approved", value: "\(viewModel.dashboardMetrics.approvedLoans)", color: .green)
                    MetricBadge(title: "Drafts", value: "\(viewModel.dashboardMetrics.draftApplications)", color: .gray)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if !viewModel.draftApplications.isEmpty {
                Section {
                    Text("DRAFTS")
                        .font(.caption.bold())
                        .foregroundStyle(LMSColors.textSecondary)
                        .listRowInsets(EdgeInsets(top: 14, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)

                    ForEach(viewModel.draftApplications) { app in
                        ApplicationCard(application: app)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                onSelectApplication(app)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    draftPendingDeletion = app
                                    showDeleteDraftConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                    }
                }
            }

            Section {
                if !viewModel.filteredSubmittedApplications.isEmpty {
                    Text("RECENT APPLICATIONS")
                        .font(.caption.bold())
                        .foregroundStyle(LMSColors.textSecondary)
                        .listRowInsets(EdgeInsets(top: 14, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }

                ForEach(viewModel.filteredSubmittedApplications) { app in
                    ApplicationCard(application: app)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onSelectApplication(app)
                        }
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(LMSColors.background)
        .alert("Delete Draft?", isPresented: $showDeleteDraftConfirmation, presenting: draftPendingDeletion) { app in
            Button("Delete", role: .destructive) {
                viewModel.deleteDraft(applicationID: app.id)
                draftPendingDeletion = nil
            }
            Button("Cancel", role: .cancel) {
                draftPendingDeletion = nil
            }
        } message: { app in
            Text("This will permanently delete draft \(app.displayIdentifier). You cannot undo this action.")
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

#endif

// MARK: - Product Category Extension
extension BorrowerLoanProductType {
    var tintColor: Color {
        switch self {
        case .personal: return LMSColors.actionBlue
        case .home: return LMSColors.brandNavy
        case .education: return LMSColors.teal
        case .business: return Color(hex: "7C3AED")
        case .vehicle: return LMSColors.emeraldDark
        case .agriculture: return Color(hex: "16A34A")
        case .consumer: return Color(hex: "6366F1")
        case .msmeStartup: return Color(hex: "4F46E5")
        case .gold: return LMSColors.amber
        case .loanAgainstProperty: return LMSColors.brandNavyLight
        case .other: return LMSColors.textSecondary
        }
    }
}

// MARK: - Loan Application Tracking Screen
struct LoanApplicationTrackingScreen: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let application: BorrowerLoanApplication
    let onResume: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false
    @State private var resubmittingDocument: BorrowerLoanDocumentItem? = nil

    private var currentApplication: BorrowerLoanApplication {
        viewModel.applications.first(where: { $0.id == application.id }) ?? application
    }

    var body: some View {
        let app = currentApplication
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: LMSSpacing.sectionGap) {
                
                // Task 1: Premium Header Card
                TrackingHeaderCard(
                    application: app,
                    progress: viewModel.progressValue(for: app),
                    onResume: onResume
                )
                
                // Task 2: Interactive Timeline Stepper
                TimelineStepperCard(
                    viewModel: viewModel,
                    application: app
                )
                
                // Task 4: Documents Section with Resubmission Action Sheet
                SubmittedDocumentsCard(
                    application: app,
                    onResubmit: { doc in
                        resubmittingDocument = doc
                    }
                )
                
                // Task 3: Collapsible Info Sections
                SubmittedInfoViewerCard(
                    application: app
                )
                
                // If it is draft, show standard delete option in page body too
                if app.isDraft {
                    Button(role: .destructive, action: {
                        showDeleteConfirmation = true
                    }) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Draft")
                        }
                        .font(LMSFont.footnote.weight(.semibold))
                        .foregroundColor(LMSColors.coral)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: LMSRadius.md)
                                .stroke(LMSColors.coral.opacity(0.2), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(LMSPressableStyle())
                    .padding(.top, 4)
                }
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)
            .padding(.vertical, LMSSpacing.screenHorizontal)
        }
        .background(LMSColors.background)
        .navigationTitle("Application Tracking")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if app.isDraft {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .destructive) {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
            }
        }
        .alert("Delete Draft?", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete draft \(app.displayIdentifier). You cannot undo this action.")
        }
        .sheet(item: $resubmittingDocument) { document in
            DocumentUploadSheet(documentName: document.name) { fileName, source in
                viewModel.uploadDocumentForApplication(
                    applicationID: app.id,
                    documentID: document.id,
                    fileName: fileName,
                    source: source
                )
            }
        }
    }
}

// MARK: - Task 1 Components (Header Card)
private struct TrackingHeaderCard: View {
    let application: BorrowerLoanApplication
    let progress: Double
    let onResume: () -> Void
    
    var body: some View {
        VStack(spacing: LMSSpacing.lg) {
            // Icon + Title + Status
            HStack(alignment: .top, spacing: LMSSpacing.md) {
                // Category Tinted Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(application.product.type.tintColor.opacity(0.12))
                        .frame(width: 52, height: 52)
                    
                    Image(systemName: application.product.type.iconName)
                        .font(.title3)
                        .foregroundStyle(application.product.type.tintColor)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: LMSSpacing.sm) {
                        Text(application.product.type.title)
                            .font(LMSFont.headline.weight(.bold))
                            .foregroundStyle(LMSColors.textPrimary)
                        
                        Text(application.product.type.rawValue.uppercased())
                            .font(.system(size: 8, weight: .black))
                            .foregroundStyle(LMSColors.brandNavy)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(LMSColors.brandNavy.opacity(0.08), in: Capsule())
                    }
                    
                    Text(application.displayIdentifier)
                        .font(LMSFont.caption.monospaced())
                        .foregroundStyle(LMSColors.textSecondary)
                }
                
                Spacer()
                
                // Large Badge Status
                HStack(spacing: 4) {
                    Circle()
                        .fill(application.currentStage.tintColor)
                        .frame(width: 6, height: 6)
                    
                    Text(application.currentStage.rawValue)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(application.currentStage.tintColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(application.currentStage.tintColor.opacity(0.12), in: Capsule())
            }
            
            Divider().background(LMSColors.separatorLight)
            
            // Grid details
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("SUBMITTED ON")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(LMSColors.textTertiary)
                    
                    Text(application.submittedAt?.formattedAsDDMMMYYYY() ?? "Draft")
                        .font(LMSFont.footnote.weight(.semibold))
                        .foregroundStyle(LMSColors.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("CURRENT QUEUE")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(LMSColors.textTertiary)
                    
                    Text(application.assignedQueue ?? "Unsubmitted Draft")
                        .font(LMSFont.footnote.weight(.semibold))
                        .foregroundStyle(LMSColors.textPrimary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                HStack {
                    Text("Processing Progress")
                        .font(LMSFont.caption2)
                        .foregroundStyle(LMSColors.textSecondary)
                    Spacer()
                    Text("\(Int(progress * 100))%")
                        .font(LMSFont.caption2.weight(.bold))
                        .foregroundStyle(LMSColors.brandNavy)
                }
                
                ProgressView(value: progress)
                    .tint(LMSColors.brandNavy)
            }
            .padding(.top, 4)
            
            if application.isDraft {
                Button(action: onResume) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.uturn.forward.circle.fill")
                        Text("Resume Application")
                            .fontWeight(.semibold)
                    }
                    .font(LMSFont.button)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(LMSColors.brandNavy, in: RoundedRectangle(cornerRadius: LMSRadius.md))
                    .foregroundStyle(.white)
                }
                .buttonStyle(LMSPressableStyle())
                .padding(.top, 4)
            }
        }
        .padding(LMSSpacing.lg)
        .lmsCardElevated()
    }
}

// MARK: - Task 2 Components (Timeline Stepper)
private struct TimelineStepperCard: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let application: BorrowerLoanApplication
    
    @State private var expandedStages: Set<BorrowerApplicationStage> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.lg) {
            Text("Status Timeline")
                .font(LMSFont.title3)
                .foregroundStyle(LMSColors.textPrimary)
            
            let stages = viewModel.timelineStages(for: application)
            
            VStack(alignment: .leading, spacing: 0) {
                ForEach(0..<stages.count, id: \.self) { index in
                    let stage = stages[index]
                    let isCompleted = isStageCompleted(stage, current: application.currentStage, stages: stages)
                    let isCurrent = stage == application.currentStage
                    let date = viewModel.stageTimestamp(for: stage, application: application)
                    
                    TimelineStepRow(
                        stage: stage,
                        date: date,
                        isCompleted: isCompleted,
                        isCurrent: isCurrent,
                        isLast: index == stages.count - 1,
                        isExpanded: expandedStages.contains(stage),
                        note: application.stageHistory.last(where: { $0.stage == stage })?.note,
                        onTap: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                if expandedStages.contains(stage) {
                                    expandedStages.remove(stage)
                                } else {
                                    expandedStages.insert(stage)
                                }
                            }
                        }
                    )
                }
            }
        }
        .padding(LMSSpacing.lg)
        .lmsCard()
    }
    
    private func isStageCompleted(_ stage: BorrowerApplicationStage, current: BorrowerApplicationStage, stages: [BorrowerApplicationStage]) -> Bool {
        guard let currentIndex = stages.firstIndex(of: current),
              let stageIndex = stages.firstIndex(of: stage) else { return false }
        return stageIndex < currentIndex
    }
}

private struct TimelineStepRow: View {
    let stage: BorrowerApplicationStage
    let date: Date?
    let isCompleted: Bool
    let isCurrent: Bool
    let isLast: Bool
    let isExpanded: Bool
    let note: String?
    let onTap: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: LMSSpacing.lg) {
            // Icon and vertical connector
            VStack(spacing: 0) {
                ZStack {
                    if isCompleted {
                        Circle()
                            .fill(LMSColors.emerald)
                            .frame(width: 24, height: 24)
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    } else if isCurrent {
                        ZStack {
                            Circle()
                                .stroke(LMSColors.brandNavy.opacity(0.2), lineWidth: 3)
                                .frame(width: 24, height: 24)
                            Circle()
                                .fill(LMSColors.brandNavy)
                                .frame(width: 12, height: 12)
                        }
                    } else {
                        Circle()
                            .stroke(LMSColors.separator, lineWidth: 2)
                            .fill(LMSColors.surface)
                            .frame(width: 24, height: 24)
                    }
                }
                
                if !isLast {
                    Rectangle()
                        .fill(isCompleted ? LMSColors.emerald.opacity(0.5) : LMSColors.separatorLight)
                        .frame(width: 2, height: isExpanded ? 70 : 36)
                }
            }
            
            // Content
            VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                Button(action: onTap) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stage.rawValue)
                                .font(LMSFont.footnote.weight(isCurrent ? .bold : .semibold))
                                .foregroundStyle(isCurrent ? LMSColors.brandNavy : (isCompleted ? LMSColors.textPrimary : LMSColors.textSecondary))
                            
                            if let date = date {
                                Text(date.formattedAsDDMMMYYYY())
                                    .font(LMSFont.caption2)
                                    .foregroundStyle(LMSColors.textTertiary)
                            }
                        }
                        
                        Spacer()
                        
                        if note != nil {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(LMSColors.textTertiary)
                                .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        }
                    }
                }
                .buttonStyle(.plain)
                
                if isExpanded, let note = note {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(note)
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.textSecondary)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(LMSColors.background, in: RoundedRectangle(cornerRadius: LMSRadius.sm))
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                    .padding(.top, 2)
                }
            }
            .padding(.bottom, isLast ? 0 : 12)
        }
    }
}

// MARK: - Task 3 Components (Submitted Info Viewer)
private struct SubmittedInfoViewerCard: View {
    let application: BorrowerLoanApplication
    
    @State private var isPersonalExpanded = false
    @State private var isFinancialExpanded = false
    @State private var isRequirementsExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("Submitted Information")
                .font(LMSFont.title3)
                .foregroundStyle(LMSColors.textPrimary)
            
            VStack(spacing: LMSSpacing.sm) {
                // Personal Section
                CollapsibleSection(
                    title: "Personal Details",
                    icon: "person.crop.circle.fill",
                    isExpanded: $isPersonalExpanded
                ) {
                    VStack(spacing: LMSSpacing.sm) {
                        InfoRow(label: "Full Name", value: application.formData.fullName)
                        InfoRow(label: "Date of Birth", value: application.formData.dateOfBirth.formattedAsDDMMMYYYY())
                        InfoRow(label: "Gender", value: application.formData.gender.isEmpty ? "Not Specified" : application.formData.gender)
                        InfoRow(label: "Mobile Number", value: application.formData.mobileNumber)
                        InfoRow(label: "Email Address", value: application.formData.emailAddress)
                        InfoRow(label: "Address", value: application.formData.address)
                    }
                    .padding(.top, 8)
                }
                
                Divider().background(LMSColors.separatorLight)
                
                // Professional/Financial Section
                CollapsibleSection(
                    title: "Employment & Income",
                    icon: "briefcase.fill",
                    isExpanded: $isFinancialExpanded
                ) {
                    VStack(spacing: LMSSpacing.sm) {
                        InfoRow(label: "Employment Type", value: application.formData.employmentType)
                        InfoRow(label: "Occupation", value: application.formData.occupation)
                        InfoRow(label: "Employer Name", value: application.formData.employerName)
                        InfoRow(label: "Work Experience", value: "\(application.formData.workExperienceYears) Years")
                        if !application.formData.gstNumber.isEmpty {
                            InfoRow(label: "GST Number", value: application.formData.gstNumber)
                        }
                        InfoRow(label: "Monthly Income", value: application.formData.monthlyIncomeValue.formattedAsINR())
                        InfoRow(label: "Annual Income", value: application.formData.annualIncomeValue.formattedAsINR())
                        if !application.formData.existingEMIs.isEmpty {
                            InfoRow(label: "Existing EMIs", value: application.formData.existingEMIsValue.formattedAsINR())
                        }
                        if !application.formData.creditScore.isEmpty {
                            InfoRow(label: "Credit Score", value: application.formData.creditScore)
                        }
                    }
                    .padding(.top, 8)
                }
                
                Divider().background(LMSColors.separatorLight)
                
                // Loan Requirements Section
                CollapsibleSection(
                    title: "Loan Requirements",
                    icon: "indianrupeesign.circle.fill",
                    isExpanded: $isRequirementsExpanded
                ) {
                    VStack(spacing: LMSSpacing.sm) {
                        InfoRow(label: "Requested Amount", value: application.formData.requestedAmountValue.formattedAsINR())
                        InfoRow(label: "Preferred Tenure", value: "\(application.formData.preferredTenureMonths) months")
                        InfoRow(label: "Loan Purpose", value: application.formData.loanPurpose)
                        InfoRow(label: "Repayment Preference", value: application.formData.repaymentPreference)
                        if application.formData.hasCoApplicant {
                            InfoRow(label: "Co-Applicant Details", value: application.formData.coApplicantDetails)
                        }
                        if application.formData.hasGuarantor {
                            InfoRow(label: "Guarantor Details", value: application.formData.guarantorDetails)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(LMSSpacing.lg)
        .lmsCard()
    }
}

private struct CollapsibleSection<Content: View>: View {
    let title: String
    let icon: String
    @Binding var isExpanded: Bool
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.25)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: LMSSpacing.md) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundStyle(LMSColors.brandNavy)
                        .frame(width: 28, height: 28)
                        .background(LMSColors.brandNavy.opacity(0.08), in: RoundedRectangle(cornerRadius: LMSRadius.sm))
                    
                    Text(title)
                        .font(LMSFont.footnote.weight(.semibold))
                        .foregroundStyle(LMSColors.textPrimary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(LMSColors.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                content()
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

private struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top) {
            Text(label)
                .font(LMSFont.footnote)
                .foregroundStyle(LMSColors.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Text(value)
                .font(LMSFont.footnote.weight(.medium))
                .foregroundStyle(LMSColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .multilineTextAlignment(.trailing)
        }
    }
}

// MARK: - Task 4 Components (Documents Section)
private struct SubmittedDocumentsCard: View {
    let application: BorrowerLoanApplication
    let onResubmit: (BorrowerLoanDocumentItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("Documents Status")
                .font(LMSFont.title3)
                .foregroundStyle(LMSColors.textPrimary)
            
            VStack(spacing: LMSSpacing.md) {
                ForEach(application.documents) { doc in
                    TrackingDocumentStatusRow(doc: doc, onResubmit: { onResubmit(doc) })
                    if doc.id != application.documents.last?.id {
                        Divider().background(LMSColors.separatorLight)
                    }
                }
            }
        }
        .padding(LMSSpacing.lg)
        .lmsCard()
    }
}

private struct TrackingDocumentStatusRow: View {
    let doc: BorrowerLoanDocumentItem
    let onResubmit: () -> Void
    
    @State private var showPreviewAlert = false
    
    var body: some View {
        HStack(alignment: .center, spacing: LMSSpacing.md) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: LMSRadius.sm)
                    .fill(doc.status.tintColor.opacity(0.08))
                    .frame(width: 40, height: 40)
                
                Image(systemName: iconName(for: doc))
                    .font(.system(size: 18))
                    .foregroundStyle(doc.status.tintColor)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(doc.name)
                    .font(LMSFont.footnote.weight(.semibold))
                    .foregroundStyle(LMSColors.textPrimary)
                
                HStack(spacing: 6) {
                    Text(doc.category.rawValue)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(LMSColors.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(LMSColors.background, in: Capsule())
                    
                    if let uploadDate = doc.uploadDate {
                        Text("•  \(uploadDate.formattedAsDDMMMYYYY())")
                            .font(.system(size: 9))
                            .foregroundStyle(LMSColors.textTertiary)
                    }
                }
            }
            
            Spacer()
            
            // Status and actions
            VStack(alignment: .trailing, spacing: LMSSpacing.xs) {
                HStack(spacing: LMSSpacing.xs) {
                    Circle()
                        .fill(doc.status.tintColor)
                        .frame(width: 6, height: 6)
                    
                    Text(doc.status.rawValue)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(doc.status.tintColor)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(doc.status.tintColor.opacity(0.1), in: Capsule())
                
                if doc.status == .rejected || doc.status == .requiresResubmission {
                    Button(action: onResubmit) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.triangle.2.circlepath.doc.on.clipboard")
                                .font(.system(size: 10))
                            Text("Resubmit")
                                .font(.system(size: 10, weight: .bold))
                        }
                        .foregroundStyle(LMSColors.brandNavy)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(LMSColors.surfaceElevated, in: RoundedRectangle(cornerRadius: LMSRadius.sm))
                        .overlay(
                            RoundedRectangle(cornerRadius: LMSRadius.sm)
                                .stroke(LMSColors.brandNavy.opacity(0.2), lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(LMSPressableStyle())
                } else if doc.status != .pendingUpload {
                    Button(action: { showPreviewAlert = true }) {
                        Text("View File")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(LMSColors.actionBlue)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .alert("File Preview", isPresented: $showPreviewAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Simulated viewing for \(doc.fileName ?? "uploaded file").\nStatus: \(doc.status.rawValue)\nCategory: \(doc.category.rawValue)")
        }
    }
    
    private func iconName(for doc: BorrowerLoanDocumentItem) -> String {
        if doc.name.lowercased().contains("passport") {
            return "globe"
        } else if doc.name.lowercased().contains("bill") || doc.name.lowercased().contains("rent") {
            return "doc.plaintext.fill"
        } else if doc.name.lowercased().contains("salary") || doc.name.lowercased().contains("statement") {
            return "banknote.fill"
        } else if doc.name.lowercased().contains("signature") {
            return "signature"
        }
        return doc.status.iconName
    }
}

// MARK: - Document Upload Sheet
struct DocumentUploadSheet: View {
    let documentName: String
    let onUpload: (String, BorrowerDocumentUploadSource) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var uploadSource: BorrowerDocumentUploadSource = .camera
    @State private var fileName: String = ""
    
    // Camera States
    @State private var hasCaptured: Bool = false
    @State private var capturedImageName: String = ""
    
    // Gallery States
    @State private var selectedIndex: Int? = nil

    private var isValidFormat: Bool {
        let name = fileName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return name.hasSuffix(".pdf") || name.hasSuffix(".png")
    }

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 4) {
                Text(documentName)
                    .font(LMSFont.title3)
                    .foregroundStyle(LMSColors.textPrimary)
                Text("Select source and upload in PDF or PNG format.")
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)
            }
            .padding(.top, 16)

            // Source Selector Segmented Control
            Picker("Source", selection: $uploadSource) {
                Text("Camera").tag(BorrowerDocumentUploadSource.camera)
                Text("Gallery").tag(BorrowerDocumentUploadSource.gallery)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            // Content Area based on Selection
            Group {
                switch uploadSource {
                case .camera:
                    CameraSimulationView(
                        hasCaptured: $hasCaptured,
                        capturedImageName: $capturedImageName,
                        fileName: $fileName
                    )
                case .gallery:
                    GallerySimulationView(
                        selectedIndex: $selectedIndex,
                        fileName: $fileName
                    )
                default:
                    EmptyView()
                }
            }
            .frame(height: 220)
            .padding(.horizontal, 16)

            // Filename input & Validation Area
            VStack(alignment: .leading, spacing: 8) {
                Text("FILE NAME")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(LMSColors.textSecondary)
                
                HStack(spacing: 8) {
                    TextField("Enter file name or select one above...", text: $fileName)
                        .font(LMSFont.body)
                        .padding(12)
                        .background(LMSColors.surfaceTertiary, in: RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(LMSColors.separatorLight, lineWidth: 1)
                        )
                    
                    if !fileName.isEmpty {
                        Image(systemName: isValidFormat ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .font(.title3)
                            .foregroundStyle(isValidFormat ? Color.lmsEmerald : Color.lmsCoral)
                    }
                }

                // Format Warning Banner
                if !fileName.isEmpty {
                    HStack(spacing: 6) {
                        Image(systemName: isValidFormat ? "checkmark.seal.fill" : "xmark.octagon.fill")
                        Text(isValidFormat ? "Supported format recognized (.pdf / .png)" : "Invalid format! Only PDF or PNG are allowed.")
                            .font(LMSFont.caption2.weight(.semibold))
                    }
                    .foregroundStyle(isValidFormat ? Color.lmsEmerald : Color.lmsCoral)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        (isValidFormat ? Color.lmsEmerald : Color.lmsCoral).opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 8)
                    )
                }
            }
            .padding(.horizontal, 16)

            Spacer()

            // Confirm Upload Button
            Button(action: {
                onUpload(fileName, uploadSource)
                dismiss()
            }) {
                HStack {
                    Spacer()
                    Text("Confirm Upload")
                        .font(LMSFont.button)
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.vertical, 14)
                .background(isValidFormat ? LMSColors.brandNavy : Color.gray.opacity(0.4), in: RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!isValidFormat)
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .presentationDetents([.height(580)])
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 22))
    }
}

// MARK: - Camera Simulation View
struct CameraSimulationView: View {
    @Binding var hasCaptured: Bool
    @Binding var capturedImageName: String
    @Binding var fileName: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.85))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )

            if hasCaptured {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 54))
                        .foregroundStyle(.white)

                    Text("Photo Captured!")
                        .font(LMSFont.headline)
                        .foregroundStyle(.white)
                    
                    Button(action: {
                        hasCaptured = false
                        fileName = ""
                    }) {
                        Text("Retake Photo")
                            .font(LMSFont.caption.bold())
                            .foregroundStyle(Color.lmsActionBlue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.15), in: Capsule())
                    }
                }
            } else {
                VStack(spacing: 14) {
                    // Shutter frame
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.4), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [8, 8]))
                            .frame(width: 140, height: 100)
                        
                        Image(systemName: "camera.metering.matrix")
                            .font(.system(size: 24))
                            .foregroundStyle(.white.opacity(0.3))
                    }

                    Button(action: {
                        let rand = Int.random(in: 1000...9999)
                        capturedImageName = "doc_snapshot_\(rand).png"
                        fileName = capturedImageName
                        hasCaptured = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "camera.fill")
                            Text("Click Photo")
                        }
                        .font(LMSFont.button)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(LMSColors.brandNavy, in: Capsule())
                    }
                }
            }
        }
    }
}

// MARK: - Gallery Simulation View
struct GallerySimulationView: View {
    @Binding var selectedIndex: Int?
    @Binding var fileName: String

    let items = [
        (name: "Aadhaar_Scan.png", label: "Aadhaar Scan", ext: "PNG"),
        (name: "PAN_Copy.png", label: "PAN Copy", ext: "PNG"),
        (name: "UtilityBill.pdf", label: "Utility Bill", ext: "PDF"),
        (name: "RentAgreement.pdf", label: "Rent Contract", ext: "PDF"),
        (name: "SalarySlip_May.jpg", label: "May Salary Slip", ext: "JPG"), // Invalid to test validation
        (name: "Doc_Draft.doc", label: "Doc Draft", ext: "DOC") // Invalid to test validation
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Simulated Photos & Files:")
                .font(LMSFont.caption)
                .foregroundStyle(LMSColors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(0..<items.count, id: \.self) { idx in
                        let item = items[idx]
                        let isSelected = selectedIndex == idx
                        let isExtValid = item.name.hasSuffix(".png") || item.name.hasSuffix(".pdf")

                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(LMSColors.surfaceTertiary)
                                    .frame(width: 100, height: 90)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(isSelected ? LMSColors.brandNavy : Color.clear, lineWidth: 2)
                                    )

                                VStack(spacing: 4) {
                                    Image(systemName: item.name.hasSuffix(".pdf") ? "doc.richtext.fill" : "photo.fill")
                                        .font(.title2)
                                        .foregroundStyle(isSelected ? LMSColors.brandNavy : LMSColors.textSecondary)
                                    
                                    Text(item.ext)
                                        .font(.system(size: 9, weight: .black))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(isExtValid ? Color.lmsEmerald : Color.lmsCoral, in: Capsule())
                                }
                            }

                            Text(item.label)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(LMSColors.textPrimary)
                                .lineLimit(1)
                                .frame(width: 100)
                        }
                        .scaleEffect(isSelected ? 1.03 : 1.0)
                        .animation(.spring(response: 0.2, dampingFraction: 0.8), value: isSelected)
                        .onTapGesture {
                            selectedIndex = idx
                            fileName = item.name
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
}
