import SwiftUI

struct AppLockView: View {
    @Binding var isUnlocked: Bool
    @StateObject private var localSecurity = LocalSecurityService.shared
    @State private var authenticationFailed = false

    var body: some View {
        ZStack {
            LMSColors.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(LMSColors.brandNavy)
                
                VStack(spacing: 8) {
                    Text("App Locked")
                        .font(.title2.bold())
                        .foregroundStyle(LMSColors.textPrimary)
                    
                    Text("Unlock to access your dashboard.")
                        .font(.subheadline)
                        .foregroundStyle(LMSColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                if authenticationFailed {
                    Text("Authentication failed. Please try again.")
                        .font(.caption.bold())
                        .foregroundStyle(LMSColors.coral)
                        .padding(.top, 8)
                }
                
                Spacer()
                
                Button {
                    authenticate()
                } label: {
                    HStack {
                        Image(systemName: "faceid")
                            .font(.title3)
                        Text("Unlock with \(localSecurity.biometricTypeName)")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(LMSColors.brandNavy, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            authenticate()
        }
    }

    private func authenticate() {
        Task {
            let success = await localSecurity.authenticate(reason: "Unlock the app securely")
            if success {
                withAnimation(.easeInOut) {
                    isUnlocked = true
                }
            } else {
                withAnimation {
                    authenticationFailed = true
                }
            }
        }
    }
}
