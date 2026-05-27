import SwiftUI
import Combine

// MARK: - Shimmer Modifier
public struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    let enabled: Bool
    
    public func body(content: Content) -> some View {
        if enabled {
            content
                .redacted(reason: .placeholder)
                .overlay(
                    GeometryReader { geo in
                        Color.white.opacity(0.15)
                            .mask(
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [.clear, .white.opacity(0.8), .clear]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .offset(x: -geo.size.width + (phase * geo.size.width * 2))
                            )
                            .blendMode(.screen)
                    }
                )
                .onAppear {
                    withAnimation(Animation.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    public func shimmer(active: Bool) -> some View {
        self.modifier(ShimmerModifier(enabled: active))
    }
}

// MARK: - Refined Portfolio Carousel View
public struct PortfolioCarouselView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var currentIndex = 0
    
    let onNavigateToLoan: (DashboardLoanAccount) -> Void
    let onNavigateToBank: (BankAccount) -> Void
    let onNavigateToInsurance: () -> Void
    let onTransferTap: (BankAccount) -> Void
    
    public init(
        viewModel: DashboardViewModel,
        onNavigateToLoan: @escaping (DashboardLoanAccount) -> Void,
        onNavigateToBank: @escaping (BankAccount) -> Void,
        onNavigateToInsurance: @escaping () -> Void,
        onTransferTap: @escaping (BankAccount) -> Void
    ) {
        self.viewModel = viewModel
        self.onNavigateToLoan = onNavigateToLoan
        self.onNavigateToBank = onNavigateToBank
        self.onNavigateToInsurance = onNavigateToInsurance
        self.onTransferTap = onTransferTap
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if viewModel.isLoading {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(LMSColors.surfaceElevated)
                            .frame(width: 310, height: 185)
                            .shimmer(active: true)
                    } else {
                        if viewModel.loanAccounts.isEmpty {
                            EmptyPortfolioView()
                                .frame(width: 310, height: 185)
                        } else {
                            // Card 1: Premium Portfolio Card View
                            PortfolioCardView(viewModel: viewModel)
                                .frame(width: 310, height: 185)
                            
                            // Cards 2..N: One card per approved/disbursed loan
                            ForEach(viewModel.loanAccounts) { loan in
                                LoanAccountCardRefined(
                                    loan: loan
                                ) {
                                    onNavigateToLoan(loan)
                                }
                                .frame(width: 310, height: 185)
                            }
                            
                            // Card Last: Insurance
                            LoanProtectionCardRefined()
                                .frame(width: 310, height: 185)
                                .onTapGesture { onNavigateToInsurance() }
                        }
                    }
                }
                .padding(.horizontal, LMSSpacing.lg)
                .padding(.vertical, LMSSpacing.xs)
            }
        }
    }
}

// MARK: - Progress Ring View
public struct ProgressRingView: View {
    let progress: Double
    let size: CGFloat
    let strokeWidth: CGFloat
    
    @State private var animatedProgress: Double = 0
    
    public init(progress: Double, size: CGFloat = 44, strokeWidth: CGFloat = 5.0) {
        self.progress = progress
        self.size = size
        self.strokeWidth = strokeWidth
    }
    
    public var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: strokeWidth)
            
            Circle()
                .trim(from: 0.0, to: CGFloat(min(animatedProgress, 1.0)))
                .stroke(
                    LinearGradient(
                        colors: [LMSColors.emerald, LMSColors.emerald.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .rotationEffect(Angle(degrees: -90))
            
            Text("\(Int(animatedProgress * 100))%")
                .font(.system(size: size * 0.22, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.easeOut(duration: 1.0)) {
                self.animatedProgress = progress
            }
        }
    }
}

// MARK: - Sparkline View
public struct SparklineView: View {
    public init() {}
    
    public var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: geo.size.height * 0.8))
                path.addLine(to: CGPoint(x: geo.size.width * 0.2, y: geo.size.height * 0.5))
                path.addLine(to: CGPoint(x: geo.size.width * 0.4, y: geo.size.height * 0.65))
                path.addLine(to: CGPoint(x: geo.size.width * 0.6, y: geo.size.height * 0.25))
                path.addLine(to: CGPoint(x: geo.size.width * 0.8, y: geo.size.height * 0.4))
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height * 0.1))
            }
            .stroke(
                LinearGradient(
                    colors: [LMSColors.emerald, LMSColors.emerald.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round)
            )
        }
        .frame(width: 44, height: 18)
    }
}

