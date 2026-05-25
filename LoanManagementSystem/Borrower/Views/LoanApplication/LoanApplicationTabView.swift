






import SwiftUI
import PhotosUI



private enum LoanApplicationRoute: Hashable {
    case overview(UUID)
    case combinedApplication
    case verificationResult
    case tracking(UUID)
}



struct LoanApplicationTabView: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {

                HStack(alignment: .center) {
                    Text("Loans")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.brandNavy)

                    Spacer()
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)
                .background(Color(.systemGroupedBackground))


                Picker("", selection: $viewModel.selectedSegment) {
                    ForEach(LoanHubSegment.allCases) { segment in
                        Text(segment.rawValue).tag(segment)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)


                switch viewModel.selectedSegment {
                case .discover:
                    LoanTypesGridSection(viewModel: viewModel) { productID in
                        navigationPath.append(LoanApplicationRoute.overview(productID))
                    }
                case .applications:
                    BorrowerApplicationsSection(viewModel: viewModel) { applicationID in
                        navigationPath.append(LoanApplicationRoute.tracking(applicationID))
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .hideNavigationBar()
            .navigationDestination(for: LoanApplicationRoute.self) { route in
                switch route {
                case .overview(let productID):
                    if let product = viewModel.product(for: productID) {
                        LoanOverviewScreen(viewModel: viewModel, product: product) {
                            viewModel.startDraft(for: product)
                            navigationPath.append(LoanApplicationRoute.combinedApplication)
                        }
                    }
                case .combinedApplication:
                    CombinedApplicationScreen(viewModel: viewModel) {
                        navigationPath.append(LoanApplicationRoute.verificationResult)
                    }
                case .verificationResult:
                    DocumentVerificationResultView(viewModel: viewModel) {
                        if viewModel.submitCurrentApplication() != nil {
                            navigationPath = NavigationPath()
                            viewModel.selectedSegment = .applications
                        }
                    }
                case .tracking(let applicationID):
                    LoanApplicationTrackingScreen(viewModel: viewModel, applicationID: applicationID)
                }
            }
            .sheet(item: $viewModel.activeInfoSheet) { item in
                ContextHelpSheetView(item: item)
                    .presentationDetents([.medium])
            }
            .alert("Application Submitted", isPresented: $viewModel.showSubmissionAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.submissionAlertMessage)
            }
        }
    }
}



private struct LoanTypesGridSection: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let onSelectProduct: (UUID) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                VStack(alignment: .leading, spacing: 6) {
                    Text("Explore Loan Products")
                        .font(.title3.weight(.bold))
                    Text("Choose a loan type to view details, eligibility, and apply.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)


                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(viewModel.products) { product in
                        LoanProductGridCard(product: product)
                            .onTapGesture {
                                onSelectProduct(product.id)
                            }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
    }
}



private struct LoanProductGridCard: View {
    let product: BorrowerLoanProduct

