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
    
    private var totalCardCount: Int {
        if viewModel.isLoading { return 1 }
        return 1 + viewModel.bankAccounts.count + 1
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if viewModel.isLoading {
                        RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
                            .fill(LMSColors.surfaceElevated)
                            .frame(width: 300, height: 180)
                            .shimmer(active: true)
                    } else {
                        // Card 1: Total Loan Outstanding
                        TotalLoanOutstandingCard(viewModel: viewModel)
                            .frame(width: 310, height: 185)
                            .onTapGesture {
                                if let firstLoan = viewModel.loanAccounts.first {
                                    onNavigateToLoan(firstLoan)
                                }
                            }
                        
                        // Cards 2...N: Bank accounts
                        ForEach(viewModel.bankAccounts.indices, id: \.self) { index in
                            let account = viewModel.bankAccounts[index]
                            BankAccountCardRefined(
                                account: account,
                                isLowBalance: viewModel.isLowBalance(account),
                                onTransfer: { onTransferTap(account) }
                            )
                            .frame(width: 310, height: 185)
                            .onTapGesture {
                                onNavigateToBank(account)
                            }
                        }
                        
                        // Card Last: Insurance
                        LoanProtectionCardRefined()
                            .frame(width: 310, height: 185)
                            .onTapGesture {
                                onNavigateToInsurance()
                            }
                    }
                }
                .padding(.horizontal, LMSSpacing.lg)
                .padding(.vertical, LMSSpacing.xs)
            }
        }
    }
}

// MARK: - Card 1: Total Loan Outstanding Card
struct TotalLoanOutstandingCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Outstanding")
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundStyle(.white.opacity(0.8))
                    Text(viewModel.totalOutstanding.formattedAsINR())
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "chart.pie.fill")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(Int(viewModel.repaidFraction * 100))% Repaid")
                        .font(.system(.caption2, design: .rounded).bold())
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    Text("\(viewModel.loanAccounts.count) Active Loans")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
                
                ProgressView(value: viewModel.repaidFraction)
                    .tint(.white)
                    .background(Color.white.opacity(0.2))
                    .scaleEffect(x: 1, y: 1.5)
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            HStack {
                Text("Manage Loans")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.right.circle.fill")
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding(LMSSpacing.xl)
        .background(
            LinearGradient(
                colors: [LMSColors.brandNavy, LMSColors.brandNavyLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
        .shadow(color: LMSColors.brandNavy.opacity(0.25), radius: 12, x: 0, y: 6)
    }
}

// MARK: - Bank Account Card
struct BankAccountCardRefined: View {
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
                        Text(account.accountType.displayName)
                            .font(.system(.caption2, design: .rounded))
                            .foregroundStyle(LMSColors.textSecondary)
                    }
                }
                Spacer()
                Text("•••• \(account.accountNumber.suffix(4))")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(LMSColors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Available Balance")
                    .font(.system(.caption2, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textSecondary)
                Text(account.availableBalance.formattedAsINR())
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(LMSColors.textPrimary)
            }
            
            Spacer()
            
            HStack {
                if isLowBalance {
                    HStack(spacing: 4) {
                        Circle().fill(.red).frame(width: 6, height: 6)
                        Text("Low Balance")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.red)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1), in: Capsule())
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 10))
                        Text("Verified")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(LMSColors.emerald)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(LMSColors.emerald.opacity(0.1), in: Capsule())
                }
                
                Spacer()
                
                Button(action: onTransfer) {
                    Text("Add Funds")
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(LMSColors.brandNavy, in: Capsule())
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

// MARK: - Legacy Adapters
public struct PortfolioCardView: View {
    public enum CardType: Hashable {
        case loan(DashboardLoanAccount)
        case bank(BankAccount)
        case insurance
    }
    
    let type: CardType
    let isLowBalance: Bool
    let isLoading: Bool
    var onTransferTap: (() -> Void)? = nil
    
    public init(type: CardType, isLowBalance: Bool = false, isLoading: Bool = false, onTransferTap: (() -> Void)? = nil) {
        self.type = type
        self.isLowBalance = isLowBalance
        self.isLoading = isLoading
        self.onTransferTap = onTransferTap
    }
    
    public var body: some View {
        Group {
            switch type {
            case .loan(_):
                TotalLoanOutstandingCard(viewModel: DashboardViewModel())
            case .bank(let bank):
                BankAccountCardRefined(account: bank, isLowBalance: isLowBalance, onTransfer: { onTransferTap?() })
            case .insurance:
                LoanProtectionCardRefined()
            }
        }
        .frame(width: 300, height: 180)
    }
}