// MARK: - Mini Info Pill
public struct MiniInfoPill: View {
    let label: String
    let value: String
    let iconName: String
    
    public init(label: String, value: String, iconName: String) {
        self.label = label
        self.value = value
        self.iconName = iconName
    }
    
    public var body: some View {
        HStack(spacing: 5) {
            Image(systemName: iconName)
                .font(.system(size: 8, weight: .semibold))
                .foregroundStyle(LMSColors.emerald)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 7, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                Text(value)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

// MARK: - Empty Portfolio View
public struct EmptyPortfolioView: View {
    @EnvironmentObject var tabRouter: BorrowerTabRouter
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 12) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(LMSColors.brandNavy.opacity(0.08))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "wallet.pass.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(LMSColors.brandNavy)
            }
            
            VStack(spacing: 2) {
                Text("No Active Loans")
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)
                
                Text("Explore tailored credit options today")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
            }
            
            Spacer()
            
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    tabRouter.select(.loans)
                }
            } label: {
                Text("Explore Loans")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [LMSColors.brandNavy, LMSColors.brandNavyLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(Capsule())
                    .shadow(color: LMSColors.brandNavy.opacity(0.18), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(LMSPressableStyle())
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LMSColors.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Portfolio Card View (Premium Overview Card)
public struct PortfolioCardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    public init(viewModel: DashboardViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top Row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "chart.pie.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(LMSColors.emerald)
                    Text("Portfolio")
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundStyle(.white.opacity(0.95))
                }
                
                Spacer()
                
                // +8% this month trend badge
                HStack(spacing: 2) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 7, weight: .bold))
                    Text("+8% this mo")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                }
                .foregroundStyle(LMSColors.emerald)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(LMSColors.emerald.opacity(0.15), in: Capsule())
            }
            
            Spacer()
            
            // Middle Row
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Total Outstanding")
                        .font(.system(size: 8, weight: .semibold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.55))
                    
                    Text(viewModel.totalOutstanding.formattedAsINR())
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    SparklineView()
                        .padding(.top, 4)
                }
                
                Spacer()
                
                ProgressRingView(progress: viewModel.repaidFraction, size: 48, strokeWidth: 5.0)
            }
            
            Spacer()
            
            // Bottom Row: 3 compact info pills
            HStack(spacing: 6) {
                let totalEMI = viewModel.loanAccounts.map(\.totalEMI).reduce(0, +)
                MiniInfoPill(
                    label: "EMI",
                    value: totalEMI > 0 ? totalEMI.formattedAsINR() : "N/A",
                    iconName: "indianrupeesign.circle.fill"
                )
                
                MiniInfoPill(
                    label: "Active",
                    value: "\(viewModel.loanAccounts.count)",
                    iconName: "doc.plaintext.fill"
                )
                
                let nextDue = viewModel.nextEMI?.dueDate
                MiniInfoPill(
                    label: "Due Date",
                    value: nextDue != nil ? nextDue!.formattedAsDDMMMYYYY() : "N/A",
                    iconName: "calendar"
                )
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [
                    Color(hex: "0B1528"),
                    Color(hex: "082820")
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.12), .white.opacity(0.02)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color(hex: "0B1528").opacity(0.35), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Loan Account Card
private struct LoanAccountCardRefined: View {
    let loan: DashboardLoanAccount
    let onOpen: () -> Void
    
    private var statusText: String { loan.principalOutstanding <= 0 ? "Closed" : "Active" }
    private var statusColor: Color { loan.principalOutstanding <= 0 ? .gray : LMSColors.emerald }
    
    private var loanIconName: String {
        let s = loan.loanType.lowercased()
        if s.contains("education") { return "graduationcap.fill" }
        if s.contains("home") { return "house.fill" }
        if s.contains("personal") { return "person.text.rectangle.fill" }
        if s.contains("business") { return "briefcase.fill" }
        if s.contains("vehicle") { return "car.fill" }
        if s.contains("gold") { return "seal.fill" }
        return "building.columns.fill"
    }
    
    private func maskAccountNumber(_ number: String) -> String {
        let suffix = number.suffix(4)
        return "•••• \(suffix.isEmpty ? "0000" : suffix)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                Image(systemName: loanIconName)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(LMSColors.brandNavy)
                    .frame(width: 36, height: 36)
                    .background(LMSColors.brandNavy.opacity(0.10), in: Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(loan.loanType)
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                        .lineLimit(1)
                    
                    Text(maskAccountNumber(loan.accountNumber))
                        .font(.caption2)
                        .foregroundStyle(LMSColors.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Text(statusText)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.12), in: Capsule())
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Loan Amount")
                        .font(.caption2)
                        .foregroundStyle(LMSColors.textSecondary)
                    Spacer()
                    Text(loan.sanctionedAmount.formattedAsINR())
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.textPrimary)
                }
                
                HStack {
                    Text("Outstanding")
                        .font(.caption2)
                        .foregroundStyle(LMSColors.textSecondary)
                    Spacer()
                    Text(loan.principalOutstanding.formattedAsINR())
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.textPrimary)
                }
                
                HStack {
                    Text("EMI")
                        .font(.caption2)
                        .foregroundStyle(LMSColors.textSecondary)
                    Spacer()
                    Text(loan.totalEMI.formattedAsINR())
                        .font(.caption2.bold())
                        .foregroundStyle(LMSColors.textPrimary)
                }
                
                HStack {
                    Text("Next EMI")
                        .font(.caption2)
                        .foregroundStyle(LMSColors.textSecondary)
                    Spacer()
                    Text(loan.nextEMIDate.formattedAsDDMMMYYYY())
                        .font(.caption2.bold())
                        .foregroundStyle(LMSColors.textPrimary)
                }
            }
        }
        .padding(LMSSpacing.xl)
        .background(LMSColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
        .contentShape(Rectangle())
        .onTapGesture { onOpen() }
    }
}

