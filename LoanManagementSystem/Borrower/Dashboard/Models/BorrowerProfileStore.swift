import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

struct UserAccount: Codable {
    var email: String
    var passwordHash: String
    var customerId: String
    var fullName: String
    var mobile: String
    var isOnboardingCompleted: Bool
    var profile: BorrowerProfile?
}

@MainActor
class BorrowerProfileStore: ObservableObject {
    static let shared = BorrowerProfileStore()

    @Published var profile: BorrowerProfile?
    @Published var accounts: [UserAccount] = []
    @Published var currentEmail: String?

    private init() {
        if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
            setupDefaultAccount()
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
    }

    // MARK: - Actions

    @discardableResult
    func ensureProfile(email: String, name: String? = nil, phone: String? = nil) -> BorrowerProfile {
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if let current = profile, current.email == cleanedEmail {
            return current
        }

        if let user = Auth.auth().currentUser, user.email?.lowercased() == cleanedEmail {
            Task {
                await fetchProfileFromFirestore(uid: user.uid, email: cleanedEmail, name: name, phone: phone)
            }
        } else {
            // Previews / offline mock check
            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                if let account = accounts.first(where: { $0.email == cleanedEmail }) {
                    self.profile = account.profile
                    self.currentEmail = cleanedEmail
                    return account.profile!
                }
            }
            
            let customerId = "C-\(Int.random(in: 100000...999999))"
            let fallbackProfile = makeEmptyProfile(name: name ?? cleanedEmail, email: cleanedEmail, phone: phone ?? "", customerId: customerId)
            self.profile = fallbackProfile
            self.currentEmail = cleanedEmail
        }

        return self.profile ?? makeEmptyProfile(name: name ?? cleanedEmail, email: cleanedEmail, phone: phone ?? "", customerId: "")
    }

    func fetchProfileFromFirestore(uid: String, email: String, name: String? = nil, phone: String? = nil) async {
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)

        do {
            let document = try await docRef.getDocument()
            if document.exists, let data = document.data() {
                if let profileData = data["profile"] as? [String: Any],
                   let decodedProfile = BorrowerProfile.from(dictionary: profileData) {
                    self.profile = decodedProfile
                } else {
                    let customerId = "C-\(Int.random(in: 100000...999999))"
                    let newProfile = makeEmptyProfile(
                        name: name ?? data["fullName"] as? String ?? email,
                        email: email,
                        phone: phone ?? data["mobileNumber"] as? String ?? "",
                        customerId: customerId
                    )
                    self.profile = newProfile
                    try await docRef.updateData(["profile": newProfile.asDictionary ?? [:]])
                }
            } else {
                let customerId = "C-\(Int.random(in: 100000...999999))"
                let newProfile = makeEmptyProfile(
                    name: name ?? email,
                    email: email,
                    phone: phone ?? "",
                    customerId: customerId
                )
                self.profile = newProfile
                let userDoc: [String: Any] = [
                    "fullName": name ?? email,
                    "email": email,
                    "mobileNumber": phone ?? "",
                    "role": "borrower",
                    "createdAt": FieldValue.serverTimestamp(),
                    "updatedAt": FieldValue.serverTimestamp(),
                    "profile": newProfile.asDictionary ?? [:]
                ]
                try await docRef.setData(userDoc)
            }
            self.currentEmail = email
        } catch {
            print("Error fetching profile from Firestore: \(error.localizedDescription)")
            let customerId = "C-\(Int.random(in: 100000...999999))"
            self.profile = makeEmptyProfile(name: name ?? email, email: email, phone: phone ?? "", customerId: customerId)
            self.currentEmail = email
        }
    }

    func updateProfile(_ updatedProfile: BorrowerProfile) {
        self.profile = updatedProfile

        guard let user = Auth.auth().currentUser else {
            if let index = accounts.firstIndex(where: { $0.email == updatedProfile.email }) {
                accounts[index].profile = updatedProfile
                accounts[index].isOnboardingCompleted = updatedProfile.isOnboardingCompleted
            }
            return
        }

        let uid = user.uid
        Task {
            let db = Firestore.firestore()
            let docRef = db.collection("users").document(uid)
            do {
                try await docRef.updateData([
                    "profile": updatedProfile.asDictionary ?? [:],
                    "updatedAt": FieldValue.serverTimestamp()
                ])
            } catch {
                print("Error updating profile in Firestore: \(error.localizedDescription)")
            }
        }
    }

    func skipOnboarding() {
        guard var activeProfile = profile else { return }
        activeProfile.isOnboardingCompleted = true
        updateProfile(activeProfile)
    }

    func signOut() {
        self.profile = nil
        self.currentEmail = nil
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

// MARK: - Codable Extensions for Firestore Serialization

extension Encodable {
    var asDictionary: [String: Any]? {
        guard let data = try? JSONEncoder().encode(self) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
    }
}

extension Decodable {
    static func from(dictionary: [String: Any]) -> Self? {
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else { return nil }
        return try? JSONDecoder().decode(Self.self, from: data)
    }
}
