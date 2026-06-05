import SwiftUI
import UIKit
@preconcurrency import Vision

struct DocumentManagementDetailView: View {
    @Bindable var viewModel: BorrowerProfileViewModel

    @State private var documents: [VaultDocument] = []
    @State private var searchText = ""
    @State private var selectedFilter: VaultDocumentFilter = .all
    @State private var selectedDocumentID: UUID?
    @State private var showingSourceSheet = false
    @State private var showingImagePicker = false
    @State private var imagePickerSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var previewDocument: VaultDocument?
    @State private var shareURL: URL?
    @State private var alertMessage: String?

    private var filteredDocuments: [VaultDocument] {
        documents.filter { document in
            let matchesSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                document.title.localizedCaseInsensitiveContains(searchText) ||
                document.fileName.localizedCaseInsensitiveContains(searchText) ||
                document.category.rawValue.localizedCaseInsensitiveContains(searchText)
            return matchesSearch && selectedFilter.matches(document)
        }
    }

    private var groupedDocuments: [(VaultDocumentCategory, [VaultDocument])] {
        VaultDocumentCategory.allCases.compactMap { category in
            let items = filteredDocuments.filter { $0.category == category }
            return items.isEmpty ? nil : (category, items)
        }
    }

    private var uploadedCount: Int {
        documents.filter(\.isUploaded).count
    }

    private var verifiedCount: Int {
        documents.filter { $0.status == .verified }.count
    }

    private var pendingCount: Int {
        documents.filter { $0.status == .pending || $0.status == .processing || $0.status == .uploading }.count
    }

    private var lastUpdated: Date? {
        documents.compactMap(\.updatedAt).max()
    }

    private var shareItemBinding: Binding<VaultShareItem?> {
        Binding(
            get: { shareURL.map { VaultShareItem(url: $0) } },
            set: { newValue in
                if newValue == nil {
                    shareURL = nil
                }
            }
        )
    }

    private var alertBinding: Binding<Bool> {
        Binding(
            get: { alertMessage != nil },
            set: { isPresented in
                if !isPresented {
                    alertMessage = nil
                }
            }
        )
    }

