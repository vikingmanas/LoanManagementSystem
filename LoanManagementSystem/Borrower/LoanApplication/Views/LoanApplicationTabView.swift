import SwiftUI

private enum LoanApplicationRoute: Hashable {
    case overview(UUID)
    case applicationForm
    case documentUpload
    case preSubmissionReview
    case tracking(UUID)
}

struct LoanApplicationTabView: View {
    @StateObject private var viewModel = LoanApplicationViewModel()
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: LMSSpacing.lg) {
                    Picker("Loan Hub", selection: $viewModel.selectedSegment) {
                        ForEach(LoanHubSegment.allCases) { segment in
                            Text(segment.rawValue).tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)
                    .fintechSegmentedContainer()

                    LoanDashboardMetricsSection(metrics: viewModel.dashboardMetrics)

                    switch viewModel.selectedSegment {
                    case .discover:
                        if !viewModel.draftApplications.isEmpty {
                            DraftApplicationsSection(
                                drafts: viewModel.draftApplications,
                                onResume: { draft in
                                    viewModel.resumeDraft(draft)
                                    navigationPath.append(LoanApplicationRoute.applicationForm)
                                }
                            )
                        }

                        LoanProductCatalogSection(
                            products: viewModel.products,
                            onOpenOverview: { product in
                                navigationPath.append(LoanApplicationRoute.overview(product.id))
                            },
                            onQuickStart: { product in
                                viewModel.startDraft(for: product)
                                navigationPath.append(LoanApplicationRoute.applicationForm)
                            }
                        )
                    case .applications:
                        ApplicationFilterSection(selectedFilter: $viewModel.selectedApplicationFilter)
                        BorrowerApplicationsSection(
                            applications: viewModel.filteredSubmittedApplications,
                            progressProvider: { app in
                                viewModel.progressValue(for: app)
                            },
                            onOpen: { app in
                                navigationPath.append(LoanApplicationRoute.tracking(app.id))
                            },
                            onAdvance: { app in
                                viewModel.advanceStage(for: app.id)
                            },
                            onReject: { app in
                                viewModel.rejectApplication(app.id)
                            }
                        )
                    }
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)
                .padding(.bottom, LMSSpacing.xxl)
            }
            .lmsScreenBackground()
            .navigationTitle("Loans")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(LMSColors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Discover Products", systemImage: "sparkles") {
                            viewModel.selectedSegment = .discover
                        }
                        Button("My Applications", systemImage: "list.bullet.rectangle.portrait") {
                            viewModel.selectedSegment = .applications
                        }

                        if let draft = viewModel.draftApplications.first {
                            Button("Resume Latest Draft", systemImage: "square.and.pencil") {
                                viewModel.resumeDraft(draft)
                                viewModel.selectedSegment = .discover
                                navigationPath.append(LoanApplicationRoute.applicationForm)
                            }
                        }

                        if let latest = viewModel.submittedApplications.first {
                            Button("Track Latest Application", systemImage: "timeline.selection") {
                                viewModel.selectedSegment = .applications
                                navigationPath.append(LoanApplicationRoute.tracking(latest.id))
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .accessibilityLabel("Loan quick actions")
                }
            }
            .refreshable {
                await viewModel.refreshDashboard()
            }
            .sheet(item: $viewModel.activeInfoSheet) { info in
                ContextHelpSheetView(item: info)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
            .alert("Application Submitted", isPresented: $viewModel.showSubmissionAlert) {
                Button("Done") {
                    viewModel.selectedSegment = .applications
                    navigationPath = NavigationPath()
                }
            } message: {
                Text(viewModel.submissionAlertMessage)
            }
            .navigationDestination(for: LoanApplicationRoute.self) { route in
                switch route {
                case .overview(let productID):
                    if let product = viewModel.product(for: productID) {
                        LoanOverviewScreen(
                            product: product,
                            documents: viewModel.previewDocuments(for: product),
                            onStartApplication: {
                                viewModel.startDraft(for: product)
                                navigationPath.append(LoanApplicationRoute.applicationForm)
                            }
                        )
                    } else {
                        ContentUnavailableView("Loan Product Not Found", systemImage: "exclamationmark.circle")
                    }
                case .applicationForm:
                    LoanApplicationFormScreen(
                        viewModel: viewModel,
                        onContinue: {
                            viewModel.autosaveDraft()
                            navigationPath.append(LoanApplicationRoute.documentUpload)
                        }
                    )
                case .documentUpload:
                    LoanDocumentUploadScreen(
                        viewModel: viewModel,
                        onContinue: {
                            viewModel.autosaveDraft()
                            navigationPath.append(LoanApplicationRoute.preSubmissionReview)
                        }
                    )
                case .preSubmissionReview:
                    LoanApplicationReviewScreen(
                        viewModel: viewModel,
                        onEditForm: {
                            if navigationPath.count >= 2 {
                                navigationPath.removeLast(2)
                            }
                        },
                        onEditDocuments: {
                            if navigationPath.count >= 1 {
                                navigationPath.removeLast()
                            }
                        },
                        onSubmit: {
                            if viewModel.submitCurrentApplication() != nil {
                                navigationPath = NavigationPath()
                            }
                        }
                    )
                case .tracking(let applicationID):
                    LoanApplicationTrackingScreen(viewModel: viewModel, applicationID: applicationID)
                }
            }
        }
    }
}



