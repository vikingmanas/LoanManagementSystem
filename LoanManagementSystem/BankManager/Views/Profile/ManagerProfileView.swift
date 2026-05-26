import SwiftUI


struct ManagerProfileView: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var authManager: AuthManager
    @State private var showSettingsSheet = false

    private var profile: ManagerStaffProfile {
        viewModel.managerProfile
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: LMSSpacing.xl) {


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

                            Text(profile.initials)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }

                        VStack(spacing: 4) {
                            Text(profile.name)
                                .font(.system(.title3, design: .rounded).bold())
                                .foregroundStyle(LMSColors.textPrimary)

                            Text(profile.roleTitle)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(Color(hex: "#00C48C"))

                            Text("\(profile.branchName) (\(profile.branchCode))")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, LMSSpacing.xl)
                    .background(LMSColors.surfaceElevated)
                    .clipShape(RoundedRectangle(cornerRadius: LMSRadius.xl, style: .continuous))


                    ManagerProfileSection(title: "Employee Information") {
                        ManagerProfileDetailRow(label: "EMPLOYEE ID", value: profile.employeeCode.isEmpty ? "Not assigned" : profile.employeeCode)
                        Divider().padding(.leading, LMSSpacing.lg)
                        ManagerProfileDetailRow(label: "DEPARTMENT", value: "Retail Lending Operations")
                        Divider().padding(.leading, LMSSpacing.lg)
                        ManagerProfileDetailRow(label: "ROLE LEVEL", value: profile.roleTitle)
                        Divider().padding(.leading, LMSSpacing.lg)
                        ManagerProfileDetailRow(label: "DATE OF JOINING", value: profile.joinedAt?.formattedAsDDMMMYYYY() ?? "Not available")
                        Divider().padding(.leading, LMSSpacing.lg)
                        ManagerProfileDetailRow(label: "APPROVAL QUEUE", value: "\(viewModel.pendingApplicants.count) pending")
                    }


                    ManagerProfileSection(title: "Contact Information") {
                        ManagerProfileDetailRow(label: "OFFICIAL EMAIL", value: profile.email.isEmpty ? "Not available" : profile.email)
                        Divider().padding(.leading, LMSSpacing.lg)
                        ManagerProfileDetailRow(label: "WORK PHONE", value: profile.phone.isEmpty ? "Not available" : profile.phone)
                    }


                    ManagerProfileSection(title: "Branch Performance") {
                        Grid(horizontalSpacing: LMSSpacing.md, verticalSpacing: LMSSpacing.md) {
                            GridRow {
                                ManagerStatBox(title: "STAFF MANAGED", value: "\(viewModel.officers.count)", subtitle: "Loan officers")
                                ManagerStatBox(title: "APPROVALS", value: "\(viewModel.applicants.filter { $0.status == .approved || $0.status == .disbursed }.count)", subtitle: "Current branch data")
                            }
                            GridRow {
                                ManagerStatBox(title: "PORTFOLIO VALUE", value: CurrencyFormatter.shared.format(viewModel.branchOverview.totalDisbursed), subtitle: "Total disbursed")
                                ManagerStatBox(title: "AUDIT RATING", value: viewModel.branchOverview.auditRating, subtitle: "Live risk mix")
                            }
                        }
                        .padding(.horizontal, LMSSpacing.lg)
                        .padding(.vertical, LMSSpacing.sm)
                    }


                    ManagerProfileSection(title: "System Settings") {
                        Button(action: {
                            HapticsManager.triggerImpact(style: .medium)
                            showSettingsSheet = true
                        }) {
                            HStack(spacing: LMSSpacing.md) {
                                ZStack {
                                    Circle()
                                        .fill(LMSColors.textSecondary.opacity(0.12))
                                        .frame(width: 36, height: 36)
                                    Image(systemName: "gearshape.fill")
                                        .foregroundStyle(LMSColors.textSecondary)
                                        .font(.system(size: 18))
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text("App Settings")
                                        .font(.system(.subheadline, design: .rounded).bold())
                                        .foregroundStyle(LMSColors.textPrimary)
                                    Text("Preferences and account settings")
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
                        
                        Divider().padding(.leading, LMSSpacing.lg)

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
        .sheet(isPresented: $showSettingsSheet) {
            ManagerSettingsView()
        }
    }
}


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

#Preview {
    ManagerProfileView(viewModel: PreviewSupport.managerViewModel)
        .previewManagerEnvironment()
}