    var body: some View {
        ScrollView {
            documentVaultContent
        }
        .background(LMSColors.background)
        .navigationTitle("Documents")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                uploadToolbarButton
            }
        }
        .confirmationDialog("Replace Document", isPresented: $showingSourceSheet, titleVisibility: .visible) {
            Button("Take Photo") {
                beginImageSelection(source: .camera)
            }
            Button("Choose from Gallery") {
                beginImageSelection(source: .photoLibrary)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Select Document Source")
        }
        .accessibleFullScreenCover(isPresented: $showingImagePicker) {
            VaultImagePicker(sourceType: imagePickerSourceType) { image in
                showingImagePicker = false
                if let selectedDocumentID {
                    processUpload(image, for: selectedDocumentID)
                }
            } onCancel: {
                showingImagePicker = false
            }
            .ignoresSafeArea()
        }
        .accessibleFullScreenCover(item: $previewDocument) { document in
            VaultDocumentPreview(
                document: document,
                onDownload: { download(document) },
                onShare: { share(document) }
            )
        }
        .accessibleSheet(item: shareItemBinding) { item in
            VaultShareSheet(items: [item.url])
        }
        .alert("Documents", isPresented: alertBinding) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
        .onAppear {
            loadDocuments()
        }
        .onChange(of: viewModel.profile?.kycVerification) { _, _ in
            loadDocuments(keepLocalUploads: true)
        }
    }

    private var documentVaultContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            summaryCard
            searchAndFilters
            documentGroupsView
            securityCard
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 32)
    }

    private var uploadToolbarButton: some View {
        Button(action: selectFirstUploadSlot) {
            Image(systemName: "plus")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(LMSColors.brandNavy)
        }
        .accessibilityLabel("Upload document")
    }

    private func selectFirstUploadSlot() {
        let target = documents.first(where: { !$0.isUploaded }) ?? documents.first
        selectedDocumentID = target?.id
        showingSourceSheet = target != nil
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Securely manage and verify your uploaded documents")
                .font(LMSFont.footnote)
                .foregroundStyle(LMSColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Documents Summary", systemImage: "shield.lefthalf.filled")
                    .font(LMSFont.callout.weight(.bold))
                    .foregroundStyle(.white)
                Spacer()
                Text(lastUpdated.map { "Updated \($0.formattedAsDDMMMYYYY())" } ?? "Not updated")
                    .font(LMSFont.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
            }

            HStack(spacing: 10) {
                summaryMetric(title: "Uploaded", value: "\(uploadedCount)")
                summaryMetric(title: "Verified", value: "\(verifiedCount)")
                summaryMetric(title: "Pending", value: "\(pendingCount)")
            }
        }
        .padding(16)
        .background(
            LinearGradient(
                colors: [LMSColors.brandNavy, LMSColors.brandNavyLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .shadow(color: LMSColors.brandNavy.opacity(0.22), radius: 14, x: 0, y: 8)
    }

    private func summaryMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text(title)
                .font(LMSFont.caption2)
                .foregroundStyle(.white.opacity(0.68))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var searchAndFilters: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(LMSColors.textSecondary)
                TextField("Search documents", text: $searchText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(LMSFont.footnote)
            }
            .padding(.horizontal, 12)
            .frame(height: 42)
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(LMSColors.separatorLight, lineWidth: 0.6)
            )

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(VaultDocumentFilter.allCases) { filter in
                        Button {
                            withAnimation(.smooth(duration: 0.2)) {
                                selectedFilter = filter
                            }
                        } label: {
                            Text(filter.title)
                                .font(LMSFont.caption.weight(.bold))
                                .foregroundStyle(selectedFilter == filter ? .white : LMSColors.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    selectedFilter == filter ? LMSColors.brandNavy : LMSColors.surface,
                                    in: Capsule()
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(selectedFilter == filter ? Color.clear : LMSColors.separatorLight, lineWidth: 0.6)
                                )
                        }
                        .buttonStyle(LMSPressableStyle())
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var documentGroupsView: some View {
        if groupedDocuments.isEmpty {
            emptyState
        } else {
            ForEach(VaultDocumentCategory.allCases, id: \.self) { category in
                let items = filteredDocuments.filter { $0.category == category }
                if !items.isEmpty {
                    documentSection(category: category, documents: items)
                }
            }
        }
    }

    private func documentSection(category: VaultDocumentCategory, documents: [VaultDocument]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(category.rawValue.uppercased())
                .font(LMSFont.caption2.weight(.bold))
                .foregroundStyle(LMSColors.textSecondary)
                .padding(.horizontal, 2)

            VStack(spacing: 10) {
                ForEach(documents) { document in
                    VaultDocumentCard(
                        document: document,
                        onView: { previewDocument = document },
                        onDownload: { download(document) },
                        onReplace: {
                            selectedDocumentID = document.id
                            showingSourceSheet = true
                        },
                        onDelete: { delete(document) }
                    )
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 42, weight: .semibold))
                .foregroundStyle(LMSColors.brandNavy)
                .frame(width: 72, height: 72)
                .background(LMSColors.brandNavy.opacity(0.08), in: Circle())
            Text("No documents uploaded")
                .font(LMSFont.headline)
                .foregroundStyle(LMSColors.textPrimary)
            Text("Upload your KYC and financial documents securely.")
                .font(LMSFont.footnote)
                .foregroundStyle(LMSColors.textSecondary)
                .multilineTextAlignment(.center)
            Button("Upload Document") {
                selectedDocumentID = documents.first?.id
                showingSourceSheet = selectedDocumentID != nil
            }
            .font(LMSFont.footnote.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(LMSColors.brandNavy, in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 0.6)
        )
    }

    private var securityCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lock.shield.fill")
                .font(.title2)
                .foregroundStyle(LMSColors.emerald)
                .frame(width: 42, height: 42)
                .background(LMSColors.emerald.opacity(0.10), in: Circle())

            VStack(alignment: .leading, spacing: 6) {
                Text("Banking-grade document security")
                    .font(LMSFont.callout.weight(.bold))
                    .foregroundStyle(LMSColors.textPrimary)
                Text("Your documents are encrypted securely, used only for verification, and never shared without your consent.")
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LMSColors.emerald.opacity(0.16), lineWidth: 0.8)
        )
    }

    private func loadDocuments(keepLocalUploads: Bool = false) {
        let existing = keepLocalUploads ? Dictionary(uniqueKeysWithValues: documents.map { ($0.kind, $0) }) : [:]
        let kyc = viewModel.profile?.kycVerification
        let profileImage = viewModel.profile?.profileImageData.flatMap(UIImage.init(data:))
        documents = VaultDocument.seedDocuments(kyc: kyc, profileImage: profileImage).map { seeded in
            guard var local = existing[seeded.kind] else { return seeded }
            local.status = seeded.status == .pending && local.isUploaded ? local.status : seeded.status
            if seeded.fileName != "Not uploaded" { local.fileName = seeded.fileName }
            if seeded.thumbnail != nil { local.thumbnail = seeded.thumbnail }
            return local
        }
    }

    private func beginImageSelection(source: UIImagePickerController.SourceType) {
        imagePickerSourceType = source == .camera && UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        showingImagePicker = true
    }

    private func processUpload(_ image: UIImage, for id: UUID) {
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        documents[index].thumbnail = image
        documents[index].status = .uploading
        documents[index].fileName = "\(documents[index].kind.filePrefix)-\(Int(Date().timeIntervalSince1970)).jpg"
        documents[index].fileSize = estimatedSize(of: image)
        documents[index].updatedAt = Date()
        documents[index].failureReason = nil
        HapticsManager.triggerImpact(style: .medium)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            guard let processingIndex = documents.firstIndex(where: { $0.id == id }) else { return }
            documents[processingIndex].status = .processing
        }

        Task {
            let ocr = await recognizeText(in: image)
            let result = validate(kind: documents[index].kind, text: ocr.text, confidence: ocr.confidence)
            await MainActor.run {
                apply(result: result, to: id)
            }
        }
    }

    private func apply(result: VaultOCRResult, to id: UUID) {
        guard let index = documents.firstIndex(where: { $0.id == id }) else { return }
        documents[index].status = result.isValid ? .verified : .rejected
        documents[index].updatedAt = Date()
        documents[index].verificationDate = result.isValid ? Date() : nil
        documents[index].failureReason = result.isValid ? nil : result.message
        documents[index].extractedDetails = result.details

        if result.isValid {
            syncKYCStatus(for: documents[index])
            HapticsManager.triggerNotification(type: .success)
        } else {
            syncRejectedStatus(for: documents[index])
            HapticsManager.triggerNotification(type: .error)
        }
    }

    private func syncKYCStatus(for document: VaultDocument) {
        switch document.kind {
        case .aadhaar:
            viewModel.updateKYCDoc(type: .aadhaar, status: .verified, fileName: document.fileName)
        case .pan:
            viewModel.updateKYCDoc(type: .pan, status: .verified, fileName: document.fileName)
        case .utilityBill, .rentalAgreement:
            viewModel.updateKYCDoc(type: .addressProof, status: .verified, fileName: document.fileName)
        case .profilePhoto:
            if let data = document.thumbnail?.jpegData(compressionQuality: 0.82) {
                viewModel.updateProfileImage(data: data)
            }
        default:
            break
        }
    }

    private func syncRejectedStatus(for document: VaultDocument) {
        switch document.kind {
        case .aadhaar:
            viewModel.updateKYCDoc(type: .aadhaar, status: .rejected)
        case .pan:
            viewModel.updateKYCDoc(type: .pan, status: .rejected)
        case .utilityBill, .rentalAgreement:
            viewModel.updateKYCDoc(type: .addressProof, status: .rejected)
        default:
            break
        }
    }

    private func delete(_ document: VaultDocument) {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        documents[index].thumbnail = nil
        documents[index].status = .pending
        documents[index].fileName = "Not uploaded"
        documents[index].fileSize = "—"
        documents[index].updatedAt = nil
        documents[index].verificationDate = nil
        documents[index].failureReason = nil
        documents[index].extractedDetails = [:]
        syncRejectedStatus(for: document)
    }

    private func download(_ document: VaultDocument) {
        guard let url = exportURL(for: document) else {
            alertMessage = "Upload or replace this document before downloading."
            return
        }
        shareURL = url
        alertMessage = "Document saved to Files"
    }

    private func share(_ document: VaultDocument) {
        guard let url = exportURL(for: document) else {
            alertMessage = "Upload or replace this document before sharing."
            return
        }
        shareURL = url
    }

    private func exportURL(for document: VaultDocument) -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(document.fileName)
        if let image = document.thumbnail, let data = image.jpegData(compressionQuality: 0.88) {
            try? data.write(to: url, options: .atomic)
            return url
        }
        let placeholder = "Secure document export: \(document.title)\nStatus: \(document.status.title)"
        try? placeholder.data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }

    private func estimatedSize(of image: UIImage) -> String {
        let bytes = image.jpegData(compressionQuality: 0.82)?.count ?? 0
        if bytes > 1_000_000 {
            return String(format: "%.1f MB", Double(bytes) / 1_000_000)
        }
        return "\(max(1, bytes / 1_000)) KB"
    }

    private func recognizeText(in image: UIImage) async -> (text: String, confidence: Float) {
        guard let cgImage = image.cgImage else { return ("", 0) }
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let candidates = observations.compactMap { $0.topCandidates(1).first }
                let text = candidates.map(\.string).joined(separator: "\n")
                let confidence = candidates.isEmpty ? 0 : candidates.map(\.confidence).reduce(0, +) / Float(candidates.count)
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

    private func validate(kind: VaultDocumentKind, text: String, confidence: Float) -> VaultOCRResult {
        let normalized = text.lowercased()
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, confidence >= 0.18 else {
            return VaultOCRResult(isValid: false, message: "The document is blurry or unreadable. Please upload a clear image.", details: ["OCR Confidence": confidenceLabel(confidence)])
        }

        switch kind {
        case .aadhaar:
            let aadhaar = firstMatch(in: text, pattern: #"(?<!\d)(\d{4}\s?\d{4}\s?\d{4})(?!\d)"#)
            let isValid = normalized.contains("government of india") || normalized.contains("aadhaar") || normalized.contains("uidai") || aadhaar != nil
            return VaultOCRResult(
                isValid: isValid,
                message: isValid ? "Document verified successfully." : "Invalid Aadhaar document. Upload a clear Aadhaar card image.",
                details: ["Aadhaar Number": aadhaar.map(maskAadhaar) ?? "Detected", "OCR Confidence": confidenceLabel(confidence)]
            )
        case .pan:
            let pan = firstMatch(in: text.uppercased(), pattern: #"[A-Z]{5}[0-9]{4}[A-Z]"#)
            let isValid = normalized.contains("income tax") || normalized.contains("permanent account") || pan != nil
            return VaultOCRResult(
                isValid: isValid,
                message: isValid ? "Document verified successfully." : "Invalid PAN document. Upload a clear PAN card image.",
                details: ["PAN": pan ?? "Detected", "OCR Confidence": confidenceLabel(confidence)]
            )
        case .salarySlip:
            return keywordValidation(text: normalized, confidence: confidence, keywords: ["salary", "payslip", "net pay", "gross", "earnings", "deductions"], invalid: "Invalid salary slip. Upload a clear payslip image.")
        case .bankStatement:
            return keywordValidation(text: normalized, confidence: confidence, keywords: ["statement", "account number", "transaction", "debit", "credit", "balance"], invalid: "Invalid bank statement. Upload a clear statement image.")
        case .utilityBill:
            return keywordValidation(text: normalized, confidence: confidence, keywords: ["bill", "electricity", "water", "gas", "consumer", "address"], invalid: "Invalid utility bill. Upload a clear address proof.")
        case .rentalAgreement:
            return keywordValidation(text: normalized, confidence: confidence, keywords: ["rental", "lease", "tenant", "landlord", "agreement", "address"], invalid: "Invalid rental agreement. Upload a clear agreement image.")
        case .passport:
            return keywordValidation(text: normalized, confidence: confidence, keywords: ["passport", "republic of india", "surname", "nationality"], invalid: "Invalid passport document. Upload a clear passport image.")
        case .signature:
            return VaultOCRResult(isValid: true, message: "Signature stored securely.", details: ["Document": "Signature", "Verification": "Manual review ready"])
        case .profilePhoto:
            return VaultOCRResult(isValid: true, message: "Profile photo stored securely.", details: ["Document": "Profile Photo", "Verification": "Face review ready"])
        }
    }

    private func keywordValidation(text: String, confidence: Float, keywords: [String], invalid: String) -> VaultOCRResult {
        let matches = keywords.filter { text.contains($0) }
        let valid = !matches.isEmpty && confidence >= 0.20
        return VaultOCRResult(
            isValid: valid,
            message: valid ? "Document verified successfully." : invalid,
            details: ["Matched Signals": matches.isEmpty ? "None" : matches.joined(separator: ", "), "OCR Confidence": confidenceLabel(confidence)]
        )
    }

    private func firstMatch(in text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, range: range), let matchRange = Range(match.range, in: text) else { return nil }
        return String(text[matchRange])
    }

    private func maskAadhaar(_ raw: String) -> String {
        let digits = raw.filter(\.isNumber)
        return "XXXX XXXX \(digits.suffix(4))"
    }

    private func confidenceLabel(_ confidence: Float) -> String {
        switch confidence {
        case 0.72...: return "High"
        case 0.40..<0.72: return "Medium"
        default: return "Low"
        }
    }
}

private struct VaultDocumentCard: View {
    let document: VaultDocument
    let onView: () -> Void
    let onDownload: () -> Void
    let onReplace: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                thumbnail

                VStack(alignment: .leading, spacing: 4) {
                    Text(document.title)
                        .font(LMSFont.callout.weight(.bold))
                        .foregroundStyle(LMSColors.textPrimary)
                    Text(document.fileName)
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textSecondary)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(document.updatedAt?.formattedAsDDMMMYYYY() ?? "Not uploaded")
                        Text("•")
                        Text(document.fileSize)
                    }
                    .font(LMSFont.caption2)
                    .foregroundStyle(LMSColors.textTertiary)
                }

                Spacer(minLength: 8)
                statusBadge
            }

            if let failure = document.failureReason, document.status == .rejected {
                Text(failure)
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.coral)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !document.extractedDetails.isEmpty && document.status == .verified {
                VStack(spacing: 4) {
                    ForEach(document.extractedDetails.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack {
                            Text(key)
                                .foregroundStyle(LMSColors.textSecondary)
                            Spacer()
                            Text(value)
                                .foregroundStyle(LMSColors.textPrimary)
                                .lineLimit(1)
                        }
                        .font(LMSFont.caption2)
                    }
                }
                .padding(10)
                .background(LMSColors.emerald.opacity(0.06), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }

            HStack(spacing: 10) {
                iconButton("eye.fill", action: onView, disabled: !document.isUploaded)
                iconButton("square.and.arrow.down", action: onDownload, disabled: !document.isUploaded)
                iconButton(document.isUploaded ? "pencil" : "arrow.up.doc.fill", action: onReplace)
                if document.isUploaded {
                    iconButton("trash", action: onDelete, tint: LMSColors.coral)
                }
                Spacer()
                if document.status == .rejected {
                    Button("Retry", action: onReplace)
                        .font(LMSFont.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(LMSColors.coral, in: Capsule())
                }
            }
        }
        .padding(14)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 0.6)
        )
        .shadow(color: .black.opacity(0.035), radius: 8, x: 0, y: 4)
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let image = document.thumbnail {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 66)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else {
            Image(systemName: document.kind.icon)
                .font(.title2)
                .foregroundStyle(document.status.tint)
                .frame(width: 56, height: 66)
                .background(document.status.tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var statusBadge: some View {
        Label(document.status.title, systemImage: document.status.icon)
            .font(LMSFont.caption2.weight(.bold))
            .foregroundStyle(document.status.tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(document.status.tint.opacity(0.10), in: Capsule())
    }

    private func iconButton(_ icon: String, action: @escaping () -> Void, disabled: Bool = false, tint: Color = LMSColors.brandNavy) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(disabled ? LMSColors.textTertiary : tint)
                .frame(width: 34, height: 34)
                .background(LMSColors.surfaceTertiary, in: Circle())
        }
        .buttonStyle(LMSPressableStyle())
        .disabled(disabled)
    }
}

