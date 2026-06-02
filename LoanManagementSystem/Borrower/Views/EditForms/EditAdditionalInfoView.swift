import SwiftUI

struct EditAdditionalInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: BorrowerProfileViewModel

    @State private var occupation: String
    @State private var hasExistingBankAccount: Bool
    @State private var existingCustomerId: String
    @State private var preferredBranch: String
    @State private var emergencyContactName: String
    @State private var emergencyContactNumber: String
    @State private var nomineeName: String
    @State private var nomineeRelationship: String
    private let relationships = ["Spouse", "Mother", "Father", "Brother", "Sister", "Child"]
    @State private var branchesList: [BranchInfo] = []

    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""

    init(viewModel: BorrowerProfileViewModel) {
        self.viewModel = viewModel

        let p = viewModel.profile
        _occupation = State(initialValue: p?.occupation ?? "")
        _hasExistingBankAccount = State(initialValue: p?.hasExistingBankAccount ?? false)
        _existingCustomerId = State(initialValue: p?.existingCustomerId ?? "")
        _preferredBranch = State(initialValue: p?.preferredBranch ?? "")
        _emergencyContactName = State(initialValue: p?.emergencyContactName ?? "")
        _emergencyContactNumber = State(initialValue: p?.emergencyContactNumber ?? "")
        _nomineeName = State(initialValue: p?.nomineeName ?? "")
        _nomineeRelationship = State(initialValue: p?.nomineeRelationship ?? "Spouse")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Emergency Reference Contact")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Emergency Contact Name")
                            .font(Font.AppTheme.caption)
                            .foregroundStyle(Color.AppTheme.textSecondary)
                        TextField("Enter Contact Full Name", text: $emergencyContactName)
                            .font(Font.AppTheme.input)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Emergency Contact Mobile Number")
                            .font(Font.AppTheme.caption)
                            .foregroundStyle(Color.AppTheme.textSecondary)
                        TextField("Enter 10-digit number", text: $emergencyContactNumber)
                            .keyboardType(.phonePad)
                            .font(Font.AppTheme.input)
                            .onChange(of: emergencyContactNumber) { _, newValue in
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered.count > 10 {
                                    emergencyContactNumber = String(filtered.prefix(10))
                                } else {
                                    emergencyContactNumber = filtered
                                }
                            }
                    }
                }

                Section(header: Text("Nominee Details")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Nominee Full Name")
                            .font(Font.AppTheme.caption)
                            .foregroundStyle(Color.AppTheme.textSecondary)
                        TextField("Enter Nominee Full Name", text: $nomineeName)
                            .font(Font.AppTheme.input)
                    }

                    Picker("Nominee Relationship", selection: $nomineeRelationship) {
                        ForEach(relationships, id: \.self) { rel in
                            Text(rel).tag(rel)
                        }
                    }
                    .font(Font.AppTheme.body)
                }

                Section(header: Text("Bank Preferences")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Occupation / Designation")
                            .font(Font.AppTheme.caption)
                            .foregroundStyle(Color.AppTheme.textSecondary)
                        TextField("Occupation", text: $occupation)
                            .font(Font.AppTheme.input)
                    }

                    Toggle("Existing Bank Account", isOn: $hasExistingBankAccount)
                        .font(Font.AppTheme.body)

                    if hasExistingBankAccount {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Existing Bank Customer ID")
                                .font(Font.AppTheme.caption)
                                .foregroundStyle(Color.AppTheme.textSecondary)
                            TextField("Customer ID", text: $existingCustomerId)
                                .font(Font.AppTheme.input)
                        }
                    }

                    Picker("Preferred Home Branch", selection: $preferredBranch) {
                        if branchesList.isEmpty {
                            Text("No branches available").tag("")
                        }
                        ForEach(branchesList, id: \.id) { branch in
                            Text(branch.name).tag(branch.name)
                        }
                    }
                    .font(Font.AppTheme.body)
                    .font(Font.AppTheme.body)
                }
            }
            .navigationTitle("Edit Preferences & Refs")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { loadBranches() }
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
                        saveChanges()
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

    private func saveChanges() {
        if emergencyContactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError("Emergency contact name cannot be empty.")
            return
        }

        let cleanPhone = emergencyContactNumber.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
            .replacingOccurrences(of: "+91", with: "")
        let phoneRegex = "^[0-9]{10}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        if !phonePredicate.evaluate(with: cleanPhone) {
            showError("Emergency phone number must be exactly 10 digits.")
            return
        }

        if nomineeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            showError("Nominee name cannot be empty.")
            return
        }


        viewModel.updateAdditionalInfo(
            occupation: occupation,
            hasExistingBankAccount: hasExistingBankAccount,
            existingCustomerId: hasExistingBankAccount ? existingCustomerId : nil,
            preferredBranch: preferredBranch,
            emergencyContactName: emergencyContactName,
            emergencyContactNumber: emergencyContactNumber,
            nomineeName: nomineeName,
            nomineeRelationship: nomineeRelationship
        )

        presentationMode.wrappedValue.dismiss()
    }

    private func showError(_ message: String) {
        alertTitle = "Validation Error"
        alertMessage = message
        showAlert = true
    }

    private func loadBranches() {
        Task {
            do {
                let fetched = try await DatabaseService.shared.fetchBranches()
                await MainActor.run {
                    self.branchesList = fetched
                    if preferredBranch.isEmpty, let first = fetched.first {
                        self.preferredBranch = first.name
                    }
                }
            } catch {
                print("Error loading branches in EditAdditionalInfoView: \(error)")
            }
        }
    }
}

#Preview {
    EditAdditionalInfoView(viewModel: BorrowerProfileViewModel())
}

