//
//  AuthTextField.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 19/05/26.
//

import SwiftUI

// MARK: - AuthTextField
/// A reusable, styled text field component for authentication screens.
/// Supports both plain text and secure (password) entry with a visibility toggle.
public struct AuthTextField: View {
    
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .never
    
    /// Controls visibility toggle for secure fields.
    @State private var isPasswordVisible: Bool = false
    
    /// Focus state for highlighting the active field.
    @FocusState private var isFocused: Bool
    
    public var body: some View {
        HStack(spacing: 14) {
            // Leading Icon
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isFocused ? Color.brandNavy : Color(.tertiaryLabel))
                .frame(width: 24)
            
            // Text Input (plain or secure)
            if isSecure && !isPasswordVisible {
                SecureField(placeholder, text: $text)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(autocapitalization)
                    .focused($isFocused)
                    .font(.system(.body, design: .rounded))
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .textInputAutocapitalization(autocapitalization)
                    .autocorrectionDisabled(true)
                    .focused($isFocused)
                    .font(.system(.body, design: .rounded))
            }
            
            // Password visibility toggle button
            if isSecure {
                Button {
                    isPasswordVisible.toggle()
                } label: {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(.tertiaryLabel))
                }
                .buttonStyle(.plain)
                .frame(width: 30, height: 44) // HIG tap target
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(isFocused ? Color.brandNavy : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
    }
}

// MARK: - Validation Helpers
/// Common form validation utilities for auth screens.
public enum AuthValidation {
    
    /// Checks if an email string matches a basic email pattern.
    public static func isValidEmail(_ email: String) -> Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return trimmed.range(of: pattern, options: .regularExpression) != nil
    }
    
    /// Checks if a password meets the minimum length requirement.
    public static func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }
    
    /// Checks if password and confirm password match.
    public static func passwordsMatch(_ password: String, _ confirm: String) -> Bool {
        return password == confirm && !password.isEmpty
    }
}
