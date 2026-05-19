//
//  SignUpView.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 19/05/26.
//

import SwiftUI

public struct SignUpView: View {
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showValidationErrors = false
    @State private var shakeError = false
    
    @FocusState private var focusedField: Field?
    private enum Field: Hashable { case name, email, password, confirm }
    
    private var emailError: String? {
        guard showValidationErrors else { return nil }
        let t = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return "Email is required" }
        if !AuthValidation.isValidEmail(t) { return "Enter a valid email" }
        return nil
    }
    private var passwordError: String? {
        guard showValidationErrors else { return nil }
        if password.isEmpty { return "Password is required" }
        if password.count < 6 { return "Min 6 characters" }
        return nil
    }
    private var confirmError: String? {
        guard showValidationErrors else { return nil }
        if confirmPassword.isEmpty { return "Confirm your password" }
        if password != confirmPassword { return "Passwords do not match" }
        return nil
    }
    private var isFormValid: Bool {
        AuthValidation.isValidEmail(email.trimmingCharacters(in: .whitespacesAndNewlines))
        && AuthValidation.isValidPassword(password)
        && AuthValidation.passwordsMatch(password, confirmPassword)
    }
    
    public var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    headerSection.padding(.top, 40).padding(.bottom, 32)
                    formSection.padding(.horizontal, 24)
                    footerSection.padding(.top, 24).padding(.horizontal, 24)
                    Spacer(minLength: 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            if authManager.isLoading { loadingOverlay }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left").font(.system(size: 14, weight: .semibold))
                        Text("Back").font(.system(.body, design: .rounded))
                    }.foregroundColor(Color.brandNavy)
                }
            }
        }
        .onChange(of: authManager.errorMessage) { _, newValue in
            if newValue != nil { triggerShake() }
        }
        .onDisappear { authManager.clearError() }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.brandEmerald, Color(hex: "#009E86")], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.brandEmerald.opacity(0.3), radius: 12, x: 0, y: 6)
                Image(systemName: "person.badge.plus")
                    .font(.system(size: 34)).foregroundColor(.white)
            }
            VStack(spacing: 6) {
                Text("Create Account")
                    .font(.system(.largeTitle, design: .rounded)).fontWeight(.bold)
                Text("Start managing your loans today")
                    .font(.system(.body, design: .rounded)).foregroundColor(Color(.secondaryLabel))
            }
        }
    }
    
    // MARK: - Form
    private var formSection: some View {
        VStack(spacing: 16) {
            if let error = authManager.errorMessage {
                errorBanner(error)
                    .offset(x: shakeError ? -8 : 0)
                    .animation(.default.repeatCount(3, autoreverses: true).speed(6), value: shakeError)
            }
            
            AuthTextField(icon: "person.fill", placeholder: "Full Name (Optional)", text: $name, textContentType: .name, autocapitalization: .words)
                .focused($focusedField, equals: .name).submitLabel(.next).onSubmit { focusedField = .email }
            
            VStack(alignment: .leading, spacing: 6) {
                AuthTextField(icon: "envelope.fill", placeholder: "Email Address", text: $email, keyboardType: .emailAddress, textContentType: .emailAddress)
                    .focused($focusedField, equals: .email).submitLabel(.next).onSubmit { focusedField = .password }
                if let e = emailError { valLabel(e) }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                AuthTextField(icon: "lock.fill", placeholder: "Password (min 6 chars)", text: $password, isSecure: true, textContentType: .newPassword)
                    .focused($focusedField, equals: .password).submitLabel(.next).onSubmit { focusedField = .confirm }
                if let e = passwordError { valLabel(e) }
                if !password.isEmpty { strengthBar }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                AuthTextField(icon: "lock.rotation", placeholder: "Confirm Password", text: $confirmPassword, isSecure: true, textContentType: .newPassword)
                    .focused($focusedField, equals: .confirm).submitLabel(.go).onSubmit { performSignUp() }
                if let e = confirmError { valLabel(e) }
            }
            
            Button(action: performSignUp) {
                Text("Create Account")
                    .font(.system(.headline, design: .rounded)).fontWeight(.bold).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(LinearGradient(colors: [Color.brandEmerald, Color(hex: "#009E86")], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(16)
                    .shadow(color: Color.brandEmerald.opacity(0.3), radius: 8, x: 0, y: 4)
            }.buttonStyle(.plain).disabled(authManager.isLoading).padding(.top, 8)
        }
    }
    
    // MARK: - Strength Bar
    private var strengthBar: some View {
        let s = strength
        return VStack(alignment: .leading, spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color(.systemGray5)).frame(height: 6)
                    RoundedRectangle(cornerRadius: 3).fill(s.color).frame(width: geo.size.width * s.frac, height: 6)
                        .animation(.easeInOut(duration: 0.3), value: password)
                }
            }.frame(height: 6)
            Text(s.label).font(.system(.caption2, design: .rounded)).fontWeight(.medium).foregroundColor(s.color)
        }.padding(.leading, 4)
    }
    private var strength: (label: String, color: Color, frac: CGFloat) {
        let l = password.count
        if l < 6 { return ("Weak", .brandCoral, 0.25) }
        if l < 8 { return ("Fair", .brandAmber, 0.5) }
        let u = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let n = password.rangeOfCharacter(from: .decimalDigits) != nil
        let sp = password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=")) != nil
        if [u, n, sp].filter({ $0 }).count >= 2 { return ("Strong", .brandEmerald, 1.0) }
        return ("Good", Color(hex: "#4CAF50"), 0.75)
    }
    
    // MARK: - Footer
    private var footerSection: some View {
        HStack(spacing: 4) {
            Text("Already have an account?").font(.system(.subheadline, design: .rounded)).foregroundColor(Color(.secondaryLabel))
            Button { dismiss() } label: {
                Text("Login").font(.system(.subheadline, design: .rounded)).fontWeight(.bold).foregroundColor(Color.brandNavy)
            }.buttonStyle(.plain)
        }.frame(minHeight: 44)
    }
    
    // MARK: - Components
    private func errorBanner(_ msg: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").font(.system(size: 16)).foregroundColor(.white)
            Text(msg).font(.system(.callout, design: .rounded)).fontWeight(.medium).foregroundColor(.white).multilineTextAlignment(.leading)
            Spacer()
            Button { authManager.clearError() } label: {
                Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundColor(.white.opacity(0.8))
            }.buttonStyle(.plain)
        }.padding(14).background(Color.brandCoral).cornerRadius(14)
    }
    private func valLabel(_ t: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.circle.fill").font(.system(size: 11))
            Text(t).font(.system(.caption, design: .rounded))
        }.foregroundColor(Color.brandCoral).padding(.leading, 4)
    }
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView().progressViewStyle(.circular).scaleEffect(1.2).tint(.white)
                Text("Creating account...").font(.system(.callout, design: .rounded)).fontWeight(.medium).foregroundColor(.white)
            }.padding(30).background(.ultraThinMaterial).cornerRadius(20)
        }
    }
    
    // MARK: - Actions
    private func performSignUp() {
        focusedField = nil
        withAnimation(.easeInOut(duration: 0.2)) { showValidationErrors = true }
        guard isFormValid else { return }
        authManager.clearError()
        Task {
            await authManager.signUp(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
        }
    }
    private func triggerShake() {
        shakeError = false
        withAnimation { shakeError = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { shakeError = false }
    }
}
