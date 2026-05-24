import SwiftUI

// MARK: - Unified Content View (Shared Logic)
struct UnifiedProfileEditContentView: View {
    @ObservedObject var viewModel: BorrowerProfileViewModel
    
    // States
    @State private var fullName: String = ""
    @State private var gender: String = ""
    @State private var maritalStatus: String = ""
    @State private var nationality: String = ""
    @State private var dateOfBirth: Date = Date()
    @State private var aadhaarNumber: String = ""
    @State private var panNumber: String = ""
    @State private var mobileNumber: String = ""
    @State private var alternateNumber: String = ""
    @State private var email: String = ""
    @State private var streetAddress: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var zipCode: String = ""
    @State private var isSameAsCurrent: Bool = true
    @State private var employmentType: String = ""
    @State private var companyName: String = ""
    @State private var designation: String = ""
    @State private var monthlyIncome: String = ""
    @State private var occupation: String = ""
    @State private var hasExistingBankAccount: Bool = false
    @State private var existingCustomerId: String = ""
    @State private var preferredBranch: String = ""
    @State private var emergencyContactName: String = ""
    @State private var emergencyContactNumber: String = ""
    @State private var nomineeName: String = ""
    @State private var nomineeRelationship: String = ""
    
    private let relationships = ["Spouse", "Mother", "Father", "Brother", "Sister", "Child"]
    private let branches = [
        "Mumbai Main Branch",
        "Andheri Tech Park Branch",
        "Mindspace Malad Branch",
        "Bandra Kurla Complex Branch",
        "Delhi Connaught Place Branch",
        "Bengaluru Whitefield Branch"
    ]
    
    var isKYCVerified: Bool {
        viewModel.profile?.isKYCVerified ?? false
    }
    
    var body: some View {
        Form {
            // Identity Section
            Section {
                if isKYCVerified {
                    LabeledContent("Full Name", value: fullName)
                    LabeledContent("Date of Birth", value: viewModel.formatDate(dateOfBirth))
                    LabeledContent("Aadhaar Number", value: viewModel.maskedAccountNumber(aadhaarNumber))
                    LabeledContent("PAN Number", value: panNumber)
                } else {
                    TextField("Full Name", text: $fullName)
                    DatePicker("Date of Birth", selection: $dateOfBirth, displayedComponents: .date)
                    TextField("Aadhaar Number", text: $aadhaarNumber).keyboardType(.numberPad)
                    TextField("PAN Number", text: $panNumber).autocapitalization(.allCharacters)
                }
            } header: {
                Text("Identity Details")
            } footer: {
                if isKYCVerified {
                    Text("Identity details are locked after KYC. Contact support for changes.")
                }
            }
            
            // Personal Section
            Section {
                TextField("Gender", text: $gender)
                TextField("Marital Status", text: $maritalStatus)
                TextField("Nationality", text: $nationality)
            } header: {
                Text("Personal Info")
            }
            
            // Contact Section
            Section {
                TextField("Mobile Number", text: $mobileNumber).keyboardType(.phonePad)
                TextField("Alternate Mobile", text: $alternateNumber).keyboardType(.phonePad)
                TextField("Email Address", text: $email).keyboardType(.emailAddress).textInputAutocapitalization(.never)
            } header: {
                Text("Contact Details")
            }
            
            // Address Section
            Section {
                TextField("Street Address", text: $streetAddress)
                TextField("City", text: $city)
                TextField("State", text: $state)
                TextField("Zip Code", text: $zipCode).keyboardType(.numberPad)
                Toggle("Permanent same as current", isOn: $isSameAsCurrent)
            } header: {
                Text("Address Information")
            }
            
            // Employment Section
            Section {
                TextField("Employment Type", text: $employmentType)
                TextField("Company Name", text: $companyName)
                TextField("Designation", text: $designation)
                TextField("Monthly Income", text: $monthlyIncome).keyboardType(.numberPad)
            } header: {
                Text("Professional Info")
            }
            
            // References Section
            Section {
                TextField("Emergency Contact Name", text: $emergencyContactName)
                TextField("Emergency Contact Mobile", text: $emergencyContactNumber).keyboardType(.phonePad)
            } header: {
                Text("Emergency Contact")
            }
            
            // Nominee Section
            Section {
                TextField("Nominee Name", text: $nomineeName)
                Picker("Relationship", selection: $nomineeRelationship) {
                    ForEach(relationships, id: \.self) { Text($0).tag($0) }
                }
            } header: {
                Text("Nominee Details")
            }
            
            // Bank Preferences
            Section {
                TextField("Occupation", text: $occupation)
                Toggle("Existing Bank Customer", isOn: $hasExistingBankAccount)
                if hasExistingBankAccount {
                    TextField("Customer ID", text: $existingCustomerId)
                }
                Picker("Preferred Branch", selection: $preferredBranch) {
                    ForEach(branches, id: \.self) { Text($0).tag($0) }
                }
            } header: {
                Text("Bank Preferences")
            }
        }
        .onAppear(perform: loadInitialData)
        .onDisappear(perform: saveChanges)
    }
    