private struct VaultDocumentPreview: View {
    let document: VaultDocument
    let onDownload: () -> Void
    let onShare: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var rotation: Angle = .zero

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if let image = document.thumbnail {
                    ZoomableImage(image: image, rotation: rotation)
                        .ignoresSafeArea(edges: .bottom)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: document.kind.icon)
                            .font(.system(size: 64))
                        Text(document.fileName)
                            .font(.headline)
                    }
                    .foregroundStyle(.white.opacity(0.82))
                }
            }
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.smooth(duration: 0.2)) { rotation += .degrees(90) }
                    } label: {
                        Image(systemName: "rotate.right")
                    }
                    Button(action: onShare) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    Button(action: onDownload) {
                        Image(systemName: "square.and.arrow.down")
                    }
                }
            }
        }
    }
}

private struct ZoomableImage: UIViewRepresentable {
    let image: UIImage
    let rotation: Angle

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 5
        scrollView.delegate = context.coordinator
        scrollView.backgroundColor = .black

        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(imageView)
        context.coordinator.imageView = imageView

        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            imageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            imageView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
        return scrollView
    }

    func updateUIView(_ scrollView: UIScrollView, context: Context) {
        context.coordinator.imageView?.image = image
        context.coordinator.imageView?.transform = CGAffineTransform(rotationAngle: CGFloat(rotation.radians))
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    final class Coordinator: NSObject, UIScrollViewDelegate {
        weak var imageView: UIImageView?
        func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
    }
}

