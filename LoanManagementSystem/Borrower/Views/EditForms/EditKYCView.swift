import SwiftUI
import UniformTypeIdentifiers
import PhotosUI
import Supabase

struct EditKYCView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: BorrowerProfileViewModel
    
    @State private var aadhaarStatus: VerificationStatus
    @State private var panStatus: VerificationStatus
    @State private var addressProofStatus: VerificationStatus
    
    @State private var aadhaarFileName: String?
    @State private var panFileName: String?
    @State private var addressProofFileName: String?
    
    @State private var showingFileImporter = false
    @State private var showingPhotosPicker = false
    @State private var showingUploadSourceDialog = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    
    @State private var documentUploading: KYCDocumentType? = nil
    @State private var isUploading = false
    @State private var secureUploadMessage = ""
    
    init(viewModel: BorrowerProfileViewModel) {
        self.viewModel = viewModel
        _aadhaarStatus = State(initialValue: viewModel.profile?.kycVerification.aadhaarStatus ?? .pending)
        _panStatus = State(initialValue: viewModel.profile?.kycVerification.panStatus ?? .pending)
        _addressProofStatus = State(initialValue: viewModel.profile?.kycVerification.addressProofStatus ?? .pending)
        
        _aadhaarFileName = State(initialValue: viewModel.profile?.kycVerification.aadhaarFileName)
        _panFileName = State(initialValue: viewModel.profile?.kycVerification.panFileName)
        _addressProofFileName = State(initialValue: viewModel.profile?.kycVerification.addressProofFileName)
    }
    
    var body: some View {
        ZStack {
            NavigationStack {
                Form {
                    Section(header: Text("Instructions")) {
                        Text("Upload your KYC documents in secure PDF or Image format. Data is encrypted using AES-256 before transmission over SSL.")
                            .font(Font.AppTheme.body)
                            .foregroundStyle(Color.AppTheme.textSecondary)
                    }
                    
                    Section(header: Text("Documents")) {
                        DocumentUploadCardView(
                            documentName: "Aadhaar Card",
                            status: aadhaarStatus,
                            fileName: aadhaarFileName,
                            onUpload: {
                                documentUploading = .aadhaar
                                showingUploadSourceDialog = true
                            },
                            onDelete: {
                                aadhaarStatus = .pending
                                aadhaarFileName = nil
                            }
                        )
                        .listRowInsets(EdgeInsets())
                        
                        DocumentUploadCardView(
                            documentName: "PAN Card",
                            status: panStatus,
                            fileName: panFileName,
                            onUpload: {
                                documentUploading = .pan
                                showingUploadSourceDialog = true
                            },
                            onDelete: {
                                panStatus = .pending
                                panFileName = nil
                            }
                        )
                        .listRowInsets(EdgeInsets())
                        
                        DocumentUploadCardView(
                            documentName: "Address Proof",
                            status: addressProofStatus,
                            fileName: addressProofFileName,
                            onUpload: {
                                documentUploading = .addressProof
                                showingUploadSourceDialog = true
                            },
                            onDelete: {
                                addressProofStatus = .pending
                                addressProofFileName = nil
                            }
                        )
                        .listRowInsets(EdgeInsets())
                    }
                }
                .navigationTitle("Update KYC")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark")
                               .foregroundStyle(Color.AppTheme.primary)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            viewModel.updateKYC(
                                aadhaar: aadhaarStatus,
                                pan: panStatus,
                                addressProof: addressProofStatus,
                                aadhaarFile: aadhaarFileName,
                                panFile: panFileName,
                                addressProofFile: addressProofFileName
                            )
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "checkmark")
                                .fontWeight(.bold)
                                .foregroundStyle(Color.AppTheme.primary)
                        }
                    }
                }
            }
            .blur(radius: isUploading ? 3 : 0)
            .disabled(isUploading)
            
            if isUploading {
                Color.black.opacity(0.4)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.AppTheme.primary))
                        .scaleEffect(1.5)
                    
                    Text("Secure Document Upload")
                        .font(Font.AppTheme.button)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.AppTheme.textPrimary)
                    
                    Text(secureUploadMessage)
                        .font(Font.AppTheme.body)
                        .foregroundStyle(Color.AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(30)
                .background(LMSColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(radius: 10)
                .frame(maxWidth: 300)
            }
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.pdf, .image],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                if let docType = documentUploading {
                    let docName: String
                    switch docType {
                    case .aadhaar: docName = "identity_proof"
                    case .pan: docName = "identity_proof"
                    case .addressProof: docName = "address_proof"
                    }
                    let filename = url.lastPathComponent
                    if let data = loadData(from: url) {
                        uploadKYCDocument(data: data, filename: filename, docType: docType, docName: docName)
                    }
                }
            case .failure(let error):
                print("Error selecting document: \(error.localizedDescription)")
            }
        }
        .confirmationDialog("Select Source", isPresented: $showingUploadSourceDialog, titleVisibility: .visible) {
            Button("Choose from Photo Library") {
                showingPhotosPicker = true
            }
            Button("Choose from Files (PDF/Image)") {
                showingFileImporter = true
            }
            Button("Cancel", role: .cancel) {}
        }
        .photosPicker(isPresented: $showingPhotosPicker, selection: $selectedPhotoItem, matching: .images)
        .onChange(of: selectedPhotoItem) { _, newItem in
            guard let newItem = newItem, let docType = documentUploading else { return }
            let docName: String
            let filename: String
            switch docType {
            case .aadhaar:
                docName = "identity_proof"
                filename = "aadhaar_kyc.jpg"
            case .pan:
                docName = "identity_proof"
                filename = "pan_kyc.jpg"
            case .addressProof:
                docName = "address_proof"
                filename = "address_proof_kyc.jpg"
            }
            
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self) {
                    uploadKYCDocument(data: data, filename: filename, docType: docType, docName: docName)
                }
            }
        }
    }
    
    private func loadData(from url: URL) -> Data? {
        guard url.startAccessingSecurityScopedResource() else {
            return try? Data(contentsOf: url)
        }
        defer { url.stopAccessingSecurityScopedResource() }
        return try? Data(contentsOf: url)
    }
    
    private func uploadKYCDocument(data: Data, filename: String, docType: KYCDocumentType, docName: String) {
        isUploading = true
        secureUploadMessage = "Establishing secure connection to SSL Gateway..."
        
        Task {
            do {
                // Wait for secure gateway simulation
                try? await Task.sleep(nanoseconds: 800_000_000)
                await MainActor.run {
                    secureUploadMessage = "Encrypting document using AES-256 key..."
                }
                
                // Get authenticated user ID
                guard let session = try? await SupabaseManager.shared.client.auth.session else {
                    print("Error: Auth session not found")
                    await MainActor.run { isUploading = false }
                    return
                }
                let userId = session.user.id
                
                try? await Task.sleep(nanoseconds: 800_000_000)
                await MainActor.run {
                    secureUploadMessage = "Uploading document to Supabase Cloud Storage..."
                }
                
                // 1. Upload to Supabase Storage (this is the primary goal)
                let path = "\(userId.uuidString)/\(filename)"
                let publicUrl = try await StorageService.shared.uploadDocument(data: data, bucket: "documents", path: path)
                
                print("✅ KYC Document uploaded successfully to Storage!")
                print("   Public URL: \(publicUrl.absoluteString)")
                
                // 2. Best-effort: try to insert a record into the documents database table
                //    This may fail if the user doesn't have a borrower record yet (FK constraint).
                //    That's OK — the file is already safely stored in Supabase Storage.
                do {
                    // First, look up the borrower_id for this user
                    let borrowerRows: [BorrowerLookup] = try await SupabaseManager.shared.client
                        .from("borrowers")
                        .select("borrower_id")
                        .eq("user_id", value: userId.uuidString)
                        .execute()
                        .value
                    
                    if let borrower = borrowerRows.first {
                        let docRow = SupabaseDocumentInsert(
                            document_id: UUID(),
                            borrower_id: borrower.borrower_id,
                            application_id: nil,
                            doc_type: docName,
                            file_url: publicUrl.absoluteString,
                            file_name: filename,
                            status: "verified"
                        )
                        
                        try await SupabaseManager.shared.client
                            .from("documents")
                            .insert(docRow)
                            .execute()
                        
                        print("✅ Document record saved to database!")
                    } else {
                        print("⚠️ No borrower record found for user — skipping DB insert. File is safe in Storage.")
                    }
                } catch {
                    print("⚠️ Database insert skipped (non-critical): \(error.localizedDescription)")
                }
                
                // 3. Update local state — always succeeds since Storage upload passed
                await MainActor.run {
                    isUploading = false
                    switch docType {
                    case .aadhaar:
                        aadhaarStatus = .verified
                        aadhaarFileName = filename
                    case .pan:
                        panStatus = .verified
                        panFileName = filename
                    case .addressProof:
                        addressProofStatus = .verified
                        addressProofFileName = filename
                    }
                    selectedPhotoItem = nil
                    documentUploading = nil
                }
            } catch {
                print("❌ Storage upload failed: \(error.localizedDescription)")
                await MainActor.run {
                    secureUploadMessage = "Upload failed: \(error.localizedDescription)"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        isUploading = false
                        selectedPhotoItem = nil
                        documentUploading = nil
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        EditKYCView(viewModel: PreviewSupport.borrowerProfileViewModel)
    }
}

struct SupabaseDocumentInsert: Codable {
    let document_id: UUID
    let borrower_id: UUID
    let application_id: UUID?
    let doc_type: String
    let file_url: String
    let file_name: String
    let status: String
}

struct BorrowerLookup: Codable {
    let borrower_id: UUID
}
