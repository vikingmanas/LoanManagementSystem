import Foundation
import Supabase


/// A database-safe representation of BorrowerProfile that exactly matches
/// the Supabase `profiles` table schema. Fields like `linkedAccounts`,
/// `gstNumber`, etc. that don't exist in the DB are excluded.
/// `profileImageData` is stored as a Base64-encoded string to match the `text` column.
private struct DBProfile: Codable {
    let id: String
    var fullName: String
    var email: String
    var mobileNumber: String
    var alternateNumber: String?
    var dateOfBirth: Date
    var gender: String
    var maritalStatus: String
    var nationality: String
    var aadhaarNumber: String
    var panNumber: String

    var isEmailVerified: Bool
    var isPhoneVerified: Bool

    var currentAddress: AddressInfo
    var permanentAddress: AddressInfo

    var employment: EmploymentInfo
    var income: IncomeInfo

    var bankDetails: BankDetails

    var kycVerification: KYCVerification
    var loanOverview: LoanOverview

    var profileImageData: String?  // Base64-encoded string — DB column is `text`

    var occupation: String
    var industry: String
    var yearsOfExperience: Int
    var hasExistingBankAccount: Bool
    var existingCustomerId: String?
    var preferredBranch: String
    var existingLoansCount: Int
    var existingCreditCardsCount: Int
    var bankingRelationshipDuration: String
    var averageMonthlyBalance: Double

    var emergencyContactName: String
    var emergencyContactNumber: String
    var emergencyContactAlternateNumber: String
    var emergencyContactAddress: String
    var emergencyContactRelationship: String
    var nomineeName: String
    var nomineeRelationship: String
    var isOnboardingCompleted: Bool

