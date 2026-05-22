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

// MARK: - Refined Portfolio Carousel View (TabView Pageable Style)
public struct PortfolioCarouselView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @State private var currentIndex = 0
    
    // Auto-scroll timer publisher
    @State private var timer = Timer.publish(every: 8, on: .main, in: .common).autoconnect()
    
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
        GeometryReader { proxy in
            let screenWidth = proxy.size.width
            let cardWidth = screenWidth - (LMSSpacing.screenHorizontal * 2)
            
            VStack(spacing: LMSSpacing.md) {
                if viewModel.isLoading {
                    // Loading Skeleton state
                    RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
                        .fill(LMSColors.surfaceElevated)
                        .frame(width: cardWidth, height: 190)
                        .shimmer(active: true)
                        .transition(.opacity.animation(.easeIn(duration: 0.4)))
                        .frame(width: screenWidth) // Center in TabView space
                } else {
                    // TabView carousel matching 190pt card dimensions
                    TabView(selection: $currentIndex) {
                        // Card 1: Total Loan Outstanding Summary
                        TotalLoanOutstandingCard(viewModel: viewModel)
                            .frame(width: cardWidth, height: 190)
                            .tag(0)
                            .onTapGesture {
                                if let firstLoan = viewModel.loanAccounts.first {
                                    onNavigateToLoan(firstLoan)
                                }
                            }
                        
                        // Cards 2...N: Dynamic Linked bank accounts
                        ForEach(viewModel.bankAccounts.indices, id: \.self) { index in
                            let account = viewModel.bankAccounts[index]
                            BankAccountCardRefined(
                                account: account,
                                cardPosition: index + 1,
                                totalAccountCards: viewModel.bankAccounts.count,
                                isLowBalance: viewModel.isLowBalance(account),
                                deficit: viewModel.balanceDeficit(for: account),
                                linkedLoanTypes: getLinkedLoanTypes(for: account),
                                onTransfer: { onTransferTap(account) }
                            )
                            .frame(width: cardWidth, height: 190)
                            .tag(1 + index)
                            .onTapGesture {
                                onNavigateToBank(account)
                            }
                        }
                        
                        // Card Last: Loan Protection
                        LoanProtectionCardRefined()
                            .frame(width: cardWidth, height: 190)
                            .tag(1 + viewModel.bankAccounts.count)
                            .onTapGesture {
                                onNavigateToInsurance()
                            }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: 190)
                    .onReceive(timer) { _ in
                        guard !UIAccessibility.isReduceMotionEnabled else { return }
                        withAnimation(.easeInOut(duration: 0.5)) {
                            currentIndex = (currentIndex + 1) % totalCardCount
                        }
                    }
                    
                    // Page Dot Indicator
                    HStack(spacing: 6) {
                        ForEach(0..<totalCardCount, id: \.self) { i in
                            Capsule()
                                .fill(i == currentIndex ? LMSColors.brandNavy : LMSColors.brandNavy.opacity(0.35))
                                .frame(width: i == currentIndex ? 20 : 6, height: 6)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
                        }
                    }
                }
            }
        }
        .frame(height: 220) // 190 card + dots + spacing
    }
    
    private func getLinkedLoanTypes(for account: BankAccount) -> String {
        let matchedLoans = viewModel.loanAccounts.filter { $0.linkedBankAccountId == account.id }
        if matchedLoans.isEmpty { return "None" }
        return matchedLoans.map(\.loanType).joined(separator: ", ")
    }
}

// MARK: - Card 1: Total Loan Outstanding Card
struct TotalLoanOutstandingCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        LoanCard(
            title: "Total Loan Outstanding",
            subtitle: "Across \(viewModel.loanAccounts.count) active loans",
            outstandingAmount: viewModel.totalOutstanding,
            repaidFraction: viewModel.repaidFraction,
            monthlyEMI: viewModel.loanAccounts.map(\.totalEMI).reduce(0, +),
            nextEMIDateText: (viewModel.loanAccounts.map(\.nextEMIDate).sorted().first ?? Date()).formattedAsDDMMMYYYY(),
            accent: LMSColors.emerald
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Total loan outstanding \(viewModel.totalOutstanding.formattedAsINR()). \(Int(viewModel.repaidFraction*100)) percent repaid out of total approved \(viewModel.totalSanctioned.formattedAsINR()).")
    }
}

// MARK: - Cards 2...N: Dynamic Refined Bank Account Card
struct BankAccountCardRefined: View {
    let account: BankAccount
    let cardPosition: Int
    let totalAccountCards: Int
    let isLowBalance: Bool
    let deficit: Double
    let linkedLoanTypes: String
    let onTransfer: () -> Void
    
