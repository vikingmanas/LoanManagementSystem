import SwiftUI

struct LoanOfficerProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {


                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [AppTheme.brandNavy, AppTheme.actionBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                                .shadow(color: AppTheme.actionBlue.opacity(0.2), radius: 8, x: 0, y: 4)

                            Text("AK")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        VStack(spacing: 4) {
                            Text("Arjun Kashyap")
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundStyle(LMSColors.textPrimary)

                            Text("Senior Loan Officer")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(AppTheme.actionBlue)

                            Text("Bengaluru Central Branch (ID: BR-492)")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(AppTheme.neutralSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .padding(.horizontal, 16)


                    VStack(alignment: .leading, spacing: 12) {
                        Text("Employee Information")
                            .font(.system(.caption, design: .rounded).bold())
                            .foregroundStyle(LMSColors.textSecondary)
                            .padding(.leading, 20)

                        VStack(spacing: 0) {
                            ProfileDetailRow(label: "EMPLOYEE ID", value: "EMP-2024-9021")
                            Divider().padding(.leading, 16)
                            ProfileDetailRow(label: "DEPARTMENT", value: "Retail Lending Operations")
                            Divider().padding(.leading, 16)
                            ProfileDetailRow(label: "ROLE LEVEL", value: "L3 Administrator")
                            Divider().padding(.leading, 16)
                            ProfileDetailRow(label: "DATE OF JOINING", value: "15 Mar 2021")
                        }
                        .background(AppTheme.neutralSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, 16)
                    }


                    VStack(alignment: .leading, spacing: 12) {
                        Text("Contact Information")
                            .font(.system(.caption, design: .rounded).bold())
                            .foregroundStyle(LMSColors.textSecondary)
                            .padding(.leading, 20)

                        VStack(spacing: 0) {
                            ProfileDetailRow(label: "OFFICIAL EMAIL", value: "arjun.kashyap@astrabank.com")
                            Divider().padding(.leading, 16)
                            ProfileDetailRow(label: "WORK PHONE", value: "+91 80 4991 2099")
                        }
                        .background(AppTheme.neutralSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, 16)
                    }


                    VStack(alignment: .leading, spacing: 12) {
                        Text("Performance & Operations")
                            .font(.system(.caption, design: .rounded).bold())
                            .foregroundStyle(LMSColors.textSecondary)
                            .padding(.leading, 20)

                        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                            GridRow {
                                MetricBox(title: "LOANS VERIFIED", value: "482", subtitle: "Year to Date")
                                MetricBox(title: "ACCURACY RATE", value: "98.7%", subtitle: "Audit Score")
                            }
                            GridRow {
                                MetricBox(title: "PORTFOLIO CAP", value: "₹ 12.8 Cr", subtitle: "Active Limit")
                                MetricBox(title: "AVG. CYCLE TIME", value: "1.8 Days", subtitle: "TAT Score")
                            }
                        }
                        .padding(.horizontal, 16)
                    }


                    VStack(alignment: .leading, spacing: 12) {
                        Text("System Settings")
                            .font(.system(.caption, design: .rounded).bold())
                            .foregroundStyle(LMSColors.textSecondary)
                            .padding(.leading, 20)

                        VStack(spacing: 0) {
                            Button(action: {
                                HapticsManager.triggerImpact(style: .heavy)
                                NotificationCenter.default.post(name: NSNotification.Name("SwitchRoleToBorrower"), object: nil)
                                dismiss()
                            }) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(AppTheme.actionBlue.opacity(0.12))
                                            .frame(width: 36, height: 36)

                                        Image(systemName: "arrow.left.arrow.right.circle.fill")
                                            .foregroundStyle(AppTheme.actionBlue)
                                            .font(LMSFont.title3)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Switch to Borrower Mode")
                                            .font(.system(.subheadline, design: .rounded).bold())
                                            .foregroundStyle(LMSColors.textPrimary)
                                        Text("Access simulation client interface")
                                            .font(.system(size: 10))
                                            .foregroundStyle(LMSColors.textSecondary)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(LMSFont.caption.bold())
                                        .foregroundStyle(LMSColors.textSecondary)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                            }
                        }
                        .background(AppTheme.neutralSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal, 16)
                    }


                    Button(action: {
                        HapticsManager.triggerImpact(style: .medium)
                        dismiss()
                        appState.logout()
                        authManager.signOut()
                    }) {
                        Text("Log Out Session")
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundStyle(AppTheme.criticalRed)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.criticalRed.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    Spacer()
                        .frame(height: 16)
                }
                .padding(.vertical, 16)
            }
            .background(AppTheme.background)
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}



struct ProfileDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(LMSColors.textSecondary)
            Spacer()
            Text(value)
                .font(.system(.footnote, design: .rounded).bold())
                .foregroundStyle(LMSColors.textPrimary)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 16)
    }
}

struct MetricBox: View {
    let title: String
    let value: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 8, weight: .bold, design: .rounded))
                .foregroundStyle(LMSColors.textSecondary)

            Text(value)
                .font(.system(.title2, design: .rounded).bold())
                .foregroundStyle(AppTheme.brandNavy)

            Text(subtitle)
                .font(.system(size: 9))
                .foregroundStyle(LMSColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.neutralSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    LoanOfficerProfileView()
        .previewLoanOfficerEnvironment()
}

