import SwiftUI

struct AdminProfileSheet: View {
    @Environment(AuthManager.self) private var authManager: AuthManager
    @Environment(AppStateManager.self) private var appState: AppStateManager
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("biometricEnabled") private var biometricEnabled = false
    @AppStorage("isDarkMode") private var isDarkMode = false

    @State private var localSecurity = LocalSecurityService.shared
    
    var body: some View {
        List {
                Section {
                    HStack(spacing: LMSSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [LMSColors.brandNavy, LMSColors.brandNavyLight],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text(authManager.userInitials)
                                .font(LMSFont.title)
                                .foregroundStyle(.white)
                        }
                        .frame(width: 68, height: 68)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.2), lineWidth: 1.5)
                        )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authManager.userDisplayName)
                                .font(LMSFont.headline)
                            Text(authManager.userEmail ?? "No email")
                                .font(LMSFont.subheadline)
                                .foregroundStyle(LMSColors.textSecondary)
                            Text("System Administrator")
                                .font(LMSFont.caption2.weight(.bold))
                                .foregroundStyle(LMSColors.actionBlue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(LMSColors.actionBlue.opacity(0.1), in: Capsule())
                                .padding(.top, 2)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Account Details") {
                    LabeledContent {
                        Text("ADM-001")
                    } label: {
                        Label("Employee ID", systemImage: "number.square")
                    }
                    LabeledContent {
                        Text("Root Access")
                    } label: {
                        Label("Access Level", systemImage: "shield.lefthalf.filled")
                    }
                    LabeledContent {
                        Text("May 2026")
                    } label: {
                        Label("Member Since", systemImage: "calendar")
                    }
                }
                

                
                Section("Security") {
                    Toggle(isOn: Binding(
                        get: { biometricEnabled },
                        set: { newValue in
                            if newValue {
                                Task {
                                    let success = await localSecurity.authenticate(reason: "Verify identity to enable biometric login")
                                    biometricEnabled = success
                                }
                            } else {
                                biometricEnabled = false
                            }
                        }
                    )) {
                        Label("\(localSecurity.biometricTypeName) Login", systemImage: "faceid")
                    }
                    .disabled(!localSecurity.canUseBiometrics())
                    Button(action: {
                        // In a real app this would present a password change sheet
                    }) {
                        Label("Change Password", systemImage: "lock.rotation")
                    }
                    .foregroundStyle(LMSColors.textPrimary)
                }
                
                Section("About") {
                    LabeledContent {
                        Text("1.0.0")
                    } label: {
                        Label("App Version", systemImage: "info.circle")
                    }
                    LabeledContent {
                        Text("42")
                    } label: {
                        Label("Build Number", systemImage: "hammer")
                    }
                }

                Section("General") {
                    NavigationLink(destination: AccessibilitySettingsView()) {
                        Label("Accessibility", systemImage: "figure.walk.circle")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        dismiss()
                        appState.logout()
                        authManager.signOut()
                    } label: {
                        Text("Sign Out")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        .listStyle(.insetGrouped)
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}
