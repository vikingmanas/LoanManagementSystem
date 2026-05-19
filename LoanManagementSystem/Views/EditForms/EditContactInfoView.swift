import SwiftUI

struct EditContactInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: BorrowerProfileViewModel
    
    @State private var mobileNumber: String
    @State private var alternateNumber: String
    @State private var email: String
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var alertTitle = ""
    
    init(viewModel: BorrowerProfileViewModel) {
        self.viewModel = viewModel
        _mobileNumber = State(initialValue: viewModel.profile?.mobileNumber ?? "")
        _alternateNumber = State(initialValue: viewModel.profile?.alternateNumber ?? "")
        _email = State(initialValue: viewModel.profile?.email ?? "")
    }
    
    var isPhoneVerified: Bool {
        viewModel.profile?.isPhoneVerified ?? false
    }
    
    var isKYCVerified: Bool {
        viewModel.profile?.isKYCVerified ?? false
    }
    
    var body: some View {
        NavigationStack {
            Form {
                if isKYCVerified || isPhoneVerified {
                    Section(header: Text("Verified Contact Details")) {
                        LockedFieldRow(label: "Mobile Number", value: mobileNumber) {
                            triggerRequestChange(for: "Mobile Number")
                        }
                        
                        Text("This verified mobile number is locked. To modify it, please request an official update.")
                            .font(Font.AppTheme.caption)
                            .foregroundColor(Color.AppTheme.textSecondary)
                    }
                } else {
                    Section(header: Text("Mobile Number")) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Mobile Number")
                                .font(Font.AppTheme.caption)
                                .foregroundColor(Color.AppTheme.textSecondary)
                            TextField("Enter Mobile Number", text: $mobileNumber)
                                .keyboardType(.phonePad)
                                .font(Font.AppTheme.body)
                        }
                    }
                }
                
                Section(header: Text("Other Contact Fields")) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Alternate Mobile Number")
                            .font(Font.AppTheme.caption)
                            .foregroundColor(Color.AppTheme.textSecondary)
                        TextField("Enter Alternate Number (Optional)", text: $alternateNumber)
                            .keyboardType(.phonePad)
                            .font(Font.AppTheme.body)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Email Address")
                            .font(Font.AppTheme.caption)
                            .foregroundColor(Color.AppTheme.textSecondary)
                        TextField("Enter Email Address", text: $email)
                            .keyboardType(.emailAddress)
                            .font(Font.AppTheme.body)
                    }
                }
            }
            .navigationTitle("Edit Contact Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .foregroundColor(Color.AppTheme.primary)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.updateContact(mobile: mobileNumber, email: email, alternate: alternateNumber)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "checkmark")
                            .fontWeight(.bold)
                            .foregroundColor(Color.AppTheme.primary)
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
        alertTitle = "Request Contact Update"
        alertMessage = "A request to change your registered \(fieldName) has been generated. For security reasons, you will receive a verification call from our relationship manager within 24 hours."
        showAlert = true
    }
}

#Preview {
    EditContactInfoView(viewModel: BorrowerProfileViewModel())
}