    init(id: String, fullName: String, email: String, mobileNumber: String, alternateNumber: String?, dateOfBirth: Date, gender: String, maritalStatus: String, nationality: String, aadhaarNumber: String, panNumber: String, isEmailVerified: Bool, isPhoneVerified: Bool, currentAddress: AddressInfo, permanentAddress: AddressInfo, employment: EmploymentInfo, income: IncomeInfo, bankDetails: BankDetails, kycVerification: KYCVerification, loanOverview: LoanOverview, profileImageData: String?, occupation: String, industry: String, yearsOfExperience: Int, hasExistingBankAccount: Bool, existingCustomerId: String?, preferredBranch: String, existingLoansCount: Int, existingCreditCardsCount: Int, bankingRelationshipDuration: String, averageMonthlyBalance: Double, emergencyContactName: String, emergencyContactNumber: String, emergencyContactAlternateNumber: String, emergencyContactAddress: String, emergencyContactRelationship: String, nomineeName: String, nomineeRelationship: String, isOnboardingCompleted: Bool) {
        self.id = id
        self.fullName = fullName
        self.email = email
        self.mobileNumber = mobileNumber
        self.alternateNumber = alternateNumber
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.maritalStatus = maritalStatus
        self.nationality = nationality
        self.aadhaarNumber = aadhaarNumber
        self.panNumber = panNumber
        self.isEmailVerified = isEmailVerified
        self.isPhoneVerified = isPhoneVerified
        self.currentAddress = currentAddress
        self.permanentAddress = permanentAddress
        self.employment = employment
        self.income = income
        self.bankDetails = bankDetails
        self.kycVerification = kycVerification
        self.loanOverview = loanOverview
        self.profileImageData = profileImageData
        self.occupation = occupation
        self.industry = industry
        self.yearsOfExperience = yearsOfExperience
        self.hasExistingBankAccount = hasExistingBankAccount
        self.existingCustomerId = existingCustomerId
        self.preferredBranch = preferredBranch
        self.existingLoansCount = existingLoansCount
        self.existingCreditCardsCount = existingCreditCardsCount
        self.bankingRelationshipDuration = bankingRelationshipDuration
        self.averageMonthlyBalance = averageMonthlyBalance
        self.emergencyContactName = emergencyContactName
        self.emergencyContactNumber = emergencyContactNumber
        self.emergencyContactAlternateNumber = emergencyContactAlternateNumber
        self.emergencyContactAddress = emergencyContactAddress
        self.emergencyContactRelationship = emergencyContactRelationship
        self.nomineeName = nomineeName
        self.nomineeRelationship = nomineeRelationship
        self.isOnboardingCompleted = isOnboardingCompleted
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        fullName = try container.decodeIfPresent(String.self, forKey: .fullName) ?? ""
        email = try container.decodeIfPresent(String.self, forKey: .email) ?? ""
        mobileNumber = try container.decodeIfPresent(String.self, forKey: .mobileNumber) ?? ""
        alternateNumber = try container.decodeIfPresent(String.self, forKey: .alternateNumber)
        dateOfBirth = try container.decodeIfPresent(Date.self, forKey: .dateOfBirth) ?? Date()
        gender = try container.decodeIfPresent(String.self, forKey: .gender) ?? ""
        maritalStatus = try container.decodeIfPresent(String.self, forKey: .maritalStatus) ?? ""
        nationality = try container.decodeIfPresent(String.self, forKey: .nationality) ?? ""
        aadhaarNumber = try container.decodeIfPresent(String.self, forKey: .aadhaarNumber) ?? ""
        panNumber = try container.decodeIfPresent(String.self, forKey: .panNumber) ?? ""
        
        isEmailVerified = try container.decodeIfPresent(Bool.self, forKey: .isEmailVerified) ?? false
        isPhoneVerified = try container.decodeIfPresent(Bool.self, forKey: .isPhoneVerified) ?? false
        
        currentAddress = try container.decodeIfPresent(AddressInfo.self, forKey: .currentAddress) ?? AddressInfo(streetAddress: "", city: "", state: "", zipCode: "", country: "India", isSameAsCurrent: true)
        permanentAddress = try container.decodeIfPresent(AddressInfo.self, forKey: .permanentAddress) ?? AddressInfo(streetAddress: "", city: "", state: "", zipCode: "", country: "India", isSameAsCurrent: true)
        
        employment = try container.decodeIfPresent(EmploymentInfo.self, forKey: .employment) ?? EmploymentInfo(employmentType: "", companyName: "", designation: "", workExperienceYears: 0, employerAddress: "")
        income = try container.decodeIfPresent(IncomeInfo.self, forKey: .income) ?? IncomeInfo(monthlyIncome: 0.0, annualIncome: 0.0, existingEMIs: 0.0, creditScore: 700, incomeSource: "")
        
        bankDetails = try container.decodeIfPresent(BankDetails.self, forKey: .bankDetails) ?? BankDetails(bankName: "", accountHolderName: "", accountNumber: "", ifscCode: "", upiID: nil, isVerified: false)
        
        kycVerification = try container.decodeIfPresent(KYCVerification.self, forKey: .kycVerification) ?? KYCVerification(aadhaarStatus: .pending, panStatus: .pending, addressProofStatus: .pending, selfieStatus: .pending)
        loanOverview = try container.decodeIfPresent(LoanOverview.self, forKey: .loanOverview) ?? LoanOverview(activeLoans: 0, loanHistoryCount: 0, nextEmiDueDate: nil, remainingBalance: 0.0, currentLoanStatus: "None")
        
        profileImageData = try container.decodeIfPresent(String.self, forKey: .profileImageData)
        
        occupation = try container.decodeIfPresent(String.self, forKey: .occupation) ?? ""
        industry = try container.decodeIfPresent(String.self, forKey: .industry) ?? ""
        yearsOfExperience = try container.decodeIfPresent(Int.self, forKey: .yearsOfExperience) ?? 0
        hasExistingBankAccount = try container.decodeIfPresent(Bool.self, forKey: .hasExistingBankAccount) ?? false
        existingCustomerId = try container.decodeIfPresent(String.self, forKey: .existingCustomerId)
        preferredBranch = try container.decodeIfPresent(String.self, forKey: .preferredBranch) ?? ""
        existingLoansCount = try container.decodeIfPresent(Int.self, forKey: .existingLoansCount) ?? 0
        existingCreditCardsCount = try container.decodeIfPresent(Int.self, forKey: .existingCreditCardsCount) ?? 0
        bankingRelationshipDuration = try container.decodeIfPresent(String.self, forKey: .bankingRelationshipDuration) ?? ""
        averageMonthlyBalance = try container.decodeIfPresent(Double.self, forKey: .averageMonthlyBalance) ?? 0.0
        
        emergencyContactName = try container.decodeIfPresent(String.self, forKey: .emergencyContactName) ?? ""
        emergencyContactNumber = try container.decodeIfPresent(String.self, forKey: .emergencyContactNumber) ?? ""
        emergencyContactAlternateNumber = try container.decodeIfPresent(String.self, forKey: .emergencyContactAlternateNumber) ?? ""
        emergencyContactAddress = try container.decodeIfPresent(String.self, forKey: .emergencyContactAddress) ?? ""
        emergencyContactRelationship = try container.decodeIfPresent(String.self, forKey: .emergencyContactRelationship) ?? ""
        nomineeName = try container.decodeIfPresent(String.self, forKey: .nomineeName) ?? ""
        nomineeRelationship = try container.decodeIfPresent(String.self, forKey: .nomineeRelationship) ?? ""
        isOnboardingCompleted = try container.decodeIfPresent(Bool.self, forKey: .isOnboardingCompleted) ?? false
    }