private struct VaultImagePicker: UIViewControllerRepresentable {
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

private struct VaultShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct VaultShareItem: Identifiable {
    let id = UUID()
    let url: URL
}

private struct VaultOCRResult {
    let isValid: Bool
    let message: String
    let details: [String: String]
}

private struct VaultDocument: Identifiable {
    let id = UUID()
    let kind: VaultDocumentKind
    let title: String
    let category: VaultDocumentCategory
    var status: VaultDocumentStatus
    var fileName: String
    var fileSize: String
    var updatedAt: Date?
    var verificationDate: Date?
    var thumbnail: UIImage?
    var failureReason: String?
    var extractedDetails: [String: String] = [:]

    var isUploaded: Bool {
        status != .pending && fileName != "Not uploaded"
    }

    static func seedDocuments(kyc: KYCVerification?, profileImage: UIImage?) -> [VaultDocument] {
        [
            VaultDocument(kind: .aadhaar, title: "Aadhaar Card", category: .identity, status: VaultDocumentStatus(kyc?.aadhaarStatus), fileName: kyc?.aadhaarFileName ?? "Not uploaded", fileSize: kyc?.aadhaarFileName == nil ? "—" : "842 KB", updatedAt: kyc?.aadhaarFileName == nil ? nil : Date(), verificationDate: kyc?.aadhaarStatus == .verified ? Date() : nil),
            VaultDocument(kind: .pan, title: "PAN Card", category: .identity, status: VaultDocumentStatus(kyc?.panStatus), fileName: kyc?.panFileName ?? "Not uploaded", fileSize: kyc?.panFileName == nil ? "—" : "624 KB", updatedAt: kyc?.panFileName == nil ? nil : Date(), verificationDate: kyc?.panStatus == .verified ? Date() : nil),
            VaultDocument(kind: .passport, title: "Passport", category: .identity, status: .pending, fileName: "Not uploaded", fileSize: "—"),
            VaultDocument(kind: .utilityBill, title: "Utility Bill", category: .address, status: VaultDocumentStatus(kyc?.addressProofStatus), fileName: kyc?.addressProofFileName ?? "Not uploaded", fileSize: kyc?.addressProofFileName == nil ? "—" : "1.1 MB", updatedAt: kyc?.addressProofFileName == nil ? nil : Date(), verificationDate: kyc?.addressProofStatus == .verified ? Date() : nil),
            VaultDocument(kind: .rentalAgreement, title: "Rental Agreement", category: .address, status: .pending, fileName: "Not uploaded", fileSize: "—"),
            VaultDocument(kind: .salarySlip, title: "Salary Slip", category: .financial, status: .pending, fileName: "Not uploaded", fileSize: "—"),
            VaultDocument(kind: .bankStatement, title: "Bank Statement", category: .financial, status: .pending, fileName: "Not uploaded", fileSize: "—"),
            VaultDocument(kind: .signature, title: "Signature", category: .signaturePhoto, status: .pending, fileName: "Not uploaded", fileSize: "—"),
            VaultDocument(kind: .profilePhoto, title: "Profile Photo", category: .signaturePhoto, status: profileImage == nil ? .pending : .verified, fileName: profileImage == nil ? "Not uploaded" : "profile-photo.jpg", fileSize: profileImage == nil ? "—" : "420 KB", updatedAt: profileImage == nil ? nil : Date(), verificationDate: profileImage == nil ? nil : Date(), thumbnail: profileImage)
        ]
    }
}

private enum VaultDocumentKind {
    case aadhaar, pan, passport, utilityBill, rentalAgreement, salarySlip, bankStatement, signature, profilePhoto

