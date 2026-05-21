import Foundation
import Combine

struct UserAccount: Codable {
    var email: String
    var passwordHash: String
    var customerId: String
    var fullName: String
    var mobile: String
    var isOnboardingCompleted: Bool
    var profile: BorrowerProfile?
}

class BorrowerProfileStore: ObservableObject {
    static let shared = BorrowerProfileStore()

    @Published var profile: BorrowerProfile?
    @Published var accounts: [UserAccount] = []
    @Published var currentEmail: String?

    private let accountsKey = "lms_persisted_accounts"
    private let activeSessionKey = "lms_active_session_email"

    private init() {
        loadAccountsFromDisk()
        loadActiveSession()
    }

    // MARK: - Local Disk Operations

    func loadAccountsFromDisk() {
        if let data = UserDefaults.standard.data(forKey: accountsKey),
           let decoded = try? JSONDecoder().decode([UserAccount].self, from: data) {
            self.accounts = decoded
        } else {
            // Setup default mock account (Rahul Sharma)
            setupDefaultAccount()
        }
    }

    func saveAccountsToDisk() {
        if let encoded = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(encoded, forKey: accountsKey)
        }
    }

    private func loadActiveSession() {
        if let activeEmail = UserDefaults.standard.string(forKey: activeSessionKey),
           let account = accounts.first(where: { $0.email == activeEmail }) {
            self.currentEmail = activeEmail
            self.profile = account.profile
        }
    }

    private func saveActiveSession(_ email: String?) {
        if let email = email {
            UserDefaults.standard.set(email, forKey: activeSessionKey)
        } else {
            UserDefaults.standard.removeObject(forKey: activeSessionKey)
        }
    }

    private func setupDefaultAccount() {
        let rahulProfile = BorrowerProfile(
            id: "C-109482",
            fullName: "Rahul Sharma",
            email: "rahul.sharma@example.com",
            mobileNumber: "+91 98765 43210",
            alternateNumber: "+91 91234 56789",
            dateOfBirth: Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date(),
            gender: "Male",
            maritalStatus: "Single",
            nationality: "Indian",
            aadhaarNumber: "123456789012",
            panNumber: "ABCDE1234F",
            isEmailVerified: true,
            isPhoneVerified: true,
            currentAddress: AddressInfo(streetAddress: "14B, Tech Park Road, Andheri East", city: "Mumbai", state: "Maharashtra", zipCode: "400069", country: "India", isSameAsCurrent: true),
            permanentAddress: AddressInfo(streetAddress: "14B, Tech Park Road, Andheri East", city: "Mumbai", state: "Maharashtra", zipCode: "400069", country: "India", isSameAsCurrent: true),
            employment: EmploymentInfo(employmentType: "Salaried", companyName: "Tech Global Pvt Ltd.", designation: "Senior Software Engineer", workExperienceYears: 8, employerAddress: "Mindspace, Malad West, Mumbai"),
            income: IncomeInfo(monthlyIncome: 120000.0, annualIncome: 1440000.0, existingEMIs: 15000.0, creditScore: 780, incomeSource: "Salary"),
            bankDetails: BankDetails(bankName: "HDFC Bank", accountHolderName: "Rahul Sharma", accountNumber: "50100234567890", ifscCode: "HDFC0001234", upiID: "rahulsharma@okhdfcbank", isVerified: true),
            kycVerification: KYCVerification(aadhaarStatus: .verified, panStatus: .verified, addressProofStatus: .rejected, selfieStatus: .verified, aadhaarFileName: "aadhaar_card.pdf", panFileName: "pan_card.pdf", addressProofFileName: nil),
            loanOverview: LoanOverview(activeLoans: 1, loanHistoryCount: 2, nextEmiDueDate: Calendar.current.date(byAdding: .day, value: 15, to: Date()), remainingBalance: 450000.0, currentLoanStatus: "Active"),
            profileImageData: nil,
            occupation: "Senior Software Engineer",
            industry: "Technology",
            yearsOfExperience: 8,
            hasExistingBankAccount: true,
            existingCustomerId: "C-109482",
            preferredBranch: "Andheri East Branch",
            existingLoansCount: 1,
            existingCreditCardsCount: 1,
            bankingRelationshipDuration: "2 Years",
            averageMonthlyBalance: 85000,
            emergencyContactName: "Priya Sharma",
            emergencyContactNumber: "+91 98765 00000",
            emergencyContactAlternateNumber: "",
            emergencyContactAddress: "Mumbai",
            emergencyContactRelationship: "Spouse",
            nomineeName: "Geeta Sharma",
            nomineeRelationship: "Mother",
            isOnboardingCompleted: true
        )

        let rahulAccount = UserAccount(
            email: "rahul.sharma@example.com",
            passwordHash: "password",
            customerId: "C-109482",
            fullName: "Rahul Sharma",
            mobile: "+91 98765 43210",
            isOnboardingCompleted: true,
            profile: rahulProfile
        )

        self.accounts = [rahulAccount]
        saveAccountsToDisk()
    }

    // MARK: - Actions

    @discardableResult
    func ensureProfile(email: String, name: String? = nil, phone: String? = nil) -> BorrowerProfile {
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanedPhone = phone?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if let index = accounts.firstIndex(where: { $0.email == cleanedEmail }) {
            currentEmail = accounts[index].email
            profile = accounts[index].profile
            saveActiveSession(accounts[index].email)

            if let existingProfile = accounts[index].profile {
                return existingProfile
            }

            let recoveredProfile = makeEmptyProfile(
                name: accounts[index].fullName,
                email: accounts[index].email,
                phone: accounts[index].mobile,
                customerId: accounts[index].customerId
            )
            accounts[index].profile = recoveredProfile
            profile = recoveredProfile
            saveAccountsToDisk()
            return recoveredProfile
        }

        let customerId = "C-\(Int.random(in: 100000...999999))"
        let displayName = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        let profile = makeEmptyProfile(
            name: displayName?.isEmpty == false ? displayName! : cleanedEmail,
            email: cleanedEmail,
            phone: cleanedPhone,
            customerId: customerId
        )

        let newAccount = UserAccount(
            email: cleanedEmail,
            passwordHash: "",
            customerId: customerId,
            fullName: profile.fullName,
            mobile: cleanedPhone,
            isOnboardingCompleted: false,
            profile: profile
        )

        accounts.append(newAccount)
        saveAccountsToDisk()
        currentEmail = cleanedEmail
        self.profile = profile
        saveActiveSession(cleanedEmail)
        return profile
    }

    func updateProfile(_ updatedProfile: BorrowerProfile) {
        self.profile = updatedProfile

        guard let activeEmail = currentEmail,
              let index = accounts.firstIndex(where: { $0.email == activeEmail }) else { return }

        accounts[index].profile = updatedProfile
        accounts[index].isOnboardingCompleted = updatedProfile.isOnboardingCompleted
        saveAccountsToDisk()
    }

    func skipOnboarding() {
        guard var activeProfile = profile else { return }
        activeProfile.isOnboardingCompleted = true
        updateProfile(activeProfile)
    }

    func signOut() {
        self.profile = nil
        self.currentEmail = nil
        saveActiveSession(nil)
    }

    private func makeEmptyProfile(name: String, email: String, phone: String, customerId: String) -> BorrowerProfile {
        BorrowerProfile(
            id: customerId,
            fullName: name,
            email: email,
            mobileNumber: phone,
            alternateNumber: nil,
            dateOfBirth: Date(),
            gender: "",
            maritalStatus: "",
            nationality: "",
            aadhaarNumber: "",
            panNumber: "",
            isEmailVerified: true,
            isPhoneVerified: !phone.isEmpty,
            currentAddress: AddressInfo(streetAddress: "", city: "", state: "", zipCode: "", country: "India", isSameAsCurrent: true),
            permanentAddress: AddressInfo(streetAddress: "", city: "", state: "", zipCode: "", country: "India", isSameAsCurrent: true),
            employment: EmploymentInfo(employmentType: "", companyName: "", designation: "", workExperienceYears: 0, employerAddress: ""),
            income: IncomeInfo(monthlyIncome: 0, annualIncome: 0, existingEMIs: 0, creditScore: 700, incomeSource: ""),
            bankDetails: BankDetails(bankName: "", accountHolderName: "", accountNumber: "", ifscCode: "", upiID: nil, isVerified: false),
            kycVerification: KYCVerification(aadhaarStatus: .pending, panStatus: .pending, addressProofStatus: .pending, selfieStatus: .pending, aadhaarFileName: nil, panFileName: nil, addressProofFileName: nil),
            loanOverview: LoanOverview(activeLoans: 0, loanHistoryCount: 0, nextEmiDueDate: nil, remainingBalance: 0.0, currentLoanStatus: "Pending Onboarding"),
            profileImageData: nil,
            occupation: "",
            industry: "",
            yearsOfExperience: 0,
            hasExistingBankAccount: false,
            existingCustomerId: nil,
            preferredBranch: "",
            existingLoansCount: 0,
            existingCreditCardsCount: 0,
            bankingRelationshipDuration: "",
            averageMonthlyBalance: 0,
            emergencyContactName: "",
            emergencyContactNumber: "",
            emergencyContactAlternateNumber: "",
            emergencyContactAddress: "",
            emergencyContactRelationship: "",
            nomineeName: "",
            nomineeRelationship: "",
            isOnboardingCompleted: false
        )
    }
}
