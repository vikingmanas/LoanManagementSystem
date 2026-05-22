import SwiftUI

struct SecurityDetailView: View {
    @State private var biometricEnabled = true
    @State private var doubleAuthEnabled = false
    
    var body: some View {
        Form {
            Section(header: Text("Biometrics")) {
                Toggle(isOn: $biometricEnabled) {
                    HStack {
                        Image(systemName: "faceid")
                            .foregroundStyle(Color.AppTheme.primary)
                        Text("Face ID Login")
                    }
                }
            }
            
            Section(header: Text("Two-Factor Authentication")) {
                Toggle(isOn: $doubleAuthEnabled) {
                    HStack {
                        Image(systemName: "shield.fill")
                            .foregroundStyle(Color.AppTheme.success)
                        Text("Two-Factor Auth (2FA)")
                    }
                }
            }
            
            Section(header: Text("Device Management")) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("iPhone 17 Pro Max")
                            .font(Font.AppTheme.body)
                        Text("Active Now • Mumbai, India")
                            .font(Font.AppTheme.caption)
                            .foregroundStyle(Color.AppTheme.textSecondary)
                    }
                    Spacer()
                    Text("Current")
                        .font(Font.AppTheme.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.AppTheme.success.opacity(0.1))
                        .foregroundStyle(Color.AppTheme.success)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
        }
        .navigationTitle("Security")
        .navigationBarTitleDisplayMode(.inline)
    }
}
