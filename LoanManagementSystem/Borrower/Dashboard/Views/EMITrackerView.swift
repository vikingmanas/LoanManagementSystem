//
//  EMITrackerView.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 19/05/26.
//

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
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("EMI Tracker")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.label))
                
                Spacer()
                
                // Month Picker Button
                Menu {
                    Picker("Select Month", selection: $selectedMonth) {
                        ForEach(months, id: \.self) { month in
                            Text(month).tag(month)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(selectedMonth)
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                }
            }
            .padding(.horizontal, 20)
            
            if viewModel.isLoading {
                // Skeleton loading state
                LoadingTrackerSkeleton()
            } else {
                VStack(spacing: 16) {
                    // 4a. KPI Status Bar
                    HStack(spacing: 12) {
                        KPITile(title: "Total EMIs", value: "24", icon: "square.grid.2x2", color: Color(.secondaryLabel), bg: Color(.secondarySystemBackground))
                        
                        // Dynamically compute count of paid vs pending from the active model list
                        let paidCount = 24 - viewModel.pendingEMIs.filter({ $0.status != .paid }).count
                        let pendingCount = viewModel.pendingEMIs.filter({ $0.status != .paid }).count
                        
                        KPITile(title: "Paid", value: "\(paidCount)", icon: "checkmark.circle.fill", color: .brandEmerald, bg: .brandEmerald.opacity(0.08))
                        
                        KPITile(title: "Pending", value: "\(pendingCount)", icon: "clock.fill", color: .brandAmber, bg: .brandAmber.opacity(0.08))
                    }
                    .padding(.horizontal, 20)
                    
                    // 4b. Highlighted Upcoming EMI Card
                    if let nextEMI = viewModel.nextEMI {
                        UpcomingEMICard(nextEMI: nextEMI, balance: viewModel.bankAccount.availableBalance, onPayTap: onPayTap)
                            .padding(.horizontal, 20)
                            .transition(.scale.combined(with: .opacity))
                    } else {
                        // All Caught Up state!
                        AllCaughtUpCard()
                            .padding(.horizontal, 20)
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // 4c. Pending EMIs list
                    let unpaidEMIs = viewModel.pendingEMIs.filter { $0.status != .paid }
                    if !unpaidEMIs.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Pending Payments")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(Color(.secondaryLabel))
                                .padding(.horizontal, 20)
                            
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
                                            .padding(.horizontal, 16)
                                    }
                                }
                            }
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                            
                            if unpaidEMIs.count > 3 {
                                Button {
                                    onViewAllPendingTap()
                                } label: {
                                    HStack {
                                        Spacer()
                                        Text("View All Pending (\(unpaidEMIs.count))")
                                            .font(.system(.callout, design: .rounded))
                                            .fontWeight(.semibold)
                                            .foregroundColor(.blue)
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
                    .font(.system(.callout, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color(.label))
                Text(title)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(Color(.secondaryLabel))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer()
        }
        .padding(10)
        .background(bg)
        .cornerRadius(16)
    }
}

// MARK: - Upcoming EMI Highlighted Card
struct UpcomingEMICard: View {
    let nextEMI: EMIRecord
    let balance: Double
    let onPayTap: () -> Void
    @State private var showingReminderAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                // Calendar icon with clock badge
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.brandAmber.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 20))
                        .foregroundColor(.brandAmber)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next EMI Due")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(Color(.secondaryLabel))
                    
                    Text(nextEMI.amount.formattedAsINR())
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(Color(.label))
                }
                
                Spacer()
                
                // Loan Type Tag
                Text(nextEMI.loanType)
                    .font(.system(.caption2, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.brandNavy)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.brandNavy.opacity(0.08))
                    .cornerRadius(10)
            }
            
            // Due alert string
            let isOverdue = nextEMI.status == .overdue
            HStack(spacing: 6) {
                Circle()
                    .fill(isOverdue ? Color.brandCoral : Color.brandAmber)
                    .frame(width: 8, height: 8)
                
                Text(isOverdue ? "Overdue! Please settle immediately" : "Due in 3 days — \(nextEMI.dueDate.formattedAsDDMMMYYYY())")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(isOverdue ? Color.brandCoral : Color(.label))
            }
            
            Divider()
            
            // Buttons Row
            HStack(spacing: 12) {
                // Set Reminder Button (Outlined)
                Button {
                    let feedback = UIImpactFeedbackGenerator(style: .light)
                    feedback.impactOccurred()
                    showingReminderAlert = true
                } label: {
                    Text("Set Reminder")
                        .font(.system(.callout, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.brandNavy)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.brandNavy, lineWidth: 1.5)
                        )
                }
                .buttonStyle(.plain)
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
                            .font(.system(.callout, design: .rounded))
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isSufficient ? Color.brandNavy : Color.gray)
                    .cornerRadius(14)
                }
                .buttonStyle(.plain)
                .disabled(!isSufficient)
            }
        }
        .padding(20)
        .background(
            ZStack {
                Color(uiColor: .systemBackground)
                
                // Left side accent border
                HStack {
                    Rectangle()
                        .fill(nextEMI.status == .overdue ? Color.brandCoral : Color.brandAmber)
                        .frame(width: 6)
                    Spacer()
                }
            }
        )
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

// MARK: - All Caught Up Card
struct AllCaughtUpCard: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 40))
                .foregroundColor(.brandEmerald)
            
            Text("All Caught Up! 🎉")
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(Color(.label))
            
            Text("No upcoming or outstanding EMIs due for this billing cycle.")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(Color(.secondaryLabel))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
    }
}

// MARK: - Pending EMI Row View
struct PendingEMIRow: View {
    let emi: EMIRecord
    var onSwipePay: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Due Date
            VStack(alignment: .leading, spacing: 2) {
                Text(emi.dueDate.formattedAsDDMMMYYYY())
                    .font(.system(.callout, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color(.label))
                Text("Due Date")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundColor(Color(.secondaryLabel))
            }
            
            Spacer()
            
            // Amount
            Text(emi.amount.formattedAsINR())
                .font(.system(.callout, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(Color(.label))
            
            // Status Badge
            Text(emi.status == .overdue ? "Overdue" : emi.status == .dueSoon ? "Due Soon" : "Upcoming")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    emi.status == .overdue ? Color.brandCoral :
                    emi.status == .dueSoon ? Color.brandAmber : Color.gray
                )
                .cornerRadius(10)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle()) // HIG tap target
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            Button {
                onSwipePay()
            } label: {
                Label("Pay", systemImage: "indianrupeesign.circle.fill")
            }
            .tint(.brandNavy)
        }
    }
}

// MARK: - Loading Skeleton
struct LoadingTrackerSkeleton: View {
    var body: some View {
        VStack(spacing: 16) {
            // KPI Tiles skeleton
            HStack(spacing: 12) {
                ForEach(0..<3) { _ in
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 52)
                        .shimmer(active: true)
                }
            }
            .padding(.horizontal, 20)
            
            // Big card skeleton
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .frame(height: 180)
                .padding(.horizontal, 20)
                .shimmer(active: true)
        }
    }
}
