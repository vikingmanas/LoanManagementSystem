import SwiftUI

struct DocumentManagementDetailView: View {
    @ObservedObject var viewModel: BorrowerProfileViewModel
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var documentToView: String?
    @State private var showingViewer = false
    
    var body: some View {
        Form {
            if let kyc = viewModel.profile?.kycVerification {
                Section {
                    documentRow(title: "Aadhaar Card", fileName: kyc.aadhaarFileName)
                    documentRow(title: "PAN Card", fileName: kyc.panFileName)
                    documentRow(title: "Address Proof", fileName: kyc.addressProofFileName)
                } header: {
                    Text("Uploaded Documents")
                } footer: {
                    Text("All documents are stored in an encrypted format for your security.")
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Documents")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Document Download", isPresented: $showingAlert) {
            Button("Dismiss", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $showingViewer) {
            if let docName = documentToView {
                DocumentPreviewSheet(fileName: docName)
            }
        }
    }
    
    @ViewBuilder
    private func documentRow(title: String, fileName: String?) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.title3)
                .foregroundStyle(fileName != nil ? .blue : .secondary)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                if let fileName = fileName {
                    Text(fileName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No file uploaded")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            
            Spacer()
            
            if let fileName = fileName {
                HStack(spacing: 16) {
                    Button {
                        documentToView = fileName
                        showingViewer = true
                    } label: {
                        Image(systemName: "eye")
                            .foregroundStyle(.blue)
                    }
                    
                    Button {
                        alertMessage = "Simulating secure download of \(fileName) in encrypted PDF format."
                        showingAlert = true
                    } label: {
                        Image(systemName: "square.and.arrow.down")
                            .foregroundStyle(.blue)
                    }
                }
                .buttonStyle(.borderless)
            }
        }
        .padding(.vertical, 4)
    }
}

struct DocumentPreviewSheet: View {
    let fileName: String
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "doc.text.viewfinder")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)
                    
                VStack(spacing: 8) {
                    Text("Preview of \(fileName)")
                        .font(.headline)
                    Text("This is a simulated document preview. In a real system, the decrypted PDF or image would be displayed here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Document Viewer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
