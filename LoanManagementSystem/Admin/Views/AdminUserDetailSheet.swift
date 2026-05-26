import SwiftUI

struct AdminUserDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AdminStaffViewModel
    let member: StaffMember


    @State private var isEditMode = false


    @State private var fullName = ""
    @State private var phoneNumber = ""
    @State private var status: StaffStatus = .active
    @State private var selectedBranchId: UUID? = nil
    @State private var designation = ""
    @State private var region = ""


    @State private var isShowingDeleteConfirmation = false
    @State private var validationErrors: [String: String] = [:]
    @State private var actionError: String? = nil
    @State private var isProcessing = false

    var body: some View {
        NavigationStack {
            Form {
                if isEditMode {
                    editFieldsSection
                } else {
                    viewFieldsSection
                }

                if let actionError {
                    Section {
                        LMSBanner(message: actionError, style: .error, icon: "exclamationmark.triangle.fill")
                            .listRowInsets(EdgeInsets())
                    }
                }

                if !isEditMode {
                    Section {
                        Button(role: .destructive, action: {
                            isShowingDeleteConfirmation = true
                        }) {
                            HStack {
                                Spacer()
                                Label("Delete Account", systemImage: "trash.fill")
                                    .font(LMSFont.button)
                                Spacer()
                            }
                        }
                        .listRowBackground(LMSColors.coral.opacity(0.1))
                    }
                }
            }
            .navigationTitle(isEditMode ? "Edit Staff Account" : member.fullName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if isEditMode {
                        Button("Cancel") {

                            loadMemberData()
                            isEditMode = false
                        }
                        .foregroundStyle(LMSColors.textSecondary)
                    } else {
                        Button("Close") {
                            dismiss()
                        }
                        .foregroundStyle(LMSColors.textSecondary)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if isProcessing {
                        ProgressView()
                    } else {
                        Button(isEditMode ? "Save" : "Edit") {
                            if isEditMode {
                                Task {
                                    await saveChanges()
                                }
                            } else {
                                isEditMode = true
                            }
                        }
                        .font(LMSFont.headline)
                        .foregroundStyle(LMSColors.brandNavy)
                    }
                }
            }
            .confirmationDialog(
                "Delete Staff Account",
                isPresented: $isShowingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Account Permanently", role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this staff account? This will permanently remove the login credentials and profile from Supabase. This action cannot be undone.")
            }
            .onAppear {
                loadMemberData()
            }
        }
    }


    private var viewFieldsSection: some View {
        Group {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: LMSSpacing.sm) {
                        Text(member.initials)
                            .font(LMSFont.largeTitle)
                            .foregroundStyle(.white)
                            .frame(width: 80, height: 80)
                            .background(member.role.themeColor, in: Circle())

                        Text(member.fullName)
                            .font(LMSFont.title3)
                            .foregroundStyle(LMSColors.textPrimary)

                        Text(member.role.displayName)
                            .font(LMSFont.subheadline.weight(.semibold))
                            .foregroundStyle(member.role.themeColor)
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            Section("Account Details") {
                LabeledRow(title: "Email", value: member.email, icon: "envelope")
                LabeledRow(title: "Phone", value: member.phoneNumber, icon: "phone")
                LabeledRow(
                    title: "Status",
                    value: member.status.displayName,
                    icon: "info.circle",
                    valueColor: member.status.themeColor
                )
            }

            Section("Employment Details") {
                LabeledRow(title: "Employee Code", value: member.employeeCode, icon: "number.square")
                LabeledRow(title: "Branch", value: member.branchName ?? "Unassigned", icon: "mappin.circle")

                if member.role == .loanOfficer {
                    LabeledRow(title: "Designation", value: member.designation ?? "Loan Officer", icon: "briefcase")
                } else if member.role == .bankManager {
                    LabeledRow(title: "Assigned Region", value: member.region ?? "General", icon: "map")
                }

                LabeledRow(title: "Registered At", value: formatDate(member.createdAt), icon: "calendar")
            }
        }
    }


    private var editFieldsSection: some View {
        Group {
            Section("Basic Credentials") {
                CustomTextField(
                    icon: "person.fill",
                    placeholder: "Full Name",
                    text: $fullName,
                    isError: validationErrors["fullName"] != nil,
                    errorMessage: validationErrors["fullName"] ?? ""
                )

                CustomTextField(
                    icon: "phone.fill",
                    placeholder: "Phone Number",
                    text: $phoneNumber,
                    isError: validationErrors["phoneNumber"] != nil,
                    errorMessage: validationErrors["phoneNumber"] ?? "",
                    keyboardType: .phonePad
                )

                Picker("Account Status", selection: $status) {
                    ForEach(StaffStatus.allCases) { statusOption in
                        Text(statusOption.displayName).tag(statusOption)
                    }
                }
                .font(LMSFont.body)
            }

            Section("Employment Details") {
                HStack(spacing: LMSSpacing.md) {
                    Image(systemName: "number.square.fill")
                        .foregroundStyle(LMSColors.textTertiary)
                        .frame(width: 22)
                    Text("Employee Code")
                        .font(LMSFont.body)
                        .foregroundStyle(LMSColors.textPrimary)
                    Spacer()
                    Text(member.employeeCode)
                        .font(LMSFont.body.weight(.semibold))
                        .foregroundStyle(LMSColors.textSecondary)
                }
                .padding(.horizontal, LMSSpacing.md)
                .frame(height: 44)

                if !viewModel.branches.isEmpty {
                    Picker("Assigned Branch", selection: $selectedBranchId) {
                        Text("Select Branch").tag(nil as UUID?)
                        ForEach(viewModel.branches) { branch in
                            Text(branch.name).tag(branch.id as UUID?)
                        }
                    }
                    .font(LMSFont.body)
                }

                if member.role == .loanOfficer {
                    CustomTextField(
                        icon: "briefcase.fill",
                        placeholder: "Designation",
                        text: $designation,
                        isError: validationErrors["designation"] != nil,
                        errorMessage: validationErrors["designation"] ?? ""
                    )
                } else if member.role == .bankManager {
                    CustomTextField(
                        icon: "map.fill",
                        placeholder: "Assigned Region",
                        text: $region,
                        isError: validationErrors["region"] != nil,
                        errorMessage: validationErrors["region"] ?? ""
                    )
                }
            }
        }
    }


    private func loadMemberData() {
        fullName = member.fullName
        phoneNumber = member.phoneNumber
        status = member.status
        selectedBranchId = member.branchId
        designation = member.designation ?? ""
        region = member.region ?? ""
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    private func validateForm() -> Bool {
        validationErrors.removeAll()

        if fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors["fullName"] = "Full name is required"
        }

        if phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors["phoneNumber"] = "Phone number is required"
        }

        if selectedBranchId == nil {
            validationErrors["branchId"] = "Please select a branch"
        }

        if member.role == .loanOfficer && designation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors["designation"] = "Designation is required"
        }

        if member.role == .bankManager && region.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors["region"] = "Region is required"
        }

        return validationErrors.isEmpty
    }

    private func saveChanges() async {
        guard validateForm(), let branchId = selectedBranchId else { return }

        isProcessing = true
        actionError = nil

        let success = await viewModel.updateStaff(
            id: member.id,
            role: member.role,
            fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            status: status,
            branchId: branchId,
            designation: member.role == .loanOfficer ? designation.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            region: member.role == .bankManager ? region.trimmingCharacters(in: .whitespacesAndNewlines) : nil
        )

        isProcessing = false

        if success {
            isEditMode = false
        } else {
            actionError = viewModel.errorMessage ?? "Failed to save updates."
        }
    }

    private func deleteAccount() async {
        isProcessing = true
        actionError = nil

        let success = await viewModel.deleteStaff(id: member.id)

        isProcessing = false

        if success {
            dismiss()
        } else {
            actionError = viewModel.errorMessage ?? "Failed to delete account."
        }
    }
}


private struct LabeledRow: View {
    let title: String
    let value: String
    let icon: String
    var valueColor: Color = LMSColors.textPrimary

    var body: some View {
        HStack(spacing: LMSSpacing.md) {
            Image(systemName: icon)
                .foregroundStyle(LMSColors.textTertiary)
                .frame(width: 22, alignment: .leading)

            Text(title)
                .font(LMSFont.body)
                .foregroundStyle(LMSColors.textPrimary)

            Spacer()

            Text(value)
                .font(LMSFont.body.weight(.medium))
                .foregroundStyle(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 8)
    }
}

