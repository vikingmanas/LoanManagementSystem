import SwiftUI

struct ChangePasswordSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authManager: AuthManager
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String? = nil
    @State private var showSuccessAlert = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("New Password"), footer: Text("Password must be at least 6 characters long.")) {
                    SecureField("New Password", text: $newPassword)
                        .textContentType(.newPassword)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .disabled(isSubmitting)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await changePassword()
                        }
                    }
                    .disabled(isSubmitting || newPassword.isEmpty || confirmPassword.isEmpty)
                }
            }
            .overlay {
                if isSubmitting {
                    ZStack {
                        Color.black.opacity(0.3).ignoresSafeArea()
                        ProgressView("Updating...")
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(10)
                            .shadow(radius: 10)
                    }
                }
            }
            .alert("Password Updated", isPresented: $showSuccessAlert) {
                Button("OK", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("Your password has been changed successfully. You have been logged out and will need to sign in again.")
            }
        }
    }
    
    private func changePassword() async {
        // Validation
        guard newPassword == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }
        
        guard newPassword.count >= 6 else {
            errorMessage = "Password must be at least 6 characters."
            return
        }
        
        errorMessage = nil
        isSubmitting = true
        
        let success = await authManager.updatePassword(newPassword: newPassword)
        
        isSubmitting = false
        
        if success {
            if let email = authManager.userEmail {
                sendEmailConfirmation(email: email)
            }
            showSuccessAlert = true
        } else {
            errorMessage = authManager.errorMessage ?? "Failed to update password."
        }
    }
    
    private func sendEmailConfirmation(email: String) {
        guard let url = URL(string: "https://loanmanagementsystem-1kev.onrender.com/api/send-reset-email") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["userEmail": email]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending email: \(error.localizedDescription)")
                return
            }
            print("Email requested successfully!")
        }.resume()
    }
}
