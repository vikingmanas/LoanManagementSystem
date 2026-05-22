import SwiftUI

struct QuickConsoleTabView: View {
    @ObservedObject var viewModel: LoanOfficerDashboardViewModel
    var onActionSelected: (String) -> Void
    
    // Live Calculator states
    @State private var principalAmount: Double = 2500000.0 // 25 Lakhs
    @State private var interestRate: Double = 8.65 // 8.65%
    @State private var tenureYears: Double = 15.0 // 15 years
    
    // Compute dynamic EMI
    private var calculatedEMI: Double {
        let monthlyRate = (interestRate / 100.0) / 12.0
        let totalMonths = tenureYears * 12.0
        
        guard monthlyRate > 0 else {
            return principalAmount / totalMonths
        }
        
        let emi = principalAmount * (monthlyRate * pow(1.0 + monthlyRate, totalMonths)) / (pow(1.0 + monthlyRate, totalMonths) - 1.0)
        return emi.isNaN ? 0.0 : emi
    }
    
    private var totalInterest: Double {
        (calculatedEMI * tenureYears * 12.0) - principalAmount
    }
    
    private var totalRepayment: Double {
        principalAmount + max(0, totalInterest)
    }
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Header Banner
                VStack(alignment: .leading, spacing: 4) {
                    Text("Operations Console")
                        .font(.system(.title3, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                    
                    Text("Select branch workspace utilities and financial simulation tools.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // 1. OPERATIONS UTILITIES GRID (2x3)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Workspace Utilities")
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                        .padding(.horizontal, 16)
                    
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ConsoleGridCard(
                            title: "New Application",
                            desc: "Onboard new customer",
                            symbol: "person.crop.circle.badge.plus",
                            color: AppTheme.successGreen
                        ) {
                            onActionSelected("new_application")
                        }
                        
                        ConsoleGridCard(
                            title: "Verify Documents",
                            desc: "Review pending KYC",
                            symbol: "doc.text.magnifyingglass",
                            color: AppTheme.actionBlue
                        ) {
                            onActionSelected("verify_documents")
                        }
                        
                        ConsoleGridCard(
                            title: "Compliance Audit",
                            desc: "Check RBI compliance",
                            symbol: "shield.checkerboard",
                            color: AppTheme.brandNavy
                        ) {
                            onActionSelected("compliance_audit")
                        }
                        
                        ConsoleGridCard(
                            title: "Branch Reports",
                            desc: "Download monthly performance",
                            symbol: "chart.bar.xaxis",
                            color: Color.purple
                        ) {
                            onActionSelected("branch_reports")
                        }
                        
                        ConsoleGridCard(
                            title: "Client Directory",
                            desc: "Browse profile databases",
                            symbol: "folder.badge.person.crop",
                            color: Color.teal
                        ) {
                            onActionSelected("client_directory")
                        }
                        
                        ConsoleGridCard(
                            title: "Escalate Case",
                            desc: "Submit query to manager",
                            symbol: "arrow.up.circle.fill",
                            color: AppTheme.criticalRed
                        ) {
                            onActionSelected("escalate_case")
                        }
                    }
                    .padding(.horizontal, 16)
                }
                
                // 2. LIVE LOAN EMI CALCULATOR WIDGET (Premium Card)
                VStack(alignment: .leading, spacing: 10) {
                    Text("Quick Financial Calculator")
                        .font(.system(.subheadline, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                        .padding(.horizontal, 16)
                    
                    VStack(spacing: 16) {
                        // Dynamic Output Metrics Display
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Monthly EMI")
                                    .font(.system(.caption, design: .rounded).bold())
                                    .foregroundStyle(LMSColors.textSecondary)
                                
                                Text(CurrencyFormatter.shared.format(calculatedEMI))
                                    .font(.system(.title, design: .rounded).bold())
                                    .foregroundStyle(AppTheme.actionBlue)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Total Interest Payable")
                                    .font(.system(.caption, design: .rounded).bold())
                                    .foregroundStyle(LMSColors.textSecondary)
                                
                                Text(CurrencyFormatter.shared.format(totalInterest))
                                    .font(.system(.body, design: .rounded).bold())
                                    .foregroundStyle(LMSColors.textPrimary)
                            }
                        }
                        .padding()
                        .background(AppTheme.actionBlue.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        
                        // Sliders Form
                        VStack(spacing: 12) {
                            // 1. Principal Amount Slider
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Principal Loan Amount")
                                        .font(.system(.caption, design: .rounded).weight(.bold))
                                    Spacer()
                                    Text(CurrencyFormatter.shared.format(principalAmount))
                                        .font(.system(.caption, design: .rounded).bold())
                                        .foregroundStyle(AppTheme.actionBlue)
                                }
                                
                                Slider(value: $principalAmount, in: 500000...10000000, step: 100000)
                                    .tint(AppTheme.actionBlue)
                            }
                            
                            // 2. Interest Rate Slider
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Interest Rate (p.a.)")
                                        .font(.system(.caption, design: .rounded).weight(.bold))
                                    Spacer()
                                    Text(String(format: "%.2f %%", interestRate))
                                        .font(.system(.caption, design: .rounded).bold())
                                        .foregroundStyle(AppTheme.actionBlue)
                                }
                                
                                Slider(value: $interestRate, in: 5.0...15.0, step: 0.05)
                                    .tint(AppTheme.actionBlue)
                            }
                            
                            // 3. Tenure Slider
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Tenure Duration")
                                        .font(.system(.caption, design: .rounded).weight(.bold))
                                    Spacer()
                                    Text("\(Int(tenureYears)) Years")
                                        .font(.system(.caption, design: .rounded).bold())
                                        .foregroundStyle(AppTheme.actionBlue)
                                }
                                
                                Slider(value: $tenureYears, in: 1...30, step: 1)
                                    .tint(AppTheme.actionBlue)
                            }
                        }
                    }
                    .padding(16)
                    .background(AppTheme.neutralSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 3)
                    .padding(.horizontal, 16)
                }
                
                Spacer()
                    .frame(height: 12)
            }
            .padding(.bottom, 24)
        }
    }
}

struct ConsoleGridCard: View {
    let title: String
    let desc: String
    let symbol: String
    let color: Color
    var onTap: () -> Void
    
    var body: some View {
        Button(action: {
            HapticsManager.triggerImpact(style: .medium)
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Top Symbol Circle
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: symbol)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(color)
                }
                
                // Title and description
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(.callout, design: .rounded).bold())
                        .foregroundStyle(LMSColors.textPrimary)
                        .multilineTextAlignment(.leading)
                    
                    Text(desc)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(LMSColors.textSecondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(AppTheme.neutralSurface)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: .black.opacity(0.02), radius: 3, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(LMSColors.textPrimary.opacity(0.04), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), action utility. \(desc)")
    }
}
