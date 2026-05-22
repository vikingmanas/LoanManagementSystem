import SwiftUI

struct KYCStatusDetailView: View {
    @ObservedObject var viewModel: BorrowerProfileViewModel
    @State private var showingEditSheet = false
    
    var body: some View {
        Form {
            if let kyc = viewModel.profile?.kycVerification {
                Section(header: Text("Overall Status")) {
                    HStack {
                        Text("KYC Verification")
                            .font(Font.AppTheme.body)
                            .foregroundStyle(Color.AppTheme.textPrimary)
                        Spacer()
                        StatusBadgeView(status: kyc.overallStatus.rawValue)
                    }
                }
                
                Section(header: Text("Documents Status")) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Aadhaar Card")
                                .font(Font.AppTheme.body)
                                .fontWeight(.medium)
                            if let fileName = kyc.aadhaarFileName {
                                Text(fileName)
                                    .font(Font.AppTheme.caption)
                                    .foregroundStyle(Color.AppTheme.primary)
                            }
                        }
                        Spacer()
                        StatusBadgeView(status: kyc.aadhaarStatus.rawValue)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PAN Card")
                                .font(Font.AppTheme.body)
                                .fontWeight(.medium)
                            if let fileName = kyc.panFileName {
                                Text(fileName)
                                    .font(Font.AppTheme.caption)
                                    .foregroundStyle(Color.AppTheme.primary)
                            }
                        }
                        Spacer()
                        StatusBadgeView(status: kyc.panStatus.rawValue)
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Address Proof")
                                .font(Font.AppTheme.body)
                                .fontWeight(.medium)
                            if let fileName = kyc.addressProofFileName {
                                Text(fileName)
                                    .font(Font.AppTheme.caption)
                                    .foregroundStyle(Color.AppTheme.primary)
                            }
                        }
                        Spacer()
                        StatusBadgeView(status: kyc.addressProofStatus.rawValue)
                    }
                }
            }
        }
        .navigationTitle("KYC Status")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditSheet = true
                }
                .foregroundStyle(Color.AppTheme.primary)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditKYCView(viewModel: viewModel)
        }
    }
}