    // MARK: - Mapping from BorrowerProfile

    static func from(_ profile: BorrowerProfile) -> DBProfile {
        return DBProfile(
            id: profile.id,
            fullName: profile.fullName,
            email: profile.email,
            mobileNumber: profile.mobileNumber,
            alternateNumber: profile.alternateNumber,
            dateOfBirth: profile.dateOfBirth,
            gender: profile.gender,
            maritalStatus: profile.maritalStatus,
            nationality: profile.nationality,
            aadhaarNumber: profile.aadhaarNumber,
            panNumber: profile.panNumber,
            isEmailVerified: profile.isEmailVerified,
            isPhoneVerified: profile.isPhoneVerified,
            currentAddress: profile.currentAddress,
            permanentAddress: profile.permanentAddress,
            employment: profile.employment,
            income: profile.income,
            bankDetails: profile.bankDetails,
            kycVerification: profile.kycVerification,
            loanOverview: profile.loanOverview,
            profileImageData: profile.profileImageData?.base64EncodedString(),
            occupation: profile.occupation,
            industry: profile.industry,
            yearsOfExperience: profile.yearsOfExperience,
            hasExistingBankAccount: profile.hasExistingBankAccount,
            existingCustomerId: profile.existingCustomerId,
            preferredBranch: profile.preferredBranch,
            existingLoansCount: profile.existingLoansCount,
            existingCreditCardsCount: profile.existingCreditCardsCount,
            bankingRelationshipDuration: profile.bankingRelationshipDuration,
            averageMonthlyBalance: profile.averageMonthlyBalance,
            emergencyContactName: profile.emergencyContactName,
            emergencyContactNumber: profile.emergencyContactNumber,
            emergencyContactAlternateNumber: profile.emergencyContactAlternateNumber,
            emergencyContactAddress: profile.emergencyContactAddress,
            emergencyContactRelationship: profile.emergencyContactRelationship,
            nomineeName: profile.nomineeName,
            nomineeRelationship: profile.nomineeRelationship,
            isOnboardingCompleted: profile.isOnboardingCompleted
        )
    }

    // MARK: - Mapping to BorrowerProfile

    func toBorrowerProfile(linkedAccounts: [LinkedBankAccount]? = nil, gstNumber: String? = nil) -> BorrowerProfile {
        return BorrowerProfile(
            id: id,
            fullName: fullName,
            email: email,
            mobileNumber: mobileNumber,
            alternateNumber: alternateNumber,
            dateOfBirth: dateOfBirth,
            gender: gender,
            maritalStatus: maritalStatus,
            nationality: nationality,
            aadhaarNumber: aadhaarNumber,
            panNumber: panNumber,
            isEmailVerified: isEmailVerified,
            isPhoneVerified: isPhoneVerified,
            currentAddress: currentAddress,
            permanentAddress: permanentAddress,
            employment: employment,
            income: income,
            bankDetails: bankDetails,
            linkedAccounts: linkedAccounts,
            gstNumber: gstNumber,
            kycVerification: kycVerification,
            loanOverview: loanOverview,
            profileImageData: profileImageData.flatMap { Data(base64Encoded: $0) },
            occupation: occupation,
            industry: industry,
            yearsOfExperience: yearsOfExperience,
            hasExistingBankAccount: hasExistingBankAccount,
            existingCustomerId: existingCustomerId,
            preferredBranch: preferredBranch,
            existingLoansCount: existingLoansCount,
            existingCreditCardsCount: existingCreditCardsCount,
            bankingRelationshipDuration: bankingRelationshipDuration,
            averageMonthlyBalance: averageMonthlyBalance,
            emergencyContactName: emergencyContactName,
            emergencyContactNumber: emergencyContactNumber,
            emergencyContactAlternateNumber: emergencyContactAlternateNumber,
            emergencyContactAddress: emergencyContactAddress,
            emergencyContactRelationship: emergencyContactRelationship,
            nomineeName: nomineeName,
            nomineeRelationship: nomineeRelationship,
            isOnboardingCompleted: isOnboardingCompleted
        )
    }
}


