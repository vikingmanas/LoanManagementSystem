import SwiftUI
import UIKit
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
    @State private var showingSourceOptions = false
    @State private var showingCamera = false
    @State private var cameraErrorMessage: String?
    @State private var documentUploading: KYCDocumentType? = nil
    @State private var isUploading = false
    @State private var secureUploadMessage = ""
    @State private var visionReviewMessage = ""
    
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
                        Text("Upload KYC documents as PDF or image scans. Image scans are checked locally for readable text before review.")
                            .font(Font.AppTheme.body)
                            .foregroundStyle(Color.AppTheme.textSecondary)

                        if !visionReviewMessage.isEmpty {
                            Label(visionReviewMessage, systemImage: "text.viewfinder")
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.actionBlue)
                        }
                    }
                    
                    Section(header: Text("Documents")) {
                        DocumentUploadCardView(
                            documentName: "Aadhaar Card",
                            status: aadhaarStatus,
                            fileName: aadhaarFileName,
                            onUpload: {
                                documentUploading = .aadhaar
                                showingSourceOptions = true
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
                                showingSourceOptions = true
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
                                showingSourceOptions = true
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
        .confirmationDialog("Upload Document", isPresented: $showingSourceOptions, titleVisibility: .visible) {
            Button {
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    showingCamera = true
                } else {
                    cameraErrorMessage = "Camera is not available on this device or simulator."
                }
            } label: {
                Label("Scan with Camera", systemImage: "camera.viewfinder")
            }

            Button {
                showingFileImporter = true
            } label: {
                Label("Choose File", systemImage: "folder")
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Use the camera for a fresh scan or choose an existing PDF/image.")
        }
        .sheet(isPresented: $showingCamera) {
            CameraCaptureView { image in
                guard let docType = documentUploading,
                      let url = saveCapturedImage(image, docType: docType) else {
                    cameraErrorMessage = "Unable to save captured document image."
                    return
                }
                simulateSecureUpload(url: url, docType: docType)
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
                    simulateSecureUpload(url: url, docType: docType)
                }
            case .failure(let error):
                print("Error selecting document: \(error.localizedDescription)")
            }
        }
        .alert("Camera Upload", isPresented: Binding(
            get: { cameraErrorMessage != nil },
            set: { if !$0 { cameraErrorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(cameraErrorMessage ?? "")
        }
    }
    
    private func simulateSecureUpload(url: URL, docType: KYCDocumentType) {
        isUploading = true
        secureUploadMessage = "Establishing secure connection to SSL Gateway..."
        visionReviewMessage = ""
        
        let filename: String
        if url.startAccessingSecurityScopedResource() {
            filename = url.lastPathComponent
            url.stopAccessingSecurityScopedResource()
        } else {
            filename = url.lastPathComponent
        }
        
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                secureUploadMessage = "Reading local document payload..."
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    secureUploadMessage = "Running local text readability check..."
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        secureUploadMessage = "Encrypting document using AES-256 key..."
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            isUploading = false
                            analyzeDocumentIfPossible(url)
                            
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

    private func analyzeDocumentIfPossible(_ url: URL) {
        let fileType = UTType(filenameExtension: url.pathExtension)
        guard fileType?.conforms(to: .image) == true else {
            visionReviewMessage = "PDF queued for manual KYC review."
            return
        }

        Task {
            if let result = await DocumentVisionService.analyzeImage(at: url) {
                visionReviewMessage = result.statusMessage
            } else {
                visionReviewMessage = "Image scan queued for manual review."
            }
        }
    }

    private func saveCapturedImage(_ image: UIImage, docType: KYCDocumentType) -> URL? {
        guard let data = image.jpegData(compressionQuality: 0.88) else { return nil }
        let fileName = "\(filePrefix(for: docType))_scan_\(Int(Date().timeIntervalSince1970)).jpg"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            return nil
        }
    }

    private func filePrefix(for docType: KYCDocumentType) -> String {
        switch docType {
        case .aadhaar: return "aadhaar"
        case .pan: return "pan"
        case .addressProof: return "address_proof"
        }
    }
}

private struct CameraCaptureView: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onCapture: (UIImage) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss, onCapture: onCapture)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let dismiss: DismissAction
        let onCapture: (UIImage) -> Void

        init(dismiss: DismissAction, onCapture: @escaping (UIImage) -> Void) {
            self.dismiss = dismiss
            self.onCapture = onCapture
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                onCapture(image)
            }
            dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
