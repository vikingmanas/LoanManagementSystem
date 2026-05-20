import SwiftUI

enum ProfileEditSheet: Identifiable {
    case personal, contact, address, employment, bank, kyc, loan, otpVerifyPhone, otpVerifyEmail
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
                Color.AppTheme.background.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Loading Profile...")
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.AppTheme.primary))
                } else if let profile = viewModel.profile {
                    ScrollView {
                        VStack(spacing: 16) {
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
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                            .padding(.bottom, 4)
                            
                            // Menu Card Group
                            VStack(spacing: 0) {
                                NavigationLink(destination: ProfileInfoDetailView(viewModel: viewModel)) {
                                    rowView(title: "Profile Information", icon: "person.fill", iconColor: .blue)
                                }
                                .buttonStyle(PlainButtonStyle())
                                cardDivider()
                                
                                NavigationLink(destination: SettingsDetailView()) {
                                    rowView(title: "Settings", icon: "gearshape.fill", iconColor: .gray)
                                }
                                .buttonStyle(PlainButtonStyle())
                                cardDivider()
                                
                                NavigationLink(destination: SecurityDetailView()) {
                                    rowView(title: "Security", icon: "lock.shield.fill", iconColor: .green)
                                }
                                .buttonStyle(PlainButtonStyle())
                                cardDivider()
                                
                                NavigationLink(destination: ResetPasswordDetailView()) {
                                    rowView(title: "Reset/Change Password", icon: "key.fill", iconColor: .orange)
                                }
                                .buttonStyle(PlainButtonStyle())
                                cardDivider()
                                
                                NavigationLink(destination: NotificationsDetailView()) {
                                    rowView(title: "Notifications", icon: "bell.fill", iconColor: .red)
                                }
                                .buttonStyle(PlainButtonStyle())
                                cardDivider()
                                
                                NavigationLink(destination: PrivacyControlsDetailView()) {
                                    rowView(title: "Privacy Controls", icon: "hand.raised.fill", iconColor: .purple)
                                }
                                .buttonStyle(PlainButtonStyle())
                                cardDivider()
                                
                                NavigationLink(destination: LinkedBankAccountsDetailView(viewModel: viewModel)) {
                                    rowView(title: "Linked Bank Accounts", icon: "creditcard.fill", iconColor: .blue)
                                }
                                .buttonStyle(PlainButtonStyle())
                                cardDivider()
                                
                                NavigationLink(destination: KYCStatusDetailView(viewModel: viewModel)) {
                                    rowView(title: "KYC Status", icon: "checkmark.seal.fill", iconColor: .green)
                                }
                                .buttonStyle(PlainButtonStyle())
                                cardDivider()
                                
                                NavigationLink(destination: DocumentManagementDetailView(viewModel: viewModel)) {
                                    rowView(title: "Document Management", icon: "doc.on.doc.fill", iconColor: .indigo)
                                }
                                .buttonStyle(PlainButtonStyle())
                                cardDivider()
                                
                                NavigationLink(destination: HelpSupportDetailView()) {
                                    rowView(title: "Help & Support", icon: "questionmark.circle.fill", iconColor: .teal)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .background(Color.AppTheme.secondary)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                            
                            // Log Out Card
                            Button(action: {
                                appState.logout()
                                authManager.signOut()
                            }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .fill(Color.AppTheme.error.opacity(0.12))
                                            .frame(width: 30, height: 30)
                                        
                                        Image(systemName: "arrow.left.square.fill")
                                            .foregroundColor(Color.AppTheme.error)
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                    
                                    Text("Log Out")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color.AppTheme.error)
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 13)
                                .padding(.horizontal, 16)
                            }
                            .background(Color.AppTheme.secondary)
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                            .padding(.bottom, 24)
                        }
                    }
                    .onAppear {
                        if let profile = viewModel.profile {
                            print("ProfileView appeared. Current Completion: \(profile.profileCompletionPercentage)%")
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func cardDivider() -> some View {
        Divider()
            .padding(.leading, 58)
    }
    
    private func rowView(title: String, icon: String, iconColor: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 30, height: 30)
                
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 15, weight: .semibold))
            }
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(Color.AppTheme.textPrimary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color.AppTheme.textSecondary.opacity(0.4))
        }
        .padding(.vertical, 13)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .environmentObject(AppStateManager())
            .environmentObject(AuthManager())
    }
}