    var icon: String {
        switch self {
        case .aadhaar, .pan, .passport: return "person.text.rectangle.fill"
        case .utilityBill, .rentalAgreement: return "house.text.fill"
        case .salarySlip, .bankStatement: return "banknote.fill"
        case .signature: return "signature"
        case .profilePhoto: return "person.crop.square.fill"
        }
    }

    var filePrefix: String {
        switch self {
        case .aadhaar: return "aadhaar-card"
        case .pan: return "pan-card"
        case .passport: return "passport"
        case .utilityBill: return "utility-bill"
        case .rentalAgreement: return "rental-agreement"
        case .salarySlip: return "salary-slip"
        case .bankStatement: return "bank-statement"
        case .signature: return "signature"
        case .profilePhoto: return "profile-photo"
        }
    }
}

private enum VaultDocumentCategory: String, CaseIterable {
    case identity = "Identity Documents"
    case address = "Address Proof"
    case financial = "Financial Documents"
    case signaturePhoto = "Signature & Photo"
}

private enum VaultDocumentStatus {
    case pending, uploading, processing, verified, rejected

    init(_ status: VerificationStatus?) {
        switch status {
        case .verified: self = .verified
        case .rejected: self = .rejected
        case .underReview: self = .processing
        case .pending, .none: self = .pending
        }
    }

