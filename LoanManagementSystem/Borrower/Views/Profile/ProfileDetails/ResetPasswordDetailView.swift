import SwiftUI

struct ResetPasswordDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AuthManager.self) var authManager: AuthManager
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var isSuccess = false
    
    var body: some View {
        Form {
            Section {
                SecureField("Current Password", text: $currentPassword)
            } header: {
                Text("Current Password")
            }
            
            Section {
                SecureField("New Password", text: $newPassword)
                SecureField("Confirm New Password", text: $confirmPassword)
            } header: {
                Text("New Password")
            } footer: {
                Text("Password must be at least 8 characters long and contain numbers and symbols.")
            }
            
            Section {
                Button {
                    savePassword()
                } label: {
                    HStack {
                        Spacer()
                        if authManager.isLoading {
                            ProgressView()
                        } else {
                            Text("Change Password")
                                .fontWeight(.semibold)
                        }
                        Spacer()
                    }
                }
                .disabled(authManager.isLoading)
            }
        }
        .navigationTitle("Password")
        .navigationBarTitleDisplayMode(.inline)
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if isSuccess {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func savePassword() {
        guard !currentPassword.isEmpty, !newPassword.isEmpty, !confirmPassword.isEmpty else {
            alertTitle = "Error"
            alertMessage = "All fields are required."
            isSuccess = false
            showAlert = true
            return
        }
        
        guard newPassword.count >= 8 else {
            alertTitle = "Error"
            alertMessage = "New password must be at least 8 characters long."
            isSuccess = false
            showAlert = true
            return
        }
        
        guard newPassword == confirmPassword else {
            alertTitle = "Error"
            alertMessage = "New passwords do not match."
            isSuccess = false
            showAlert = true
            return
        }
        
        Task {
            let success = await authManager.updatePassword(newPassword: newPassword)
            if success {
                alertTitle = "Success"
                alertMessage = "Your password has been changed securely."
                isSuccess = true
            } else {
                alertTitle = "Error"
                alertMessage = authManager.errorMessage ?? "Failed to change password."
                isSuccess = false
            }
            showAlert = true
        }
    }
}

#Preview {
    NavigationStack {
        ResetPasswordDetailView()
            .environment(AuthManager())
    }
}
