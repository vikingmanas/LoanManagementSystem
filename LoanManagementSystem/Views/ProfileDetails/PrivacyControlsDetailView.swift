import SwiftUI

struct PrivacyControlsDetailView: View {
    @State private var shareWithBureaus = true
    @State private var trackingEnabled = false
    @State private var personalizedAds = false
    
    var body: some View {
        Form {
            Section(header: Text("Credit Bureaus"), footer: Text("Disabling this may delay credit limits check and loan dispatch speed.")) {
                Toggle(isOn: $shareWithBureaus) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(Color.AppTheme.primary)
                        VStack(alignment: .leading) {
                            Text("Share Credit Activity")
                            Text("Report loan repayments to major credit bureaus")
                                .font(Font.AppTheme.caption)
                                .foregroundColor(Color.AppTheme.textSecondary)
                        }
                    }
                }
            }
            
            Section(header: Text("Diagnostics")) {
                Toggle(isOn: $trackingEnabled) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading) {
                            Text("Diagnostics and Usage")
                            Text("Share anonymous diagnostic data with developers")
                                .font(Font.AppTheme.caption)
                                .foregroundColor(Color.AppTheme.textSecondary)
                        }
                    }
                }
            }
            
            Section(header: Text("Personalization")) {
                Toggle(isOn: $personalizedAds) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        VStack(alignment: .leading) {
                            Text("Personalized Loan Offers")
                            Text("Enable matching based on credit profile")
                                .font(Font.AppTheme.caption)
                                .foregroundColor(Color.AppTheme.textSecondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Privacy Controls")
        .navigationBarTitleDisplayMode(.inline)
    }
}
