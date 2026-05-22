import SwiftUI

public struct EMITrackerView: View {
    @ObservedObject var viewModel: DashboardViewModel
    var onPayTap: () -> Void
    var onViewAllPendingTap: () -> Void
    
    @State private var selectedMonth = "May 2025"
    let months = ["Jan 2025", "Feb 2025", "Mar 2025", "Apr 2025", "May 2025", "Jun 2025", "Jul 2025"]
    
    public init(viewModel: DashboardViewModel, onPayTap: @escaping () -> Void, onViewAllPendingTap: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onPayTap = onPayTap
        self.onViewAllPendingTap = onViewAllPendingTap
    }
    
    public var body: some View {
        SectionContainer(title: "EMI Tracker", subtitle: "Upcoming dues and payment status") {
            Menu {
                Picker("Select Month", selection: $selectedMonth) {
                    ForEach(months, id: \.self) { month in
                        Text(month).tag(month)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedMonth)
                        .font(LMSFont.subheadline.weight(.medium))
                    Image(systemName: "chevron.down")
                        .font(LMSFont.caption2.weight(.bold))
                }
                .foregroundColor(LMSColors.brandNavy)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(LMSColors.surfaceElevated, in: Capsule())
            }
        } content: {
            if viewModel.isLoading {
                // Skeleton loading state
                LoadingTrackerSkeleton()
            } else {
                VStack(spacing: LMSSpacing.lg) {
                    // 4a. KPI Status Bar
                    HStack(spacing: LMSSpacing.sm) {
                        KPITile(title: "Total EMIs", value: "24", icon: "square.grid.2x2", color: LMSColors.textSecondary, bg: LMSColors.surfaceElevated)
                        
                        // Dynamically compute count of paid vs pending from the active model list
                        let paidCount = 24 - viewModel.pendingEMIs.filter({ $0.status != .paid }).count
                        let pendingCount = viewModel.pendingEMIs.filter({ $0.status != .paid }).count
                        
                        KPITile(title: "Paid", value: "\(paidCount)", icon: "checkmark.circle.fill", color: LMSColors.emerald, bg: LMSColors.emerald.opacity(0.08))
                        
                        KPITile(title: "Pending", value: "\(pendingCount)", icon: "clock.fill", color: LMSColors.amber, bg: LMSColors.amber.opacity(0.08))
                    }
                    .padding(.horizontal, 1)
                    
                    // 4b. Highlighted Upcoming EMI Card
                    if let nextEMI = viewModel.nextEMI {
                        UpcomingEMICard(nextEMI: nextEMI, balance: viewModel.bankAccount.availableBalance, onPayTap: onPayTap)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        // All Caught Up state!
                        AllCaughtUpCard()
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // 4c. Pending EMIs list
                    let unpaidEMIs = viewModel.pendingEMIs.filter { $0.status != .paid }
                    if !unpaidEMIs.isEmpty {
                        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                            Text("Pending Payments")
                                .font(LMSFont.caption.weight(.bold))
                                .foregroundColor(LMSColors.textSecondary)
                                .padding(.horizontal, 1)
                            
                            VStack(spacing: 0) {
                                ForEach(unpaidEMIs.prefix(3)) { emi in
                                    PendingEMIRow(emi: emi) {
                                        // Interactive pay action for row
                                        if viewModel.bankAccount.availableBalance >= emi.amount {
                                            viewModel.payNextEMI()
                                        }
                                    }
                                    if emi.id != unpaidEMIs.prefix(3).last?.id {
                                        Divider()
                                            .padding(.horizontal, LMSSpacing.lg)
                                    }
                                }
                            }
                            .background(LMSColors.surfaceElevated)
                            .cornerRadius(LMSRadius.lg)
                            .padding(.horizontal, 1)
                            
                            if unpaidEMIs.count > 3 {
                                Button {
                                    onViewAllPendingTap()
                                } label: {
                                    HStack {
                                        Spacer()
                                        Text("View All Pending (\(unpaidEMIs.count))")
                                            .font(LMSFont.callout.weight(.semibold))
                                            .foregroundColor(LMSColors.actionBlue)
                                        Spacer()
                                    }
                                    .frame(height: 44) // Tap target compliance
                                }
                                .padding(.top, 4)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - KPI Tile view
struct KPITile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let bg: Color
    
    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(LMSFont.callout.weight(.bold))
                    .foregroundColor(LMSColors.textPrimary)
                Text(title)
                    .font(LMSFont.caption2)
                    .foregroundColor(LMSColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer()
        }
        .padding(10)
        .background(bg)
        .cornerRadius(LMSRadius.lg)
    }
}

// MARK: - Upcoming EMI Highlighted Card
struct UpcomingEMICard: View {
    let nextEMI: EMIRecord
    let balance: Double
    let onPayTap: () -> Void
    @State private var showingReminderAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.lg) {
            HStack(alignment: .top, spacing: LMSSpacing.sm) {
                // Calendar icon with clock badge
                ZStack {
                    RoundedRectangle(cornerRadius: LMSRadius.md)
                        .fill(LMSColors.amber.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 20))
                        .foregroundColor(LMSColors.amber)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next EMI Due")
                        .font(LMSFont.subheadline.weight(.semibold))
                        .foregroundColor(LMSColors.textSecondary)
                    
                    Text(nextEMI.amount.formattedAsINR())
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .monospacedDigit()
                        .contentTransition(.numericText())
                        .foregroundColor(LMSColors.textPrimary)
                }
                
                Spacer()
                
                // Loan Type Tag
                Text(nextEMI.loanType)
                    .font(LMSFont.caption2.weight(.bold))
                    .foregroundColor(LMSColors.brandNavy)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(LMSColors.brandNavy.opacity(0.08))
                    .cornerRadius(10)
            }
            
            // Due alert string
            let isOverdue = nextEMI.status == .overdue
            HStack(spacing: 6) {
                Circle()
                    .fill(isOverdue ? LMSColors.coral : LMSColors.amber)
                    .frame(width: 8, height: 8)
                
                Text(isOverdue ? "Overdue! Please settle immediately" : "Due in 3 days — \(nextEMI.dueDate.formattedAsDDMMMYYYY())")
                    .font(LMSFont.caption.weight(.medium))
                    .foregroundColor(isOverdue ? LMSColors.coral : LMSColors.textPrimary)
            }
            
            Divider()
            
            // Buttons Row
            HStack(spacing: LMSSpacing.sm) {
                // Set Reminder Button (Outlined)
                Button {
                    let feedback = UIImpactFeedbackGenerator(style: .light)
                    feedback.impactOccurred()
                    showingReminderAlert = true
                } label: {
                    Text("Set Reminder")
                        .font(LMSFont.callout.weight(.semibold))
                        .foregroundColor(LMSColors.brandNavy)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: LMSRadius.md)
                                .stroke(LMSColors.brandNavy, lineWidth: 1.5)
                        )
                }
                .buttonStyle(DashboardPressableStyle())
                .alert("Reminder Scheduled", isPresented: $showingReminderAlert) {
                    Button("OK", role: .cancel) {}
                } message: {
                    Text("We'll remind you 24 hours before your EMI of \(nextEMI.amount.formattedAsINR()) on \(nextEMI.dueDate.formattedAsDDMMMYYYY()).")
                }
                
                // Pay Now Button (Filled)
                let isSufficient = balance >= nextEMI.amount
                Button {
                    onPayTap()
                } label: {
                    HStack {
                        if !isSufficient {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                        }
                        Text(isSufficient ? "Pay Now" : "Insufficient Funds")
                            .font(LMSFont.callout.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isSufficient ? LMSColors.brandNavy : Color.gray)
                    .cornerRadius(LMSRadius.md)
                }
                .buttonStyle(DashboardPressableStyle())
                .disabled(!isSufficient)
            }
        }
        .padding(LMSSpacing.xl)
        .background(
            ZStack {
                LMSColors.surface
                
                // Left side accent border
                HStack {
                    Rectangle()
                        .fill(nextEMI.status == .overdue ? LMSColors.coral : LMSColors.amber)
                        .frame(width: 6)
                    Spacer()
                }
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - All Caught Up Card
struct AllCaughtUpCard: View {
    var body: some View {
        VStack(spacing: LMSSpacing.sm) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundColor(LMSColors.emerald)
            
            Text("All Caught Up! 🎉")
                .font(LMSFont.subheadline.weight(.bold))
                .foregroundColor(LMSColors.textPrimary)
            
            Text("No upcoming or outstanding EMIs due for this billing cycle.")
                .font(LMSFont.caption)
                .foregroundColor(LMSColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(LMSSpacing.xxl)
        .frame(maxWidth: .infinity)
        .background(LMSColors.surfaceElevated)
        .cornerRadius(LMSRadius.card)
    }
}

// MARK: - Pending EMI Row View
struct PendingEMIRow: View {
    let emi: EMIRecord
    var onSwipePay: () -> Void
    
    var body: some View {
        HStack(spacing: LMSSpacing.lg) {
            // Due Date
            VStack(alignment: .leading, spacing: 2) {
                Text(emi.dueDate.formattedAsDDMMMYYYY())
                    .font(LMSFont.callout.weight(.bold))
                    .foregroundColor(LMSColors.textPrimary)
                Text("Due Date")
                    .font(LMSFont.caption2)
                    .foregroundColor(LMSColors.textSecondary)
            }
            
            Spacer()
            
            // Amount
            Text(emi.amount.formattedAsINR())
                .font(LMSFont.callout.weight(.bold))
                .foregroundColor(LMSColors.textPrimary)
            
            // Status Badge
            Text(emi.status == .overdue ? "Overdue" : emi.status == .dueSoon ? "Due Soon" : "Upcoming")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    emi.status == .overdue ? LMSColors.coral :
                    emi.status == .dueSoon ? LMSColors.amber : Color.gray
                )
                .cornerRadius(10)
        }
        .padding(.horizontal, LMSSpacing.lg)
        .padding(.vertical, 14)
        .contentShape(Rectangle()) // HIG tap target
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

// MARK: - Loading Skeleton
struct LoadingTrackerSkeleton: View {
    var body: some View {
        VStack(spacing: LMSSpacing.lg) {
            // KPI Tiles skeleton
            HStack(spacing: LMSSpacing.sm) {
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: LMSRadius.lg)
                        .fill(LMSColors.surfaceElevated)
                        .frame(height: 52)
                        .shimmer(active: true)
                }
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)
            
            // Big card skeleton
            RoundedRectangle(cornerRadius: LMSRadius.card)
                .fill(LMSColors.surfaceElevated)
                .frame(height: 180)
                .padding(.horizontal, LMSSpacing.screenHorizontal)
                .shimmer(active: true)
        }
    }
}
