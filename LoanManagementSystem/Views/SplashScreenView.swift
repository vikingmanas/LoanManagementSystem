import SwiftUI

struct SplashScreenView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    
    var body: some View {
        ZStack {
            Color.AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                
                // Animated App Icon Container
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.AppTheme.primary, Color.AppTheme.primary.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.AppTheme.primary.opacity(0.3), radius: 15, x: 0, y: 10)
                    
                    Image(systemName: "shield.chevron.fill")
                        .foregroundColor(.white)
                        .font(.system(size: 45, weight: .bold))
                }
                .scaleEffect(scale)
                .opacity(opacity)
                
                VStack(spacing: 8) {
                    Text("LMS")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(Color.AppTheme.textPrimary)
                    
                    Text("Simplifying Loans, Empowering Lives")
                        .font(Font.AppTheme.body)
                        .foregroundColor(Color.AppTheme.textSecondary)
                }
                .opacity(opacity)
                
                Spacer()
                
                // Footer details
                VStack(spacing: 6) {
                    Text("Secured with AES-256 & SSL Gateway")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.AppTheme.textSecondary.opacity(0.6))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                        Text("Enterprise Grade Security")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(Color.AppTheme.success)
                }
                .padding(.bottom, 30)
                .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                self.scale = 1.0
                self.opacity = 1.0
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
