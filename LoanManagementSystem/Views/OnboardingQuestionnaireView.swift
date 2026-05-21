import SwiftUI

struct OnboardingQuestionnaireView: View {
    @EnvironmentObject private var authManager: AuthManager
    @EnvironmentObject private var appState: AppStateManager
    @ObservedObject private var profileStore = BorrowerProfileStore.shared
    
    // Step indicator: 0 = Identity, 1 = Professional & Finance, 2 = Bank & Preferences, 3 = Nominee & Emergency
    @State private var currentStep = 0
    private let totalSteps = 4
    
    // Step 1: Personal & Identity
    @State private var dateOfBirth = Date()
    @State private var gender = "Male"
    @State private var maritalStatus = "Single"
    @State private var aadhaarNumber = ""
    @State private var panNumber = ""
    
    // Step 2: Professional & Finance
    @State private var employmentType = "Salaried"
    @State private var occupation = ""
    @State private var companyName = ""
    @State private var monthlyIncome = ""
    
    // Step 3: Bank & Preferences
    @State private var hasExistingBankAccount = false
    @State private var existingCustomerId = ""
    @State private var preferredBranch = "Mumbai Main Branch"
    @State private var selectedInterests: Set<String> = []
    
    // Step 4: Nominee & Emergency
    @State private var emergencyContactName = ""
    @State private var emergencyContactNumber = ""
    @State private var nomineeName = ""
    @State private var nomineeRelationship = "Spouse"
    
    // Error feedback
    @State private var errorMessage = ""
    @State private var showValidationError = false
    
    // Lists of Options
    private let genders = ["Male", "Female", "Other", "Prefer not to say"]
    private let maritalStatuses = ["Single", "Married", "Divorced", "Widowed"]
    private let employmentTypes = ["Salaried", "Self-Employed", "Business Owner", "Student", "Retired"]
    private let relationships = ["Spouse", "Mother", "Father", "Brother", "Sister", "Child"]
    private let branches = [
        "Mumbai Main Branch",
        "Andheri Tech Park Branch",
        "Mindspace Malad Branch",
        "Bandra Kurla Complex Branch",
        "Delhi Connaught Place Branch",
        "Bengaluru Whitefield Branch"
    ]
    private let loanInterests = ["Home", "Personal", "Education", "Vehicle", "Business"]
    
