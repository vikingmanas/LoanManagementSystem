import SwiftUI

struct KYCStatusDetailView: View {
    @Bindable var viewModel: BorrowerProfileViewModel
    @State private var showingEditSheet = false
    
    var body: some View {
        Form {
            if let kyc = viewModel.profile?.kycVerification {
                Section {
                    LabeledContent("Overall Status") {
                        statusText(kyc.overallStatus)
                    }
                } header: {
                    Text("Verification Progress")
                }
                
                Section {
                    kycRow(title: "Aadhaar Card", fileName: kyc.aadhaarFileName, status: kyc.aadhaarStatus)
                    kycRow(title: "PAN Card", fileName: kyc.panFileName, status: kyc.panStatus)
                    kycRow(title: "Address Proof", fileName: kyc.addressProofFileName, status: kyc.addressProofStatus)
                } header: {
                    Text("Documents Status")
                }
            }
        }
        .navigationTitle("KYC Status")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Update") {
                    showingEditSheet = true
                }
            }
        }
        .accessibleSheet(isPresented: $showingEditSheet) {
            EditKYCView(viewModel: viewModel)
        }
    }
    
    @ViewBuilder
    private func kycRow(title: String, fileName: String?, status: VerificationStatus) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.body)
                Spacer()
                statusText(status)
            }
            if let fileName = fileName {
                Text(fileName)
                    .font(.caption)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 2)
    }
    
    @ViewBuilder
    private func statusText(_ status: VerificationStatus) -> some View {
        Text(status.rawValue)
            .font(.caption.bold())
            .foregroundStyle(statusColor(status))
    }
    
    private func statusColor(_ status: VerificationStatus) -> Color {
        switch status {
        case .verified: return .green
        case .pending: return .orange
        case .underReview: return .blue
        case .rejected: return .red
        }
    }
}
