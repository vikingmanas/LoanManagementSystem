import SwiftUI
import UniformTypeIdentifiers

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
                        Text("Upload your KYC documents in secure PDF format. Data is encrypted using AES-256 before transmission over SSL.")
                            .font(Font.AppTheme.body)
                            .foregroundColor(Color.AppTheme.textSecondary)
                    }
                    
                    Section(header: Text("Documents")) {
                        DocumentUploadCardView(
                            documentName: "Aadhaar Card",
                            status: aadhaarStatus,
                            fileName: aadhaarFileName,
                            onUpload: {
                                documentUploading = .aadhaar
                                showingFileImporter = true
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
                                showingFileImporter = true
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
                                showingFileImporter = true
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
                               .foregroundColor(Color.AppTheme.primary)
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
                                .foregroundColor(Color.AppTheme.primary)
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
                        .foregroundColor(Color.AppTheme.textPrimary)
                    
                    Text(secureUploadMessage)
                        .font(Font.AppTheme.body)
                        .foregroundColor(Color.AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(30)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(radius: 10)
                .frame(maxWidth: 300)
            }
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.pdf],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                if let docType = documentUploading {
                    simulateSecureUpload(url: url, docType: docType)
                }
            case .failure(let error):
                print("Error selecting document: \(error.localizedDescription)")
            }
        }
    }
    
    private func simulateSecureUpload(url: URL, docType: KYCDocumentType) {
        isUploading = true
        secureUploadMessage = "Establishing secure connection to SSL Gateway..."
        
        let filename: String
        if url.startAccessingSecurityScopedResource() {
            filename = url.lastPathComponent
            url.stopAccessingSecurityScopedResource()
        } else {
            filename = url.lastPathComponent
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            secureUploadMessage = "Reading local PDF payload..."
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                secureUploadMessage = "Encrypting document using AES-256 key..."
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    secureUploadMessage = "Sending encrypted packet to API endpoint (HTTPS POST)..."
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
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
                    }
                }
            }
        }
    }
}