private struct LoanDashboardMetricsSection: View {
    let metrics: BorrowerLoanDashboardMetrics

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Loan Dashboard")
                    .font(LMSFont.title3)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(Int(metrics.averageProgress * 100))% Avg Progress")
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    MetricCard(
                        title: "Active Applications",
                        value: "\(metrics.activeApplications)",
                        icon: "clock.badge.checkmark.fill",
                        tint: LMSColors.brandNavy
                    )
                    MetricCard(
                        title: "Draft Applications",
                        value: "\(metrics.draftApplications)",
                        icon: "square.and.pencil",
                        tint: .orange
                    )
                    MetricCard(
                        title: "Approved Loans",
                        value: "\(metrics.approvedLoans)",
                        icon: "checkmark.seal.fill",
                        tint: LMSColors.emerald
                    )
                    MetricCard(
                        title: "Rejected Loans",
                        value: "\(metrics.rejectedLoans)",
                        icon: "xmark.octagon.fill",
                        tint: LMSColors.coral
                    )
                    MetricCard(
                        title: "Outstanding Balance",
                        value: metrics.outstandingBalance.formattedAsINR(),
                        icon: "wallet.bifold.fill",
                        tint: LMSColors.brandNavy
                    )
                    MetricCard(
                        title: "Upcoming EMIs",
                        value: metrics.upcomingEMIs.formattedAsINR(),
                        icon: "calendar.badge.clock",
                        tint: .orange
                    )
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(tint)
                    .padding(8)
                    .background(tint.opacity(0.12), in: Circle())
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(LMSColors.textPrimary)
                Text(title)
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(width: 140, alignment: .leading)
        .padding(16)
        .background(LMSColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

private struct DraftApplicationsSection: View {
    let drafts: [BorrowerLoanApplication]
    let onResume: (BorrowerLoanApplication) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Continue Drafts")
                .font(LMSFont.headline)

            ForEach(drafts) { draft in
                Button {
                    onResume(draft)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: draft.product.type.iconName)
                            .foregroundStyle(LMSColors.brandNavy)
                            .frame(width: 28, height: 28)
                            .background(LMSColors.brandNavy.opacity(0.12), in: Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text(draft.product.type.title)
                                .font(LMSFont.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(LMSColors.textPrimary)
                            Text("Last updated \(draft.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(LMSFont.caption.weight(.semibold))
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                    .padding(12)
                    .background(LMSColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct LoanProductCatalogSection: View {
    let products: [BorrowerLoanProduct]
    let onOpenOverview: (BorrowerLoanProduct) -> Void
    let onQuickStart: (BorrowerLoanProduct) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Available Loan Products")
                .font(LMSFont.headline)

            ForEach(products) { product in
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .center) {
                        Label(product.type.title, systemImage: product.type.iconName)
                            .font(LMSFont.headline)
                            .foregroundStyle(LMSColors.textPrimary)
                        Spacer()
                        Text(product.interestRateRange)
                            .font(LMSFont.caption.weight(.semibold))
                            .foregroundStyle(LMSColors.brandNavy)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(LMSColors.brandNavy.opacity(0.10), in: Capsule())
                    }

                    Text(product.shortDescription)
                        .font(LMSFont.subheadline)
                        .foregroundStyle(LMSColors.textSecondary)
                        .multilineTextAlignment(.leading)

                    VStack(spacing: 8) {
                        ProductDataPoint(label: "Max Loan", value: product.maximumAmount.formattedAsINR())
                        ProductDataPoint(label: "Processing Time", value: product.estimatedProcessingTime)
                        ProductDataPoint(label: "Eligibility", value: product.eligibilitySnapshot)
                    }

                    HStack(spacing: 10) {
                        Button {
                            onOpenOverview(product)
                        } label: {
                            Label("View Details", systemImage: "doc.text.magnifyingglass")
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                        }
                        .buttonStyle(.bordered)
                        .tint(LMSColors.brandNavy)

                        Button {
                            onQuickStart(product)
                        } label: {
                            Label("Apply", systemImage: "paperplane.fill")
                                .frame(maxWidth: .infinity)
                                .frame(height: 42)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(LMSColors.brandNavy)
                    }
                }
                .padding(14)
                .background(LMSColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
    }
}

private struct ProductDataPoint: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text(label)
                .font(LMSFont.caption)
                .foregroundStyle(LMSColors.textSecondary)
                .frame(width: 110, alignment: .leading)
            Text(value)
                .font(LMSFont.caption)
                .fontWeight(.medium)
                .foregroundStyle(LMSColors.textPrimary)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
    }
}

private struct ApplicationFilterSection: View {
    @Binding var selectedFilter: BorrowerApplicationFilter

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Application Tracking")
                .font(LMSFont.headline)
            Text("Filter by status to quickly find and manage your applications.")
                .font(LMSFont.caption)
                .foregroundStyle(LMSColors.textSecondary)
            Picker("Filter", selection: $selectedFilter) {
                ForEach(BorrowerApplicationFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

private struct BorrowerApplicationsSection: View {
    let applications: [BorrowerLoanApplication]
    let progressProvider: (BorrowerLoanApplication) -> Double
    let onOpen: (BorrowerLoanApplication) -> Void
    let onAdvance: (BorrowerLoanApplication) -> Void
    let onReject: (BorrowerLoanApplication) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if applications.isEmpty {
                ContentUnavailableView(
                    "No applications found",
                    systemImage: "list.bullet.rectangle.portrait",
                    description: Text("Try changing filters or start a new application from the Discover tab.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            } else {
                ForEach(applications) { application in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(application.displayIdentifier)
                                .font(LMSFont.caption.monospaced())
                                .foregroundStyle(LMSColors.textSecondary)
                            Spacer()
                            StageBadge(stage: application.currentStage)
                        }

                        Text(application.product.type.title)
                            .font(LMSFont.headline)
                            .foregroundStyle(LMSColors.textPrimary)

                        HStack(spacing: 16) {
                            Label(application.formData.requestedAmountValue.formattedAsINR(), systemImage: "indianrupeesign.circle")
                            Label(application.submittedAt?.formattedAsDDMMMYYYY() ?? "-", systemImage: "calendar")
                        }
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textSecondary)

                        ProgressView(value: progressProvider(application))
                            .tint(LMSColors.brandNavy)

                        HStack(spacing: 10) {
                            Button {
                                onOpen(application)
                            } label: {
                                Label("Track", systemImage: "timeline.selection")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(LMSColors.brandNavy)

                            if !application.currentStage.isTerminal {
                                Menu {
                                    Button("Advance Status", systemImage: "arrow.right.circle.fill") {
                                        onAdvance(application)
                                    }
                                    Button("Mark Rejected", systemImage: "xmark.circle.fill", role: .destructive) {
                                        onReject(application)
                                    }
                                } label: {
                                    Label("Update", systemImage: "ellipsis.circle")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                    .padding(14)
                    .background(LMSColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .contextMenu {
                        if !application.currentStage.isTerminal {
                            Button("Advance Status", systemImage: "arrow.right.circle.fill") {
                                onAdvance(application)
                            }
                            Button("Mark Rejected", systemImage: "xmark.circle.fill", role: .destructive) {
                                onReject(application)
                            }
                        }
                        Button("Open Timeline", systemImage: "timeline.selection") { onOpen(application) }
                    }
                }
            }
        }
    }
}

private struct StageBadge: View {
    let stage: BorrowerApplicationStage

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: stage.iconName)
                .font(LMSFont.caption2.weight(.bold))
            Text(stage.rawValue)
                .font(LMSFont.caption.weight(.semibold))
        }
        .foregroundStyle(stage.tintColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(stage.tintColor.opacity(0.13), in: Capsule())
    }
}

private struct LoanOverviewScreen: View {
    let product: BorrowerLoanProduct
    let documents: [BorrowerLoanDocumentItem]
    let onStartApplication: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 10) {
                    Label(product.type.title, systemImage: product.type.iconName)
                        .font(LMSFont.title3.weight(.bold))
                    Text(product.shortDescription)
                        .foregroundStyle(LMSColors.textSecondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LMSColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                overviewInfoSection
                documentsSection
                faqSection

                Button(action: onStartApplication) {
                    Text("Start Application")
                        .font(LMSFont.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(LMSColors.brandNavy)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .accessibilityLabel("Start loan application")
            }
            .padding(20)
            .padding(.bottom, 18)
        }
        .background(LMSColors.background)
        .navigationTitle("Loan Overview")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var overviewInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Loan Information")
                .font(LMSFont.headline)

            overviewRow("Purpose", product.purpose)
            overviewRow("Benefits", product.benefits.joined(separator: ", "))
            overviewRow("Eligibility Criteria", product.eligibilityCriteria.joined(separator: ", "))
            overviewRow("Minimum Requirements", product.minimumRequirements.joined(separator: ", "))
            overviewRow("Interest Info", product.interestInformation)
            overviewRow("Repayment", product.repaymentOverview)
            overviewRow("Processing Fee", product.processingFees)
        }
        .padding(14)
        .background(LMSColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func overviewRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(LMSFont.caption)
                .foregroundStyle(LMSColors.textSecondary)
            Text(value)
                .font(LMSFont.subheadline)
        }
    }

    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Required Documents")
                .font(LMSFont.headline)

            ForEach(BorrowerDocumentCategory.allCases) { category in
                let categoryDocuments = documents.filter { $0.category == category }
                if !categoryDocuments.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category.rawValue)
                            .font(LMSFont.subheadline.weight(.semibold))

                        ForEach(categoryDocuments) { document in
                            HStack(alignment: .top, spacing: 10) {
                                Image(systemName: document.status.iconName)
                                    .foregroundStyle(document.status.tintColor)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(document.name)
                                    Text("Upload: \(document.status.uploadStatusText) • Verification: \(document.status.verificationStatusText)")
                                        .font(LMSFont.caption)
                                        .foregroundStyle(LMSColors.textSecondary)
                                    Text("Last updated: \(document.lastUpdated?.formattedAsDDMMMYYYY() ?? "Not updated")")
                                        .font(LMSFont.caption2)
                                        .foregroundStyle(LMSColors.textSecondary)
                                }
                                Spacer()
                            }
                        }
                    }
                    .padding(12)
                    .background(LMSColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding(14)
        .background(LMSColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Frequently Asked Questions")
                .font(LMSFont.headline)

            ForEach(product.faqs) { faq in
                VStack(alignment: .leading, spacing: 6) {
                    Text(faq.question)
                        .font(LMSFont.subheadline.weight(.semibold))
                    Text(faq.answer)
                        .font(LMSFont.subheadline)
                        .foregroundStyle(LMSColors.textSecondary)
                }
                .padding(12)
                .background(LMSColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(14)
        .background(LMSColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct LoanApplicationFormScreen: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let onContinue: () -> Void
    
    @FocusState private var isInputActive: Bool

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Form Progress")
                            .font(LMSFont.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(Int(viewModel.formCompletionRatio * 100))%")
                            .font(LMSFont.caption.weight(.semibold))
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                    ProgressView(value: viewModel.formCompletionRatio)
                        .tint(LMSColors.brandNavy)
                    Text("Draft auto-saves as you type.")
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textSecondary)
                    if let lastSaved = viewModel.lastDraftSavedAt {
                        Text("Last saved \(lastSaved.formatted(date: .abbreviated, time: .shortened))")
                            .font(LMSFont.caption2)
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                }
            }

            Section("Personal Information") {
                TextField("Full Name", text: $viewModel.formData.fullName)
                    .focused($isInputActive)
                    .textInputAutocapitalization(.words)
                FieldErrorView(message: viewModel.validationMessage(for: .fullName))

                DatePicker("Date of Birth", selection: $viewModel.formData.dateOfBirth, in: ...Date(), displayedComponents: .date)

                TextField("Mobile Number", text: $viewModel.formData.mobileNumber)
                    .focused($isInputActive)
                    .keyboardType(.phonePad)
                FieldErrorView(message: viewModel.validationMessage(for: .mobileNumber))

                TextField("Email Address", text: $viewModel.formData.emailAddress)
                    .focused($isInputActive)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                FieldErrorView(message: viewModel.validationMessage(for: .emailAddress))

                TextField("Current Address", text: $viewModel.formData.address, axis: .vertical)
                    .focused($isInputActive)
                FieldErrorView(message: viewModel.validationMessage(for: .address))
            }

            Section {
                infoLabelRow("Employment Type", .employmentType) {
                    Picker("Employment Type", selection: $viewModel.formData.employmentType) {
                        ForEach(viewModel.employmentTypes, id: \.self) { type in
                            Text(type).tag(type)
                        }
                    }
                }

                TextField("Occupation", text: $viewModel.formData.occupation)
                    .focused($isInputActive)
                FieldErrorView(message: viewModel.validationMessage(for: .occupation))

                TextField("Employer Name", text: $viewModel.formData.employerName)
                    .focused($isInputActive)
                FieldErrorView(message: viewModel.validationMessage(for: .employerName))

                Stepper("Work Experience: \(viewModel.formData.workExperienceYears) years", value: $viewModel.formData.workExperienceYears, in: 0...40)
            } header: {
                Text("Employment Information")
            }

            Section {
                TextField("Monthly Income", text: $viewModel.formData.monthlyIncome)
                    .focused($isInputActive)
                    .keyboardType(.decimalPad)
                FieldErrorView(message: viewModel.validationMessage(for: .monthlyIncome))

                infoLabelRow("Annual Income", .annualIncome) {
                    TextField("Annual Income", text: $viewModel.formData.annualIncome)
                        .focused($isInputActive)
                        .keyboardType(.decimalPad)
                }
                FieldErrorView(message: viewModel.validationMessage(for: .annualIncome))

                infoLabelRow("Existing Liabilities", .existingLiabilities) {
                    Group {
                        TextField("Existing Loans (count or amount)", text: $viewModel.formData.existingLoans)
                            .focused($isInputActive)
                            .keyboardType(.decimalPad)
                        TextField("Existing EMIs", text: $viewModel.formData.existingEMIs)
                            .focused($isInputActive)
                            .keyboardType(.decimalPad)
                        TextField("Credit Card Obligations", text: $viewModel.formData.creditCardObligations)
                            .focused($isInputActive)
                            .keyboardType(.decimalPad)
                    }
                }

                infoLabelRow("Credit Score", .creditScore) {
                    TextField("Credit Score", text: $viewModel.formData.creditScore)
                        .focused($isInputActive)
                        .keyboardType(.numberPad)
                }
            } header: {
                Text("Financial Information")
            }

            Section {
                TextField("Loan Amount Requested", text: $viewModel.formData.loanAmountRequested)
                    .focused($isInputActive)
                    .keyboardType(.decimalPad)
                FieldErrorView(message: viewModel.validationMessage(for: .loanAmountRequested))

                TextField("Loan Purpose", text: $viewModel.formData.loanPurpose, axis: .vertical)
                    .focused($isInputActive)
                FieldErrorView(message: viewModel.validationMessage(for: .loanPurpose))

                Picker("Repayment Preference", selection: $viewModel.formData.repaymentPreference) {
                    ForEach(viewModel.repaymentPreferences, id: \.self) { preference in
                        Text(preference).tag(preference)
                    }
                }

                Picker("Preferred Tenure", selection: $viewModel.formData.preferredTenureMonths) {
                    ForEach(viewModel.tenureOptions, id: \.self) { tenure in
                        Text("\(tenure) months").tag(tenure)
                    }
                }

                if let product = viewModel.selectedProduct {
                    infoLabelRow("Interest Rate", .interestRate) {
                        Text(product.interestRateRange)
                            .foregroundStyle(LMSColors.textSecondary)
                    }

                    infoLabelRow("Processing Fee", .processingFee) {
                        Text(product.processingFees)
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                }
            } header: {
                Text("Loan Details")
            }

            Section("Additional Information") {
                Toggle("Include Co-applicant", isOn: $viewModel.formData.hasCoApplicant)
                if viewModel.formData.hasCoApplicant {
                    infoLabelRow("Co-applicant Details", .coApplicant) {
                        TextField("Name, relationship, income summary", text: $viewModel.formData.coApplicantDetails, axis: .vertical)
                            .focused($isInputActive)
                    }
                    FieldErrorView(message: viewModel.validationMessage(for: .coApplicantDetails))
                }

                Toggle("Include Guarantor", isOn: $viewModel.formData.hasGuarantor)
                if viewModel.formData.hasGuarantor {
                    TextField("Guarantor Details", text: $viewModel.formData.guarantorDetails, axis: .vertical)
                        .focused($isInputActive)
                    FieldErrorView(message: viewModel.validationMessage(for: .guarantorDetails))
                }
            }

            if !viewModel.formValidationErrors.isEmpty {
                Section("Validation Warnings") {
                    ForEach(viewModel.formValidationErrors, id: \.self) { error in
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(LMSFont.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Section {
                Button {
                    onContinue()
                } label: {
                    Text("Continue to Document Verification")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .buttonStyle(.borderedProminent)
                .tint(LMSColors.brandNavy)
                .disabled(!viewModel.formValidationErrors.isEmpty)
            }
        }
        .navigationTitle("Application Form")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isInputActive = false
                }
            }
        }
        .onChange(of: viewModel.formData) { _, _ in
            viewModel.autosaveDraft()
        }
    }

    @ViewBuilder
    private func infoLabelRow<Content: View>(_ title: String, _ topic: BorrowerContextHelpTopic, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)
                Spacer()
                Button {
                    viewModel.presentInfo(for: topic)
                } label: {
                    Image(systemName: "info.circle")
                }
                .buttonStyle(.plain)
                .foregroundStyle(LMSColors.brandNavy)
                .accessibilityLabel("About \(title)")
            }
            content()
        }
    }
}

private struct FieldErrorView: View {
    let message: String?

    var body: some View {
        if let message {
            Text(message)
                .font(LMSFont.caption2)
                .foregroundStyle(.orange)
        }
    }
}

private struct LoanDocumentUploadScreen: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let onContinue: () -> Void

    @State private var previewDocument: BorrowerLoanDocumentItem?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Document Upload & Verification")
                        .font(LMSFont.headline)
                    Text("\(viewModel.verifiedDocumentsCount) of \(viewModel.documents.count) documents verified")
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textSecondary)
                    ProgressView(value: viewModel.documents.isEmpty ? 0 : Double(viewModel.verifiedDocumentsCount) / Double(viewModel.documents.count))
                        .tint(LMSColors.brandNavy)
                }
                .padding(14)
                .background(LMSColors.surfaceElevated)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                uploadSourceSection

                ForEach(BorrowerDocumentCategory.allCases) { category in
                    let categoryDocs = viewModel.documents(for: category)
                    if !categoryDocs.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(category.rawValue)
                                .font(LMSFont.subheadline.weight(.semibold))

                            ForEach(categoryDocs) { document in
                                DocumentRequirementCard(
                                    document: document,
                                    selectedUploadSource: viewModel.selectedUploadSource,
                                    onPreview: {
                                        previewDocument = document
                                    },
                                    onUpload: {
                                        viewModel.uploadDocument(document.id)
                                    },
                                    onMarkForVerification: {
                                        viewModel.moveDocumentToVerification(document.id)
                                    },
                                    onMarkStatus: { status in
                                        viewModel.markDocument(document.id, status: status)
                                    }
                                )
                            }
                        }
                        .padding(14)
                        .background(LMSColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }

                if !viewModel.missingDocumentNames.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Action Required", systemImage: "exclamationmark.triangle.fill")
                            .font(LMSFont.subheadline.weight(.semibold))
                            .foregroundStyle(.orange)
                        Text(viewModel.missingDocumentNames.joined(separator: ", "))
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                    .padding(12)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                HStack(spacing: 12) {
                    Button("Run Verification") {
                        viewModel.runBulkVerification()
                    }
                    .buttonStyle(.bordered)
                    .tint(LMSColors.brandNavy)

                    Button("Continue to Review") {
                        onContinue()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(LMSColors.brandNavy)
                }
            }
            .padding(20)
            .padding(.bottom, 20)
        }
        .background(LMSColors.background)
        .navigationTitle("Verify Documents")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $previewDocument) { document in
            DocumentPreviewSheet(document: document)
                .presentationDetents([.medium])
        }
    }

    private var uploadSourceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Upload Methods")
                .font(LMSFont.subheadline.weight(.semibold))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(BorrowerDocumentUploadSource.allCases) { source in
                    Button {
                        viewModel.selectedUploadSource = source
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: source.iconName)
                            Text(source.rawValue)
                                .font(LMSFont.caption.weight(.semibold))
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .foregroundStyle(viewModel.selectedUploadSource == source ? .white : LMSColors.brandNavy)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(viewModel.selectedUploadSource == source ? LMSColors.brandNavy : LMSColors.brandNavy.opacity(0.12))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Text("Drag & Drop is best on iPad and larger screens.")
                .font(LMSFont.caption2)
                .foregroundStyle(LMSColors.textSecondary)
        }
        .padding(14)
        .background(LMSColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

private struct DocumentRequirementCard: View {
    let document: BorrowerLoanDocumentItem
    let selectedUploadSource: BorrowerDocumentUploadSource
    let onPreview: () -> Void
    let onUpload: () -> Void
    let onMarkForVerification: () -> Void
    let onMarkStatus: (BorrowerDocumentStatus) -> Void

    private var uploadButtonLabel: String {
        switch document.status {
        case .pendingUpload:
            return "Upload"
        case .rejected, .requiresResubmission:
            return "Re-upload"
        default:
            return "Replace"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(document.name)
                        .font(LMSFont.subheadline.weight(.semibold))
                    Text("Upload: \(document.status.uploadStatusText)")
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textSecondary)
                    Text("Verification: \(document.status.verificationStatusText)")
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textSecondary)
                    Text("Last updated: \(document.lastUpdated?.formattedAsDDMMMYYYY() ?? "Not updated")")
                        .font(LMSFont.caption2)
                        .foregroundStyle(LMSColors.textSecondary)
                }
                Spacer()
                HStack(spacing: 6) {
                    Image(systemName: document.status.iconName)
                    Text(document.status.rawValue)
                        .font(LMSFont.caption2.weight(.semibold))
                }
                .foregroundStyle(document.status.tintColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(document.status.tintColor.opacity(0.15), in: Capsule())
            }

            HStack(spacing: 10) {
                Button("Preview") {
                    onPreview()
                }
                .buttonStyle(.bordered)

                if !document.isLocked {
                    Button(uploadButtonLabel) {
                        onUpload()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(LMSColors.brandNavy)

                    Button("Verify") {
                        onMarkForVerification()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Label("Locked", systemImage: "lock.fill")
                        .font(LMSFont.caption.weight(.semibold))
                        .foregroundStyle(LMSColors.textSecondary)
                }
            }

            Text("Selected source: \(selectedUploadSource.rawValue)")
                .font(LMSFont.caption2)
                .foregroundStyle(LMSColors.textSecondary)
        }
        .padding(12)
        .background(LMSColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .contextMenu {
            if !document.isLocked {
                Button("Mark Uploaded") { onMarkStatus(.uploaded) }
                Button("Mark Under Verification") { onMarkStatus(.underVerification) }
                Button("Mark Verified") { onMarkStatus(.verified) }
                Button("Requires Resubmission") { onMarkStatus(.requiresResubmission) }
                Button("Mark Rejected", role: .destructive) { onMarkStatus(.rejected) }
            }
        }
    }
}

private struct DocumentPreviewSheet: View {
    let document: BorrowerLoanDocumentItem

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.image.fill")
                .font(.system(size: 50))
                .foregroundStyle(LMSColors.brandNavy)
            Text(document.name)
                .font(LMSFont.headline)
            Text(document.fileName ?? "No file uploaded yet")
                .font(LMSFont.subheadline)
                .foregroundStyle(LMSColors.textSecondary)
            Text("Uploaded: \(document.uploadDate?.formattedAsDDMMMYYYY() ?? "Not uploaded")")
                .font(LMSFont.caption)
                .foregroundStyle(LMSColors.textSecondary)
            Text("Verification: \(document.status.rawValue)")
                .font(LMSFont.caption.weight(.semibold))
                .foregroundStyle(document.status.tintColor)
        }
        .padding(24)
    }
}

private struct LoanApplicationReviewScreen: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let onEditForm: () -> Void
    let onEditDocuments: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Pre-Submission Review")
                        .font(LMSFont.headline)
                    Spacer()
                    if let product = viewModel.selectedProduct {
                        Text(product.type.title)
                            .font(LMSFont.caption.weight(.semibold))
                            .foregroundStyle(LMSColors.brandNavy)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(LMSColors.brandNavy.opacity(0.12), in: Capsule())
                    }
                }

                if !viewModel.preSubmissionWarnings.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Warnings", systemImage: "exclamationmark.triangle.fill")
                            .font(LMSFont.subheadline.weight(.semibold))
                            .foregroundStyle(.orange)
                        ForEach(viewModel.preSubmissionWarnings, id: \.self) { warning in
                            Text("• \(warning)")
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                    }
                    .padding(14)
                    .background(Color.orange.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                Group {
                    reviewCard("Applicant Information") {
                        reviewRow("Full Name", viewModel.formData.fullName)
                        reviewRow("DOB", viewModel.formData.dateOfBirth.formatted(date: .abbreviated, time: .omitted))
                        reviewRow("Mobile", viewModel.formData.mobileNumber)
                        reviewRow("Email", viewModel.formData.emailAddress)
                        reviewRow("Address", viewModel.formData.address)
                    }

                    reviewCard("Financial Information") {
                        reviewRow("Monthly Income", viewModel.formData.monthlyIncomeValue.formattedAsINR())
                        reviewRow("Annual Income", viewModel.formData.annualIncomeValue.formattedAsINR())
                        reviewRow("Existing EMIs", viewModel.formData.existingEMIsValue.formattedAsINR())
                        reviewRow("Credit Card Obligations", viewModel.formData.creditCardObligationsValue.formattedAsINR())
                        reviewRow("Credit Score", viewModel.formData.creditScore.isEmpty ? "-" : viewModel.formData.creditScore)
                    }

                    reviewCard("Loan Information") {
                        reviewRow("Requested Amount", viewModel.formData.requestedAmountValue.formattedAsINR())
                        reviewRow("Purpose", viewModel.formData.loanPurpose)
                        reviewRow("Repayment Preference", viewModel.formData.repaymentPreference)
                        reviewRow("Preferred Tenure", "\(viewModel.formData.preferredTenureMonths) months")
                        reviewRow("Co-applicant", viewModel.formData.hasCoApplicant ? viewModel.formData.coApplicantDetails : "Not added")
                        reviewRow("Guarantor", viewModel.formData.hasGuarantor ? viewModel.formData.guarantorDetails : "Not added")
                    }

                    reviewCard("Uploaded Documents") {
                        ForEach(viewModel.documents) { document in
                            HStack(alignment: .top) {
                                Text(document.name)
                                Spacer()
                                Text(document.status.rawValue)
                                    .font(LMSFont.caption2.weight(.semibold))
                                    .foregroundStyle(document.status.tintColor)
                            }
                            .font(LMSFont.caption)
                        }
                    }

                    reviewCard("Eligibility Summary") {
                        ForEach(viewModel.eligibilitySummary, id: \.self) { line in
                            Label(line, systemImage: "checkmark.circle")
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button("Edit Form") {
                        onEditForm()
                    }
                    .buttonStyle(.bordered)
                    .tint(LMSColors.brandNavy)

                    Button("Edit Documents") {
                        onEditDocuments()
                    }
                    .buttonStyle(.bordered)
                    .tint(LMSColors.brandNavy)
                }

                Button {
                    onSubmit()
                } label: {
                    Text("Submit Application")
                        .font(LMSFont.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(viewModel.canSubmitApplication ? LMSColors.brandNavy : Color.gray)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(!viewModel.canSubmitApplication)

                if !viewModel.canSubmitApplication {
                    Text("Resolve warnings and ensure all documents are verified to submit.")
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textSecondary)
                }
            }
            .padding(20)
            .padding(.bottom, 24)
        }
        .background(LMSColors.background)
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func reviewCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(LMSFont.subheadline.weight(.semibold))
            content()
        }
        .padding(14)
        .background(LMSColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func reviewRow(_ title: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(title)
                .foregroundStyle(LMSColors.textSecondary)
            Spacer()
            Text(value.isEmpty ? "-" : value)
                .multilineTextAlignment(.trailing)
        }
        .font(LMSFont.caption)
    }
}

private enum TimelineNodeState {
    case completed
    case current
    case pending
}

private struct LoanApplicationTrackingScreen: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let applicationID: UUID

    var body: some View {
        if let application = viewModel.application(for: applicationID) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(application.displayIdentifier)
                                .font(LMSFont.caption.monospaced())
                                .foregroundStyle(LMSColors.textSecondary)
                            Spacer()
                            StageBadge(stage: application.currentStage)
                        }
                        Text(application.product.type.title)
                            .font(LMSFont.title3.weight(.semibold))
                        HStack(spacing: 14) {
                            Label(application.formData.requestedAmountValue.formattedAsINR(), systemImage: "indianrupeesign.circle.fill")
                            Label(application.submittedAt?.formattedAsDDMMMYYYY() ?? "-", systemImage: "calendar")
                        }
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textSecondary)
                        ProgressView(value: viewModel.progressValue(for: application))
                            .tint(LMSColors.brandNavy)
                    }
                    .padding(14)
                    .background(LMSColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    timelineSection(application: application)

                    reviewCard("Officer Queue Details") {
                        reviewRow("Assigned Queue", application.assignedQueue ?? "Not assigned")
                        reviewRow("Outstanding Balance", application.outstandingBalance.formattedAsINR())
                        reviewRow("Upcoming EMI", application.upcomingEMI.formattedAsINR())
                    }

                    if !application.currentStage.isTerminal {
                        HStack(spacing: 12) {
                            Button("Advance Status") {
                                viewModel.advanceStage(for: application.id)
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(LMSColors.brandNavy)

                            Button("Mark Rejected") {
                                viewModel.rejectApplication(application.id)
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                        }
                    }
                }
                .padding(20)
                .padding(.bottom, 24)
            }
            .background(LMSColors.background)
            .navigationTitle("Application Tracking")
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView("Application Not Found", systemImage: "exclamationmark.circle")
        }
    }

    private func timelineSection(application: BorrowerLoanApplication) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status Timeline")
                .font(LMSFont.headline)

            let stages = viewModel.timelineStages(for: application)
            ForEach(Array(stages.enumerated()), id: \.offset) { index, stage in
                let state = timelineState(for: stage, in: application)
                HStack(alignment: .top, spacing: 10) {
                    VStack(spacing: 0) {
                        Circle()
                            .fill(timelineColor(for: state))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Image(systemName: timelineIcon(for: state))
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                        if index < stages.count - 1 {
                            Rectangle()
                                .fill(timelineColor(for: state).opacity(0.35))
                                .frame(width: 2, height: 26)
                        }
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(stage.rawValue)
                            .font(LMSFont.subheadline.weight(state == .current ? .bold : .regular))
                        Text(viewModel.stageTimestamp(for: stage, application: application)?.formattedAsDDMMMYYYY() ?? "Pending")
                            .font(LMSFont.caption2)
                            .foregroundStyle(LMSColors.textSecondary)
                    }

                    Spacer()
                }
            }
        }
        .padding(14)
        .background(LMSColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func timelineState(for stage: BorrowerApplicationStage, in application: BorrowerLoanApplication) -> TimelineNodeState {
        let stages = viewModel.timelineStages(for: application)
        guard let currentIndex = stages.firstIndex(of: application.currentStage),
              let stageIndex = stages.firstIndex(of: stage) else {
            return .pending
        }

        if stageIndex < currentIndex {
            return .completed
        }
        if stageIndex == currentIndex {
            return .current
        }
        return .pending
    }

    private func timelineColor(for state: TimelineNodeState) -> Color {
        switch state {
        case .completed:
            return LMSColors.emerald
        case .current:
            return LMSColors.brandNavy
        case .pending:
            return Color(.systemGray3)
        }
    }

    private func timelineIcon(for state: TimelineNodeState) -> String {
        switch state {
        case .completed:
            return "checkmark"
        case .current:
            return "circle.fill"
        case .pending:
            return "circle"
        }
    }

    private func reviewCard<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(LMSFont.subheadline.weight(.semibold))
            content()
        }
        .padding(14)
        .background(LMSColors.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func reviewRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(LMSColors.textSecondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(LMSFont.caption)
    }
}

private struct ContextHelpSheetView: View {
    let item: BorrowerContextHelpItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(item.title)
                        .font(LMSFont.title3.weight(.bold))
                    Spacer()
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(LMSColors.brandNavy)
                }

                Text(item.explanation)
                    .font(LMSFont.body)
                    .foregroundStyle(LMSColors.textSecondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Examples")
                        .font(LMSFont.headline)
                    ForEach(item.examples, id: \.self) { example in
                        Label(example, systemImage: "checkmark.circle")
                            .font(LMSFont.subheadline)
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tip")
                        .font(LMSFont.headline)
                    Text(item.recommendation)
                        .font(LMSFont.subheadline)
                        .foregroundStyle(LMSColors.textSecondary)
                }
            }
            .padding(20)
        }
    }
}
