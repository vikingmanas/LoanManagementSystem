import SwiftUI

struct SecurityDetailView: View {
    @AppStorage("biometricEnabled") private var biometricEnabled = true
    @AppStorage("doubleAuthEnabled") private var doubleAuthEnabled = false
    @StateObject private var localSecurity = LocalSecurityService.shared
    @State private var showOTPSheet = false
    @State private var securityMessage: String?
    
    private var deviceName: String {
        #if os(iOS)
        return UIDevice.current.name
        #else
        return "Unknown Device"
        #endif
    }
    
    var body: some View {
        Form {
            Section {
                Toggle(isOn: $biometricEnabled) {
                    Label("\(localSecurity.biometricTypeName) Login", systemImage: "faceid")
                }

                Button {
                    Task {
                        let success = await localSecurity.authenticate(reason: "Verify your identity to enable secure quick login.")
                        securityMessage = success ? "\(localSecurity.biometricTypeName) verified successfully." : "Biometric verification was not completed."
                        if !success {
                            biometricEnabled = false
                        }
                    }
                } label: {
                    Label("Test Biometric Login", systemImage: "checkmark.shield")
                }
                .disabled(!localSecurity.canUseBiometrics())
            } header: {
                Text("Biometrics")
            } footer: {
                Text(localSecurity.canUseBiometrics() ? "Use device biometrics to verify account access." : "No supported biometric sensor is available on this device.")
            }
            
            Section {
                Toggle(isOn: $doubleAuthEnabled) {
                    Label("Two-Factor Auth (2FA)", systemImage: "shield")
                }
                .onChange(of: doubleAuthEnabled) { _, enabled in
                    if enabled {
                        showOTPSheet = true
                    }
                }

                Button {
                    showOTPSheet = true
                } label: {
                    Label(doubleAuthEnabled ? "Regenerate OTP" : "Set Up OTP", systemImage: "number")
                }
            } header: {
                Text("Two-Factor Authentication")
            } footer: {
                Text("Local OTP adds a second verification step without requiring any back-end service.")
            }
            
            Section {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(deviceName)
                            .font(.body)
                        Text("Active Now")
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
        .sheet(isPresented: $showOTPSheet) {
            LocalOTPSetupSheet(isEnabled: $doubleAuthEnabled)
        }
        .alert("Security Check", isPresented: Binding(
            get: { securityMessage != nil },
            set: { if !$0 { securityMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(securityMessage ?? "")
        }
    }
}

private struct LocalOTPSetupSheet: View {
    @Binding var isEnabled: Bool
    @Environment(\.dismiss) private var dismiss
    @StateObject private var localSecurity = LocalSecurityService.shared
    @State private var enteredCode = ""
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 14) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 48))
                            .foregroundStyle(LMSColors.brandNavy)

                        Text(localSecurity.lastOTPCode.isEmpty ? "Generate a one-time code" : localSecurity.lastOTPCode)
                            .font(.system(.largeTitle, design: .rounded).weight(.bold).monospacedDigit())
                            .foregroundStyle(LMSColors.textPrimary)

                        Text("For this offline build, the code is shown locally so testers can complete the flow without SMS or network services.")
                            .font(LMSFont.footnote)
                            .foregroundStyle(LMSColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)

                    Button {
                        enteredCode = ""
                        errorMessage = ""
                        localSecurity.issueOTP()
                    } label: {
                        Label("Generate OTP", systemImage: "sparkles")
                    }
                }

                Section {
                    TextField("Enter 6-digit OTP", text: $enteredCode)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .font(.system(.body, design: .rounded).monospacedDigit())

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.coral)
                    }

                    Button {
                        if localSecurity.verifyOTP(enteredCode) {
                            isEnabled = true
                            localSecurity.clearOTP()
                            dismiss()
                        } else {
                            errorMessage = "Invalid or expired OTP. Generate a new code and try again."
                        }
                    } label: {
                        Text("Verify and Enable")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(enteredCode.trimmingCharacters(in: .whitespacesAndNewlines).count < 6)
                } header: {
                    Text("Verification")
                }
            }
            .navigationTitle("Local OTP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if !isEnabled {
                            localSecurity.clearOTP()
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                if localSecurity.lastOTPCode.isEmpty {
                    localSecurity.issueOTP()
                }
            }
        }
    }
}
