//
//  PortfolioCardView.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 19/05/26.
//

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
    
    // Auto-scroll timer publisher (increased from 5 to 8 seconds for a more relaxed reading experience)
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
        if viewModel.isLoading {
            return 1
        }
        return 1 + viewModel.bankAccounts.count + 1
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            if viewModel.isLoading {
                // Loading Skeleton state
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: UIScreen.main.bounds.width - 32, height: 190)
                    .shimmer(active: true)
                    .transition(.opacity.animation(.easeIn(duration: 0.4)))
            } else {
                // TabView carousel matching 190pt card dimensions
                TabView(selection: $currentIndex) {
                    // Card 1: Total Loan Outstanding Summary
                    TotalLoanOutstandingCard(viewModel: viewModel)
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
                        .tag(1 + index)
                        .onTapGesture {
                            onNavigateToBank(account)
                        }
                    }
                    
                    // Card Last: Loan Protection
                    LoanProtectionCardRefined()
                        .tag(1 + viewModel.bankAccounts.count)
                        .onTapGesture {
                            onNavigateToInsurance()
                        }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 190)
                .frame(width: UIScreen.main.bounds.width)
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
                            .fill(i == currentIndex ? Color.brandNavy : Color.brandNavy.opacity(0.35))
                            .frame(width: i == currentIndex ? 20 : 6, height: 6)
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
                    }
                }
            }
        }
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
            accent: Color(hex: "00C48C")
        )
        .frame(width: UIScreen.main.bounds.width - 32, height: 190)
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
                    HStack(spacing: 8) {
                        Image(systemName: "building.columns.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(account.accountType.displayName)
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.semibold)
                                .foregroundColor(.white.opacity(0.85))
                            
                            Text("•••• \(account.accountNumber.suffix(4))")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.white.opacity(0.70))
                            
                            Text(account.bankName)
                                .font(.system(.caption2, design: .rounded))
                                .foregroundColor(.white.opacity(0.55))
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(cardPosition) of \(totalAccountCards)")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                }
                
                Spacer()
                
                // Center - Balance Block
                VStack(alignment: .leading, spacing: 2) {
                    Text("Current Balance")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))
                    
                    HStack(alignment: .center, spacing: 8) {
                        Text(account.availableBalance.formattedAsINR())
                            .font(.system(.title, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if isLowBalance {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 10))
                                Text("Low Balance — Top up ₹\(Int(deficit)) to avoid penalty")
                                    .font(.system(.caption2, design: .rounded).weight(.medium))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.red.opacity(0.85))
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
                            .font(.system(.caption2, design: .rounded))
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(Color.brandNavy)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    Text("Linked: \(linkedLoanTypes)")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.white.opacity(0.65))
                    
                    Spacer()
                    
                    Button(action: onTransfer) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 10, weight: .bold))
                            Text("Transfer")
                                .font(.system(.caption2, design: .rounded))
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .frame(width: UIScreen.main.bounds.width - 32, height: 190)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 6)
        .overlay(
            Group {
                if isLowBalance {
                    Rectangle()
                        .fill(Color.red)
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
            return [Color(hex: "00C48C"), Color(hex: "0096A0")]
        case .overdraft:
            return [Color(hex: "FFB300"), Color(hex: "F4511E")]
        case .current:
            return [Color(hex: "4158D0"), Color(hex: "C850C0")]
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
                    HStack(spacing: 8) {
                        Image(systemName: "shield.lefthalf.filled")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                        
                        Text("LOAN PROTECTION")
                            .font(.system(.caption2, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.white.opacity(0.85))
                    }
                    
                    Spacer()
                }
                
                Spacer()
                
                // Middle block
                HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Coverage Amount")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(.white.opacity(0.65))
                        Text("₹ 15,00,000")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Monthly Premium")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(.white.opacity(0.65))
                        Text("₹ 850 / mo")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
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
                            .font(.system(.caption2, design: .rounded))
                            .fontWeight(.bold)
                    }
                    .foregroundColor(Color(hex: "00C48C"))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white)
                    .cornerRadius(8)
                    
                    Spacer()
                    
                    Text("Renews: 12 Jan 2026")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.white.opacity(0.65))
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Text("View Policy")
                            .font(.system(.caption2, design: .rounded))
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(.white)
                }
            }
            .padding(16)
        }
        .frame(width: UIScreen.main.bounds.width - 32, height: 190)
        .cornerRadius(20)
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
        .cornerRadius(20)
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
                .foregroundColor(.white)
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
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.brandCoral)
            .cornerRadius(10)
    }
}

struct InsuranceCard: View {
    var body: some View {
        LoanProtectionCardRefined()
    }
}
