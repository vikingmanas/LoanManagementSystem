import Observation
import Foundation
import Combine
import Supabase

public struct UserAccount: Codable {
    public var email: String
    public var passwordHash: String
    public var customerId: String
    public var fullName: String
    public var mobile: String
    public var isOnboardingCompleted: Bool
    public var profile: BorrowerProfile?
}

@MainActor
@Observable
public class BorrowerProfileStore {
    public static let shared = BorrowerProfileStore()

    public var profile: BorrowerProfile?
    public var accounts: [UserAccount] = []
    var currentEmail: String?

    private init() {
        setupDefaultAccount()
    }

    private func setupDefaultAccount() {
        self.accounts = []
    }



    @discardableResult
    func ensureProfile(email: String, name: String? = nil, phone: String? = nil, alternatePhone: String? = nil) -> BorrowerProfile {
        let cleanedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if let current = profile, current.email == cleanedEmail {
            self.currentEmail = cleanedEmail
            Task {
                await refreshAuthenticatedProfile(
                    email: cleanedEmail,
                    name: name,
                    phone: phone,
                    alternatePhone: alternatePhone
                )
            }
            return current
        }

        let customerId = "C-\(Int.random(in: 100000...999999))"
        let placeholderProfile = makeEmptyProfile(
            name: name ?? cleanedEmail,
            email: cleanedEmail,
            phone: phone ?? "",
            alternatePhone: alternatePhone,
            customerId: customerId
        )
        self.currentEmail = cleanedEmail

        let isAuthenticatedBorrowerEmail = AuthManager.shared.currentUser?.email?.lowercased() == cleanedEmail
        if isAuthenticatedBorrowerEmail {
            self.profile = nil
        } else {
            self.profile = placeholderProfile
        }

        Task {
            if let currentUser = AuthManager.shared.currentUser,
               currentUser.email?.lowercased() == cleanedEmail {
                await fetchProfileFromSupabase(
                    uid: currentUser.uid,
                    email: cleanedEmail,
                    name: name,
                    phone: phone,
                    alternatePhone: alternatePhone
                )
                return
            }

            if let session = try? await SupabaseManager.shared.client.auth.session {
                let user = session.user
                if user.email?.lowercased() == cleanedEmail {
                    await fetchProfileFromSupabase(
                        uid: user.id.uuidString,
                        email: cleanedEmail,
                        name: name,
                        phone: phone,
                        alternatePhone: alternatePhone
                    )
                    return
                }
            }

            if ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" {
                if let account = accounts.first(where: { $0.email == cleanedEmail }) {
                    self.profile = account.profile
                    self.currentEmail = cleanedEmail
                }
            }
        }

