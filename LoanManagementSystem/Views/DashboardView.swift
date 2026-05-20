import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showPayEMISheet = false
    @State private var showApplyLoanSheet = false
    @State private var mockEmiSuccess = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.AppTheme.background.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Updating Dashboard...")
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.AppTheme.primary))
                } else {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 20) {
                            // 1. Welcome Header
                            welcomeHeaderSection
                            
                            // 2. Active Loan Overview Card
                            activeLoanCardSection
                            
                            // 3. Quick Actions Grid
                            quickActionsSection
                            
                            // 4. Credit Score & Eligibility Card
                            creditScoreSection
                            
                            // 5. Recent Transactions / Activities
                            recentActivitySection
                            
                            Spacer().frame(height: 20)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                    }
                }
            }
            .navigationTitle("LMS Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .hideNavigationBar()
            .sheet(isPresented: $showPayEMISheet) {
                payEMISheetView
            }
            .sheet(isPresented: $showApplyLoanSheet) {
                applyLoanSheetView
            }
        }
    }
    
    // MARK: - 1. Welcome Header
    private var welcomeHeaderSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome Back,")
                    .font(Font.AppTheme.caption)
                    .foregroundColor(Color.AppTheme.textSecondary)
                Text("Rahul Sharma")
                    .font(Font.system(size: 24, weight: .bold))
                    .foregroundColor(Color.AppTheme.textPrimary)
            }
            
            Spacer()
            
            // Bell Notification Button
            Button(action: {
                // Future notification view trigger
            }) {
                ZStack {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.AppTheme.primary)
                        .padding(10)
                        .background(Color.AppTheme.secondary)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.04), radius: 5, x: 0, y: 3)
                    
                    Circle()
                        .fill(Color.AppTheme.error)
                        .frame(width: 8, height: 8)
                        .offset(x: 8, y: -8)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - 2. Active Loan Card
    private var activeLoanCardSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACTIVE LOAN BALANCE")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color.AppTheme.primary)
                    Text(viewModel.formatCurrency(viewModel.remainingBalance))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color.AppTheme.textPrimary)
                }
                Spacer()
                
                Text(viewModel.activeLoansCount > 0 ? "Active" : "No Loans")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.AppTheme.success.opacity(0.12))
                    .foregroundColor(Color.AppTheme.success)
                    .cornerRadius(8)
            }
            
            // Repayment Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Repayment Progress")
                        .font(Font.AppTheme.caption)
                        .foregroundColor(Color.AppTheme.textSecondary)
                    Spacer()
                    Text("\(Int(viewModel.repaymentProgress * 100))% Paid")
                        .font(Font.AppTheme.caption)
                        .foregroundColor(Color.AppTheme.textPrimary)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.AppTheme.textSecondary.opacity(0.15))
                            .frame(height: 8)
                        
                        Capsule()
                            .fill(LinearGradient(gradient: Gradient(colors: [Color.AppTheme.primary, Color.AppTheme.primary.opacity(0.75)]), startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * CGFloat(viewModel.repaymentProgress), height: 8)
                    }
                }
                .frame(height: 8)
            }
            
            Divider()
            
            // Next EMI Due Info
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next EMI Amount")
                        .font(Font.AppTheme.caption)
                        .foregroundColor(Color.AppTheme.textSecondary)
                    Text(viewModel.formatCurrency(viewModel.emiAmount))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.AppTheme.textPrimary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Due Date")
                        .font(Font.AppTheme.caption)
                        .foregroundColor(Color.AppTheme.textSecondary)
                    Text(viewModel.formatDate(viewModel.nextEmiDate))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color.AppTheme.error)
                }
            }
        }
        .padding(20)
        .background(Color.AppTheme.secondary)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - 3. Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.AppTheme.textPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Action 1: Apply for Loan
                Button(action: {
                    showApplyLoanSheet = true
                }) {
                    quickActionCard(
                        title: "Apply Loan",
                        subtitle: "Check Eligibility",
                        icon: "doc.badge.plus",
                        color: Color.AppTheme.primary
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                // Action 2: Pay EMI
                Button(action: {
                    showPayEMISheet = true
                }) {
                    quickActionCard(
                        title: "Pay EMI",
                        subtitle: "Instant Repayment",
                        icon: "indianrupeesign.circle.fill",
                        color: Color.AppTheme.success
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private func quickActionCard(title: String, subtitle: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18, weight: .medium))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.AppTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(Color.AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.AppTheme.secondary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 3)
    }
    
    // MARK: - 4. Credit Score Section
    private var creditScoreSection: some View {
        HStack(spacing: 20) {
            // Circular Arc Gauge
            ZStack {
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Color.AppTheme.textSecondary.opacity(0.15), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(135))
                
                Circle()
                    .trim(from: 0, to: 0.75 * CGFloat(Double(viewModel.creditScore) / 900.0))
                    .stroke(
                        LinearGradient(gradient: Gradient(colors: [Color.orange, Color.AppTheme.success]), startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(135))
                
                VStack(spacing: 2) {
                    Text("\(viewModel.creditScore)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(Color.AppTheme.textPrimary)
                    Text("CIBIL")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(Color.AppTheme.textSecondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Excellent Credit Profile")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(Color.AppTheme.textPrimary)
                Text("Congratulations! Your score places you in the highest loan eligibility bracket with lower interest rates.")
                    .font(.system(size: 11))
                    .foregroundColor(Color.AppTheme.textSecondary)
                    .lineLimit(3)
            }
            Spacer()
        }
        .padding(16)
        .background(Color.AppTheme.secondary)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - 5. Recent Activity Section
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.AppTheme.textPrimary)
                Spacer()
            }
            
            if viewModel.recentTransactions.isEmpty {
                Text("No recent transaction logs.")
                    .font(Font.AppTheme.body)
                    .foregroundColor(Color.AppTheme.textSecondary)
                    .padding(.vertical, 10)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentTransactions) { tx in
                        transactionRow(tx)
                        if tx.id != viewModel.recentTransactions.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .background(Color.AppTheme.secondary)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
            }
        }
    }
    
    private func transactionRow(_ tx: DashboardTransaction) -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(transactionColor(tx).opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: transactionIcon(tx))
                    .foregroundColor(transactionColor(tx))
                    .font(.system(size: 16, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(tx.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.AppTheme.textPrimary)
                Text(tx.description)
                    .font(.system(size: 11))
                    .foregroundColor(Color.AppTheme.textSecondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(transactionSign(tx) + viewModel.formatCurrency(tx.amount))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(transactionColor(tx))
                Text(viewModel.formatDate(tx.date))
                    .font(.system(size: 10))
                    .foregroundColor(Color.AppTheme.textSecondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func transactionIcon(_ tx: DashboardTransaction) -> String {
        switch tx.type {
        case .repayment: return "arrow.up.circle.fill"
        case .disbursement: return "arrow.down.circle.fill"
        case .processingFee: return "checkmark.seal.fill"
        }
    }
    
    private func transactionColor(_ tx: DashboardTransaction) -> Color {
        switch tx.type {
        case .repayment: return Color.AppTheme.success
        case .disbursement: return Color.AppTheme.primary
        case .processingFee: return Color.gray
        }
    }
    
    private func transactionSign(_ tx: DashboardTransaction) -> String {
        switch tx.type {
        case .repayment: return "-"
        case .disbursement: return "+"
        case .processingFee: return "-"
        }
    }
    
    // MARK: - Pay EMI Sheet
    private var payEMISheetView: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.system(size: 72))
                    .foregroundColor(Color.AppTheme.success)
                    .padding(.top, 40)
                
                VStack(spacing: 8) {
                    Text("Repay EMI")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Select a payment mode to disburse the installment.")
                        .font(.subheadline)
                        .foregroundColor(Color.AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    paymentDetailRow(label: "Loan ID", value: "#L-890214")
                    paymentDetailRow(label: "EMI Amount", value: viewModel.formatCurrency(viewModel.emiAmount))
                    paymentDetailRow(label: "Payee Name", value: "Rahul Sharma")
                    paymentDetailRow(label: "Debiting Bank Account", value: "HDFC Bank (•••• 7890)")
                }
                .padding(20)
                .background(Color.AppTheme.background)
                .cornerRadius(12)
                .padding(.horizontal, 24)
                
                Spacer()
                
                if mockEmiSuccess {
                    Text("Payment Completed Successfully!")
                        .foregroundColor(Color.AppTheme.success)
                        .fontWeight(.semibold)
                        .padding()
                } else {
                    Button(action: {
                        withAnimation {
                            mockEmiSuccess = true
                            viewModel.remainingBalance -= viewModel.emiAmount
                            viewModel.totalRepaid += viewModel.emiAmount
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showPayEMISheet = false
                            mockEmiSuccess = false
                        }
                    }) {
                        Text("Pay Now")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.AppTheme.success)
                            .cornerRadius(12)
                            .padding(.horizontal, 24)
                    }
                }
            }
            .navigationTitle("Pay EMI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showPayEMISheet = false
                    }
                }
            }
        }
    }
    
    private func paymentDetailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(Color.AppTheme.textSecondary)
                .font(.system(size: 14))
            Spacer()
            Text(value)
                .foregroundColor(Color.AppTheme.textPrimary)
                .fontWeight(.medium)
                .font(.system(size: 14))
        }
    }
    
    // MARK: - Apply Loan Sheet
    private var applyLoanSheetView: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "doc.text.fill.badge.plus")
                    .font(.system(size: 72))
                    .foregroundColor(Color.AppTheme.primary)
                    .padding(.top, 40)
                
                VStack(spacing: 8) {
                    Text("Apply for a New Loan")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Submit application forms for personal or auto financing.")
                        .font(.subheadline)
                        .foregroundColor(Color.AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                
                VStack(alignment: .leading, spacing: 20) {
                    Text("Choose Loan Type")
                        .font(.headline)
                    
                    loanTypeCard(title: "Personal Loan", rate: "10.5% p.a.", icon: "person.fill")
                    loanTypeCard(title: "Home Loan", rate: "8.5% p.a.", icon: "house.fill")
                    loanTypeCard(title: "Auto Loan", rate: "9.2% p.a.", icon: "car.fill")
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                Button(action: {
                    showApplyLoanSheet = false
                }) {
                    Text("Close")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.AppTheme.primary)
                        .cornerRadius(12)
                        .padding(.horizontal, 24)
                }
            }
            .navigationTitle("Apply Loan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showApplyLoanSheet = false
                    }
                }
            }
        }
    }
    
    private func loanTypeCard(title: String, rate: String, icon: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(Color.AppTheme.primary)
                .font(.system(size: 24))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.medium)
                Text("Interest starting at \(rate)")
                    .font(.caption)
                    .foregroundColor(Color.AppTheme.textSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(Color.AppTheme.textSecondary)
                .font(.caption)
        }
        .padding()
        .background(Color.AppTheme.secondary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.02), radius: 5, x: 0, y: 3)
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