// MARK: - Bank Account Card (legacy adapter)
private struct BankAccountCardRefined: View {
    let account: BankAccount
    let isLowBalance: Bool
    let onTransfer: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(LMSColors.brandNavy)
                        .frame(width: 36, height: 36)
                        .background(LMSColors.brandNavy.opacity(0.1), in: Circle())
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(account.bankName)
                            .font(.system(.subheadline, design: .rounded).bold())
                            .lineLimit(1)
                        Text(account.accountType.displayName)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(LMSColors.textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                Text("•••• \(account.accountNumber.suffix(4))")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(LMSColors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(account.accountType == .overdraft ? "OD Available Balance" : "Available Balance")
                    .font(.system(.caption2, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textSecondary)
                Text(account.availableBalance.formattedAsINR())
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(LMSColors.textPrimary)
            }
            
            Spacer()
        }
        .padding(LMSSpacing.xl)
        .background(LMSColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 5)
        .onTapGesture { onTransfer() }
    }
}

// MARK: - Insurance Card
struct LoanProtectionCardRefined: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                HStack(spacing: 12) {
                    Image(systemName: "shield.lefthalf.filled")
                        .font(.system(size: 18))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(.white.opacity(0.2), in: Circle())
                    
                    Text("Loan Protection")
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundStyle(.white)
                }
                Spacer()
                Text("Active")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, LMSSpacing.sm)
                    .padding(.vertical, LMSSpacing.xs)
                    .background(.white.opacity(0.2), in: Capsule())
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Coverage Up To")
                    .font(.system(.caption2, design: .rounded).bold())
                    .foregroundStyle(.white.opacity(0.7))
                Text("₹ 15,00,000")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            Spacer()
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Premium")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white.opacity(0.6))
                    Text("₹ 850/mo")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                }
                Spacer()
                Text("View Policy")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, LMSSpacing.lg)
                    .padding(.vertical, LMSSpacing.sm)
                    .background(.white.opacity(0.2), in: Capsule())
            }
        }
        .padding(LMSSpacing.xl)
        .background(
            LinearGradient(
                colors: [Color(hex: "667EEA"), Color(hex: "764BA2")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
        .shadow(color: Color(hex: "667EEA").opacity(0.3), radius: 12, x: 0, y: 6)
    }
}
