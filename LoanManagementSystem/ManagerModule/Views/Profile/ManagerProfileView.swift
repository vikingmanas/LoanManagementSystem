import SwiftUI

// MARK: - Manager Profile View
struct ManagerProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: LMSSpacing.xl) {

                    // MARK: 1 — Profile Header Card
                    VStack(spacing: LMSSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "#00C48C"), Color(hex: "#009E70")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: Color(hex: "#00C48C").opacity(0.25), radius: 8, x: 0, y: 4)

                            Text(ManagerMockData.managerInitials)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        VStack(spacing: 4) {
                            Text(ManagerMockData.managerName)
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundStyle(LMSColors.textPrimary)

                            Text("Branch Manager")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(Color(hex: "#00C48C"))

                            Text("\(ManagerMockData.branchName) (\(ManagerMockData.branchCode))")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LMSSpacing.xl)
                    .background(LMSColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: LMSRadius.xl, style: .continuous))

                    // MARK: 2 — Employee Details
                    ManagerProfileSection(title: "Employee Information") {
                        ManagerProfileDetailRow(label: "EMPLOYEE ID", value: ManagerMockData.employeeId)
                        Divider().padding(.leading, LMSSpacing.lg)
                        ManagerProfileDetailRow(label: "DEPARTMENT", value: "Retail Lending Operations")
                        Divider().padding(.leading, LMSSpacing.lg)
                        ManagerProfileDetailRow(label: "ROLE LEVEL", value: "BM-L5 (Branch Head)")
                        Divider().padding(.leading, LMSSpacing.lg)
                        ManagerProfileDetailRow(label: "DATE OF JOINING", value: "12 Sep 2016")
                        Divider().padding(.leading, LMSSpacing.lg)
                        ManagerProfileDetailRow(label: "APPROVAL AUTHORITY", value: "Up to ₹1 Cr")
                    }

                    // MARK: 3 — Contact Details
                    ManagerProfileSection(title: "Contact Information") {
                        ManagerProfileDetailRow(label: "OFFICIAL EMAIL", value: "ramanathan.swamy@astrabank.com")
                        Divider().padding(.leading, LMSSpacing.lg)
                        ManagerProfileDetailRow(label: "WORK PHONE", value: "+91 80 4112 9900")
                    }

                    // MARK: 4 — Branch Performance Stats
                    ManagerProfileSection(title: "Branch Performance") {
                        Grid(horizontalSpacing: LMSSpacing.md, verticalSpacing: LMSSpacing.md) {
                            GridRow {
                                ManagerStatBox(title: "STAFF MANAGED", value: "18", subtitle: "Officers & Support")
                                ManagerStatBox(title: "APPROVALS YTD", value: "187", subtitle: "Year to Date")
                            }
                            GridRow {
                                ManagerStatBox(title: "PORTFOLIO VALUE", value: "₹4.8 Cr", subtitle: "Total Disbursed")
                                ManagerStatBox(title: "AUDIT RATING", value: "A+", subtitle: "Last Quarter")
                            }
                        }
                        .padding(.horizontal, LMSSpacing.lg)
                        .padding(.vertical, LMSSpacing.sm)
                    }

                    // MARK: 5 — Role Switch
                    ManagerProfileSection(title: "System Settings") {
                        Button(action: {
                            HapticsManager.triggerImpact(style: .heavy)
                            NotificationCenter.default.post(name: NSNotification.Name("SwitchRoleToBorrower"), object: nil)
                            dismiss()
                        }) {
                            HStack(spacing: LMSSpacing.md) {
                                ZStack {
                                    Circle()
                                        .fill(LMSColors.actionBlue.opacity(0.12))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "arrow.left.arrow.right.circle.fill")
                                        .foregroundStyle(LMSColors.actionBlue)
                                        .font(.system(size: 18))
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
                                    .font(.system(.caption, design: .rounded).bold())
                                    .foregroundStyle(LMSColors.textSecondary)
                            }
                            .padding(.vertical, LMSSpacing.md)
                            .padding(.horizontal, LMSSpacing.lg)
                        }
                    }

                    // MARK: 6 — Logout
                    Button(action: {
                        HapticsManager.triggerImpact(style: .medium)
                        dismiss()
                        appState.logout()
                        authManager.signOut()
                    }) {
                        Text("Log Out Session")
                            .font(.system(.subheadline, design: .rounded).bold())
                            .foregroundStyle(LMSColors.coral)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(LMSColors.coral.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                    }
                    .padding(.top, LMSSpacing.sm)

                    Spacer().frame(height: LMSSpacing.lg)
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)
                .padding(.vertical, LMSSpacing.lg)
            }
            .background(LMSColors.background)
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(.body, design: .rounded).bold())
                }
            }
        }
    }
}

// MARK: - Profile Section Container
private struct ManagerProfileSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
            Text(title)
                .font(.system(.caption, design: .rounded).bold())
                .foregroundStyle(LMSColors.textSecondary)
                .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .background(LMSColors.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        }
    }
}

// MARK: - Profile Detail Row
private struct ManagerProfileDetailRow: View {
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
        .padding(.horizontal, LMSSpacing.lg)
    }
}

// MARK: - Profile Stat Box
private struct ManagerStatBox: View {
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
                .foregroundStyle(LMSColors.brandNavy)
            Text(subtitle)
                .font(.system(size: 9))
                .foregroundStyle(LMSColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LMSSpacing.md)
        .background(LMSColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
    }
}
