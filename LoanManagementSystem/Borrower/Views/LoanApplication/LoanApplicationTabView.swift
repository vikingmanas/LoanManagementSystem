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
    @EnvironmentObject private var authManager: AuthManager
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                Picker("Loan Hub", selection: $viewModel.selectedSegment) {
                    ForEach(LoanHubSegment.allCases) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)

                Group {
                    switch viewModel.selectedSegment {
                    case .discover:
                        ScrollView {
                            LoanDiscoveryContent(viewModel: viewModel) { product in
                                viewModel.startDraft(for: product)
                                navigationPath.append(LoanApplicationRoute.overview(product))
                            }
                            .padding(.bottom, 32)
                        }
                    case .applications:
                        BorrowerApplicationsContent(viewModel: viewModel) { application in
                            navigationPath.append(LoanApplicationRoute.tracking(application))
                        }
                    }
                }
            }
            .background(LMSColors.background)
            .navigationTitle("Loans")
            .navigationBarTitleDisplayMode(.large)
            .task(id: authManager.userEmail) {
                viewModel.setBorrowerAuthContext(
                    email: authManager.userEmail,
                    displayName: authManager.userDisplayName
                )
            }
            .navigationDestination(for: LoanApplicationRoute.self) { route in
                switch route {
                case .overview(let product):
                    BorrowerLoanWizardView(viewModel: viewModel, product: product) {
                        navigationPath = NavigationPath()
                        viewModel.selectedSegment = .applications
                    }
                    .environmentObject(authManager)
                case .combinedApplication:
                    EmptyView()
                case .verificationResult:
                    EmptyView()
                case .tracking(let application):
                    LoanApplicationTrackingScreen(
                        viewModel: viewModel,
                        application: application,
                        onResume: {
                            viewModel.resumeDraft(application)
                            navigationPath.append(LoanApplicationRoute.overview(application.product))
                        },
                        onDelete: {
                            if viewModel.deleteDraft(applicationID: application.id) {
                                if !navigationPath.isEmpty {
                                    navigationPath.removeLast()
                                }
                            }
                        }
                    )
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

// MARK: - Loan Application Tracking Screen
private struct LoanApplicationTrackingScreen: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let application: BorrowerLoanApplication
    let onResume: () -> Void
    let onDelete: () -> Void

    @State private var showDeleteConfirmation = false

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

                    if application.isDraft {
                        Button(action: onResume) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.uturn.forward.circle.fill")
                                Text("Resume Application")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(LMSColors.brandNavy)
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
        .toolbar {
            if application.isDraft {
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
            Text("This will permanently delete draft \(application.displayIdentifier). You cannot undo this action.")
        }
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