    private func loadInitialData() {
        if let p = viewModel.profile {
            fullName = p.fullName
            gender = p.gender
            maritalStatus = p.maritalStatus
            nationality = p.nationality
            dateOfBirth = p.dateOfBirth
            aadhaarNumber = p.aadhaarNumber
            panNumber = p.panNumber
            mobileNumber = p.mobileNumber
            alternateNumber = p.alternateNumber ?? ""
            email = p.email
            streetAddress = p.currentAddress.streetAddress
            city = p.currentAddress.city
            state = p.currentAddress.state
            zipCode = p.currentAddress.zipCode
            isSameAsCurrent = p.currentAddress.isSameAsCurrent
            employmentType = p.employment.employmentType
            companyName = p.employment.companyName
            designation = p.employment.designation
            monthlyIncome = String(format: "%.0f", p.income.monthlyIncome)
            occupation = p.occupation
            hasExistingBankAccount = p.hasExistingBankAccount
            existingCustomerId = p.existingCustomerId ?? ""
            preferredBranch = p.preferredBranch
            emergencyContactName = p.emergencyContactName
            emergencyContactNumber = p.emergencyContactNumber
            nomineeName = p.nomineeName
            nomineeRelationship = p.nomineeRelationship
        }
    }
    
    private func saveChanges() {
        viewModel.updatePersonalInfo(fullName: fullName, gender: gender, maritalStatus: maritalStatus, nationality: nationality, dateOfBirth: dateOfBirth, aadhaarNumber: aadhaarNumber, panNumber: panNumber)
        viewModel.updateContact(mobile: mobileNumber, email: email, alternate: alternateNumber)
        viewModel.updateAddress(street: streetAddress, city: city, state: state, zip: zipCode, isSame: isSameAsCurrent)
        viewModel.updateEmployment(type: employmentType, company: companyName, designation: designation, income: Double(monthlyIncome) ?? 0)
        viewModel.updateAdditionalInfo(occupation: occupation, hasExistingBankAccount: hasExistingBankAccount, existingCustomerId: existingCustomerId.isEmpty ? nil : existingCustomerId, preferredBranch: preferredBranch, emergencyContactName: emergencyContactName, emergencyContactNumber: emergencyContactNumber, nomineeName: nomineeName, nomineeRelationship: nomineeRelationship)
    }
}

// MARK: - Legacy View (Modal Wrapper)
struct UnifiedProfileEditView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: BorrowerProfileViewModel
    
    var body: some View {
        NavigationStack {
            UnifiedProfileEditContentView(viewModel: viewModel)
                .navigationTitle("Edit Profile")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                            .fontWeight(.bold)
                    }
                }
        }
    }
}
