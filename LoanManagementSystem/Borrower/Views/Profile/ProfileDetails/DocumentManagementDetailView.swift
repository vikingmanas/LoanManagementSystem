import SwiftUI

struct DocumentManagementDetailView: View {
    @ObservedObject var viewModel: BorrowerProfileViewModel
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        Form {
            if let kyc = viewModel.profile?.kycVerification {
                Section(header: Text("Uploaded Documents")) {
                    documentRow(title: "Aadhaar Card", fileName: kyc.aadhaarFileName)
                    documentRow(title: "PAN Card", fileName: kyc.panFileName)
                    documentRow(title: "Address Proof", fileName: kyc.addressProofFileName)
                }
            } else {
                Text("Loading documents...")
            }
        }
        .navigationTitle("Document Management")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showingAlert) {
            Alert(title: Text("Document Viewer"), message: Text(alertMessage), dismissButton: .default(Text("Dismiss")))
        }
    }

    @ViewBuilder
    private func documentRow(title: String, fileName: String?) -> some View {
        HStack {
            Image(systemName: "doc.text.fill")
                .foregroundStyle(fileName != nil ? Color.AppTheme.primary : Color.gray)
                .font(.system(size: 24))
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(Font.AppTheme.body)
                    .fontWeight(.medium)
                if let fileName = fileName {
                    Text(fileName)
                        .font(Font.AppTheme.caption)
                        .foregroundStyle(Color.AppTheme.textSecondary)
                } else {
                    Text("No file uploaded")
                        .font(Font.AppTheme.caption)
                        .foregroundStyle(Color.AppTheme.error)
                }
            }

            Spacer()

            if let fileName = fileName {
                Button(action: {
                    alertMessage = "Simulating secure decryption & display for \(fileName)."
                    showingAlert = true
                }) {
                    Image(systemName: "eye.fill")
                        .foregroundStyle(Color.AppTheme.primary)
                }
                .buttonStyle(BorderlessButtonStyle())

                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 4)

                Button(action: {
                    alertMessage = "Simulating secure download of \(fileName) in encrypted PDF format."
                    showingAlert = true
                }) {
                    Image(systemName: "square.and.arrow.down")
                        .foregroundStyle(Color.AppTheme.primary)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        DocumentManagementDetailView(viewModel: PreviewSupport.borrowerProfileViewModel)
    }
}

