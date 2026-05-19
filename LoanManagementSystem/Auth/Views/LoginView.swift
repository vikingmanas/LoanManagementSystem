//
//  LoginView.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 19/05/26.
//

import SwiftUI

// MARK: - LoginView
/// The main login screen with email/password authentication.
/// Features real-time field validation, loading state, error banners,
/// navigation to Sign Up, and a Forgot Password sheet.
public struct LoginView: View {
    
    // MARK: - Environment
    @EnvironmentObject private var authManager: AuthManager
    
    // MARK: - Form State
    @State private var email: String = ""
    @State private var password: String = ""
    
    // MARK: - UI State
    @State private var showSignUp: Bool = false
    @State private var showForgotPassword: Bool = false
    @State private var shakeError: Bool = false
    @State private var showValidationErrors: Bool = false
    
    // MARK: - Focus
    @FocusState private var focusedField: LoginField?
    
    private enum LoginField: Hashable {
        case email, password
    }
    
    // MARK: - Validation
    private var emailError: String? {
        guard showValidationErrors else { return nil }
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return "Email is required" }
        if !AuthValidation.isValidEmail(trimmed) { return "Enter a valid email address" }
        return nil
    }
    
    private var passwordError: String? {
        guard showValidationErrors else { return nil }
        if password.isEmpty { return "Password is required" }
        if password.count < 6 { return "Password must be at least 6 characters" }
        return nil
    }
    
    private var isFormValid: Bool {
        let trimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)
        return AuthValidation.isValidEmail(trimmed) && AuthValidation.isValidPassword(password)
    }
    
    // MARK: - Body
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemBackground)
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        
                        // MARK: - Header Section
                        headerSection
                            .padding(.top, 60)
                            .padding(.bottom, 40)
                        
                        // MARK: - Form Section
                        formSection
                            .padding(.horizontal, 24)
                        
                        // MARK: - Footer Section
                        footerSection
                            .padding(.top, 24)
                            .padding(.horizontal, 24)
                        
                        Spacer(minLength: 40)
                    }
                }
                .scrollDismissesKeyboard(.interactively)
                
                // MARK: - Loading Overlay
                if authManager.isLoading {
                    loadingOverlay
                }
            }
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showForgotPassword) {
                ForgotPasswordView()
                    .environmentObject(authManager)
            }
            .onChange(of: authManager.errorMessage) { _, newValue in
                if newValue != nil {
                    triggerShake()
                }
            }
            .onDisappear {
                authManager.clearError()
            }
        }
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon / Logo
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.brandNavy, Color(hex: "#2E3B84")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                    .shadow(color: Color.brandNavy.opacity(0.3), radius: 12, x: 0, y: 6)
                
                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 6) {
                Text("Welcome Back")
                    .font(.system(.largeTitle, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color(.label))
                
                Text("Sign in to manage your loans")
                    .font(.system(.body, design: .rounded))
                    .foregroundColor(Color(.secondaryLabel))
            }
        }
    }
    
    // MARK: - Form
    private var formSection: some View {
        VStack(spacing: 16) {
            // Error Banner
            if let error = authManager.errorMessage {
                errorBanner(message: error)
                    .offset(x: shakeError ? -8 : 0)
                    .animation(.default.repeatCount(3, autoreverses: true).speed(6), value: shakeError)
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
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
                
                if let error = emailError {
                    validationLabel(error)
                }
            }
            
            // Password Field
            VStack(alignment: .leading, spacing: 6) {
                AuthTextField(
                    icon: "lock.fill",
                    placeholder: "Password",
                    text: $password,
                    isSecure: true,
                    textContentType: .password
                )
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                .onSubmit { performLogin() }
                
                if let error = passwordError {
                    validationLabel(error)
                }
            }
            
            // Forgot Password Link
            HStack {
                Spacer()
                Button {
                    showForgotPassword = true
                } label: {
                    Text("Forgot Password?")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.medium)
                        .foregroundColor(Color.brandNavy)
                }
                .buttonStyle(.plain)
                .frame(minHeight: 44)
            }
            
            // Login Button
            Button(action: performLogin) {
                Text("Login")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(
                            colors: [Color.brandNavy, Color(hex: "#2E3B84")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.brandNavy.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(authManager.isLoading)
        }
    }
    
    // MARK: - Footer
    private var footerSection: some View {
        HStack(spacing: 4) {
            Text("Don't have an account?")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(Color(.secondaryLabel))
            
            Button {
                showSignUp = true
            } label: {
                Text("Sign Up")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(Color.brandNavy)
            }
            .buttonStyle(.plain)
        }
        .frame(minHeight: 44)
    }
    
    // MARK: - Shared Components
    
    private func errorBanner(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 16))
                .foregroundColor(.white)
            
            Text(message)
                .font(.system(.callout, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Button {
                authManager.clearError()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.brandCoral)
        .cornerRadius(14)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: authManager.errorMessage)
    }
    
    private func validationLabel(_ text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 11))
            Text(text)
                .font(.system(.caption, design: .rounded))
        }
        .foregroundColor(Color.brandCoral)
        .padding(.leading, 4)
        .transition(.opacity)
    }
    
    private var loadingOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.2)
                    .tint(.white)
                
                Text("Signing in...")
                    .font(.system(.callout, design: .rounded))
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .padding(30)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
        }
        .transition(.opacity)
        .animation(.easeInOut(duration: 0.25), value: authManager.isLoading)
    }
    
    // MARK: - Actions
    
    private func performLogin() {
        // Dismiss keyboard
        focusedField = nil
        
        // Show validation errors
        withAnimation(.easeInOut(duration: 0.2)) {
            showValidationErrors = true
        }
        
        // Validate form
        guard isFormValid else { return }
        
        // Clear previous errors and attempt login
        authManager.clearError()
        
        Task {
            await authManager.signIn(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
        }
    }
    
    private func triggerShake() {
        shakeError = false
        withAnimation {
            shakeError = true
        }
        // Reset after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            shakeError = false
        }
    }
}
