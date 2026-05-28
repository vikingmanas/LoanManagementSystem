import SwiftUI

struct PrivacyControlsDetailView: View {
    @AppStorage("shareWithBureaus") private var shareWithBureaus = true
    @AppStorage("trackingEnabled") private var trackingEnabled = false
    @AppStorage("personalizedAds") private var personalizedAds = false
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false
    @State private var privacyMessage: String?
    
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

            Section {
                Button {
                    exportPrivacyData()
                } label: {
                    Label("Export My Data", systemImage: "square.and.arrow.up")
                }

                Button(role: .destructive) {
                    privacyMessage = "A local account deletion request has been recorded. Staff review is required before irreversible deletion."
                } label: {
                    Label("Request Data Deletion", systemImage: "trash")
                }
            } header: {
                Text("Data Rights")
            } footer: {
                Text("These controls are handled locally in this build and do not require network services.")
            }
        }
        .navigationTitle("Privacy")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showShareSheet) {
            PrivacyShareSheet(activityItems: shareItems)
        }
        .alert("Privacy Request", isPresented: Binding(
            get: { privacyMessage != nil },
            set: { if !$0 { privacyMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(privacyMessage ?? "")
        }
    }

    private func exportPrivacyData() {
        let profile = BorrowerProfileStore.shared.profile
        let contents = """
        LMS Privacy Export
        Generated: \(Date().formatted(date: .abbreviated, time: .shortened))
        Name: \(profile?.fullName ?? "Unavailable")
        Email: \(profile?.email ?? "Unavailable")
        Share Credit Activity: \(shareWithBureaus ? "Enabled" : "Disabled")
        Diagnostics: \(trackingEnabled ? "Enabled" : "Disabled")
        Personalized Offers: \(personalizedAds ? "Enabled" : "Disabled")
        """

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("LMS_Privacy_Export.txt")
        do {
            try contents.write(to: url, atomically: true, encoding: .utf8)
            shareItems = [url]
            showShareSheet = true
        } catch {
            privacyMessage = error.localizedDescription
        }
    }
}

private struct PrivacyShareSheet: UIViewControllerRepresentable {
    var activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationStack {
        PrivacyControlsDetailView()
    }
}
