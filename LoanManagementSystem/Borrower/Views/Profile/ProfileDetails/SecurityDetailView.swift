import SwiftUI

struct SecurityDetailView: View {
    @State private var biometricEnabled = true
    @State private var doubleAuthEnabled = false
    
    var body: some View {
        Form {
            Section {
                Toggle(isOn: $biometricEnabled) {
                    Label("Face ID Login", systemImage: "faceid")
                }
            } header: {
                Text("Biometrics")
            } footer: {
                Text("Use Face ID to quickly and securely log into your account.")
            }
            
            Section {
                Toggle(isOn: $doubleAuthEnabled) {
                    Label("Two-Factor Auth (2FA)", systemImage: "shield")
                }
            } header: {
                Text("Two-Factor Authentication")
            } footer: {
                Text("Add an extra layer of security to your account by requiring a code from your phone.")
            }
            
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("iPhone 17 Pro Max")
                            .font(.body)
                        Text("Active Now • Mumbai, India")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("Current")
                        .font(.caption.bold())
                        .foregroundStyle(.blue)
                }
            } header: {
                Text("Device Management")
            }
        }
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
    }
}
