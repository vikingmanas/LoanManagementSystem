import SwiftUI

private enum AddEntityType: String, CaseIterable {
    case loanOfficer = "Loan Officer"
    case bankManager = "Bank Manager"
    case bankBranch = "Bank Branch"
}

struct AdminAddUserSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: AdminStaffViewModel

    @State private var entityType: AddEntityType = .loanOfficer

    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var phoneNumber = ""
    @State private var selectedBranchId: UUID? = nil
    @State private var employeeCode = ""
    @State private var designation = ""
    @State private var region = ""

    @State private var dateOfBirth = Date()
    @State private var dateOfJoining = Date()
    @State private var address = ""
    @State private var baseSalary = ""
    @State private var employmentType = "Full-Time"
    let employmentTypes = ["Full-Time", "Part-Time", "Contract", "Intern"]

    @State private var branchName = ""
    @State private var branchCode = ""
    @State private var branchRegion = ""
    @State private var branchAddress = ""
    @State private var branchCity = ""
    @State private var branchState = ""
    @State private var branchPincode = ""
    @State private var branchContactNumber = ""
    @State private var branchEmail = ""
    @State private var branchIFSC = ""

    @State private var validationErrors: [String: String] = [:]
    @State private var submissionError: String? = nil
    @State private var isSubmitting = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Select Type", selection: $entityType) {
                        ForEach(AddEntityType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                    .padding(.bottom, LMSSpacing.sm)
                } header: {
                    Text("Create")
                        .font(LMSFont.caption.weight(.bold))
                }

                if entityType == .bankBranch {
                    branchFormSections
                } else {
                    staffFormSections
                }

                if let submissionError {
                    Section {
                        LMSBanner(message: submissionError, style: .error, icon: "exclamationmark.triangle.fill")
                            .listRowInsets(EdgeInsets())
                    }
                }
            }
            .navigationTitle(entityType == .bankBranch ? "Add Branch" : "Create Staff Account")
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
                                if entityType == .bankBranch {
                                    await submitBranch()
                                } else {
                                    await submitStaff()
                                }
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


    @ViewBuilder
    private var branchFormSections: some View {
        Section {
            TextField("Branch Name", text: $branchName)
            TextField("Branch Code (e.g. BR-006)", text: $branchCode)
                .autocapitalization(.allCharacters)
        } header: {
            Text("Branch Identity")
                .font(LMSFont.caption.weight(.bold))
        }

        Section {
            TextField("Full Address", text: $branchAddress)
            TextField("City", text: $branchCity)
            TextField("State", text: $branchState)
            TextField("Pincode", text: $branchPincode)
                .keyboardType(.numberPad)
            Picker("Region", selection: $branchRegion) {
                Text("Select Region").tag("")
                Text("North").tag("North")
                Text("South").tag("South")
                Text("East").tag("East")
                Text("West").tag("West")
                Text("Central").tag("Central")
                Text("National").tag("National")
            }
        } header: {
            Text("Location Details")
                .font(LMSFont.caption.weight(.bold))
        }

        Section {
            TextField("Contact Number", text: $branchContactNumber)
                .keyboardType(.phonePad)
            TextField("Branch Email", text: $branchEmail)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            TextField("IFSC Code (Optional)", text: $branchIFSC)
                .autocapitalization(.allCharacters)
        } header: {
            Text("Contact Information")
                .font(LMSFont.caption.weight(.bold))
        }
    }


    @ViewBuilder
    private var staffFormSections: some View {
        Section {
            TextField("Full Name", text: $fullName)

            TextField("Email Address", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)

            SecureField("Login Password", text: $password)

            TextField("Phone Number", text: $phoneNumber)
                .keyboardType(.phonePad)
        } header: {
            Text("Basic Credentials")
                .font(LMSFont.caption.weight(.bold))
        }

        Section {
            DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
            TextField("Full Address", text: $address)
        } header: {
            Text("Personal Details")
                .font(LMSFont.caption.weight(.bold))
        }

        Section {
            TextField("Employee Code", text: $employeeCode)

            if !viewModel.branches.isEmpty {
                Picker("Branch", selection: $selectedBranchId) {
                    Text("Select Branch").tag(nil as UUID?)
                    ForEach(viewModel.branches) { branch in
                        Text(branch.name).tag(branch.id as UUID?)
                    }
                }
            } else if viewModel.isLoading {
                Text("Loading branches...")
                    .foregroundStyle(.secondary)
            }

            if entityType == .loanOfficer {
                TextField("Designation (e.g. Senior Underwriter)", text: $designation)
            } else if entityType == .bankManager {
                TextField("Assigned Region (e.g. North India)", text: $region)
            }

            Picker("Employment Type", selection: $employmentType) {
                ForEach(employmentTypes, id: \.self) { type in
                    Text(type).tag(type)
                }
            }

            DatePicker("Date of Joining", selection: $dateOfJoining, displayedComponents: .date)

            HStack {
                Text("Base Salary (₹)")
                Spacer()
                TextField("Amount", text: $baseSalary)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
            }
        } header: {
            Text("Employment Details")
                .font(LMSFont.caption.weight(.bold))
        }
    }


    private func validateStaffForm() -> Bool {
        validationErrors.removeAll()

        if fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors["fullName"] = "Full name is required"
        }

        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

        if cleanedEmail.isEmpty {
            validationErrors["email"] = "Email address is required"
        } else if !emailPredicate.evaluate(with: cleanedEmail) {
            validationErrors["email"] = "Enter a valid email address"
        }

        if password.count < 8 {
            validationErrors["password"] = "Password must be at least 8 characters"
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

        if entityType == .loanOfficer && designation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors["designation"] = "Designation is required"
        }

        if entityType == .bankManager && region.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors["region"] = "Region is required"
        }

        return validationErrors.isEmpty
    }

    private func validateBranchForm() -> Bool {
        validationErrors.removeAll()

        if branchName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors["branchName"] = "Branch name is required"
        }
        if branchCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors["branchCode"] = "Branch code is required"
        }
        if branchRegion.isEmpty {
            validationErrors["branchRegion"] = "Please select a region"
        }
        if branchAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors["branchAddress"] = "Address is required"
        }
        if branchCity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors["branchCity"] = "City is required"
        }

        return validationErrors.isEmpty
    }

    private func submitStaff() async {
        let role: StaffRole = entityType == .loanOfficer ? .loanOfficer : .bankManager

        guard validateStaffForm(), let branchId = selectedBranchId else {
            submissionError = validationErrors.values.first ?? "Please fill all required fields."
            return
        }

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

    private func submitBranch() async {
        guard validateBranchForm() else {
            submissionError = validationErrors.values.first ?? "Please fill all required fields."
            return
        }

        isSubmitting = true
        submissionError = nil

        let fullAddress: String
        if !branchCity.isEmpty || !branchState.isEmpty || !branchPincode.isEmpty {
            let parts = [branchAddress, branchCity, branchState, branchPincode].filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            fullAddress = parts.joined(separator: ", ")
        } else {
            fullAddress = branchAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let success = await viewModel.createBranch(
            name: branchName.trimmingCharacters(in: .whitespacesAndNewlines),
            code: branchCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased(),
            region: branchRegion,
            address: fullAddress
        )

        isSubmitting = false

        if success {
            dismiss()
        } else {
            submissionError = viewModel.errorMessage ?? "An error occurred while creating the branch."
        }
    }
}