    var body: some View {
        ZStack {
            // Elegant Background
            LinearGradient(
                colors: [Color.brandNavy, Color(hex: "#162E5C")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Block with progress bar
                headerSection
                    .padding(.top, 16)
                
                // Form Card Area
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Main Multi-step Form Card (Glassmorphic look)
                        VStack(alignment: .leading, spacing: 20) {
                            formStepView
                        }
                        .padding(24)
                        .background(
                            RoundedRectangle(cornerRadius: 24)
                                .fill(Color(UIColor.secondarySystemBackground).opacity(0.12))
                                .background(
                                    VisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
                                        .cornerRadius(24)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 24)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                )
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        
                        // Error message banner
                        if showValidationError {
                            HStack(spacing: 12) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.white)
                                
                                Text(errorMessage)
                                    .font(.system(.body, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .lineLimit(2)
                                    .minimumScaleFactor(0.9)
                                
                                Spacer()
                                
                                Button {
                                    showValidationError = false
                                } label: {
                                    Image(systemName: "xmark")
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .padding()
                            .background(Color.brandCoral)
                            .cornerRadius(16)
                            .padding(.horizontal, 20)
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                    .padding(.bottom, 24)
                }
                
                // Footer Navigation Controls
                footerSection
            }
        }
        .onAppear {
            prepopulateFieldsIfPossible()
        }
    }
    
    // MARK: - Subviews
    
    private var headerSection: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CUSTOMER ONBOARDING")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(Color.brandAmber)
                        .tracking(1.5)
                    
                    Text(stepTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button {
                    // Sign out option in case they want to quit
                    profileStore.signOut()
                    appState.logout()
                    authManager.signOut()
                } label: {
                    Text("Cancel")
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                }
            }
            .padding(.horizontal, 24)
            
            // Modern Step Indicators
            HStack(spacing: 6) {
                ForEach(0..<totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentStep ? Color.brandEmerald : Color.white.opacity(0.2))
                        .frame(height: 6)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentStep)
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var formStepView: some View {
        Group {
            switch currentStep {
            case 0:
                stepIdentityView
            case 1:
                stepProfessionalView
            case 2:
                stepPreferencesView
            case 3:
                stepNomineeView
            default:
                EmptyView()
            }
        }
    }
    
    private var footerSection: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.15))
            
            HStack {
                if currentStep > 0 {
                    Button {
                        withAnimation {
                            currentStep -= 1
                            showValidationError = false
                        }
                    } label: {
                        HStack {
                            Image(systemName: "chevron.left")
                                .fontWeight(.bold)
                            Text("Back")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                }
                
                Button {
                    validateAndProceed()
                } label: {
                    HStack {
                        Text(currentStep == totalSteps - 1 ? "Submit Profile" : "Continue")
                            .fontWeight(.bold)
                        if currentStep < totalSteps - 1 {
                            Image(systemName: "chevron.right")
                                .fontWeight(.bold)
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.brandEmerald)
                    .cornerRadius(16)
                    .shadow(color: Color.brandEmerald.opacity(0.3), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.brandNavy.opacity(0.95).ignoresSafeArea())
        }
    }
    
    // MARK: - Step-Specific Views
    
    private var stepIdentityView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Personal & Identity Details")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.bottom, 4)
            
            // DOB Picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Date of Birth")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                
                DatePicker("", selection: $dateOfBirth, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .colorScheme(.dark)
            }
            
            // Gender Selector
            VStack(alignment: .leading, spacing: 6) {
                Text("Gender")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 8) {
                    ForEach(genders, id: \.self) { item in
                        Button {
                            gender = item
                        } label: {
                            Text(item)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(gender == item ? Color.brandEmerald : Color.white.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                }
            }
            
            // Marital Status Picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Marital Status")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 8) {
                    ForEach(maritalStatuses, id: \.self) { item in
                        Button {
                            maritalStatus = item
                        } label: {
                            Text(item)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(maritalStatus == item ? Color.brandEmerald : Color.white.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                }
            }
            
            // PAN Number Textfield
            VStack(alignment: .leading, spacing: 6) {
                Text("PAN Card Number")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                
                TextField("Enter 10-digit PAN (e.g. ABCDE1234F)", text: $panNumber)
                    .autocapitalization(.allCharacters)
                    .disableAutocorrection(true)
                    .foregroundColor(.white)
                    .padding(14)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            }
            
            // Aadhaar Number Textfield
            VStack(alignment: .leading, spacing: 6) {
                Text("Aadhaar Card Number")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                
                TextField("Enter 12-digit Aadhaar", text: $aadhaarNumber)
                    .keyboardType(.numberPad)
                    .foregroundColor(.white)
                    .padding(14)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            }
        }
    }
    
    private var stepProfessionalView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Professional & Financial Status")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.bottom, 4)
            
            // Employment Type Picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Employment Type")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(employmentTypes, id: \.self) { item in
                            Button {
                                employmentType = item
                            } label: {
                                Text(item)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(employmentType == item ? Color.brandEmerald : Color.white.opacity(0.1))
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
            }
            
            // Occupation TextField
            VStack(alignment: .leading, spacing: 6) {
                Text("Occupation / Designation")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                
                TextField("e.g. Software Engineer, Proprietor, Teacher", text: $occupation)
                    .foregroundColor(.white)
                    .padding(14)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            }
            
            // Company Name TextField
            VStack(alignment: .leading, spacing: 6) {
                Text("Company / Business Name")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                
                TextField("e.g. Google, Self-Employed Retail", text: $companyName)
                    .foregroundColor(.white)
                    .padding(14)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            }
            
            // Monthly Income TextField
            VStack(alignment: .leading, spacing: 6) {
                Text("Monthly Salary / Net Profit (₹)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                
                TextField("Enter monthly income in ₹", text: $monthlyIncome)
                    .keyboardType(.numberPad)
                    .foregroundColor(.white)
                    .padding(14)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            }
        }
    }
    
    private var stepPreferencesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preferences & Existing Relationship")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.bottom, 4)
            
            // Existing customer check
            VStack(alignment: .leading, spacing: 10) {
                Toggle(isOn: $hasExistingBankAccount) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Existing Bank Account")
                            .font(.system(.body, design: .rounded))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        Text("Do you hold a savings or current account with us?")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: Color.brandEmerald))
                .padding(12)
                .background(Color.white.opacity(0.06))
                .cornerRadius(12)
            }
            
            if hasExistingBankAccount {
                // Customer ID input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Existing Bank Customer ID (Optional)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white.opacity(0.8))
                    
                    TextField("Enter your Customer ID (e.g. C-123456)", text: $existingCustomerId)
                        .autocapitalization(.allCharacters)
                        .foregroundColor(.white)
                        .padding(14)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Preferred Branch Picker
            VStack(alignment: .leading, spacing: 6) {
                Text("Preferred Home Branch")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                
                Menu {
                    ForEach(branches, id: \.self) { branch in
                        Button(branch) {
                            preferredBranch = branch
                        }
                    }
                } label: {
                    HStack {
                        Text(preferredBranch)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
                }
            }
            
            // Loan Interests (Multiple checkboxes)
            VStack(alignment: .leading, spacing: 8) {
                Text("Loan Products Interested In")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 8) {
                    ForEach(loanInterests, id: \.self) { interest in
                        let isSelected = selectedInterests.contains(interest)
                        Button {
                            if isSelected {
                                selectedInterests.remove(interest)
                            } else {
                                selectedInterests.insert(interest)
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(isSelected ? .brandEmerald : .white.opacity(0.5))
                                Text(interest)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isSelected ? Color.brandEmerald.opacity(0.2) : Color.white.opacity(0.08))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected ? Color.brandEmerald : Color.white.opacity(0.15), lineWidth: 1)
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var stepNomineeView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Emergency Contact & Nominee Details")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.bottom, 4)
            
            // Emergency Contact Name
            VStack(alignment: .leading, spacing: 6) {
                Text("Emergency Contact Name")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                
                TextField("Enter contact person's full name", text: $emergencyContactName)
                    .foregroundColor(.white)
                    .padding(14)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            }
            
            // Emergency Contact Number
            VStack(alignment: .leading, spacing: 6) {
                Text("Emergency Contact Mobile Number")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                
                TextField("Enter 10-digit mobile number", text: $emergencyContactNumber)
                    .keyboardType(.phonePad)
                    .foregroundColor(.white)
                    .padding(14)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            }
            
            // Nominee Name
            VStack(alignment: .leading, spacing: 6) {
                Text("Nominee Full Name")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                
                TextField("Enter nominee's full name", text: $nomineeName)
                    .foregroundColor(.white)
                    .padding(14)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    )
            }
            
            // Nominee Relationship
            VStack(alignment: .leading, spacing: 6) {
                Text("Nominee Relationship")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white.opacity(0.8))
                
                HStack(spacing: 8) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(relationships, id: \.self) { item in
                                Button {
                                    nomineeRelationship = item
                                } label: {
                                    Text(item)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(nomineeRelationship == item ? Color.brandEmerald : Color.white.opacity(0.1))
                                        .cornerRadius(10)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Validation & Submitting
    
    private var stepTitle: String {
        switch currentStep {
        case 0: return "Identity Setup"
        case 1: return "Professional Background"
        case 2: return "Account Preferences"
        case 3: return "Emergency Reference"
        default: return "Onboarding Form"
        }
    }
    
    private func prepopulateFieldsIfPossible() {
        if let currentProfile = profileStore.profile {
            // DOB is initialized to Date() on signup, which is fine
            if !currentProfile.panNumber.isEmpty { panNumber = currentProfile.panNumber }
            if !currentProfile.aadhaarNumber.isEmpty { aadhaarNumber = currentProfile.aadhaarNumber }
            if !currentProfile.occupation.isEmpty { occupation = currentProfile.occupation }
            if !currentProfile.employment.employmentType.isEmpty { employmentType = currentProfile.employment.employmentType }
            if !currentProfile.employment.companyName.isEmpty { companyName = currentProfile.employment.companyName }
            if currentProfile.income.monthlyIncome > 0 { monthlyIncome = String(Int(currentProfile.income.monthlyIncome)) }
            hasExistingBankAccount = currentProfile.hasExistingBankAccount
            if let cid = currentProfile.existingCustomerId { existingCustomerId = cid }
            if !currentProfile.preferredBranch.isEmpty { preferredBranch = currentProfile.preferredBranch }
            if !currentProfile.loanPurposeInterests.isEmpty { selectedInterests = Set(currentProfile.loanPurposeInterests) }
            if !currentProfile.emergencyContactName.isEmpty { emergencyContactName = currentProfile.emergencyContactName }
            if !currentProfile.emergencyContactNumber.isEmpty { emergencyContactNumber = currentProfile.emergencyContactNumber }
            if !currentProfile.nomineeName.isEmpty { nomineeName = currentProfile.nomineeName }
            if !currentProfile.nomineeRelationship.isEmpty { nomineeRelationship = currentProfile.nomineeRelationship }
        }
    }
    
    private func validateAndProceed() {
        showValidationError = false
        errorMessage = ""
        
        switch currentStep {
        case 0:
            // Identity step validations
            let calendar = Calendar.current
            let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
            let age = ageComponents.year ?? 0
            if age < 18 {
                showError("You must be at least 18 years old to proceed.")
                return
            }
            
            let panRegex = "^[A-Z]{5}[0-9]{4}[A-Z]{1}$"
            let panPredicate = NSPredicate(format: "SELF MATCHES %@", panRegex)
            if !panPredicate.evaluate(with: panNumber.uppercased()) {
                showError("Invalid PAN format. Must be like ABCDE1234F.")
                return
            }
            
            let aadhaarRegex = "^[0-9]{12}$"
            let aadhaarPredicate = NSPredicate(format: "SELF MATCHES %@", aadhaarRegex)
            if !aadhaarPredicate.evaluate(with: aadhaarNumber) {
                showError("Invalid Aadhaar number. Must be exactly 12 numeric digits.")
                return
            }
            
            withAnimation { currentStep += 1 }
            
        case 1:
            // Professional validations
            if occupation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showError("Occupation cannot be empty.")
                return
            }
            if companyName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showError("Company / Business Name cannot be empty.")
                return
            }
            guard let incomeVal = Double(monthlyIncome), incomeVal > 0 else {
                showError("Please enter a valid monthly income greater than 0.")
                return
            }
            
            withAnimation { currentStep += 1 }
            
        case 2:
            // Preferences validations
            if hasExistingBankAccount && existingCustomerId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showError("Please provide your existing Customer ID or disable the option.")
                return
            }
            
            withAnimation { currentStep += 1 }
            
        case 3:
            // Emergency Contact & Nominee validations
            if emergencyContactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showError("Emergency contact name cannot be empty.")
                return
            }
            let phoneRegex = "^[0-9]{10}$"
            let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
            // Strip spaces, dashes, or +91 prefixes for verification simplicity
            let cleanPhone = emergencyContactNumber.replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: "+91", with: "")
            if !phonePredicate.evaluate(with: cleanPhone) {
                showError("Emergency mobile number must be exactly 10 digits.")
                return
            }
            if nomineeName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                showError("Nominee name cannot be empty.")
                return
            }
            
            // Finish Questionnaire Onboarding!
            submitOnboardingQuestionnaire()
            
        default:
            break
        }
    }
    
    private func showError(_ msg: String) {
        withAnimation {
            errorMessage = msg
            showValidationError = true
        }
    }
    
    private func submitOnboardingQuestionnaire() {
        guard var updatedProfile = profileStore.profile else {
            showError("Active user profile session not found.")
            return
        }
        
        // Map details back into the active database profile
        updatedProfile.dateOfBirth = dateOfBirth
        updatedProfile.gender = gender
        updatedProfile.maritalStatus = maritalStatus
        updatedProfile.panNumber = panNumber.uppercased()
        updatedProfile.aadhaarNumber = aadhaarNumber
        
        // Mark KYC verified under the hood since they filled correct information
        updatedProfile.kycVerification.aadhaarStatus = .verified
        updatedProfile.kycVerification.panStatus = .verified
        updatedProfile.kycVerification.aadhaarFileName = "aadhaar_verified.pdf"
        updatedProfile.kycVerification.panFileName = "pan_verified.pdf"
        
        // Employment & Income mapping
        updatedProfile.occupation = occupation
        updatedProfile.employment = EmploymentInfo(
            employmentType: employmentType,
            companyName: companyName,
            designation: occupation,
            workExperienceYears: 2, // Default mock experience
            employerAddress: "Office Space, \(preferredBranch)"
        )
        let incomeVal = Double(monthlyIncome) ?? 0.0
        updatedProfile.income = IncomeInfo(
            monthlyIncome: incomeVal,
            annualIncome: incomeVal * 12.0,
            existingEMIs: 0.0,
            creditScore: 750, // Premium default eligibility
            incomeSource: employmentType
        )
        
        // bank preferences
        updatedProfile.hasExistingBankAccount = hasExistingBankAccount
        updatedProfile.existingCustomerId = hasExistingBankAccount ? existingCustomerId : nil
        updatedProfile.preferredBranch = preferredBranch
        updatedProfile.loanPurposeInterests = Array(selectedInterests)
        
        // nominee emergency references
        updatedProfile.emergencyContactName = emergencyContactName
        updatedProfile.emergencyContactNumber = emergencyContactNumber
        updatedProfile.nomineeName = nomineeName
        updatedProfile.nomineeRelationship = nomineeRelationship
        
        // Set completion flag!
        updatedProfile.isOnboardingCompleted = true
        
        // Setup initial Mock Loan & Bank Account for realistic display if they don't have one!
        if updatedProfile.loanOverview.activeLoans == 0 {
            // Mock bank details setup
            updatedProfile.bankDetails = BankDetails(
                bankName: "Astra Bank",
                accountHolderName: updatedProfile.fullName,
                accountNumber: "XXXXXX" + String(Int.random(in: 100000...999999)),
                ifscCode: "ASTA0001094",
                upiID: updatedProfile.fullName.replacingOccurrences(of: " ", with: "").lowercased() + "@okastra",
                isVerified: true
            )
        }
        
        // Push updates to save in UserDefaults accounts database
        withAnimation {
            profileStore.updateProfile(updatedProfile)
        }
    }
}

// Visual Effect View helper for modern premium glassmorphic blurs
struct VisualEffectView: UIViewRepresentable {
    var effect: UIVisualEffect?
    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView()
    }
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = effect
    }
}

#Preview {
    OnboardingQuestionnaireView()
        .environmentObject(AuthManager())
        .environmentObject(AppStateManager())
}
