import SwiftUI

public struct EMITrackerView: View {
    @ObservedObject var viewModel: DashboardViewModel
    var onPayTap: () -> Void
    var onViewAllPendingTap: () -> Void
    
    public init(viewModel: DashboardViewModel, onPayTap: @escaping () -> Void, onViewAllPendingTap: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onPayTap = onPayTap
        self.onViewAllPendingTap = onViewAllPendingTap
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("REPAYMENT STATUS")
                    .font(.system(.caption, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textSecondary)
                
                Spacer()
                
                let pendingCount = viewModel.pendingEMIs.filter { $0.status != .paid }.count
                if pendingCount > 0 {
                    Text("\(pendingCount) Dues")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(LMSColors.amber, in: Capsule())
                }
            }
            .padding(.horizontal, LMSSpacing.lg)
            
            if viewModel.isLoading {
                LoadingTrackerSkeleton()
            } else {
                VStack(spacing: 16) {
                    if let nextEMI = viewModel.nextEMI {
                        UpcomingEMICard(
                            nextEMI: nextEMI,
                            amountDue: viewModel.nextDueAmount,
                            loanLabel: viewModel.nextDueLoanLabel,
                            status: viewModel.nextDueStatus,
                            balance: viewModel.bankAccount.availableBalance,
                            onPayTap: onPayTap
                        )
                    } else {
                        AllCaughtUpCard()
                    }
                    
                    let unpaidEMIs = viewModel.pendingEMIs.filter { $0.status != .paid }
                    if !unpaidEMIs.isEmpty {
                        VStack(spacing: 0) {
                            ForEach(unpaidEMIs.prefix(2)) { emi in
                                PendingEMIRow(emi: emi) {
                                    if viewModel.bankAccount.availableBalance >= emi.amount {
                                        viewModel.payNextEMI()
                                    }
                                }
                                if emi.id != unpaidEMIs.prefix(2).last?.id {
                                    Divider().padding(.leading, LMSSpacing.lg)
                                }
                            }
                        }
                        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                        
                        if unpaidEMIs.count > 2 {
                            Button {
                                onViewAllPendingTap()
                            } label: {
                                HStack {
                                    Text("View all \(unpaidEMIs.count) pending payments")
                                        .font(.system(.subheadline, design: .rounded).bold())
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption2.bold())
                                }
                                .foregroundStyle(LMSColors.brandNavy)
                                .padding(.vertical, 12)
                            }
                        }
                    }
                }
                .padding(.horizontal, LMSSpacing.lg)
            }
        }
    }
}

struct UpcomingEMICard: View {
    let nextEMI: EMIRecord
    let amountDue: Double
    let loanLabel: String
    let status: DashboardEMIStatus
    let balance: Double
    let onPayTap: () -> Void
    
    private var isOverdue: Bool { status == .overdue }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isOverdue ? "OVERDUE PAYMENT" : "UPCOMING EMI")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(isOverdue ? LMSColors.coral : LMSColors.brandNavy)
                    
                    Text(amountDue.formattedAsINR())
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.textPrimary)
                }
                
                Spacer()
                
                Image(systemName: isOverdue ? "exclamationmark.triangle.fill" : "calendar.badge.clock")
                    .font(.title2)
                    .foregroundStyle(isOverdue ? LMSColors.coral : LMSColors.brandNavy)
                    .padding(12)
                    .background(isOverdue ? LMSColors.coral.opacity(0.1) : LMSColors.brandNavy.opacity(0.1), in: Circle())
            }
            .padding(.bottom, 20)
            
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DUE DATE")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                    Text(nextEMI.dueDate.formattedAsDDMMMYYYY())
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("LOAN TYPE")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                    Text(loanLabel)
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                }
                
                Spacer()
            }
            .padding(.bottom, 20)
            
            let isSufficient = balance >= amountDue
            
            Button {
                onPayTap()
            } label: {
                HStack {
                    Text(isSufficient ? "Authorize Payment" : "Insufficient Balance")
                        .font(.system(.body, design: .rounded).bold())
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.headline)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(isOverdue ? LMSColors.coral : (isSufficient ? LMSColors.brandNavy : Color.gray), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(!isSufficient && !isOverdue)
            .buttonStyle(DashboardPressableStyle())
        }
        .padding(LMSSpacing.xl)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 1)
        )
    }
}

struct AllCaughtUpCard: View {
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: "checkmark.seal.fill")
                .font(.title)
                .foregroundStyle(LMSColors.emerald)
                .padding(10)
                .background(LMSColors.emerald.opacity(0.1), in: Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text("All Caught Up!")
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)
                Text("No outstanding EMIs for this cycle.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
            }
            Spacer()
        }
        .padding(LMSSpacing.lg)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
    }
}

struct PendingEMIRow: View {
    let emi: EMIRecord
    var onSwipePay: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(emi.dueDate.formattedAsDDMMMYYYY())
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)
                Text("Repayment Date")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(LMSColors.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(emi.amount.formattedAsINR())
                    .font(.system(.subheadline, design: .rounded).bold())
                    .foregroundStyle(LMSColors.textPrimary)
                
                Text(emi.status == .overdue ? "OVERDUE" : "UPCOMING")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(emi.status == .overdue ? LMSColors.coral : LMSColors.amber)
            }
        }
        .padding(.horizontal, LMSSpacing.lg)
        .padding(.vertical, LMSSpacing.lg)
        .contentShape(Rectangle()) 
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                onSwipePay()
            } label: {
                Label("Pay", systemImage: "indianrupeesign.circle.fill")
            }
            .tint(LMSColors.brandNavy)
        }
    }
}

struct LoadingTrackerSkeleton: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(LMSColors.surface)
            .frame(height: 200)
            .shimmer(active: true)
    }
}
