import SwiftUI

enum ProfileEditSheet: Identifiable {
    case personal, contact, address, employment, bank, kyc, loan, additional
    var id: String { String(describing: self) }
}

struct ProfileView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = BorrowerProfileViewModel()
    @StateObject private var notifVM = NotificationViewModel()
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var activeSheet: ProfileEditSheet?

    var body: some View {
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
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let profile = viewModel.profile {
                profileForm(profile)
            } else {
                profileUnavailableView
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .background(LMSColors.background)
        .task(id: authManager.userEmail) {
            viewModel.loadProfile(
                email: authManager.userEmail,
                displayName: authManager.userDisplayName
            )
            // Configure notification VM with current user ID
            if let profile = BorrowerProfileStore.shared.profile,
               let userId = UUID(uuidString: profile.id) {
                notifVM.configure(userId: userId)
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }


    @ViewBuilder
    private func profileForm(_ profile: BorrowerProfile) -> some View {
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
                        
                        NavigationLink(destination: LinkedBankAccountsDetailView(viewModel: viewModel)) {
                            Label("Loan Account", systemImage: "building.columns")
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
                        
                        NavigationLink(destination: NotificationsDetailView(showSettings: true, showNotifications: false, notificationViewModel: notifVM)) {
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
                        
                        NavigationLink(destination: AccessibilitySettingsView()) {
                            Label("Accessibility", systemImage: "figure.walk.circle")
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

    private var profileUnavailableView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 52))
                .foregroundStyle(LMSColors.brandNavy.opacity(0.8))

            Text("Profile Not Available")
                .font(.system(.title3, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)

            Text("We could not load your profile yet. Sign in again or refresh to continue.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(LMSColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                viewModel.loadProfile(
                    email: authManager.userEmail,
                    displayName: authManager.userDisplayName
                )
            } label: {
                Text("Refresh Profile")
                    .font(.system(.body, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(LMSColors.brandNavy, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.horizontal, 40)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AppStateManager())
            .environmentObject(AuthManager())
    }
}
