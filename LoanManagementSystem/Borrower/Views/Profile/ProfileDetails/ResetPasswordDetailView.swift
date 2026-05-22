import SwiftUI

struct ResetPasswordDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    var body: some View {
        Form {
            Section(header: Text("Current Password")) {
                SecureField("Enter current password", text: $currentPassword)
            }
            
            Section(header: Text("New Password"), footer: Text("Password must be at least 8 characters long and contain numbers and symbols.")) {
                SecureField("Enter new password", text: $newPassword)
                SecureField("Confirm new password", text: $confirmPassword)
            }
            
            Section {
                Button(action: savePassword) {
                    HStack {
                        Spacer()
                        Text("Update Password")
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                        Spacer()
                    }
                }
                .listRowBackground(Color.AppTheme.primary)
            }
        }
        .navigationTitle("Reset/Change Password")
        .navigationBarTitleDisplayMode(.inline)
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(isSuccess ? "Success" : "Error"),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK")) {
                    if isSuccess {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            )
        }
    }
    
    private func savePassword() {
        guard !currentPassword.isEmpty, !newPassword.isEmpty, !confirmPassword.isEmpty else {
            alertMessage = "All fields are required."
            isSuccess = false
            showAlert = true
            return
        }
        
        guard newPassword.count >= 8 else {
            alertMessage = "New password must be at least 8 characters long."
            isSuccess = false
            showAlert = true
            return
        }
        
        guard newPassword == confirmPassword else {
            alertMessage = "New passwords do not match."
            isSuccess = false
            showAlert = true
            return
        }
        
        alertMessage = "Your password has been changed securely."
        isSuccess = true
        showAlert = true
    }
}

#Preview {
    NavigationStack {
        ResetPasswordDetailView()
    }
}
