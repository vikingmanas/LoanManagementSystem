import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct StaffLoginView: View {
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var authManager: AuthManager
    
    @State private var employeeID: String = ""
    @State private var password: String = ""
    
    @State private var employeeIDError: String = ""
    @State private var passwordError: String = ""
    @State private var generalError: String = ""
    @State private var isLoading: Bool = false
    
    var isFormValid: Bool {
        return !employeeID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !password.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        // Top Back Navigation Button
                        Button(action: {
                            HapticsManager.triggerImpact(style: .medium)
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                appState.showRoleSelection = true
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                Text("Back to Roles")
                            }
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundColor(Color.AppTheme.primary)
                        }
                        .padding(.top, 16)
                        
                        // Header Section
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.AppTheme.primary.opacity(0.12))
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: appState.selectedRole.icon)
                                        .font(.title3)
                                        .foregroundColor(Color.AppTheme.primary)
                                }
                                
                                Text("Branch Staff")
                                    .font(.system(.caption, design: .rounded).weight(.bold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            
                            Text("\(appState.selectedRole.rawValue) Portal")
                                .font(Font.AppTheme.title)
                                .foregroundColor(Color.AppTheme.textPrimary)
                            
                            Text("Secure branch sign-in. Access credentials require verification.")
                                .font(Font.AppTheme.subtitle)
                                .foregroundColor(Color.AppTheme.textSecondary)
                        }
                        .padding(.top, 12)
                        
                        // Error Banner
                        if !generalError.isEmpty {
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(Color.AppTheme.error)
                                Text(generalError)
                                    .font(Font.AppTheme.caption)
                                    .foregroundColor(Color.AppTheme.error)
                                Spacer()
                            }
                            .padding()
                            .background(Color.AppTheme.error.opacity(0.1))
                            .cornerRadius(12)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                        
                        // Input Fields Stack
                        VStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("EMPLOYEE ID")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.AppTheme.textSecondary)
                                    .padding(.leading, 4)
                                
                                CustomTextField(
                                    icon: "person.text.rectangle",
                                    placeholder: employeeIDPlaceholder,
                                    text: $employeeID,
                                    isError: !employeeIDError.isEmpty,
                                    errorMessage: employeeIDError
                                )
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("PASSWORD")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.AppTheme.textSecondary)
                                    .padding(.leading, 4)
                                
                                SecureInputField(
                                    placeholder: "Branch Password",
                                    text: $password,
                                    isError: !passwordError.isEmpty,
                                    errorMessage: passwordError
                                )
                            }
                        }
                        
                        // Info Note on credentials (Helper guidelines)
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                                .font(.footnote)
                            
                            Text("Staff IDs correspond to branch assignments (e.g. Loan Officer starts with 'LO', Bank Manager with 'BM', Admin with 'AD').")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                        
                        // Action Buttons
                        PrimaryButton(
                            title: "Authorize Portal Access",
                            isLoading: isLoading,
                            isDisabled: !isFormValid,
                            action: {
                                handleStaffLogin()
                            }
                        )
                        .padding(.top, 12)
                        
                        Spacer()
                            .frame(height: 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .hideNavigationBar()
        }
    }
    
    // MARK: - Role Placeholder Helper
    private var employeeIDPlaceholder: String {
        switch appState.selectedRole {
        case .loanOfficer: return "e.g., LO1234"
        case .bankManager: return "e.g., BM1234"
        case .admin: return "e.g., AD1234"
        default: return "Branch Employee ID"
        }
    }
    
    // MARK: - Credentials Validation Handler
    private func handleStaffLogin() {
        // Reset Error State
        employeeIDError = ""
        passwordError = ""
        generalError = ""
        
        let cleanedID = employeeID.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // 1. Basic Format Validations
        if cleanedID.isEmpty {
            employeeIDError = "Employee ID cannot be empty"
            return
        }
        
        if password.isEmpty {
            passwordError = "Password cannot be empty"
            return
        }
        
        // 2. Validate prefix based on selected role
        switch appState.selectedRole {
        case .loanOfficer:
            if !cleanedID.hasPrefix("LO") {
                employeeIDError = "Loan Officer Employee ID must start with 'LO'"
                return
            }
        case .bankManager:
            if !cleanedID.hasPrefix("BM") {
                employeeIDError = "Bank Manager Employee ID must start with 'BM'"
                return
            }
        case .admin:
            if !cleanedID.hasPrefix("AD") {
                employeeIDError = "Admin Employee ID must start with 'AD'"
                return
            }
        default:
            break
        }
        
        isLoading = true
        
        Task {
            // Bypass Firebase/Firestore authentication for branch staff roles using dummy credentials
            try? await Task.sleep(nanoseconds: 800_000_000) // Simulated network latency for high premium feel
            
            await MainActor.run {
                HapticsManager.triggerImpact(style: .heavy)
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    appState.login()
                }
                self.isLoading = false
            }
        }
    }
}

struct StaffLoginView_Previews: PreviewProvider {
    static var previews: some View {
        StaffLoginView()
            .environmentObject(AppStateManager())
            .environmentObject(AuthManager())
    }
}
