import SwiftUI

struct AdminProfileSheet: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: LMSSpacing.md) {
                        Text(authManager.userInitials)
                            .font(LMSFont.title)
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(LMSColors.brandNavy, in: Circle())
                        
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
                
                Section {
                    Button(role: .destructive) {
                        dismiss()
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
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
