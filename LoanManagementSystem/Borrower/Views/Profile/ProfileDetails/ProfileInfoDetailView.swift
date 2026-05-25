import SwiftUI

struct ProfileInfoDetailView: View {
    @ObservedObject var viewModel: BorrowerProfileViewModel
    @State private var activeSheet: ProfileEditSheet?

    var body: some View {
        Form {
            if let profile = viewModel.profile {
                Section(header: Text("Personal Information")) {
                    DataRowView(label: "Full Name", value: profile.fullName, isVerified: profile.isKYCVerified)
                    DataRowView(label: "Gender", value: profile.gender)
                    DataRowView(label: "Marital Status", value: profile.maritalStatus)
                    DataRowView(label: "Nationality", value: profile.nationality)
                    DataRowView(label: "Date of Birth", value: viewModel.formatDate(profile.dateOfBirth), isVerified: profile.isKYCVerified)
                    DataRowView(label: "Aadhaar Number", value: viewModel.maskedAccountNumber(profile.aadhaarNumber), isVerified: profile.kycVerification.aadhaarStatus == .verified)
                    DataRowView(label: "PAN Number", value: profile.panNumber, isVerified: profile.kycVerification.panStatus == .verified)
                }


                Section(header: Text("Contact Information")) {
                    HStack {
                        DataRowView(label: "Mobile Number", value: profile.mobileNumber)
                        Spacer()
                        if profile.isPhoneVerified {
                            StatusBadgeView(status: "Verified")
                        } else {
                            Button(action: {
                                viewModel.verifyMobile()
                            }) {
                                Text("Verify")
                                    .font(Font.AppTheme.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.AppTheme.primary)
                            }
                        }
                    }

                    HStack {
                        DataRowView(label: "Email Address", value: profile.email)
                        Spacer()
                        if profile.isEmailVerified {
                            StatusBadgeView(status: "Verified")
                        } else {
                            Button(action: {
                                viewModel.verifyEmail()
                            }) {
                                Text("Verify")
                                    .font(Font.AppTheme.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.AppTheme.primary)
                            }
                        }
                    }

                    if let alt = profile.alternateNumber {
                        DataRowView(label: "Alternate Number", value: alt)
                    }
                }


                Section(header: Text("Current Address")) {
                    DataRowView(label: "Address", value: profile.currentAddress.streetAddress)
                    DataRowView(label: "City", value: profile.currentAddress.city)
                    DataRowView(label: "State", value: profile.currentAddress.state)
                    DataRowView(label: "ZIP Code", value: profile.currentAddress.zipCode)
                }

                if !profile.permanentAddress.isSameAsCurrent {
                    Section(header: Text("Permanent Address")) {
                        DataRowView(label: "Address", value: profile.permanentAddress.streetAddress)
                        DataRowView(label: "City", value: profile.permanentAddress.city)
                        DataRowView(label: "State", value: profile.permanentAddress.state)
                        DataRowView(label: "ZIP Code", value: profile.permanentAddress.zipCode)
                    }
                }


                Section(header: Text("Employment & Income")) {
                    DataRowView(label: "Employment Type", value: profile.employment.employmentType)
                    DataRowView(label: "Company", value: profile.employment.companyName)
                    DataRowView(label: "Designation", value: profile.employment.designation)
                    DataRowView(label: "Monthly Income", value: viewModel.formatCurrency(profile.income.monthlyIncome))
                }


                Section(header: Text("Emergency Reference Contact")) {
                    DataRowView(label: "Contact Name", value: profile.emergencyContactName)
                    DataRowView(label: "Mobile Number", value: profile.emergencyContactNumber)
                }

                Section(header: Text("Nominee Details")) {
                    DataRowView(label: "Nominee Name", value: profile.nomineeName)
                    DataRowView(label: "Relationship", value: profile.nomineeRelationship)
                }


                Section(header: Text("Bank Preferences")) {
                    DataRowView(label: "Preferred Branch", value: profile.preferredBranch)
                    DataRowView(label: "Occupation", value: profile.occupation)
                    DataRowView(label: "Existing Bank Customer", value: profile.hasExistingBankAccount ? "Yes (\(profile.existingCustomerId ?? "N/A"))" : "No")
                }

            } else {
                Text("Loading profile...")
            }
        }
        .navigationTitle("Profile Information")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button("Personal Info") { activeSheet = .personal }
                    Button("Contact Info") { activeSheet = .contact }
                    Button("Address Info") { activeSheet = .address }
                    Button("Employment") { activeSheet = .employment }
                    Button("References & Prefs") { activeSheet = .additional }
                } label: {
                    Text("Edit")
                        .foregroundStyle(Color.AppTheme.primary)
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .personal:
                EditPersonalInfoView(viewModel: viewModel)
            case .contact:
                EditContactInfoView(viewModel: viewModel)
            case .address:
                EditAddressInfoView(viewModel: viewModel)
            case .employment:
                EditEmploymentView(viewModel: viewModel)
            case .bank:
                EditBankDetailsView(viewModel: viewModel)
            case .kyc:
                EditKYCView(viewModel: viewModel)
            case .loan:
                EditLoanOverviewView(viewModel: viewModel)
            case .additional:
                EditAdditionalInfoView(viewModel: viewModel)
            }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileInfoDetailView(viewModel: PreviewSupport.borrowerProfileViewModel)
    }
}