    @State private var pulseScale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            // Background Gradient depending on accountType
            LinearGradient(
                colors: getGradientColors(),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 0) {
                // Top Row
                HStack(alignment: .top) {
                    HStack(spacing: LMSSpacing.sm) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(account.accountType.displayName)
                                .font(LMSFont.caption2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.9))
                            
                            Text("•••• \(account.accountNumber.suffix(4))")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.70))
                            
                            Text(account.bankName)
                                .font(LMSFont.caption2)
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(cardPosition) of \(totalAccountCards)")
                        .font(LMSFont.caption2)
                        .foregroundStyle(.white.opacity(0.45))
                }
                
                Spacer()
                
                // Center - Balance Block
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Balance")
                        .font(LMSFont.caption)
                        .foregroundStyle(.white.opacity(0.75))
                    
                    HStack(alignment: .center, spacing: LMSSpacing.sm) {
                        Text(account.availableBalance.formattedAsINR())
                            .font(.system(.title, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                        
                        if isLowBalance {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 10))
                                Text("Low Balance — Top up ₹\(Int(deficit)) to avoid penalty")
                                    .font(LMSFont.caption2.weight(.medium))
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(LMSColors.coral.opacity(0.85))
                            .clipShape(Capsule())
                            .scaleEffect(pulseScale)
                            .onAppear {
                                withAnimation(Animation.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                                    pulseScale = 1.04
                                }
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Bottom Row
                HStack(alignment: .center) {
                    // Account Info Chip
                    HStack(spacing: 4) {
                        Image(systemName: getChipIconName())
                            .font(.system(size: 10))
                        Text(getChipText())
                            .font(LMSFont.caption2.weight(.semibold))
                    }
                    .foregroundStyle(LMSColors.brandNavy)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    
                    Spacer()
                    
                    Text("Linked: \(linkedLoanTypes)")
                        .font(LMSFont.caption2)
                        .foregroundStyle(.white.opacity(0.65))
                    
                    Spacer()
                    
                    Button(action: onTransfer) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 10, weight: .bold))
                            Text("Transfer")
                                .font(LMSFont.caption2.weight(.semibold))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(LMSSpacing.lg)
        }
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
        .overlay(
            Group {
                if isLowBalance {
                    Rectangle()
                        .fill(LMSColors.coral)
                        .frame(height: 3)
                }
            },
            alignment: .bottom
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(account.accountType.displayName). Account ending \(account.accountNumber.suffix(4)). Current balance \(account.availableBalance.formattedAsINR()).\(isLowBalance ? " Warning: Low balance." : "")")
    }
    
    private func getGradientColors() -> [Color] {
        switch account.accountType {
        case .savings:
            return [LMSColors.emerald, LMSColors.emeraldDark]
        case .overdraft:
            return [LMSColors.amber, Color(hex: "F4511E")]
        case .current:
            return [LMSColors.actionBlue, Color(hex: "5E35B1")]
        }
    }
    
    private func getChipIconName() -> String {
        switch account.accountType {
        case .overdraft:  return "creditcard"
        case .savings:    return "lock.shield"
        case .current:    return "checkmark.circle"
        }
    }
    
    private func getChipText() -> String {
        switch account.accountType {
        case .overdraft:  return "OD Limit: ₹\(Int(account.odLimit ?? 50000))"
        case .savings:    return "Min Bal: ₹\(Int(account.minBalance ?? 5000))"
        case .current:    return "No Min Balance"
        }
    }
}

// MARK: - Card Last: Refined Loan Protection Card
struct LoanProtectionCardRefined: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "667EEA"), Color(hex: "F093FB")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            VStack(alignment: .leading, spacing: 0) {
                // Top Row
                HStack(alignment: .top) {
                    HStack(spacing: LMSSpacing.sm) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 22))
                            .foregroundStyle(.white)
                        
                        Text("LOAN PROTECTION")
                            .font(LMSFont.caption2.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                // Middle block
                HStack(spacing: LMSSpacing.xxl) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Coverage Amount")
                            .font(LMSFont.caption2)
                            .foregroundStyle(.white.opacity(0.65))
                        Text("₹ 15,00,000")
                            .font(.system(.title2, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Monthly Premium")
                            .font(LMSFont.caption2)
                            .foregroundStyle(.white.opacity(0.65))
                        Text("₹ 850 / mo")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
                
                Spacer()
                
                // Bottom Row
                HStack(alignment: .center) {
                    // Active Badge
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10))
                        Text("Active")
                            .font(LMSFont.caption2.weight(.bold))
                    }
                    .foregroundStyle(LMSColors.emerald)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    
                    Spacer()
                    
                    Text("Renews: 12 Jan 2026")
                        .font(LMSFont.caption2)
                        .foregroundStyle(.white.opacity(0.65))
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("View Policy")
                            .font(LMSFont.caption2.weight(.semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(.white)
                }
            }
            .padding(LMSSpacing.lg)
        }
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Loan Protection Policy. Status Active. Coverage Amount 15 Lakh rupees. Renews 12 January 2026.")
    }
}

// MARK: - Legacy PortfolioCardView (For Backward Compatibility with other files)
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
            case .loan(let loan):
                LoanOverviewCard(loan: loan)
            case .bank(let bank):
                BankAccountCard(bank: bank, isLowBalance: isLowBalance, onTransferTap: onTransferTap)
            case .insurance:
                InsuranceCard()
            }
        }
        .frame(width: 280, height: 180)
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        .shimmer(active: isLoading)
    }
}

struct LoanOverviewCard: View {
    let loan: DashboardLoanAccount
    
    var body: some View {
        TotalLoanOutstandingCard(viewModel: DashboardViewModel()) // Fallback adapter
    }
}

struct RepaidProgressArc: View {
    let percentage: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.15), lineWidth: 4)
            Circle()
                .trim(from: 0, to: CGFloat(percentage))
                .stroke(Color.white, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            
            Text("\(Int(percentage * 100))%")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
        .frame(width: 36, height: 36)
    }
}

struct BankAccountCard: View {
    let bank: BankAccount
    let isLowBalance: Bool
    var onTransferTap: (() -> Void)?
    
    var body: some View {
        BankAccountCardRefined(
            account: bank,
            cardPosition: 1,
            totalAccountCards: 1,
            isLowBalance: isLowBalance,
            deficit: 0,
            linkedLoanTypes: "None",
            onTransfer: { onTransferTap?() }
        )
    }
}

struct PulsingLowBalanceBadge: View {
    var body: some View {
        Text("Low Balance")
            .font(.system(size: 9, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(LMSColors.coral)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

struct InsuranceCard: View {
    var body: some View {
        LoanProtectionCardRefined()
    }
}
