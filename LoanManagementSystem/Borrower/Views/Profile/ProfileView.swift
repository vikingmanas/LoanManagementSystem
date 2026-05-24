import SwiftUI

enum ProfileEditSheet: Identifiable {
    case personal, contact, address, employment, bank, kyc, loan, additional
    var id: String { String(describing: self) }
}

struct ProfileView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = BorrowerProfileViewModel()
    @State private var activeSheet: ProfileEditSheet?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading Profile...")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    }
                } else if let profile = viewModel.profile {
                    Form {
                        // MARK: - Header Section
                        Section {
                            ProfileHeaderView(
                                name: profile.fullName,
                                id: profile.id,
                                completionPercentage: profile.profileCompletionPercentage,
                                isVerified: profile.kycVerification.overallStatus == .verified,
                                imageData: profile.profileImageData,
                                onPhotoSelected: { data in
                                    viewModel.updateProfileImage(data: data)
                                }
                            )
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets())
                        }
                        
                        // MARK: - Account Information
                        Section {
                            NavigationLink(destination: ProfileInfoDetailView(viewModel: viewModel)) {
                                Label("Profile Information", systemImage: "person.circle")
                            }
                            
                            NavigationLink(destination: KYCStatusDetailView(viewModel: viewModel)) {
                                Label("KYC Verification", systemImage: "checkmark.seal")
                            }
                            
                            NavigationLink(destination: LinkedBankAccountsDetailView(viewModel: viewModel)) {
                                Label("Linked Bank Accounts", systemImage: "building.columns")
                            }
                            
                            NavigationLink(destination: DocumentManagementDetailView(viewModel: viewModel)) {
                                Label("Document Management", systemImage: "doc.on.doc")
                            }
                        } header: {
                            Text("Account Details")
                        }
                        
                        // MARK: - Security & Privacy
                        Section {
                            NavigationLink(destination: SecurityDetailView()) {
                                Label("Security", systemImage: "lock.shield")
                            }
                            
                            NavigationLink(destination: ResetPasswordDetailView()) {
                                Label("Change Password", systemImage: "key")
                            }
                            
                            NavigationLink(destination: PrivacyControlsDetailView()) {
                                Label("Privacy Controls", systemImage: "hand.raised")
                            }
                            
                            NavigationLink(destination: NotificationsDetailView()) {
                                Label("Notifications", systemImage: "bell")
                            }
                        } header: {
                            Text("Security & Privacy")
                        }
                        
                        // MARK: - Support & General
                        Section {
                            NavigationLink(destination: SettingsDetailView()) {
                                Label("App Settings", systemImage: "gearshape")
                            }
                            
                            NavigationLink(destination: HelpSupportDetailView()) {
                                Label("Help & Support", systemImage: "questionmark.circle")
                            }
                        } header: {
                            Text("General")
                        }
                        
                        // MARK: - Sign Out
                        Section {
                            Button(role: .destructive) {
                                HapticsManager.triggerImpact(style: .medium)
                                BorrowerProfileStore.shared.signOut()
                                appState.logout()
                                authManager.signOut()
                            } label: {
                                HStack {
                                    Spacer()
                                    Text("Sign Out")
                                        .fontWeight(.semibold)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AppStateManager())
        .environmentObject(AuthManager())
}
