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
    
    // Additional Native Fields
    @State private var dateOfBirth = Date()
    @State private var dateOfJoining = Date()
    @State private var address = ""
    @State private var baseSalary = ""
    @State private var employmentType = "Full-Time"
    let employmentTypes = ["Full-Time", "Part-Time", "Contract", "Intern"]


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

                    if role == .loanOfficer {
                        TextField("Designation (e.g. Senior Underwriter)", text: $designation)
                    } else if role == .bankManager {
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