    private var accentGradient: LinearGradient {
        switch product.type {
        case .personal:
            return LinearGradient(colors: [Color(hex: "667EEA"), Color(hex: "764BA2")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .home:
            return LinearGradient(colors: [Color(hex: "11998E"), Color(hex: "38EF7D")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .education:
            return LinearGradient(colors: [Color(hex: "FC5C7D"), Color(hex: "6A82FB")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .business:
            return LinearGradient(colors: [Color(hex: "F2994A"), Color(hex: "F2C94C")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .vehicle:
            return LinearGradient(colors: [Color(hex: "4FACFE"), Color(hex: "00F2FE")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .gold:
            return LinearGradient(colors: [Color(hex: "F7971E"), Color(hex: "FFD200")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .loanAgainstProperty:
            return LinearGradient(colors: [Color(hex: "834D9B"), Color(hex: "D04ED6")], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .other:
            return LinearGradient(colors: [Color(hex: "606C88"), Color(hex: "3F4C6B")], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            ZStack {
                Circle()
                    .fill(accentGradient)
                    .frame(width: 44, height: 44)
                Image(systemName: product.type.iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text(product.type.title)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(product.shortDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            Spacer(minLength: 0)


            HStack(spacing: 4) {
                Image(systemName: "percent")
                    .font(.system(size: 9, weight: .bold))
                Text(product.interestRateRange)
                    .font(.caption2.weight(.semibold))
            }
            .foregroundColor(.brandNavy)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.brandNavy.opacity(0.1), in: Capsule())
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: 180)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
}



private struct LoanOverviewScreen: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let product: BorrowerLoanProduct
    let onApply: () -> Void

    @State private var expandedFAQ: UUID?

    private var accentColor: Color {
        switch product.type {
        case .personal: return Color(hex: "667EEA")
        case .home: return Color(hex: "11998E")
        case .education: return Color(hex: "FC5C7D")
        case .business: return Color(hex: "F2994A")
        case .vehicle: return Color(hex: "4FACFE")
        case .gold: return Color(hex: "F7971E")
        case .loanAgainstProperty: return Color(hex: "834D9B")
        case .other: return Color(hex: "606C88")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                heroHeader


                quickInfoGrid


                benefitsSection


                eligibilitySection


                documentsSection


                if !product.faqs.isEmpty {
                    faqsSection
                }


                applyButton
            }
            .padding(16)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(product.type.title)
        .navigationBarTitleDisplayMode(.inline)
    }


    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 56, height: 56)
                    Image(systemName: product.type.iconName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(accentColor)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.interestRateRange)
                        .font(.title3.weight(.bold))
                        .foregroundColor(accentColor)
                    Text("Interest Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(product.type.title)
                .font(.title2.weight(.bold))

            Text(product.shortDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)


            Rectangle()
                .fill(accentColor.opacity(0.3))
                .frame(height: 2)
                .clipShape(Capsule())
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
    }


    private var quickInfoGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            quickInfoTile(
                icon: "indianrupeesign.circle.fill",
                title: "Max Amount",
                value: product.maximumAmount.formattedAsINR(),
                color: .brandEmerald
            )
            quickInfoTile(
                icon: "clock.fill",
                title: "Processing",
                value: product.estimatedProcessingTime,
                color: .brandAmber
            )
            quickInfoTile(
                icon: "doc.text.fill",
                title: "Processing Fee",
                value: product.processingFees,
                color: .brandNavy
            )
            quickInfoTile(
                icon: "calendar.badge.clock",
                title: "Repayment",
                value: product.repaymentOverview,
                color: Color(hex: "834D9B")
            )
        }
    }

    private func quickInfoTile(icon: String, title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }


    private var benefitsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Key Benefits", systemImage: "star.fill")
                .font(.subheadline.weight(.bold))
                .foregroundColor(.brandNavy)

            ForEach(product.benefits, id: \.self) { benefit in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.brandEmerald)
                        .padding(.top, 1)
                    Text(benefit)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }


    private var eligibilitySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Eligibility Criteria", systemImage: "person.badge.shield.checkmark.fill")
                .font(.subheadline.weight(.bold))
                .foregroundColor(.brandNavy)

            ForEach(product.eligibilityCriteria, id: \.self) { criterion in
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 5))
                        .foregroundColor(.brandNavy)
                        .padding(.top, 6)
                    Text(criterion)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
            }

            Divider()

            Text(product.eligibilitySnapshot)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }


    private var documentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Required Documents", systemImage: "doc.on.doc.fill")
                .font(.subheadline.weight(.bold))
                .foregroundColor(.brandNavy)

            let previewDocs = viewModel.previewDocuments(for: product)
            let groupedDocs = Dictionary(grouping: previewDocs, by: \.category)

            ForEach(BorrowerDocumentCategory.allCases) { category in
                if let docs = groupedDocs[category], !docs.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(category.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)

                        ForEach(docs) { doc in
                            HStack(spacing: 8) {
                                Image(systemName: "doc.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(accentColor.opacity(0.7))
                                Text(doc.name)
                                    .font(.subheadline)
                                Spacer()
                                Image(systemName: doc.status.iconName)
                                    .font(.system(size: 12))
                                    .foregroundColor(doc.status.tintColor)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }


    private var faqsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Frequently Asked Questions", systemImage: "questionmark.circle.fill")
                .font(.subheadline.weight(.bold))
                .foregroundColor(.brandNavy)

            ForEach(product.faqs) { faq in
                VStack(alignment: .leading, spacing: 6) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            expandedFAQ = expandedFAQ == faq.id ? nil : faq.id
                        }
                    } label: {
                        HStack {
                            Text(faq.question)
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: expandedFAQ == faq.id ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.bold))
                                .foregroundColor(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    if expandedFAQ == faq.id {
                        Text(faq.answer)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(10)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }


    private var applyButton: some View {
        Button(action: onApply) {
            HStack(spacing: 10) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 16, weight: .semibold))
                Text("Apply Now")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [Color.brandNavy, Color.brandNavy.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.brandNavy.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
}



private struct CombinedApplicationScreen: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let onVerify: () -> Void

    @FocusState private var isInputActive: Bool
    @State private var previewDocument: BorrowerLoanDocumentItem?


    @State private var isPhotoPickerPresented = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var activeUploadingDocID: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                applicationProgressHeader


                personalInfoSection


                employmentSection


                financialSection


                loanDetailsSection


                additionalInfoSection


                documentUploadSection


                if !viewModel.formValidationErrors.isEmpty {
                    validationWarningsSection
                }


                verifyButton
            }
            .padding(16)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Apply")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { isInputActive = false }
            }
        }
        .onChange(of: viewModel.formData) {
            viewModel.autosaveDraft()
        }
        .sheet(item: $previewDocument) { document in
            DocumentPreviewSheet(document: document)
                .presentationDetents([.medium])
        }
        .photosPicker(isPresented: $isPhotoPickerPresented, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem = newItem, let docID = activeUploadingDocID else { return }
            Task {
                do {
                    if let data = try await newItem.loadTransferable(type: Data.self) {
                        await viewModel.uploadDocument(docID, imageData: data)
                    }
                } catch {
                    print("Error loading picked image data: \(error.localizedDescription)")
                }
                await MainActor.run {
                    selectedPhotoItem = nil
                    activeUploadingDocID = nil
                }
            }
        }
    }


    private var applicationProgressHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let product = viewModel.selectedProduct {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: product.type.iconName)
                            .font(.system(size: 14))
                        Text(product.type.title)
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(.brandNavy)
                    Spacer()
                    if let savedAt = viewModel.lastDraftSavedAt {
                        Text("Saved \(savedAt.formattedAsDDMMMYYYY())")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            HStack(spacing: 14) {
                progressBadge("Form", value: viewModel.formCompletionRatio, color: .brandNavy)
                progressBadge("Docs", value: viewModel.documents.isEmpty ? 0 : Double(viewModel.verifiedDocumentsCount) / Double(viewModel.documents.count), color: .brandEmerald)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func progressBadge(_ title: String, value: Double, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            ProgressView(value: value)
                .tint(color)
            Text("\(Int(value * 100))%")
                .font(.caption2.weight(.bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }


    private var personalInfoSection: some View {
        formCard("Personal Information", icon: "person.fill") {
            formField("Full Name", text: $viewModel.formData.fullName, validation: .fullName)
            DatePicker("Date of Birth", selection: $viewModel.formData.dateOfBirth, displayedComponents: .date)
                .font(.subheadline)
            formField("Mobile Number", text: $viewModel.formData.mobileNumber, validation: .mobileNumber, keyboard: .phonePad)
            formField("Email Address", text: $viewModel.formData.emailAddress, validation: .emailAddress, keyboard: .emailAddress)
            formField("Current Address", text: $viewModel.formData.address, validation: .address, axis: .vertical)
        }
    }


    private var employmentSection: some View {
        formCard("Employment Details", icon: "briefcase.fill") {
            formField("Occupation", text: $viewModel.formData.occupation, validation: .occupation)

            VStack(alignment: .leading, spacing: 4) {
                Text("Employment Type")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("Employment Type", selection: $viewModel.formData.employmentType) {
                    ForEach(viewModel.employmentTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(.menu)
            }

            formField("Employer Name", text: $viewModel.formData.employerName, validation: .employerName)

            Stepper("Experience: \(viewModel.formData.workExperienceYears) years", value: $viewModel.formData.workExperienceYears, in: 0...50)
                .font(.subheadline)
        }
    }


    private var financialSection: some View {
        formCard("Financial Information", icon: "indianrupeesign.circle.fill") {
            formField("Monthly Income (₹)", text: $viewModel.formData.monthlyIncome, validation: .monthlyIncome, keyboard: .numberPad)
            formField("Annual Income (₹)", text: $viewModel.formData.annualIncome, validation: .annualIncome, keyboard: .numberPad)
            formField("Existing EMIs (₹)", text: $viewModel.formData.existingEMIs, keyboard: .numberPad)
            formField("Credit Card Obligations (₹)", text: $viewModel.formData.creditCardObligations, keyboard: .numberPad)
            formField("Credit Score", text: $viewModel.formData.creditScore, keyboard: .numberPad)
        }
    }


    private var loanDetailsSection: some View {
        formCard("Loan Details", icon: "doc.text.fill") {
            formField("Loan Amount (₹)", text: $viewModel.formData.loanAmountRequested, validation: .loanAmountRequested, keyboard: .numberPad)
            formField("Loan Purpose", text: $viewModel.formData.loanPurpose, validation: .loanPurpose, axis: .vertical)

            VStack(alignment: .leading, spacing: 4) {
                Text("Repayment Preference")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("Repayment", selection: $viewModel.formData.repaymentPreference) {
                    ForEach(viewModel.repaymentPreferences, id: \.self) { pref in
                        Text(pref).tag(pref)
                    }
                }
                .pickerStyle(.menu)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Preferred Tenure")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Picker("Tenure", selection: $viewModel.formData.preferredTenureMonths) {
                    ForEach(viewModel.tenureOptions, id: \.self) { months in
                        Text("\(months) months").tag(months)
                    }
                }
                .pickerStyle(.menu)
            }

            if let product = viewModel.selectedProduct {
                HStack {
                    Text("Interest Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(product.interestRateRange)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.brandNavy)
                }

                HStack {
                    Text("Processing Fee")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(product.processingFees)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
    }


    private var additionalInfoSection: some View {
        formCard("Additional Information", icon: "person.2.fill") {
            Toggle("Include Co-applicant", isOn: $viewModel.formData.hasCoApplicant)
                .font(.subheadline)
            if viewModel.formData.hasCoApplicant {
                formField("Co-applicant Details", text: $viewModel.formData.coApplicantDetails, validation: .coApplicantDetails, axis: .vertical)
            }

            Toggle("Include Guarantor", isOn: $viewModel.formData.hasGuarantor)
                .font(.subheadline)
            if viewModel.formData.hasGuarantor {
                formField("Guarantor Details", text: $viewModel.formData.guarantorDetails, validation: .guarantorDetails, axis: .vertical)
            }
        }
    }


    private var documentUploadSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Document Upload", systemImage: "arrow.up.doc.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundColor(.brandNavy)
                Spacer()
                Text("\(viewModel.verifiedDocumentsCount)/\(viewModel.documents.count) verified")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.brandEmerald)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.brandEmerald.opacity(0.1), in: Capsule())
            }


            uploadSourcePicker


            ForEach(BorrowerDocumentCategory.allCases) { category in
                let categoryDocs = viewModel.documents(for: category)
                if !categoryDocs.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(category.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                            .padding(.top, 4)

                        ForEach(categoryDocs) { document in
                            InlineDocumentCard(
                                document: document,
                                selectedUploadSource: viewModel.selectedUploadSource,
                                onPreview: { previewDocument = document },
                                onUpload: {
                                    activeUploadingDocID = document.id
                                    isPhotoPickerPresented = true
                                },
                                onMarkForVerification: { viewModel.moveDocumentToVerification(document.id) }
                            )
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var uploadSourcePicker: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(BorrowerDocumentUploadSource.allCases) { source in
                Button {
                    viewModel.selectedUploadSource = source
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: source.iconName)
                            .font(.system(size: 12))
                        Text(source.rawValue)
                            .font(.caption2.weight(.semibold))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .foregroundColor(viewModel.selectedUploadSource == source ? .white : .brandNavy)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(viewModel.selectedUploadSource == source ? Color.brandNavy : Color.brandNavy.opacity(0.1))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }


    private var validationWarningsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Validation Issues", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.orange)
            ForEach(viewModel.formValidationErrors, id: \.self) { error in
                Text("• \(error)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }


    private var verifyButton: some View {
        Button {
            viewModel.verifyAndShowResult()
            onVerify()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Verify My Documents")
                    .font(.headline)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(
                    colors: [Color.brandNavy, Color.brandNavy.opacity(0.85)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.brandNavy.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }


    @ViewBuilder
    private func formCard<Content: View>(_ title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.brandNavy)
            content()
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    @ViewBuilder
    private func formField(_ label: String, text: Binding<String>, validation: BorrowerLoanFormField? = nil, keyboard: UIKeyboardType = .default, axis: Axis = .horizontal) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(label, text: text, axis: axis == .vertical ? .vertical : .horizontal)
                .font(.subheadline)
                .keyboardType(keyboard)
                .focused($isInputActive)
                .textFieldStyle(.roundedBorder)
            if let field = validation, let message = viewModel.validationMessage(for: field) {
                Text(message)
                    .font(.caption2)
                    .foregroundColor(.orange)
            }
        }
    }
}



private struct InlineDocumentCard: View {
    let document: BorrowerLoanDocumentItem
    let selectedUploadSource: BorrowerDocumentUploadSource
    let onPreview: () -> Void
    let onUpload: () -> Void
    let onMarkForVerification: () -> Void

    private var uploadButtonLabel: String {
        switch document.status {
        case .pendingUpload: return "Upload"
        case .rejected, .requiresResubmission: return "Re-upload"
        default: return "Replace"
        }
    }

    var body: some View {
        HStack(spacing: 10) {

            Image(systemName: document.status.iconName)
                .font(.system(size: 16))
                .foregroundColor(document.status.tintColor)
                .frame(width: 32, height: 32)
                .background(document.status.tintColor.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))


            VStack(alignment: .leading, spacing: 2) {
                Text(document.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(document.status.rawValue)
                    .font(.caption2)
                    .foregroundColor(document.status.tintColor)
            }

            Spacer()


            if !document.isLocked {
                HStack(spacing: 6) {
                    Button(action: onPreview) {
                        Image(systemName: "eye")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(width: 28, height: 28)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Button(action: onUpload) {
                        Text(uploadButtonLabel)
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .frame(height: 28)
                            .background(Color.brandNavy)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Image(systemName: "lock.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}



private struct DocumentVerificationResultView: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let onSubmit: () -> Void


    @State private var isPhotoPickerPresented = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var activeUploadingDocID: UUID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {

                verificationStatusHeader


                documentResultsList


                if !viewModel.rejectedDocuments.isEmpty {
                    rejectedDocumentsSection
                }


                if !viewModel.preSubmissionWarnings.isEmpty {
                    warningsSection
                }


                reviewSummary


                actionButtons
            }
            .padding(16)
            .padding(.bottom, 30)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Verification")
        .navigationBarTitleDisplayMode(.inline)
        .photosPicker(isPresented: $isPhotoPickerPresented, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem = newItem, let docID = activeUploadingDocID else { return }
            Task {
                do {
                    if let data = try await newItem.loadTransferable(type: Data.self) {
                        await viewModel.uploadDocument(docID, imageData: data)
                    }
                } catch {
                    print("Error loading picked image data in verification: \(error.localizedDescription)")
                }
                await MainActor.run {
                    selectedPhotoItem = nil
                    activeUploadingDocID = nil
                }
            }
        }
    }

    private var verificationStatusHeader: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(viewModel.allDocumentsVerified
                          ? Color.brandEmerald.opacity(0.15)
                          : Color.brandCoral.opacity(0.15))
                    .frame(width: 70, height: 70)
                Image(systemName: viewModel.allDocumentsVerified
                      ? "checkmark.seal.fill"
                      : "exclamationmark.triangle.fill")
                    .font(.system(size: 30))
                    .foregroundColor(viewModel.allDocumentsVerified
                                    ? .brandEmerald
                                    : .brandCoral)
            }

            Text(viewModel.allDocumentsVerified
                 ? "All Documents Verified!"
                 : "Some Documents Need Attention")
                .font(.title3.weight(.bold))
                .multilineTextAlignment(.center)

            Text(viewModel.allDocumentsVerified
                 ? "Your application is ready to submit."
                 : "Please re-upload the highlighted documents and try again.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var documentResultsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Document Status")
                .font(.subheadline.weight(.bold))
                .foregroundColor(.brandNavy)

            ForEach(viewModel.documents) { document in
                HStack(spacing: 10) {
                    Image(systemName: document.status.iconName)
                        .font(.system(size: 14))
                        .foregroundColor(document.status.tintColor)
                        .frame(width: 28, height: 28)
                        .background(document.status.tintColor.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                    Text(document.name)
                        .font(.subheadline)
                        .lineLimit(1)

                    Spacer()

                    Text(document.status.rawValue)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(document.status.tintColor)
                }
                .padding(8)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var rejectedDocumentsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Action Required", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.bold))
                .foregroundColor(.brandCoral)

            Text("The following documents were rejected or need resubmission. Please re-upload them from the application form.")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(viewModel.rejectedDocuments) { doc in
                HStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.brandCoral)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(doc.name)
                            .font(.subheadline.weight(.medium))
                        Text(doc.status.rawValue)
                            .font(.caption2)
                            .foregroundColor(.brandCoral)
                    }
                    Spacer()
                    Button("Re-upload") {
                        activeUploadingDocID = doc.id
                        isPhotoPickerPresented = true
                    }
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.brandCoral)
                    .clipShape(Capsule())
                }
                .padding(10)
                .background(Color.brandCoral.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var warningsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Pre-Submission Warnings", systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.orange)
            ForEach(viewModel.preSubmissionWarnings, id: \.self) { warning in
                Text("• \(warning)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var reviewSummary: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Application Summary")
                .font(.subheadline.weight(.bold))
                .foregroundColor(.brandNavy)

            if let product = viewModel.selectedProduct {
                summaryRow("Loan Type", product.type.title)
            }
            summaryRow("Applicant", viewModel.formData.fullName)
            summaryRow("Requested Amount", viewModel.formData.requestedAmountValue.formattedAsINR())
            summaryRow("Tenure", "\(viewModel.formData.preferredTenureMonths) months")
            summaryRow("Documents Verified", "\(viewModel.verifiedDocumentsCount)/\(viewModel.documents.count)")

            ForEach(viewModel.eligibilitySummary, id: \.self) { line in
                Label(line, systemImage: "checkmark.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func summaryRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundColor(.primary)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 10) {
            if viewModel.canSubmitApplication {
                Button(action: onSubmit) {
                    HStack(spacing: 10) {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Submit Application")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        LinearGradient(
                            colors: [Color.brandEmerald, Color(hex: "11998E")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color.brandEmerald.opacity(0.3), radius: 10, x: 0, y: 5)
                }
            }

            if !viewModel.rejectedDocuments.isEmpty {
                Button {
                    viewModel.verifyAndShowResult()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Re-verify Documents")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(.brandNavy)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.brandNavy.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }

            if !viewModel.canSubmitApplication {
                Text("Resolve all warnings and ensure documents are verified to submit.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}



private struct BorrowerApplicationsSection: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let onSelectApplication: (UUID) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                metricsRow


                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(BorrowerApplicationFilter.allCases) { filter in
                            Button {
                                viewModel.selectedApplicationFilter = filter
                            } label: {
                                Text(filter.rawValue)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(viewModel.selectedApplicationFilter == filter ? .white : .brandNavy)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        viewModel.selectedApplicationFilter == filter
                                        ? Color.brandNavy
                                        : Color.brandNavy.opacity(0.1)
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }


                if !viewModel.draftApplications.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Drafts")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.secondary)

                        ForEach(viewModel.draftApplications) { app in
                            ApplicationListCard(application: app) {
                                onSelectApplication(app.id)
                            }
                        }
                    }
                }


                if viewModel.filteredSubmittedApplications.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary.opacity(0.5))
                        Text("No applications found")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Applications")
                            .font(.subheadline.weight(.bold))
                            .foregroundColor(.secondary)

                        ForEach(viewModel.filteredSubmittedApplications) { app in
                            ApplicationListCard(application: app) {
                                onSelectApplication(app.id)
                            }
                        }
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .refreshable {
            await viewModel.refreshDashboard()
        }
    }

    private var metricsRow: some View {
        let metrics = viewModel.dashboardMetrics
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            metricTile("Active", "\(metrics.activeApplications)", .brandNavy)
            metricTile("Approved", "\(metrics.approvedLoans)", .brandEmerald)
            metricTile("Rejected", "\(metrics.rejectedLoans)", .brandCoral)
        }
    }

    private func metricTile(_ title: String, _ value: String, _ color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundColor(color)
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}



private struct ApplicationListCard: View {
    let application: BorrowerLoanApplication
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: application.product.type.iconName)
                            .font(.system(size: 13))
                        Text(application.product.type.title)
                            .font(.subheadline.weight(.semibold))
                    }
                    Spacer()
                    StageBadge(stage: application.currentStage)
                }

                HStack(spacing: 12) {
                    Text(application.displayIdentifier)
                        .font(.caption.monospaced())
                        .foregroundColor(.secondary)
                    Spacer()
                    if application.formData.requestedAmountValue > 0 {
                        Text(application.formData.requestedAmountValue.formattedAsINR())
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.brandNavy)
                    }
                }

                if let submittedAt = application.submittedAt {
                    Text("Submitted: \(submittedAt.formattedAsDDMMMYYYY())")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}



private struct StageBadge: View {
    let stage: BorrowerApplicationStage

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: stage.iconName)
                .font(.system(size: 9))
            Text(stage.rawValue)
                .font(.caption2.weight(.semibold))
        }
        .foregroundColor(stage.tintColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(stage.tintColor.opacity(0.12), in: Capsule())
    }
}



private struct DocumentPreviewSheet: View {
    let document: BorrowerLoanDocumentItem

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.image.fill")
                .font(.system(size: 50))
                .foregroundColor(.brandNavy)
            Text(document.name)
                .font(.headline)
            Text(document.fileName ?? "No file uploaded yet")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("Uploaded: \(document.uploadDate?.formattedAsDDMMMYYYY() ?? "Not uploaded")")
                .font(.caption)
                .foregroundColor(.secondary)
            Text("Verification: \(document.status.rawValue)")
                .font(.caption.weight(.semibold))
                .foregroundColor(document.status.tintColor)
        }
        .padding(24)
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
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)
                            Spacer()
                            StageBadge(stage: application.currentStage)
                        }
                        Text(application.product.type.title)
                            .font(.title3.weight(.semibold))
                        HStack(spacing: 14) {
                            Label(application.formData.requestedAmountValue.formattedAsINR(), systemImage: "indianrupeesign.circle.fill")
                            Label(application.submittedAt?.formattedAsDDMMMYYYY() ?? "-", systemImage: "calendar")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        ProgressView(value: viewModel.progressValue(for: application))
                            .tint(.brandNavy)
                    }
                    .padding(14)
                    .background(Color(.secondarySystemBackground))
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
                            .tint(.brandNavy)

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
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Application Tracking")
            .navigationBarTitleDisplayMode(.inline)
        } else {
            ContentUnavailableView("Application Not Found", systemImage: "exclamationmark.circle")
        }
    }

    private func timelineSection(application: BorrowerLoanApplication) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status Timeline")
                .font(.headline)

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
                                    .foregroundColor(.white)
                            )
                        if index < stages.count - 1 {
                            Rectangle()
                                .fill(timelineColor(for: state).opacity(0.35))
                                .frame(width: 2, height: 26)
                        }
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(stage.rawValue)
                            .font(.subheadline.weight(state == .current ? .bold : .regular))
                        Text(viewModel.stageTimestamp(for: stage, application: application)?.formattedAsDDMMMYYYY() ?? "Pending")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
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
            return .brandEmerald
        case .current:
            return .brandNavy
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
                .font(.subheadline.weight(.semibold))
            content()
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func reviewRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.caption)
    }
}



private struct ContextHelpSheetView: View {
    let item: BorrowerContextHelpItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text(item.title)
                        .font(.title3.weight(.bold))
                    Spacer()
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.brandNavy)
                }

                Text(item.explanation)
                    .font(.body)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Examples")
                        .font(.headline)
                    ForEach(item.examples, id: \.self) { example in
                        Label(example, systemImage: "checkmark.circle")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Tip")
                        .font(.headline)
                    Text(item.recommendation)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(20)
        }
    }
}

#Preview {
    LoanApplicationTabView(viewModel: PreviewSupport.loanApplicationViewModel)
        .previewBorrowerEnvironment()
}

