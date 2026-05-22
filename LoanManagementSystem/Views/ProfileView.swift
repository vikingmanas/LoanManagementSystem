import SwiftUI

enum ProfileEditSheet: Identifiable {
    case personal, contact, address, employment, bank, kyc, loan, additional
    var id: String { String(describing: self) }
}

struct ProfileView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = BorrowerProfileViewModel()
    @State private var activeSheet: ProfileEditSheet?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.clear

                if viewModel.isLoading {
                    ProgressView("Loading Profile...")
                        .progressViewStyle(CircularProgressViewStyle(tint: LMSColors.brandNavy))
                } else if let profile = viewModel.profile {
                    ScrollView {
                        VStack(spacing: LMSSpacing.lg) {
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
                            .padding(.horizontal, LMSSpacing.xl)
                            .padding(.top, LMSSpacing.md)
                            .padding(.bottom, LMSSpacing.xs)

                            // Menu Card Group
                            VStack(spacing: 0) {
                                NavigationLink(destination: ProfileInfoDetailView(viewModel: viewModel)) {
                                    profileRow(title: "Profile Information", icon: "person.fill", iconColor: LMSColors.actionBlue)
                                }
                                .buttonStyle(PlainButtonStyle())
                                cardDivider()

                                NavigationLink(destination: SettingsDetailView()) {
                                    profileRow(title: "Settings", icon: "gearshape.fill", iconColor: LMSColors.textSecondary)
                                }
                                .buttonStyle(PlainButtonStyle())
                                cardDivider()

                                NavigationLink(destination: SecurityDetailView()) {
                                    profileRow(title: "Security", icon: "lock.shield.fill", iconColor: LMSColors.emerald)
                                }
                                .buttonStyle(PlainButtonStyle())
                                cardDivider()

                                NavigationLink(destination: ResetPasswordDetailView()) {
                                    profileRow(title: "Reset/Change Password", icon: "key.fill", iconColor: LMSColors.amber)
                                }
                                .buttonStyle(PlainButtonStyle())
                                cardDivider()

                                NavigationLink(destination: NotificationsDetailView()) {
                                    profileRow(title: "Notifications", icon: "bell.fill", iconColor: LMSColors.coral)
                                }
                                .buttonStyle(PlainButtonStyle())
                                cardDivider()

                                NavigationLink(destination: PrivacyControlsDetailView()) {
                                    profileRow(title: "Privacy Controls", icon: "hand.raised.fill", iconColor: .purple)
                                }
                                .buttonStyle(PlainButtonStyle())
                                cardDivider()

                                NavigationLink(destination: LinkedBankAccountsDetailView(viewModel: viewModel)) {
                                    profileRow(title: "Linked Bank Accounts", icon: "creditcard.fill", iconColor: LMSColors.actionBlue)
                                }
                                .buttonStyle(PlainButtonStyle())
                                cardDivider()

                                NavigationLink(destination: KYCStatusDetailView(viewModel: viewModel)) {
                                    profileRow(title: "KYC Status", icon: "checkmark.seal.fill", iconColor: LMSColors.emerald)
                                }
                                .buttonStyle(PlainButtonStyle())
                                cardDivider()

                                NavigationLink(destination: DocumentManagementDetailView(viewModel: viewModel)) {
                                    profileRow(title: "Document Management", icon: "doc.on.doc.fill", iconColor: .indigo)
                                }
                                .buttonStyle(PlainButtonStyle())
                                cardDivider()

                                NavigationLink(destination: HelpSupportDetailView()) {
                                    profileRow(title: "Help & Support", icon: "questionmark.circle.fill", iconColor: LMSColors.teal)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .background(LMSColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
                            .padding(.horizontal, LMSSpacing.lg)

                            // Log Out
                            Button(action: {
                                HapticsManager.triggerImpact(style: .medium)
                                BorrowerProfileStore.shared.signOut()
                                appState.logout()
                                authManager.signOut()
                            }) {
                                HStack(spacing: LMSSpacing.md) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous)
                                            .fill(LMSColors.coral.opacity(0.10))
                                            .frame(width: 32, height: 32)

                                        Image(systemName: "arrow.left.square.fill")
                                            .foregroundColor(LMSColors.coral)
                                            .font(.system(size: 15, weight: .semibold))
                                    }

                                    Text("Log Out")
                                        .font(LMSFont.callout.weight(.semibold))
                                        .foregroundColor(LMSColors.coral)

                                    Spacer()
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, LMSSpacing.lg)
                            }
                            .background(LMSColors.surface)
                            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
                            .padding(.horizontal, LMSSpacing.lg)
                            .padding(.bottom, LMSSpacing.xxl)
                        }
                    }
                    .onAppear {
                        if let profile = viewModel.profile {
                            print("ProfileView appeared. Current Completion: \(profile.profileCompletionPercentage)%")
                        }
                    }
                }
            }
            .lmsScreenBackground()
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func cardDivider() -> some View {
        LMSGroupedDivider()
    }

    private func profileRow(title: String, icon: String, iconColor: Color) -> some View {
        LMSListRow(title: title, icon: icon, iconColor: iconColor)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AppStateManager())
            .environmentObject(AuthManager())
    }
}