        return placeholderProfile
    }

    private func refreshAuthenticatedProfile(email: String, name: String?, phone: String?, alternatePhone: String?) async {
        if let currentUser = AuthManager.shared.currentUser,
           currentUser.email?.lowercased() == email {
            await fetchProfileFromSupabase(
                uid: currentUser.uid,
                email: email,
                name: name,
                phone: phone,
                alternatePhone: alternatePhone
            )
            return
        }

        if let session = try? await SupabaseManager.shared.client.auth.session {
            let user = session.user
            if user.email?.lowercased() == email {
                await fetchProfileFromSupabase(
                    uid: user.id.uuidString,
                    email: email,
                    name: name,
                    phone: phone,
                    alternatePhone: alternatePhone
                )
            }
        }
    }

    func fetchProfileFromSupabase(uid: String, email: String, name: String? = nil, phone: String? = nil, alternatePhone: String? = nil) async {
        do {
            var resolvedUid = uid
            if UUID(uuidString: uid) == nil {
                let cleaned = uid.filter { $0.isHexDigit || $0.isNumber }
                let padded = (cleaned + "00000000000000000000000000000000").prefix(32)
                let part1 = padded.prefix(8)
                let part2 = padded.dropFirst(8).prefix(4)
                let part3 = padded.dropFirst(12).prefix(4)
                let part4 = padded.dropFirst(16).prefix(4)
                let part5 = padded.dropFirst(20).prefix(12)
                resolvedUid = "\(part1)-\(part2)-\(part3)-\(part4)-\(part5)"
            }
            
            if let decodedProfile = try await DatabaseService.shared.fetchProfile(userId: uid) {
                self.profile = decodedProfile
                if let borrowerId = UUID(uuidString: resolvedUid) {
                    await CentralLoanRepository.shared.fetchApplicationsFromSupabase(borrowerId: borrowerId)
                }
            } else {


                let customerId = "C-\(Int.random(in: 100000...999999))"
                var newProfile = makeEmptyProfile(
                    name: name ?? email,
                    email: email,
                    phone: phone ?? "",
                    alternatePhone: alternatePhone,
                    customerId: customerId
                )
                newProfile.id = uid
                self.profile = newProfile
                try? await DatabaseService.shared.updateProfile(newProfile)
                if let borrowerId = UUID(uuidString: resolvedUid) {
                    await CentralLoanRepository.shared.fetchApplicationsFromSupabase(borrowerId: borrowerId)
                }
            }
            self.currentEmail = email
        } catch {
            print("Error fetching profile from Supabase: \(error.localizedDescription)")


            if let cachedProfile = DatabaseService.shared.loadProfileLocally(userId: uid) {
                self.profile = cachedProfile
            } else {
                let customerId = "C-\(Int.random(in: 100000...999999))"
                var fallbackProfile = makeEmptyProfile(name: name ?? email, email: email, phone: phone ?? "", alternatePhone: alternatePhone, customerId: customerId)
                fallbackProfile.id = uid
                self.profile = fallbackProfile
            }
            self.currentEmail = email
        }
    }

    func borrowerProfile(matchingEmail email: String) -> BorrowerProfile? {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty else { return nil }

        if let current = profile, current.email.lowercased() == normalized {
            return current
        }

        if let account = accounts.first(where: { $0.email.lowercased() == normalized }) {
            return account.profile
        }

        return nil
    }

    @discardableResult
    func provisionODAccountForApprovedLoan(
        email: String,
        applicationId: UUID,
        applicationNumber: String,
        borrowerName: String,
        sanctionedAmount: Double
    ) -> String? {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty, sanctionedAmount > 0,
              var borrowerProfile = borrowerProfile(matchingEmail: normalized) else {
            return nil
        }

        var linkedAccounts = borrowerProfile.linkedAccounts ?? []
        if let existingIndex = linkedAccounts.firstIndex(where: {
            $0.linkedLoanApplicationId == applicationId && $0.isOverdraftAccount
        }) {
            var hasChanges = false
            if linkedAccounts[existingIndex].balance == 0 {
                linkedAccounts[existingIndex].balance = sanctionedAmount
                hasChanges = true
            }
            if (linkedAccounts[existingIndex].odSanctionLimit ?? 0) < sanctionedAmount {
                linkedAccounts[existingIndex].odSanctionLimit = sanctionedAmount
                hasChanges = true
            }
            if hasChanges {
                borrowerProfile.linkedAccounts = linkedAccounts
                persistBorrowerProfile(borrowerProfile, email: normalized)
            }
            return linkedAccounts[existingIndex].accountNumber
        }

        let customerId = borrowerProfile.existingCustomerId ?? borrowerProfile.id
        let holderName = borrowerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? borrowerProfile.fullName
            : borrowerName
        let bank = borrowerProfile.bankDetails
        let odAccountNumber = makeODAccountNumber(customerId: customerId, applicationNumber: applicationNumber)

        let odAccount = LinkedBankAccount(
            bankName: bank.bankName.isEmpty ? "LMS Bank" : bank.bankName,
            accountNumber: odAccountNumber,
            ifscCode: bank.ifscCode.isEmpty ? "LMSB0000001" : bank.ifscCode,
            balance: sanctionedAmount,
            branch: borrowerProfile.preferredBranch.isEmpty ? "Home Branch" : borrowerProfile.preferredBranch,
            customerId: customerId,
            accountHolderName: holderName,
            accountKind: .overdraft,
            linkedLoanApplicationId: applicationId,
            odSanctionLimit: sanctionedAmount
        )

        linkedAccounts.append(odAccount)
        borrowerProfile.linkedAccounts = linkedAccounts
        borrowerProfile.loanOverview = LoanOverview(
            activeLoans: borrowerProfile.loanOverview.activeLoans + 1,
            loanHistoryCount: borrowerProfile.loanOverview.loanHistoryCount + 1,
            nextEmiDueDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
            remainingBalance: borrowerProfile.loanOverview.remainingBalance + sanctionedAmount,
            currentLoanStatus: "Approved"
        )

        persistBorrowerProfile(borrowerProfile, email: normalized)
        return odAccountNumber
    }

    func updateLinkedAccountBalance(accountId: UUID, balance: Double) {
        guard var borrowerProfile = profile,
              var linkedAccounts = borrowerProfile.linkedAccounts,
              let index = linkedAccounts.firstIndex(where: { $0.id == accountId }) else {
            return
        }

        linkedAccounts[index].balance = balance
        borrowerProfile.linkedAccounts = linkedAccounts
        updateProfile(borrowerProfile)
    }

    func creditBorrower(email: String, amount: Double, accountNumber: String) {
        let normalized = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty, amount > 0 else { return }

        guard var borrowerProfile = borrowerProfile(matchingEmail: normalized) else { return }

        var linkedAccounts = borrowerProfile.linkedAccounts ?? []
        if let index = linkedAccounts.firstIndex(where: { $0.accountNumber == accountNumber }) {
            linkedAccounts[index].balance += amount
        } else if !borrowerProfile.bankDetails.accountNumber.isEmpty {
            let bank = borrowerProfile.bankDetails
            linkedAccounts.append(
                LinkedBankAccount(
                    id: UUID(),
                    bankName: bank.bankName.isEmpty ? "Primary Account" : bank.bankName,
                    accountNumber: bank.accountNumber,
                    ifscCode: bank.ifscCode,
                    balance: amount,
                    branch: borrowerProfile.preferredBranch,
                    customerId: borrowerProfile.existingCustomerId ?? borrowerProfile.id
                )
            )
        } else if accountNumber != "0000000000" {
            linkedAccounts.append(
                LinkedBankAccount(
                    id: UUID(),
                    bankName: "Loan Disbursement Account",
                    accountNumber: accountNumber,
                    ifscCode: "",
                    balance: amount,
                    branch: "",
                    customerId: borrowerProfile.existingCustomerId ?? borrowerProfile.id
                )
            )
        }
        borrowerProfile.linkedAccounts = linkedAccounts
        borrowerProfile.loanOverview = LoanOverview(
            activeLoans: borrowerProfile.loanOverview.activeLoans + 1,
            loanHistoryCount: borrowerProfile.loanOverview.loanHistoryCount + 1,
            nextEmiDueDate: Calendar.current.date(byAdding: .month, value: 1, to: Date()),
            remainingBalance: borrowerProfile.loanOverview.remainingBalance + amount,
            currentLoanStatus: "Approved"
        )

        persistBorrowerProfile(borrowerProfile, email: normalized)
    }

    private func persistBorrowerProfile(_ borrowerProfile: BorrowerProfile, email normalizedEmail: String) {
        if profile?.email.lowercased() == normalizedEmail {
            updateProfile(borrowerProfile)
            return
        }

        if let index = accounts.firstIndex(where: { $0.email.lowercased() == normalizedEmail }) {
            accounts[index].profile = borrowerProfile
        }
    }

    private func makeODAccountNumber(customerId: String, applicationNumber: String) -> String {
        let customerDigits = customerId.filter(\.isNumber)
        let customerSuffix = customerDigits.isEmpty
            ? String(customerId.suffix(4)).uppercased()
            : String(customerDigits.suffix(6))
        let applicationSuffix = applicationNumber
            .replacingOccurrences(of: "APP-", with: "")
            .filter(\.isNumber)
        let applicationPart = applicationSuffix.isEmpty
            ? String(Int.random(in: 1000...9999))
            : String(applicationSuffix.suffix(4))
        return "OD\(customerSuffix)\(applicationPart)"
    }

    func updateProfile(_ updatedProfile: BorrowerProfile) {
        self.profile = updatedProfile

        Task {
            do {
                if let session = try? await SupabaseManager.shared.client.auth.session {
                    let user = session.user
                    var profileWithUid = updatedProfile
                    profileWithUid.id = user.id.uuidString
                    try await DatabaseService.shared.updateProfile(profileWithUid)
                    print("[BorrowerProfileStore] Profile synchronization completed successfully. ✅")
                } else {
                    print("[BorrowerProfileStore] No active Supabase session — saving locally only.")
                    if let index = accounts.firstIndex(where: { $0.email == updatedProfile.email }) {
                        accounts[index].profile = updatedProfile
                        accounts[index].isOnboardingCompleted = updatedProfile.isOnboardingCompleted
                    }
                }
            } catch {
                print("[BorrowerProfileStore] ❌ ERROR syncing profile to Supabase: \(error)")
                print("[BorrowerProfileStore] ❌ Localized: \(error.localizedDescription)")
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

    private func makeEmptyProfile(name: String, email: String, phone: String, alternatePhone: String? = nil, customerId: String) -> BorrowerProfile {
        BorrowerProfile(
            id: customerId,
            fullName: name,
            email: email,
            mobileNumber: phone,
            alternateNumber: alternatePhone,
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
            income: IncomeInfo(monthlyIncome: 0, annualIncome: 0, existingEMIs: 0, creditScore: 0, incomeSource: ""),
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
