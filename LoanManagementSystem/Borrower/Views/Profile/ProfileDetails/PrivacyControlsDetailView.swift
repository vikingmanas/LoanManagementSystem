import SwiftUI

struct PrivacyControlsDetailView: View {
    @State private var shareWithBureaus = true
    @State private var trackingEnabled = false
    @State private var personalizedAds = false
    
    var body: some View {
        Form {
            Section {
                Toggle(isOn: $shareWithBureaus) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Share Credit Activity")
                            Text("Report loan repayments to major credit bureaus")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                    }
                }
            } header: {
                Text("Credit Bureaus")
            } footer: {
                Text("Disabling this may delay credit limits check and loan dispatch speed.")
            }
            
            Section {
                Toggle(isOn: $trackingEnabled) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Diagnostics and Usage")
                            Text("Share anonymous diagnostic data with developers")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "exclamationmark.triangle")
                    }
                }
            } header: {
                Text("Diagnostics")
            }
            
            Section {
                Toggle(isOn: $personalizedAds) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Personalized Loan Offers")
                            Text("Enable matching based on credit profile")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "sparkles")
                    }
                }
            } header: {
                Text("Personalization")
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}
