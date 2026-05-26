import SwiftUI

struct AdminAddUserSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AdminStaffViewModel


    @State private var email = ""
    @State private var password = ""
    @State private var role: StaffRole = .loanOfficer
    @State private var fullName = ""
    @State private var phoneNumber = ""
    @State private var selectedBranchId: UUID? = nil
    @State private var employeeCode = ""
    @State private var designation = ""
    @State private var region = ""


    @State private var validationErrors: [String: String] = [:]
    @State private var submissionError: String? = nil
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Select Role", selection: $role) {
                        Text("Loan Officer").tag(StaffRole.loanOfficer)
                        Text("Bank Manager").tag(StaffRole.bankManager)
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .padding(.bottom, LMSSpacing.sm)

                    CustomTextField(
                        icon: "person.fill",
                        placeholder: "Full Name",
                        text: $fullName,
                        isError: validationErrors["fullName"] != nil,
                        errorMessage: validationErrors["fullName"] ?? ""
                    )

                    CustomTextField(
                        icon: "envelope.fill",
                        placeholder: "Email Address",
                        text: $email,
                        isError: validationErrors["email"] != nil,
                        errorMessage: validationErrors["email"] ?? "",
                        keyboardType: .emailAddress
                    )

                    SecureInputField(
                        placeholder: "Login Password",
                        text: $password,
                        isError: validationErrors["password"] != nil,
                        errorMessage: validationErrors["password"] ?? ""
                    )

                    CustomTextField(
                        icon: "phone.fill",
                        placeholder: "Phone Number",
                        text: $phoneNumber,
                        isError: validationErrors["phoneNumber"] != nil,
                        errorMessage: validationErrors["phoneNumber"] ?? "",
                        keyboardType: .phonePad
                    )
                } header: {
                    Text("Basic Credentials")
                        .font(LMSFont.caption.weight(.bold))
                }

                Section {
                    CustomTextField(
                        icon: "card.fill",
                        placeholder: "Employee Code",
                        text: $employeeCode,
                        isError: validationErrors["employeeCode"] != nil,
                        errorMessage: validationErrors["employeeCode"] ?? ""
                    )

                    if !viewModel.branches.isEmpty {
                        Picker("Assigned Branch", selection: $selectedBranchId) {
                            Text("Select Branch").tag(nil as UUID?)
                            ForEach(viewModel.branches) { branch in
                                Text(branch.name).tag(branch.id as UUID?)
                            }
                        }
                        .font(LMSFont.body)
                        .foregroundStyle(LMSColors.textPrimary)
                    } else if viewModel.isLoading {
                        Text("Loading branches...")
                            .font(LMSFont.footnote)
                            .foregroundStyle(LMSColors.textSecondary)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("No branches loaded")
                                .font(LMSFont.footnote.weight(.semibold))
                                .foregroundStyle(LMSColors.coral)
                            if let errorMsg = viewModel.errorMessage {
                                Text(errorMsg)
                                    .font(LMSFont.caption)
                                    .foregroundStyle(LMSColors.textSecondary)
                            }
                        }
                    }

                    if let branchError = validationErrors["branchId"] {
                        HStack(spacing: LMSSpacing.xs) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 11))
                            Text(branchError)
                                .font(LMSFont.caption)
                        }
                        .foregroundStyle(LMSColors.coral)
                        .padding(.leading, LMSSpacing.xs)
                    }

                    if role == .loanOfficer {
                        CustomTextField(
                            icon: "briefcase.fill",
                            placeholder: "Designation (e.g. Senior Underwriter)",
                            text: $designation,
                            isError: validationErrors["designation"] != nil,
                            errorMessage: validationErrors["designation"] ?? ""
                        )
                    } else if role == .bankManager {
                        CustomTextField(
                            icon: "map.fill",
                            placeholder: "Assigned Region (e.g. North India)",
                            text: $region,
                            isError: validationErrors["region"] != nil,
                            errorMessage: validationErrors["region"] ?? ""
                        )
                    }
                } header: {
                    Text("Employment Details")
                        .font(LMSFont.caption.weight(.bold))
                }

                if let submissionError {
                    Section {
                        LMSBanner(message: submissionError, style: .error, icon: "exclamationmark.triangle.fill")
                            .listRowInsets(EdgeInsets())
                    }
                }
            }
            .navigationTitle("Create Staff Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(LMSColors.textSecondary)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if isSubmitting {
                        ProgressView()
                    } else {
                        Button("Save") {
                            Task {
                                await submitForm()
                            }
                        }
                        .font(LMSFont.headline)
                        .foregroundStyle(LMSColors.brandNavy)
                    }
                }
            }
            .task {
                if viewModel.branches.isEmpty {
                    await viewModel.loadData()
                }

                if selectedBranchId == nil, let firstBranch = viewModel.branches.first {
                    selectedBranchId = firstBranch.id
                }
            }
        }
    }


    private func validateForm() -> Bool {
        validationErrors.removeAll()

        if fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors["fullName"] = "Full name is required"
        }

        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedEmail.isEmpty {
            validationErrors["email"] = "Email address is required"
        } else if !cleanedEmail.contains("@") || !cleanedEmail.contains(".") {
            validationErrors["email"] = "Enter a valid email address"
        }

        if password.count < 6 {
            validationErrors["password"] = "Password must be at least 6 characters"
        }

        if phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors["phoneNumber"] = "Phone number is required"
        }

        if employeeCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors["employeeCode"] = "Employee code is required"
        }

        if selectedBranchId == nil {
            validationErrors["branchId"] = "Please select a branch"
        }

        if role == .loanOfficer && designation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors["designation"] = "Designation is required"
        }

        if role == .bankManager && region.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors["region"] = "Region is required"
        }

        return validationErrors.isEmpty
    }

    private func submitForm() async {
        guard validateForm(), let branchId = selectedBranchId else { return }

        isSubmitting = true
        submissionError = nil

        let payload = AdminStaffService.CreateStaffPayload(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            password: password,
            role: role.rawValue,
            fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
            phoneNumber: phoneNumber.trimmingCharacters(in: .whitespacesAndNewlines),
            branchId: branchId,
            employeeCode: employeeCode.trimmingCharacters(in: .whitespacesAndNewlines),
            designation: role == .loanOfficer ? designation.trimmingCharacters(in: .whitespacesAndNewlines) : nil,
            region: role == .bankManager ? region.trimmingCharacters(in: .whitespacesAndNewlines) : nil
        )

        let success = await viewModel.createStaff(payload: payload)

        isSubmitting = false

        if success {
            dismiss()
        } else {
            submissionError = viewModel.errorMessage ?? "An error occurred while creating the account."
        }
    }
}

