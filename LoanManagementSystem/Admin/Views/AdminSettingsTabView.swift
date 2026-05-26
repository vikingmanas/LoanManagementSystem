import SwiftUI
import Supabase

struct AdminSettingsTabView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var authManager: AuthManager


    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isUpdatingPassword = false
    @State private var passwordMessage: String? = nil
    @State private var passwordError: String? = nil

    var body: some View {
        NavigationStack {
            Form {

                Section {
                    HStack(spacing: LMSSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [Color(hex: "#0A2540"), Color(hex: "#234B75")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 60, height: 60)

                            Text("AD")
                                .font(LMSFont.title3)
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("System Administrator")
                                .font(LMSFont.callout.weight(.bold))
                                .foregroundStyle(LMSColors.textPrimary)
                            Text(authManager.currentUser?.email ?? "admin@lms.com")
                                .font(LMSFont.footnote)
                                .foregroundStyle(LMSColors.textSecondary)
                            Text("Astra Portal Admin · Level 5")
                                .font(LMSFont.caption)
                                .foregroundStyle(LMSColors.brandNavy)
                        }
                    }
                    .padding(.vertical, 8)
                }


                Section("System Permissions") {
                    HStack {
                        Label("Access Level", systemImage: "shield.fill")
                            .font(LMSFont.body)
                            .foregroundStyle(LMSColors.textPrimary)
                        Spacer()
                        Text("Root / System Superuser")
                            .font(LMSFont.footnote.weight(.semibold))
                            .foregroundStyle(LMSColors.emerald)
                    }

                    HStack {
                        Label("Database Control", systemImage: "externaldrive.fill")
                            .font(LMSFont.body)
                            .foregroundStyle(LMSColors.textPrimary)
                        Spacer()
                        Text("Full CRUD Access")
                            .font(LMSFont.footnote.weight(.semibold))
                            .foregroundStyle(LMSColors.textSecondary)
                    }

                    HStack {
                        Label("Staff Management", systemImage: "person.badge.key.fill")
                            .font(LMSFont.body)
                            .foregroundStyle(LMSColors.textPrimary)
                        Spacer()
                        Text("Enabled")
                            .font(LMSFont.footnote.weight(.semibold))
                            .foregroundStyle(LMSColors.brandNavy)
                    }
                }


                Section("Update Administrator Password") {
                    SecureInputField(
                        placeholder: "New Password",
                        text: $newPassword
                    )
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                    .padding(.vertical, LMSSpacing.xs)

                    SecureInputField(
                        placeholder: "Confirm New Password",
                        text: $confirmPassword
                    )
                    .listRowInsets(EdgeInsets())
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                    .padding(.vertical, LMSSpacing.xs)

                    if let passwordMessage {
                        LMSBanner(message: passwordMessage, style: .success, icon: "checkmark.circle.fill")
                            .listRowInsets(EdgeInsets())
                    }

                    if let passwordError {
                        LMSBanner(message: passwordError, style: .error, icon: "exclamationmark.triangle.fill")
                            .listRowInsets(EdgeInsets())
                    }

                    Button(action: {
                        Task {
                            await updatePassword()
                        }
                    }) {
                        if isUpdatingPassword {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Update Password")
                                .font(LMSFont.button)
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(LMSColors.brandNavy, in: RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .padding(.top, LMSSpacing.sm)
                    .disabled(newPassword.isEmpty || confirmPassword.isEmpty || isUpdatingPassword)
                }


                Section {
                    Button(action: {
                        HapticsManager.triggerImpact(style: .medium)
                        appState.logout()
                        authManager.signOut()
                    }) {
                        HStack {
                            Spacer()
                            Label("Sign Out Admin Console", systemImage: "power")
                                .font(LMSFont.button)
                                .foregroundStyle(LMSColors.coral)
                            Spacer()
                        }
                    }
                    .listRowBackground(LMSColors.coral.opacity(0.08))
                }
            }
            .navigationTitle("Admin Settings")
            .lmsScreenBackground()
        }
    }


    private func updatePassword() async {
        passwordMessage = nil
        passwordError = nil

        guard newPassword == confirmPassword else {
            passwordError = "Passwords do not match."
            return
        }

        guard newPassword.count >= 6 else {
            passwordError = "Password must be at least 6 characters long."
            return
        }

        isUpdatingPassword = true

        do {
            let client = SupabaseManager.shared.client
            try await client.auth.update(user: UserAttributes(password: newPassword))
            passwordMessage = "Password updated successfully!"
            newPassword = ""
            confirmPassword = ""
        } catch {
            passwordError = error.localizedDescription
        }

        isUpdatingPassword = false
    }
}

