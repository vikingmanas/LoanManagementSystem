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
                
                // 2. Contact Information
                Section(header: Text("Contact Information")) {
                    HStack {
                        DataRowView(label: "Mobile Number", value: profile.mobileNumber)
                        Spacer()
                        if profile.isPhoneVerified {
                            StatusBadgeView(status: "Verified")
                        } else {
                            Button(action: {
                                activeSheet = .otpVerifyPhone
                            }) {
                                Text("Verify")
                                    .font(Font.AppTheme.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.AppTheme.primary)
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
                                activeSheet = .otpVerifyEmail
                            }) {
                                Text("Verify")
                                    .font(Font.AppTheme.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.AppTheme.primary)
                            }
                        }
                    }
                    
                    if let alt = profile.alternateNumber {
                        DataRowView(label: "Alternate Number", value: alt)
                    }
                }
                
                // 3. Address Information
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
                
                // 4. Employment & Income
                Section(header: Text("Employment & Income")) {
                    DataRowView(label: "Employment Type", value: profile.employment.employmentType)
                    DataRowView(label: "Company", value: profile.employment.companyName)
                    DataRowView(label: "Designation", value: profile.employment.designation)
                    DataRowView(label: "Monthly Income", value: viewModel.formatCurrency(profile.income.monthlyIncome))
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
                } label: {
                    Text("Edit")
                        .foregroundColor(Color.AppTheme.primary)
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
            case .otpVerifyPhone:
                OTPVerificationView(isForLogin: false) {
                    viewModel.verifyMobile()
                }
            case .otpVerifyEmail:
                OTPVerificationView(isForLogin: false) {
                    viewModel.verifyEmail()
                }
            }
        }
    }
}