    var title: String {
        switch self {
        case .pending: return "Pending"
        case .uploading: return "Uploading"
        case .processing: return "Verifying"
        case .verified: return "Verified"
        case .rejected: return "Rejected"
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock"
        case .uploading: return "arrow.up.doc.fill"
        case .processing: return "viewfinder"
        case .verified: return "checkmark.seal.fill"
        case .rejected: return "xmark.octagon.fill"
        }
    }

    var tint: Color {
        switch self {
        case .pending, .uploading, .processing: return LMSColors.amber
        case .verified: return LMSColors.emerald
        case .rejected: return LMSColors.coral
        }
    }
}

private enum VaultDocumentFilter: String, CaseIterable, Identifiable {
    case all, verified, pending, rejected, identity, financial

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: return "All"
        case .verified: return "Verified"
        case .pending: return "Pending"
        case .rejected: return "Rejected"
        case .identity: return "Identity"
        case .financial: return "Financial"
        }
    }

    func matches(_ document: VaultDocument) -> Bool {
        switch self {
        case .all: return true
        case .verified: return document.status == .verified
        case .pending: return document.status == .pending || document.status == .uploading || document.status == .processing
        case .rejected: return document.status == .rejected
        case .identity: return document.category == .identity
        case .financial: return document.category == .financial
        }
    }
}

private extension CGImagePropertyOrientation {
    init(_ orientation: UIImage.Orientation) {
        switch orientation {
        case .up: self = .up
        case .upMirrored: self = .upMirrored
        case .down: self = .down
        case .downMirrored: self = .downMirrored
        case .left: self = .left
        case .leftMirrored: self = .leftMirrored
        case .right: self = .right
        case .rightMirrored: self = .rightMirrored
        @unknown default: self = .up
        }
    }
}