final class DatabaseService {
    static let shared = DatabaseService()
    private init() {}

    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }


    func fetchProfile(userId: String) async throws -> BorrowerProfile? {

        let dbProfiles: [DBProfile] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .execute()
            .value

        if let dbProfile = dbProfiles.first {
            // Convert DB representation back to full BorrowerProfile,
            // preserving any locally-cached linkedAccounts/gstNumber
            let cached = loadProfileLocally(userId: userId)
            let profile = dbProfile.toBorrowerProfile(
                linkedAccounts: cached?.linkedAccounts,
                gstNumber: cached?.gstNumber
            )
            saveProfileLocally(profile, userId: userId)
            print("[DatabaseService] Successfully fetched profile from Supabase for user: \(userId)")
            return profile
        } else {
            print("[DatabaseService] No profile found in Supabase for user: \(userId)")
            return nil
        }
    }


    func updateProfile(_ profile: BorrowerProfile) async throws {

        saveProfileLocally(profile, userId: profile.id)


        if let userId = UUID(uuidString: profile.id) {
            let userUpsert: [String: String] = [
                "id": userId.uuidString,
                "email": profile.email,
                "full_name": profile.fullName,
                "mobile_number": profile.mobileNumber
            ]
            print("UPSERT REQUEST - Table: users, ID: \(userId), Payload: \(userUpsert)")
            do {
                try await client
                    .from("users")
                    .upsert(userUpsert)
                    .execute()
                print("UPSERT RESPONSE - Table: users, Status: Success")
            } catch {
                print("EXACT SUPABASE ERROR - Table: users, Sync Error: \(error.localizedDescription)")
                throw error
            }
        }

        // Convert to DB-safe struct that matches the profiles table schema exactly.
        // This excludes fields like linkedAccounts, gstNumber that don't exist in the table.
        let dbProfile = DBProfile.from(profile)
        print("UPDATE REQUEST - Table: profiles, ID: \(profile.id)")
        do {
            try await client
                .from("profiles")
                .upsert(dbProfile)
                .execute()
            print("UPDATED RESPONSE - Table: profiles, Status: Success ✅")
        } catch {
            print("EXACT SUPABASE ERROR - Table: profiles, Error: \(error)")
            print("EXACT SUPABASE ERROR - Table: profiles, Localized: \(error.localizedDescription)")
            throw error
        }
    }



    private func saveProfileLocally(_ profile: BorrowerProfile, userId: String) {
        do {
            let data = try JSONEncoder().encode(profile)
            let fileURL = getLocalProfileURL(userId: userId)
            try data.write(to: fileURL, options: .atomic)
            print("[DatabaseService] Cached profile locally for user: \(userId)")
        } catch {
            print("[DatabaseService] Error caching profile locally: \(error.localizedDescription)")
        }
    }

    func loadProfileLocally(userId: String) -> BorrowerProfile? {
        let fileURL = getLocalProfileURL(userId: userId)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: fileURL)
            let profile = try JSONDecoder().decode(BorrowerProfile.self, from: data)
            print("[DatabaseService] Loaded profile from local cache for user: \(userId)")
            return profile
        } catch {
            print("[DatabaseService] Error loading cached profile: \(error.localizedDescription)")
            return nil
        }
    }

    private func getLocalProfileURL(userId: String) -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let directory = paths[0].appendingPathComponent("Profiles", isDirectory: true)

        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
        return directory.appendingPathComponent("\(userId).json")
    }
}
