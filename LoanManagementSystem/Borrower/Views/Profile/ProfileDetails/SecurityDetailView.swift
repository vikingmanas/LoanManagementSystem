import SwiftUI

struct SecurityDetailView: View {
    @AppStorage("biometricEnabled") private var biometricEnabled = false
    @AppStorage("doubleAuthEnabled") private var doubleAuthEnabled = false
    @EnvironmentObject private var authManager: AuthManager
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
                Toggle(isOn: Binding(
                    get: { biometricEnabled },
                    set: { newValue in
                        if newValue {
                            Task {
                                let success = await localSecurity.authenticate(reason: "Verify your identity to enable secure quick login.")
                                biometricEnabled = success
                                securityMessage = success
                                    ? "\(localSecurity.biometricTypeName) enabled successfully."
                                    : "Biometric verification was not completed."
                            }
                        } else {
                            biometricEnabled = false
                        }
                    }
                )) {
                    Label("\(localSecurity.biometricTypeName) Login", systemImage: "faceid")
                }
                .disabled(!localSecurity.canUseBiometrics())
            } header: {
                Text("Biometrics")
            } footer: {
                Text(localSecurity.canUseBiometrics() ? "Use device biometrics to verify account access." : "No supported biometric sensor is available on this device.")
            }
            
            Section {
                Toggle(isOn: $doubleAuthEnabled) {
                    Label("Email OTP Verification", systemImage: "envelope.badge.shield.half.filled")
                }
                .onChange(of: doubleAuthEnabled) { _, enabled in
                    if enabled {
                        showOTPSheet = true
                    }
                }

                Button {
                    showOTPSheet = true
                } label: {
                    Label(doubleAuthEnabled ? "Re-verify Email OTP" : "Set Up Email OTP", systemImage: "number")
                }
                .disabled(authManager.currentUser?.email == nil)
            } header: {
                Text("Email Security")
            } footer: {
                Text(authManager.currentUser?.email == nil ? "Sign in with an email account to enable OTP verification." : "A one-time code is sent by Supabase Auth and must be verified before this device marks OTP protection as enabled.")
            }

            Section {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "person.badge.key")
                        .font(.title2)
                        .foregroundStyle(LMSColors.brandNavy)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Passkeys")
                            .font(LMSFont.body.weight(.semibold))
                        Text("Requires Apple Associated Domains and a production WebAuthn/passkey provider for the app bundle before it can be enabled safely.")
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.textSecondary)
                    }

                    Spacer()

                    Text("Setup Needed")
                        .font(LMSFont.caption.weight(.semibold))
                        .foregroundStyle(LMSColors.amber)
                }
            } header: {
                Text("Passwordless Login")
            } footer: {
                Text("This build has no associated-domains entitlement, so passkeys are shown as a readiness item instead of a non-working toggle.")
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
        .accessibleSheet(isPresented: $showOTPSheet) {
            EmailOTPSetupSheet(isEnabled: $doubleAuthEnabled)
                .environmentObject(authManager)
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

private struct EmailOTPSetupSheet: View {
    @Binding var isEnabled: Bool
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @State private var enteredCode = ""
    @State private var errorMessage = ""
    @State private var infoMessage = ""
    @State private var hasSentCode = false
    @State private var isWorking = false

    private var email: String {
        authManager.currentUser?.email ?? ""
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(spacing: 14) {
                        Image(systemName: "envelope.badge.shield.half.filled")
                            .font(.system(size: 48))
                            .foregroundStyle(LMSColors.brandNavy)

                        Text("Verify your email")
                            .font(.title2.weight(.bold))
                            .foregroundStyle(LMSColors.textPrimary)

                        Text(email.isEmpty ? "No email is attached to the current session." : "We will send a one-time code to \(email).")
                            .font(LMSFont.footnote)
                            .foregroundStyle(LMSColors.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)

                    Button {
                        Task { await sendCode() }
                    } label: {
                        Label(hasSentCode ? "Resend OTP" : "Send OTP", systemImage: "paperplane")
                    }
                    .disabled(email.isEmpty || isWorking)
                }

                Section {
                    TextField("Enter 6-digit OTP", text: $enteredCode)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .font(.system(.body, design: .rounded).monospacedDigit())

                    if !infoMessage.isEmpty {
                        Text(infoMessage)
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.emerald)
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(LMSFont.caption)
                            .foregroundStyle(LMSColors.coral)
                    }

                    Button {
                        Task { await verifyCode() }
                    } label: {
                        Text(isWorking ? "Verifying..." : "Verify and Enable")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(!hasSentCode || enteredCode.trimmingCharacters(in: .whitespacesAndNewlines).count < 6 || isWorking)
                } header: {
                    Text("Verification")
                }
            }
            .navigationTitle("Email OTP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if !isEnabled {
                            enteredCode = ""
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                if !email.isEmpty && !hasSentCode {
                    Task { await sendCode() }
                }
            }
        }
    }

    @MainActor
    private func sendCode() async {
        isWorking = true
        errorMessage = ""
        infoMessage = ""
        enteredCode = ""

        let sent = await authManager.sendEmailOTP(email: email)
        isWorking = false

        if sent {
            hasSentCode = true
            infoMessage = "OTP sent. Check your email inbox."
        } else {
            errorMessage = authManager.errorMessage ?? "Unable to send OTP. Try again."
        }
    }

    @MainActor
    private func verifyCode() async {
        isWorking = true
        errorMessage = ""
        infoMessage = ""

        let result = await authManager.verifyEmailOTP(email: email, token: enteredCode)
        isWorking = false

        if result.success {
            isEnabled = true
            dismiss()
        } else {
            errorMessage = authManager.errorMessage ?? "Invalid or expired OTP. Request a new code and try again."
        }
    }
}
