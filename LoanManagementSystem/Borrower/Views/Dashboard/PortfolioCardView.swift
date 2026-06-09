import SwiftUI
import Combine

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

public struct PortfolioCarouselView: View {
    @Bindable var viewModel: DashboardViewModel
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
                        RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
                            .fill(LMSColors.surfaceElevated)
                            .frame(width: 300, height: 180)
                            .shimmer(active: true)
                    } else {
                        if viewModel.loanAccounts.isEmpty {
                            EmptyLoanAccountStateCard()
                                .frame(width: 310, height: 185)
                        } else {

                            TotalLoanOutstandingCard(viewModel: viewModel)
                                .frame(width: 310, height: 185)
                            
                            ForEach(viewModel.loanAccounts) { loan in
                                LoanAccountCardRefined(
                                    loan: loan
                                ) {
                                    onNavigateToLoan(loan)
                                }
                                .frame(width: 310, height: 185)
                            }
                            
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

private struct EmptyLoanAccountStateCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(LMSColors.brandNavy)
                    .frame(width: 36, height: 36)
                    .background(LMSColors.brandNavy.opacity(0.10), in: Circle())
                VStack(alignment: .leading, spacing: 4) {
                    Text("No active loan account found")
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                        .lineLimit(2)
                    Text("Your loan account will be automatically created once a loan application is approved.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
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
    }
}

struct TotalLoanOutstandingCard: View {
    @Bindable var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Active Loans")
                        .font(.system(.caption, design: .rounded).bold())
                        .foregroundStyle(.white.opacity(0.8))
                    Text("\(viewModel.loanAccounts.count)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
                Spacer()
                Image(systemName: "doc.plaintext")
                    .font(.title2)
                    .foregroundStyle(.white.opacity(0.9))
            }
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Total Outstanding: \(viewModel.totalOutstanding.formattedAsINR())")
                        .font(.system(.caption2, design: .rounded).bold())
                        .foregroundStyle(.white.opacity(0.85))
                    Spacer()
                    let nextDue = viewModel.nextEMI?.dueDate
                    Text(nextDue != nil ? "Next EMI: \(nextDue!.formattedAsDDMMMYYYY())" : "Next EMI: N/A")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                }
                HStack {
                    Text("\(viewModel.loansClosedCount) Closed")
                        .font(.system(.caption2, design: .rounded).bold())
                        .foregroundStyle(.white.opacity(0.8))
                    Spacer()
                    ProgressView(value: viewModel.repaidFraction)
                        .tint(.white)
                        .background(Color.white.opacity(0.2))
                        .scaleEffect(x: 1, y: 1.5)
                        .clipShape(Capsule())
                        .frame(width: 120)
                }
            }
            
            Spacer()
            
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
        .voiceOverCard(text: "Total Active Loans: \(viewModel.loanAccounts.count). Total Outstanding: \(viewModel.totalOutstanding.formattedAsINR()).")
    }
}

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
        .voiceOverCard(text: "Loan Account \(loan.loanType). Status: \(statusText). Outstanding: \(loan.principalOutstanding.formattedAsINR())")
    }
}

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
        .voiceOverCard(text: "Bank Account \(account.bankName). Available Balance: \(account.availableBalance.formattedAsINR())")
    }
}

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
        .voiceOverCard(text: "Loan Protection. Active. Coverage Up To ₹ 15,00,000")
    }
}

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
