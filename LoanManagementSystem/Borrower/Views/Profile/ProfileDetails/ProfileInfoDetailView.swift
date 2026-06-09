import SwiftUI

struct ProfileInfoDetailView: View {
    @Bindable var viewModel: BorrowerProfileViewModel
    @State private var showingEditView = false
    
    var body: some View {
        Form {
            if let profile = viewModel.profile {
                Section {
                    LabeledContent("Full Name") {
                        HStack(spacing: 4) {
                            Text(profile.fullName)
                            if profile.isKYCVerified {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(.blue)
                                    .font(.caption)
                            }
                        }
                    }
                    LabeledContent("Gender", value: profile.gender)
                    LabeledContent("Marital Status", value: profile.maritalStatus)
                    LabeledContent("Nationality", value: profile.nationality)
                    LabeledContent("Date of Birth", value: viewModel.formatDate(profile.dateOfBirth))
                } header: {
                    Text("Personal Details")
                }
                
                Section {
                    LabeledContent("Aadhaar Number", value: viewModel.maskedAccountNumber(profile.aadhaarNumber))
                    LabeledContent("PAN Number", value: profile.panNumber)
                } header: {
                    Text("Identity")
                }
                
                Section {
                    LabeledContent("Mobile Number") {
                        HStack {
                            Text(profile.mobileNumber)
                            if profile.isPhoneVerified {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Button("Verify") {
                                    viewModel.verifyMobile()
                                }
                                .font(.caption.bold())
                            }
                        }
                    }
                    
                    LabeledContent("Email Address") {
                        HStack {
                            Text(profile.email)
                            if profile.isEmailVerified {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Button("Verify") {
                                    viewModel.verifyEmail()
                                }
                                .font(.caption.bold())
                            }
                        }
                    }
                    
                    if let alt = profile.alternateNumber {
                        LabeledContent("Alternate Number", value: alt)
                    }
                } header: {
                    Text("Contact Details")
                }
                
                Section {
                    LabeledContent("Street", value: profile.currentAddress.streetAddress)
                    LabeledContent("City", value: profile.currentAddress.city)
                    LabeledContent("State", value: profile.currentAddress.state)
                    LabeledContent("ZIP Code", value: profile.currentAddress.zipCode)
                } header: {
                    Text("Current Address")
                }
                
                if !profile.permanentAddress.isSameAsCurrent {
                    Section {
                        LabeledContent("Street", value: profile.permanentAddress.streetAddress)
                        LabeledContent("City", value: profile.permanentAddress.city)
                        LabeledContent("State", value: profile.permanentAddress.state)
                        LabeledContent("ZIP Code", value: profile.permanentAddress.zipCode)
                    } header: {
                        Text("Permanent Address")
                    }
                }
                
                Section {
                    LabeledContent("Employment", value: profile.employment.employmentType)
                    LabeledContent("Company", value: profile.employment.companyName)
                    LabeledContent("Designation", value: profile.employment.designation)
                    LabeledContent("Monthly Income", value: viewModel.formatCurrency(profile.income.monthlyIncome))
                } header: {
                    Text("Professional Info")
                }
                
                Section {
                    LabeledContent("Emergency Contact", value: profile.emergencyContactName)
                    LabeledContent("Mobile", value: profile.emergencyContactNumber)
                } header: {
                    Text("Emergency Reference")
                }
                
                Section {
                    LabeledContent("Nominee Name", value: profile.nomineeName)
                    LabeledContent("Relationship", value: profile.nomineeRelationship)
                } header: {
                    Text("Nominee")
                }
                
            } else {
                ProgressView()
            }
        }
        .navigationTitle("Information")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditView = true
                }
            }
        }
        .navigationDestination(isPresented: $showingEditView) {
            UnifiedProfileEditScreen(viewModel: viewModel)
        }
    }
}

struct UnifiedProfileEditScreen: View {
    @Bindable var viewModel: BorrowerProfileViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        UnifiedProfileEditContentView(viewModel: viewModel)
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {

                        dismiss()
                    }
                    .fontWeight(.bold)
                }
            }
    }
}
