import SwiftUI

struct EditPersonalInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: BorrowerProfileViewModel

    @State private var fullName: String
    @State private var gender: String
    @State private var maritalStatus: String
    @State private var nationality: String
    @State private var dateOfBirth: Date
    @State private var aadhaarNumber: String
    @State private var panNumber: String

    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""

    init(viewModel: BorrowerProfileViewModel) {
        self.viewModel = viewModel
        _fullName = State(initialValue: viewModel.profile?.fullName ?? "")
        _gender = State(initialValue: viewModel.profile?.gender ?? "")
        _maritalStatus = State(initialValue: viewModel.profile?.maritalStatus ?? "")
        _nationality = State(initialValue: viewModel.profile?.nationality ?? "")
        _dateOfBirth = State(initialValue: viewModel.profile?.dateOfBirth ?? Date())
        _aadhaarNumber = State(initialValue: viewModel.profile?.aadhaarNumber ?? "")
        _panNumber = State(initialValue: viewModel.profile?.panNumber ?? "")
    }

    var isKYCVerified: Bool {
        viewModel.profile?.isKYCVerified ?? false
    }

    var body: some View {
        NavigationStack {
            Form {
                if isKYCVerified {
                    Section(header: Text("Verified Identity Details (Locked)")) {
                        LockedFieldRow(label: "Full Name", value: fullName) {
                            triggerRequestChange(for: "Full Name")
                        }

                        LockedFieldRow(label: "Date of Birth", value: viewModel.formatDate(dateOfBirth)) {
                            triggerRequestChange(for: "Date of Birth")
                        }

                        LockedFieldRow(label: "Aadhaar Card Number", value: viewModel.maskedAccountNumber(aadhaarNumber)) {
                            triggerRequestChange(for: "Aadhaar Card Number")
                        }

                        LockedFieldRow(label: "PAN Card Number", value: panNumber) {
                            triggerRequestChange(for: "PAN Card Number")
                        }

                        Text("These identity fields are locked because your KYC verification has been completed. To update this information, tap 'Request Change' to notify support.")
                            .font(Font.AppTheme.caption)
                            .foregroundStyle(Color.AppTheme.textSecondary)
                    }
                } else {
                    Section(header: Text("Identity Details")) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Full Name")
                                .font(Font.AppTheme.caption)
                                .foregroundStyle(Color.AppTheme.textSecondary)
                            TextField("Enter Full Name", text: $fullName)
                                .font(Font.AppTheme.input)
                        }

                        DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                            .font(Font.AppTheme.body)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Aadhaar Number")
                                .font(Font.AppTheme.caption)
                                .foregroundStyle(Color.AppTheme.textSecondary)
                            TextField("Enter Aadhaar Number", text: $aadhaarNumber)
                                .keyboardType(.numberPad)
                                .font(Font.AppTheme.input)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("PAN Number")
                                .font(Font.AppTheme.caption)
                                .foregroundStyle(Color.AppTheme.textSecondary)
                            TextField("Enter PAN Number", text: $panNumber)
                                .autocapitalization(.allCharacters)
                                .font(Font.AppTheme.input)
                        }
                    }
                }

                Section(header: Text("Other Personal Details")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Gender")
                            .font(Font.AppTheme.caption)
                            .foregroundStyle(Color.AppTheme.textSecondary)
                        TextField("Enter Gender", text: $gender)
                            .font(Font.AppTheme.input)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Marital Status")
                            .font(Font.AppTheme.caption)
                            .foregroundStyle(Color.AppTheme.textSecondary)
                        TextField("Enter Marital Status", text: $maritalStatus)
                            .font(Font.AppTheme.input)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nationality")
                            .font(Font.AppTheme.caption)
                            .foregroundStyle(Color.AppTheme.textSecondary)
                        TextField("Enter Nationality", text: $nationality)
                            .font(Font.AppTheme.input)
                    }
                }
            }
            .navigationTitle("Edit Personal Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundStyle(Color.AppTheme.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.updatePersonalInfo(
                            fullName: fullName,
                            gender: gender,
                            maritalStatus: maritalStatus,
                            nationality: nationality,
                            dateOfBirth: dateOfBirth,
                            aadhaarNumber: aadhaarNumber,
                            panNumber: panNumber
                        )
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "checkmark")
                            .fontWeight(.bold)
                            .foregroundStyle(Color.AppTheme.primary)
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    private func triggerRequestChange(for fieldName: String) {
        alertTitle = "Request Change"
        alertMessage = "A request to change your \(fieldName) has been initiated. Our support representative will contact you via email shortly to request updated official identification documents."
        showAlert = true
    }
}

#Preview {
    EditPersonalInfoView(viewModel: BorrowerProfileViewModel())
}

