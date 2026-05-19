//
//  ForgotPasswordView.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 19/05/26.
//

import SwiftUI

// MARK: - ForgotPasswordView
/// A sheet view that sends a Firebase password reset email.
/// Shows a success confirmation or error message.
public struct ForgotPasswordView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var showValidation = false
    @State private var resetSent = false
    
    private var emailError: String? {
        guard showValidation else { return nil }
        let t = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return "Email is required" }
        if !AuthValidation.isValidEmail(t) { return "Enter a valid email" }
        return nil
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.brandAmber.opacity(0.12))
                        .frame(width: 80, height: 80)
                    Image(systemName: "key.fill")
                        .font(.system(size: 34))
                        .foregroundColor(.brandAmber)
                }
                .padding(.top, 16)
                
                if resetSent {
                    // Success State
                    VStack(spacing: 12) {
                        Text("Reset Link Sent!")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                        
                        Text("We've sent a password reset link to **\(email.trimmingCharacters(in: .whitespacesAndNewlines))**. Check your inbox and follow the instructions to reset your password.")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(Color(.secondaryLabel))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("Back to Login")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.brandNavy)
                                .cornerRadius(14)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                } else {
                    // Input State
                    VStack(spacing: 12) {
                        Text("Forgot Password?")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                        
                        Text("Enter your registered email address and we'll send you a link to reset your password.")
                            .font(.system(.body, design: .rounded))
                            .foregroundColor(Color(.secondaryLabel))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Error Banner
                    if let error = authManager.errorMessage {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white)
                            Text(error)
                                .font(.system(.callout, design: .rounded))
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(12)
                        .background(Color.brandCoral)
                        .cornerRadius(12)
                    }
                    
                    // Email Field
                    VStack(alignment: .leading, spacing: 6) {
                        AuthTextField(
                            icon: "envelope.fill",
                            placeholder: "Email Address",
                            text: $email,
                            keyboardType: .emailAddress,
                            textContentType: .emailAddress
                        )
                        
                        if let e = emailError {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 11))
                                Text(e)
                                    .font(.system(.caption, design: .rounded))
                            }
                            .foregroundColor(Color.brandCoral)
                            .padding(.leading, 4)
                        }
                    }
                    
                    // Send Button
                    Button {
                        sendReset()
                    } label: {
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.brandNavy)
                                .cornerRadius(14)
                        } else {
                            Text("Send Reset Link")
                                .font(.system(.headline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.brandNavy)
                                .cornerRadius(14)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(authManager.isLoading)
                }
            }
            .padding(24)
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onDisappear {
                authManager.clearError()
            }
        }
    }
    
    private func sendReset() {
        withAnimation { showValidation = true }
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard AuthValidation.isValidEmail(trimmed) else { return }
        authManager.clearError()
        Task {
            let success = await authManager.resetPassword(email: trimmed)
            if success {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    resetSent = true
                }
            }
        }
    }
}
