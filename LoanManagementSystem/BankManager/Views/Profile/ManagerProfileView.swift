import SwiftUI


struct ManagerProfileView: View {
    @ObservedObject var viewModel: ManagerDashboardViewModel
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var authManager: AuthManager

    @State private var showChangePassword = false
    @AppStorage("isDarkMode") private var isDarkMode = false

    private var profile: ManagerStaffProfile {
        viewModel.managerProfile
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: LMSSpacing.md) {
                        ZStack {
                            Circle()
                                .fill(LMSColors.brandNavy.gradient)
                                .frame(width: 80, height: 80)
                            
                            Text(profile.initials)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        .padding(.top, LMSSpacing.md)

                        VStack(spacing: 4) {
                            Text(profile.name)
                                .font(.title3.bold())
                                .foregroundStyle(Color(.label))

                            Text(profile.roleTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(LMSColors.brandNavy)

                            Text("\(profile.branchName) (\(profile.branchCode))")
                                .font(.caption)
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                        .padding(.bottom, LMSSpacing.md)
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                Section("Branch Performance") {
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            StatPill(title: "Staff", value: "\(viewModel.officers.count)", icon: "person.2.fill", color: .blue)
                            StatPill(title: "Approvals", value: "\(viewModel.applicants.filter { $0.status == .approved || $0.status == .disbursed }.count)", icon: "checkmark.circle.fill", color: .green)
                        }
                        HStack(spacing: 16) {
                            StatPill(title: "Portfolio", value: viewModel.branchOverview.totalDisbursed.formattedAsCompactINR(), icon: "indianrupeesign.circle.fill", color: .orange)
                            StatPill(title: "Rating", value: viewModel.branchOverview.auditRating, icon: "shield.fill", color: .purple)
                        }
                    }
                    .padding(.vertical, 8)
                }

                Section("Employee Information") {
                    LabeledContent("Employee ID", value: profile.employeeCode.isEmpty ? "Not assigned" : profile.employeeCode)
                    LabeledContent("Department", value: "Retail Lending")
                    LabeledContent("Role Level", value: profile.roleTitle)
                    LabeledContent("Joined", value: profile.joinedAt?.formattedAsDDMMMYYYY() ?? "N/A")
                }

                Section("Contact Information") {
                    LabeledContent("Official Email", value: profile.email)
                    LabeledContent("Work Phone", value: profile.phone)
                }

                Section("System Settings") {
                    NavigationLink {
                        ManagerSettingsView()
                    } label: {
                        Label("App Settings", systemImage: "gearshape.fill")
                    }
                    .foregroundStyle(Color(.label))

                    Button {
                        showChangePassword = true
                    } label: {
                        Label("Change Password", systemImage: "lock.fill")
                    }
                    .foregroundStyle(Color(.label))


                }

                Section {
                    Button(role: .destructive) {
                        HapticsManager.triggerImpact(style: .medium)
                        dismiss()
                        appState.logout()
                        authManager.signOut()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Log Out Session")
                                .bold()
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .bold()
                }
            }
        }
        .preferredColorScheme(isDarkMode ? .dark : .light)
        .accessibleSheet(isPresented: $showChangePassword) {
            ChangePasswordSheet()
        }

    }
}

private struct StatPill: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color(.secondaryLabel))
                    .textCase(.uppercase)
            }
            
            Text(value)
                .font(.headline.bold())
                .foregroundStyle(Color(.label))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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

