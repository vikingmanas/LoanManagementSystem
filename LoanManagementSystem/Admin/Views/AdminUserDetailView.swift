import SwiftUI

struct AdminUserDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AdminStaffViewModel
    let member: StaffMember

    @State private var showingEditSheet = false
    @State private var isShowingDeleteConfirmation = false
    @State private var actionError: String? = nil
    @State private var isProcessing = false

    var body: some View {
        Form {
            viewFieldsSection

            if let actionError {
                Section {
                    LMSBanner(message: actionError, style: .error, icon: "exclamationmark.triangle.fill")
                        .listRowInsets(EdgeInsets())
                }
            }

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
        .navigationTitle(member.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isProcessing {
                    ProgressView()
                } else {
                    Button("Edit") {
                        showingEditSheet = true
                    }
                    .font(LMSFont.headline)
                    .foregroundStyle(LMSColors.brandNavy)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            AdminEditUserSheet(viewModel: viewModel, member: member)
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
    }

    private var viewFieldsSection: some View {
        Group {
            Section {
                HStack {
                    Spacer()
                    VStack(spacing: LMSSpacing.sm) {
                        ZStack {
                            Circle()
                                .fill(member.role.themeColor)
                            
                            Text(member.initials)
                                .font(LMSFont.largeTitle)
                                .foregroundStyle(.white)
                        }
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())

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
                LabeledRow(title: "Department", value: member.branchName ?? "Unassigned", icon: "building.2")

                if member.role == .loanOfficer {
                    LabeledRow(title: "Designation", value: member.designation ?? "Loan Officer", icon: "briefcase")
                } else if member.role == .bankManager {
                    LabeledRow(title: "Assigned Region", value: member.region ?? "General", icon: "map")
                }

                LabeledRow(title: "Registered At", value: formatDate(member.createdAt), icon: "calendar")
            }
        }
    }

    private static let sharedDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private func formatDate(_ date: Date) -> String {
        return Self.sharedDateFormatter.string(from: date)
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

struct AdminEditUserSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AdminStaffViewModel
    let member: StaffMember

    @State private var fullName = ""
    @State private var phoneNumber = ""
    @State private var status: StaffStatus = .active
    @State private var selectedBranchId: UUID? = nil
    @State private var designation = ""
    @State private var region = ""

    @State private var validationErrors: [String: String] = [:]
    @State private var actionError: String? = nil
    @State private var isProcessing = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Credentials") {
                    TextField("Full Name", text: $fullName)
                    
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)

                    Picker("Account Status", selection: $status) {
                        ForEach(StaffStatus.allCases) { statusOption in
                            Text(statusOption.displayName).tag(statusOption)
                        }
                    }
                }

                Section("Employment Details") {
                    HStack {
                        Text("Employee Code")
                        Spacer()
                        Text(member.employeeCode)
                            .foregroundStyle(.secondary)
                    }

                    if !viewModel.branches.isEmpty {
                        Picker("Department", selection: $selectedBranchId) {
                            Text("Select Department").tag(nil as UUID?)
                            ForEach(viewModel.branches) { branch in
                                Text(branch.name).tag(branch.id as UUID?)
                            }
                        }
                    }

                    if member.role == .loanOfficer {
                        TextField("Designation (e.g. Senior Underwriter)", text: $designation)
                    } else if member.role == .bankManager {
                        TextField("Assigned Region (e.g. North India)", text: $region)
                    }
                }
                
                if let actionError {
                    Section {
                        LMSBanner(message: actionError, style: .error, icon: "exclamationmark.triangle.fill")
                            .listRowInsets(EdgeInsets())
                    }
                }
            }
            .navigationTitle("Edit Staff Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isProcessing {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task {
                                await saveChanges()
                            }
                        }
                        .fontWeight(.bold)
                    }
                }
            }
            .onAppear {
                loadMemberData()
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

    private func validateForm() -> Bool {
        validationErrors.removeAll()

        if fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors["fullName"] = "Full name is required"
        }

        if phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors["phoneNumber"] = "Phone number is required"
        }

        if selectedBranchId == nil {
            validationErrors["branchId"] = "Please select a department"
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
            dismiss()
        } else {
            actionError = viewModel.errorMessage ?? "Failed to save updates."
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
