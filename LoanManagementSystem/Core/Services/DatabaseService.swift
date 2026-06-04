import Foundation
import Supabase


/// A database-safe representation of BorrowerProfile that matches
/// the Supabase `profiles` table schema.
/// `profileImageData` stores a public URL pointing to the image in Supabase Storage (bucket: `avatars`).
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

    var profileImageData: String?  // Public URL to avatar in Supabase Storage — DB column is `text`
    var linkedAccounts: [LinkedBankAccount]?
    var gstNumber: String?

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

    init(id: String, fullName: String, email: String, mobileNumber: String, alternateNumber: String?, dateOfBirth: Date, gender: String, maritalStatus: String, nationality: String, aadhaarNumber: String, panNumber: String, isEmailVerified: Bool, isPhoneVerified: Bool, currentAddress: AddressInfo, permanentAddress: AddressInfo, employment: EmploymentInfo, income: IncomeInfo, bankDetails: BankDetails, kycVerification: KYCVerification, loanOverview: LoanOverview, profileImageData: String?, linkedAccounts: [LinkedBankAccount]?, gstNumber: String?, occupation: String, industry: String, yearsOfExperience: Int, hasExistingBankAccount: Bool, existingCustomerId: String?, preferredBranch: String, existingLoansCount: Int, existingCreditCardsCount: Int, bankingRelationshipDuration: String, averageMonthlyBalance: Double, emergencyContactName: String, emergencyContactNumber: String, emergencyContactAlternateNumber: String, emergencyContactAddress: String, emergencyContactRelationship: String, nomineeName: String, nomineeRelationship: String, isOnboardingCompleted: Bool) {
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
        self.linkedAccounts = linkedAccounts
        self.gstNumber = gstNumber
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
        linkedAccounts = try container.decodeIfPresent([LinkedBankAccount].self, forKey: .linkedAccounts)
        gstNumber = try container.decodeIfPresent(String.self, forKey: .gstNumber)
        
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
            profileImageData: nil, // Image URL is set separately after Storage upload — never store base64
            linkedAccounts: profile.linkedAccounts,
            gstNumber: profile.gstNumber,
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

    func toBorrowerProfile(linkedAccounts: [LinkedBankAccount]? = nil, gstNumber: String? = nil, prefetchedImageData: Data? = nil) -> BorrowerProfile {
        let resolvedLinkedAccounts = linkedAccounts ?? self.linkedAccounts
        let resolvedGSTNumber = gstNumber ?? self.gstNumber

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
            linkedAccounts: resolvedLinkedAccounts,
            gstNumber: resolvedGSTNumber,
            kycVerification: kycVerification,
            loanOverview: loanOverview,
            profileImageData: prefetchedImageData ?? profileImageData.flatMap { Data(base64Encoded: $0) },
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

private struct DBLinkedBankAccount: Codable {
    let id: UUID
    var bankName: String
    var accountNumber: String
    var ifscCode: String
    var balance: Double
    var branch: String
    var customerId: String
    var accountHolderName: String
    var accountKind: String
    var linkedLoanApplicationId: UUID?
    var odSanctionLimit: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case bankName = "bank_name"
        case accountNumber = "account_number"
        case ifscCode = "ifsc_code"
        case balance
        case branch
        case customerId = "customer_id"
        case accountHolderName = "account_holder_name"
        case accountKind = "account_kind"
        case linkedLoanApplicationId = "linked_loan_application_id"
        case odSanctionLimit = "od_sanction_limit"
    }

    init?(_ account: LinkedBankAccount, fallbackCustomerId: String? = nil) {
        let resolvedCustomerId: String
        if UUID(uuidString: account.customerId.trimmingCharacters(in: .whitespacesAndNewlines)) != nil {
            resolvedCustomerId = account.customerId
        } else if let fallbackCustomerId,
                  UUID(uuidString: fallbackCustomerId.trimmingCharacters(in: .whitespacesAndNewlines)) != nil {
            resolvedCustomerId = fallbackCustomerId
        } else {
            return nil
        }

        self.id = account.id
        self.bankName = account.bankName
        self.accountNumber = account.accountNumber
        self.ifscCode = account.ifscCode
        self.balance = account.balance
        self.branch = account.branch
        self.customerId = resolvedCustomerId
        self.accountHolderName = account.accountHolderName
        self.accountKind = account.accountKind.rawValue
        self.linkedLoanApplicationId = account.linkedLoanApplicationId
        self.odSanctionLimit = account.odSanctionLimit
    }

    func toLinkedBankAccount() -> LinkedBankAccount {
        LinkedBankAccount(
            id: id,
            bankName: bankName,
            accountNumber: accountNumber,
            ifscCode: ifscCode,
            balance: balance,
            branch: branch,
            customerId: customerId,
            accountHolderName: accountHolderName,
            accountKind: LinkedAccountKind(rawValue: accountKind) ?? .savings,
            linkedLoanApplicationId: linkedLoanApplicationId,
            odSanctionLimit: odSanctionLimit
        )
    }
}


final class DatabaseService {
    static let shared = DatabaseService()
    private init() {}

    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    func fetchLoanOfficerProfile(userId: UUID) async throws -> StaffMember? {
        struct DBUser: Codable {
            let id: UUID
            let email: String
            let role: String
            let fullName: String
            let mobileNumber: String
            let status: String
            let createdBy: UUID?
            let createdAt: Date
        }

        struct DBLoanOfficer: Codable {
            let officerId: UUID
            let userId: UUID
            let employeeCode: String
            let branchId: UUID
            let designation: String
            let createdAt: Date
        }

        let dbUsers: [DBUser] = try await client
            .from("users")
            .select()
            .eq("id", value: userId)
            .execute()
            .value

        guard let dbUser = dbUsers.first else {
            return nil
        }

        let dbOfficers: [DBLoanOfficer] = try await client
            .from("loan_officers")
            .select()
            .eq("user_id", value: userId)
            .execute()
            .value

        guard let dbOfficer = dbOfficers.first else {
            return nil
        }

        let dbBranches: [BranchInfo] = try await client
            .from("branches")
            .select()
            .eq("branch_id", value: dbOfficer.branchId)
            .execute()
            .value

        let branchName = dbBranches.first?.name

        return StaffMember(
            id: dbUser.id,
            email: dbUser.email,
            role: .loanOfficer,
            fullName: dbUser.fullName,
            phoneNumber: dbUser.mobileNumber,
            status: StaffStatus(rawValue: dbUser.status) ?? .active,
            createdBy: dbUser.createdBy,
            createdAt: dbUser.createdAt,
            employeeCode: dbOfficer.employeeCode,
            branchId: dbOfficer.branchId,
            branchName: branchName,
            designation: dbOfficer.designation,
            region: nil
        )
    }

    func fetchLoanOfficerAssignment(officerId: UUID) async throws -> AssignedLoanOfficer? {
        struct DBLoanOfficer: Codable {
            let officerId: UUID
            let userId: UUID
            let employeeCode: String
            let branchId: UUID
            let designation: String
            let createdAt: Date
        }

        struct DBUser: Codable {
            let id: UUID
            let fullName: String
            let status: String
        }

        let officers: [DBLoanOfficer] = try await client
            .from("loan_officers")
            .select()
            .eq("officer_id", value: officerId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let officer = officers.first else { return nil }

        let users: [DBUser] = try await client
            .from("users")
            .select("id, full_name, status")
            .eq("id", value: officer.userId.uuidString)
            .limit(1)
            .execute()
            .value

        guard let user = users.first else { return nil }

        let branches: [BranchInfo] = try await client
            .from("branches")
            .select()
            .eq("branch_id", value: officer.branchId.uuidString)
            .limit(1)
            .execute()
            .value

        return AssignedLoanOfficer(
            officerId: officer.officerId,
            userId: officer.userId,
            fullName: user.fullName,
            employeeCode: officer.employeeCode,
            branchId: officer.branchId,
            branchName: branches.first?.name ?? "Home Branch",
            designation: officer.designation.isEmpty ? "Loan Officer" : officer.designation,
            lastAssignedAt: nil,
            activeWorkload: 0
        )
    }

    func assignLoanOfficer(forBranchName branchName: String) async throws -> AssignedLoanOfficer? {
        struct DBLoanOfficer: Codable {
            let officerId: UUID
            let userId: UUID
            let employeeCode: String
            let branchId: UUID
            let designation: String
            let createdAt: Date
        }

        struct DBUser: Codable {
            let id: UUID
            let fullName: String
            let status: String
        }

        struct WorkloadApplication: Codable {
            let officerId: UUID?
            let status: String
            let updatedAt: Date
            let submittedAt: Date?
        }

        let branches: [BranchInfo] = try await client
            .from("branches")
            .select()
            .execute()
            .value

        let normalizedBranch = Self.normalizedBranchName(branchName)
        let selectedBranch = branches.first { Self.normalizedBranchName($0.name) == normalizedBranch }
            ?? branches.first { Self.normalizedBranchName($0.name).contains(normalizedBranch) || normalizedBranch.contains(Self.normalizedBranchName($0.name)) }
            ?? branches.first

        guard let selectedBranch else { return nil }

        let officers: [DBLoanOfficer] = try await client
            .from("loan_officers")
            .select()
            .eq("branch_id", value: selectedBranch.branchId.uuidString)
            .execute()
            .value

        guard !officers.isEmpty else { return nil }

        let userIds = officers.map(\.userId.uuidString)
        let users: [DBUser] = try await client
            .from("users")
            .select("id, full_name, status")
            .in("id", values: userIds)
            .eq("status", value: "active")
            .execute()
            .value

        let activeUserIds = Set(users.map(\.id))
        let eligibleOfficers = officers.filter { activeUserIds.contains($0.userId) }
        guard !eligibleOfficers.isEmpty else { return nil }

        let officerIds = eligibleOfficers.map(\.officerId.uuidString)
        let activeStatuses = [
            "submitted",
            "under_review",
            "document_verification",
            "officer_review",
            "customer_response_received",
            "pending_documents"
        ]

        let workloadRows: [WorkloadApplication] = try await client
            .from("loan_applications")
            .select("officer_id, status, updated_at, submitted_at")
            .in("officer_id", values: officerIds)
            .in("status", values: activeStatuses)
            .execute()
            .value

        var workloadByOfficer: [UUID: Int] = [:]
        var lastAssignmentByOfficer: [UUID: Date] = [:]

        for row in workloadRows {
            guard let officerId = row.officerId else { continue }
            workloadByOfficer[officerId, default: 0] += 1
            let assignmentDate = row.submittedAt ?? row.updatedAt
            if let current = lastAssignmentByOfficer[officerId] {
                lastAssignmentByOfficer[officerId] = max(current, assignmentDate)
            } else {
                lastAssignmentByOfficer[officerId] = assignmentDate
            }
        }

        let userById = Dictionary(uniqueKeysWithValues: users.map { ($0.id, $0) })

        guard let selectedOfficer = eligibleOfficers.sorted(by: { lhs, rhs in
            let lhsWorkload = workloadByOfficer[lhs.officerId, default: 0]
            let rhsWorkload = workloadByOfficer[rhs.officerId, default: 0]
            if lhsWorkload != rhsWorkload {
                return lhsWorkload < rhsWorkload
            }

            let lhsLastAssigned = lastAssignmentByOfficer[lhs.officerId] ?? .distantPast
            let rhsLastAssigned = lastAssignmentByOfficer[rhs.officerId] ?? .distantPast
            if lhsLastAssigned != rhsLastAssigned {
                return lhsLastAssigned < rhsLastAssigned
            }

            return lhs.createdAt < rhs.createdAt
        }).first,
        let selectedUser = userById[selectedOfficer.userId] else {
            return nil
        }

        return AssignedLoanOfficer(
            officerId: selectedOfficer.officerId,
            userId: selectedOfficer.userId,
            fullName: selectedUser.fullName,
            employeeCode: selectedOfficer.employeeCode,
            branchId: selectedOfficer.branchId,
            branchName: selectedBranch.name,
            designation: selectedOfficer.designation.isEmpty ? "Loan Officer" : selectedOfficer.designation,
            lastAssignedAt: lastAssignmentByOfficer[selectedOfficer.officerId],
            activeWorkload: workloadByOfficer[selectedOfficer.officerId, default: 0]
        )
    }

    private static func normalizedBranchName(_ value: String) -> String {
        value
            .lowercased()
            .replacingOccurrences(of: "branch", with: "")
            .replacingOccurrences(of: "-", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
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
            let cachedLinkedAccounts = cached?.linkedAccounts?.isEmpty == false ? cached?.linkedAccounts : nil
            let cachedGSTNumber = cached?.gstNumber?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? cached?.gstNumber : nil
            
            var prefetchedImageData: Data? = nil
            if let dbImageString = dbProfile.profileImageData {
                if dbImageString.starts(with: "http"), let url = URL(string: dbImageString) {
                    if let (data, _) = try? await URLSession.shared.data(from: url) {
                        prefetchedImageData = data
                    }
                }
            }

            var profile = dbProfile.toBorrowerProfile(
                linkedAccounts: cachedLinkedAccounts,
                gstNumber: cachedGSTNumber,
                prefetchedImageData: prefetchedImageData
            )
            profile.linkedAccounts = await mergedLinkedAccounts(
                profile: profile,
                cachedAccounts: cached?.linkedAccounts ?? []
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
        var profileToSave = profile

        // Fetch the existing remote profile first — we need the existing avatar URL.
        let existingRemote = try? await fetchRawProfile(userId: profile.id)

        if let existingProfile = existingRemote,
           shouldProtectRemoteProfile(existingProfile, from: profile) {
            profileToSave = mergeMissingProfileDetails(from: existingProfile, into: profile)
            print("[DatabaseService] Protected existing Supabase profile details from sparse local overwrite.")
        }

        saveProfileLocally(profileToSave, userId: profileToSave.id)

        if let userId = UUID(uuidString: profileToSave.id) {
            let userUpsert: [String: String] = [
                "id": userId.uuidString,
                "email": profileToSave.email,
                "full_name": profileToSave.fullName,
                "mobile_number": profileToSave.mobileNumber
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

        // Fetch the raw DB string for the existing avatar URL (it's a String in DB, not Data)
        let existingAvatarURL: String? = await fetchExistingAvatarURL(userId: profileToSave.id)

        // Convert to DB-safe struct — never encode image as base64 here.
        var dbProfile = DBProfile.from(profileToSave)

        // --- Profile Image: Upload to Storage, NEVER save base64 to Postgres ---
        if let imageData = profileToSave.profileImageData, !imageData.isEmpty {
            do {
                // Use a subfolder named after the user's ID to satisfy Storage RLS policies.
                // IMPORTANT: Must be lowercased — Supabase auth.uid() returns lowercase UUIDs,
                // and the RLS policy compares auth.uid()::text against the folder name.
                let path = "\(profileToSave.id.lowercased())/avatar.png"
                let url = try await StorageService.shared.uploadDocument(
                    data: imageData,
                    bucket: "avatars",
                    path: path,
                    contentType: "image/png"
                )
                dbProfile.profileImageData = url.absoluteString
                print("✅ [DatabaseService] Avatar uploaded to Storage: \(url.absoluteString)")
            } catch {
                // IMPORTANT: Never fall back to base64. Preserve the existing URL if available.
                // A missing image is better than blowing up your database with megabytes of text.
                print("❌ [DatabaseService] Avatar upload failed: \(error)")
                print("❌ [DatabaseService] Avatar upload localized error: \(error.localizedDescription)")
                if let storageError = error as? StorageError {
                    print("❌ [DatabaseService] StorageError details: \(storageError)")
                }
                dbProfile.profileImageData = existingAvatarURL
            }
        } else {
            // No new image — preserve existing URL so we don't wipe it on every profile save
            dbProfile.profileImageData = existingAvatarURL
        }

        print("UPDATE REQUEST - Table: profiles, ID: \(profileToSave.id)")
        do {
            try await client
                .from("profiles")
                .upsert(dbProfile)
                .execute()
            print("UPDATED RESPONSE - Table: profiles, Status: Success ✅")
            await syncLinkedBankAccounts(profileToSave.linkedAccounts ?? [], ownerProfileId: profileToSave.id)
        } catch {
            print("EXACT SUPABASE ERROR - Table: profiles, Error: \(error)")
            print("EXACT SUPABASE ERROR - Table: profiles, Localized: \(error.localizedDescription)")
            throw error
        }
    }

    /// Fetches only the raw `profile_image_data` string from the DB (a URL or nil — never base64).
    private func fetchExistingAvatarURL(userId: String) async -> String? {
        struct AvatarOnly: Codable {
            let profileImageData: String?
        }
        let rows: [AvatarOnly]? = try? await client
            .from("profiles")
            .select("profile_image_data")
            .eq("id", value: userId)
            .limit(1)
            .execute()
            .value
        guard let raw = rows?.first?.profileImageData, raw.hasPrefix("http") else {
            return nil
        }
        return raw
    }

    private func fetchRawProfile(userId: String) async throws -> BorrowerProfile? {
        let dbProfiles: [DBProfile] = try await client
            .from("profiles")
            .select()
            .eq("id", value: userId)
            .limit(1)
            .execute()
            .value

        guard let dbProfile = dbProfiles.first else { return nil }
        
        var prefetchedImageData: Data? = nil
        if let dbImageString = dbProfile.profileImageData {
            if dbImageString.starts(with: "http"), let url = URL(string: dbImageString) {
                if let (data, _) = try? await URLSession.shared.data(from: url) {
                    prefetchedImageData = data
                }
            }
        }

        return dbProfile.toBorrowerProfile(prefetchedImageData: prefetchedImageData)
    }

    private func shouldProtectRemoteProfile(_ remote: BorrowerProfile, from local: BorrowerProfile) -> Bool {
        remote.hasPersistedBorrowerDetails && local.isSparsePlaceholderProfile
    }

    private func mergeMissingProfileDetails(from remote: BorrowerProfile, into local: BorrowerProfile) -> BorrowerProfile {
        var merged = local

        if merged.gender.isBlank { merged.gender = remote.gender }
        if merged.maritalStatus.isBlank { merged.maritalStatus = remote.maritalStatus }
        if merged.nationality.isBlank { merged.nationality = remote.nationality }
        if merged.aadhaarNumber.isBlank { merged.aadhaarNumber = remote.aadhaarNumber }
        if merged.panNumber.isBlank { merged.panNumber = remote.panNumber }
        if merged.mobileNumber.isBlank { merged.mobileNumber = remote.mobileNumber }
        if merged.alternateNumber?.isBlank != false { merged.alternateNumber = remote.alternateNumber }
        if merged.occupation.isBlank { merged.occupation = remote.occupation }
        if merged.industry.isBlank { merged.industry = remote.industry }
        if merged.preferredBranch.isBlank { merged.preferredBranch = remote.preferredBranch }
        if merged.existingCustomerId?.isBlank != false { merged.existingCustomerId = remote.existingCustomerId }
        if merged.bankingRelationshipDuration.isBlank { merged.bankingRelationshipDuration = remote.bankingRelationshipDuration }
        if merged.emergencyContactName.isBlank { merged.emergencyContactName = remote.emergencyContactName }
        if merged.emergencyContactNumber.isBlank { merged.emergencyContactNumber = remote.emergencyContactNumber }
        if merged.emergencyContactAlternateNumber.isBlank { merged.emergencyContactAlternateNumber = remote.emergencyContactAlternateNumber }
        if merged.emergencyContactAddress.isBlank { merged.emergencyContactAddress = remote.emergencyContactAddress }
        if merged.emergencyContactRelationship.isBlank { merged.emergencyContactRelationship = remote.emergencyContactRelationship }
        if merged.nomineeName.isBlank { merged.nomineeName = remote.nomineeName }
        if merged.nomineeRelationship.isBlank { merged.nomineeRelationship = remote.nomineeRelationship }

        if merged.currentAddress.isBlank { merged.currentAddress = remote.currentAddress }
        if merged.permanentAddress.isBlank { merged.permanentAddress = remote.permanentAddress }
        if merged.employment.isBlank { merged.employment = remote.employment }
        if merged.income.isBlank { merged.income = remote.income }
        if merged.bankDetails.isBlank { merged.bankDetails = remote.bankDetails }
        if merged.kycVerification.isBlank { merged.kycVerification = remote.kycVerification }
        if merged.loanOverview.isBlank { merged.loanOverview = remote.loanOverview }
        if merged.profileImageData == nil { merged.profileImageData = remote.profileImageData }
        if merged.linkedAccounts?.isEmpty != false { merged.linkedAccounts = remote.linkedAccounts }
        if merged.gstNumber?.isBlank != false { merged.gstNumber = remote.gstNumber }

        if Calendar.current.isDateInToday(merged.dateOfBirth),
           !Calendar.current.isDateInToday(remote.dateOfBirth) {
            merged.dateOfBirth = remote.dateOfBirth
        }

        merged.isEmailVerified = merged.isEmailVerified || remote.isEmailVerified
        merged.isPhoneVerified = merged.isPhoneVerified || remote.isPhoneVerified
        merged.isOnboardingCompleted = merged.isOnboardingCompleted || remote.isOnboardingCompleted
        merged.yearsOfExperience = max(merged.yearsOfExperience, remote.yearsOfExperience)
        merged.existingLoansCount = max(merged.existingLoansCount, remote.existingLoansCount)
        merged.existingCreditCardsCount = max(merged.existingCreditCardsCount, remote.existingCreditCardsCount)
        merged.averageMonthlyBalance = max(merged.averageMonthlyBalance, remote.averageMonthlyBalance)

        return merged
    }

    private func mergedLinkedAccounts(profile: BorrowerProfile, cachedAccounts: [LinkedBankAccount]) async -> [LinkedBankAccount] {
        var merged = cachedAccounts
        var customerIds = Set(
            cachedAccounts
                .map(\.customerId)
                .filter(Self.isValidUUIDString)
        )

        if let existingCustomerId = profile.existingCustomerId,
           Self.isValidUUIDString(existingCustomerId) {
            customerIds.insert(existingCustomerId)
        }
        if Self.isValidUUIDString(profile.id) {
            customerIds.insert(profile.id)
        }

        for customerId in customerIds {
            do {
                let remoteAccounts = try await fetchLinkedBankAccounts(customerId: customerId)
                for remoteAccount in remoteAccounts {
                    if let index = merged.firstIndex(where: { $0.id == remoteAccount.id || $0.accountNumber == remoteAccount.accountNumber }) {
                        merged[index] = remoteAccount
                    } else {
                        merged.append(remoteAccount)
                    }
                }
            } catch {
                print("[DatabaseService] Error fetching bank_accounts for customer_id \(customerId): \(error.localizedDescription)")
            }
        }

        return merged
    }

    func fetchLinkedBankAccounts(customerId: String) async throws -> [LinkedBankAccount] {
        let dbAccounts: [DBLinkedBankAccount] = try await client
            .from("bank_accounts")
            .select()
            .eq("customer_id", value: customerId)
            .execute()
            .value
        return dbAccounts.map { $0.toLinkedBankAccount() }
    }

    private func syncLinkedBankAccounts(_ accounts: [LinkedBankAccount], ownerProfileId: String) async {
        guard !accounts.isEmpty else { return }
        do {
            try await upsertLinkedBankAccounts(accounts, ownerProfileId: ownerProfileId)
            print("[DatabaseService] Synced \(accounts.count) linked bank account(s) to Supabase.")
        } catch {
            print("EXACT SUPABASE ERROR - Table: bank_accounts, Error: \(error)")
            print("EXACT SUPABASE ERROR - Table: bank_accounts, Localized: \(error.localizedDescription)")
        }
    }

    func upsertLinkedBankAccounts(_ accounts: [LinkedBankAccount], ownerProfileId: String? = nil) async throws {
        let dbAccounts = accounts.compactMap { account in
            DBLinkedBankAccount(account, fallbackCustomerId: ownerProfileId)
        }
        guard !dbAccounts.isEmpty else {
            print("[DatabaseService] Skipping bank_accounts sync: no UUID customer_id available.")
            return
        }
        try await client
            .from("bank_accounts")
            .upsert(dbAccounts)
            .execute()
    }

    private static func isValidUUIDString(_ value: String) -> Bool {
        UUID(uuidString: value.trimmingCharacters(in: .whitespacesAndNewlines)) != nil
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

    // MARK: - Supabase Document Sync Operations

    func upsertDocument(_ doc: DBDocument) async throws {
        do {
            try await client
                .from("documents")
                .upsert(doc, onConflict: "document_id")
                .execute()
            print("[DatabaseService] Document upserted successfully: \(doc.documentId)")
        } catch {
            print("❌ [DatabaseService] upsertDocument failed: \(error)")
            throw error
        }
    }

    func fetchDocuments(applicationId: UUID) async throws -> [DBDocument] {
        return try await client
            .from("documents")
            .select()
            .eq("application_id", value: applicationId.uuidString)
            .execute()
            .value
    }

    func fetchDocuments(borrowerId: UUID) async throws -> [DBDocument] {
        return try await client
            .from("documents")
            .select()
            .eq("borrower_id", value: borrowerId.uuidString)
            .execute()
            .value
    }

    /// Batch-fetch documents for multiple application IDs in a single query.
    /// Replaces the N+1 pattern of calling fetchDocuments(applicationId:) per app.
    func fetchDocumentsBatch(applicationIds: [UUID]) async throws -> [UUID: [DBDocument]] {
        guard !applicationIds.isEmpty else { return [:] }
        let idStrings = applicationIds.map(\.uuidString)
        let allDocs: [DBDocument] = try await client
            .from("documents")
            .select()
            .in("application_id", values: idStrings)
            .execute()
            .value
        return Dictionary(grouping: allDocs, by: \.applicationId!)
    }

    // MARK: - Supabase Repayment & Account Operations

    func insertLoanAccount(_ account: DBLoanAccount) async throws {
        try await client
            .from("loan_accounts")
            .insert(account)
            .execute()
    }

    func insertEMISchedule(_ schedule: [DBEMISchedule]) async throws {
        try await client
            .from("emi_schedule")
            .insert(schedule)
            .execute()
    }

    func fetchLoanAccounts(borrowerId: UUID) async throws -> [DBLoanAccount] {
        return try await client
            .from("loan_accounts")
            .select()
            .eq("borrower_id", value: borrowerId.uuidString)
            .execute()
            .value
    }

    func fetchEMISchedule(accountId: UUID) async throws -> [DBEMISchedule] {
        return try await client
            .from("emi_schedule")
            .select()
            .eq("account_id", value: accountId.uuidString)
            .execute()
            .value
    }

    func updateEMIScheduleItemStatus(emiId: UUID, status: String, paidDate: Date?, paidAmount: Double?) async throws {
        struct EMIUpdate: Codable {
            let status: String
            let paidDate: Date?
            let paidAmount: Double?
        }
        try await client
            .from("emi_schedule")
            .update(EMIUpdate(status: status, paidDate: paidDate, paidAmount: paidAmount))
            .eq("emi_id", value: emiId.uuidString)
            .execute()
    }

    // MARK: - Supabase Chat Sync Operations

    func fetchMessagesForApplication(applicationId: UUID) async throws -> [DBMessage] {
        return try await client
            .from("messages")
            .select()
            .eq("application_id", value: applicationId.uuidString)
            .order("sent_at", ascending: true)
            .execute()
            .value
    }

    func fetchAssignedLoanOfficerUserId(applicationId: UUID) async throws -> UUID? {
        struct ApplicationOfficerRow: Codable {
            let officerId: UUID?
        }

        struct LoanOfficerUserRow: Codable {
            let userId: UUID
        }

        let applications: [ApplicationOfficerRow] = try await client
            .from("loan_applications")
            .select("officer_id")
            .eq("application_id", value: applicationId.uuidString)
            .limit(1)
            .execute()
            .value

        if let officerId = applications.first?.officerId {
            let officers: [LoanOfficerUserRow] = try await client
                .from("loan_officers")
                .select("user_id")
                .eq("officer_id", value: officerId.uuidString)
                .limit(1)
                .execute()
                .value

            if let userId = officers.first?.userId {
                return userId
            }
        }

        return nil
    }

    func fetchMessages(for userId: UUID) async throws -> [DBMessage] {
        return try await client
            .from("messages")
            .select()
            .or("sender_id.eq.\(userId.uuidString),receiver_id.eq.\(userId.uuidString)")
            .order("sent_at", ascending: true)
            .execute()
            .value
    }

    func sendMessage(_ msg: DBMessage) async throws {
        try await client
            .from("messages")
            .insert(msg)
            .execute()
    }

    func markMessagesRead(messageIds: [UUID]) async throws {
        guard !messageIds.isEmpty else { return }
        struct ReadUpdate: Encodable {
            let isRead: Bool

            enum CodingKeys: String, CodingKey {
                case isRead = "is_read"
            }
        }

        try await client
            .from("messages")
            .update(ReadUpdate(isRead: true))
            .in("message_id", values: messageIds.map(\.uuidString))
            .execute()
    }

    func subscribeToMessages(forApplicationId applicationId: UUID, onInsert: @escaping (DBMessage) -> Void) async -> RealtimeChannelV2 {
        let channel = client.channel("messages_app_\(applicationId.uuidString)")
        
        let stream = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "messages",
            filter: "application_id=eq.\(applicationId.uuidString)"
        )
        
        Task {
            for await action in stream {
                do {
                    let message = try action.record.decode(as: DBMessage.self, decoder: SupabaseManager.shared.defaultDecoder)
                    onInsert(message)
                } catch {
                    print("[DatabaseService] Error decoding realtime message: \(error)")
                }
            }
        }
        
        await channel.subscribe()
        return channel
    }
    
    func subscribeToAllMessages(forUserId userId: UUID, onInsert: @escaping (DBMessage) -> Void) async -> RealtimeChannelV2 {
        let channel = client.channel("messages_user_\(userId.uuidString)")
        
        let stream = channel.postgresChange(
            InsertAction.self,
            schema: "public",
            table: "messages"
        )
        
        Task {
            for await action in stream {
                do {
                    let message = try action.record.decode(as: DBMessage.self, decoder: SupabaseManager.shared.defaultDecoder)
                    if message.senderId == userId || message.receiverId == userId {
                        onInsert(message)
                    }
                } catch {
                    print("[DatabaseService] Error decoding realtime message: \(error)")
                }
            }
        }
        
        await channel.subscribe()
        return channel
    }

    func createNotification(userId: UUID, title: String, message: String, type: String = "push") async throws {
        struct NotificationInsert: Encodable {
            let userId: UUID
            let notifType: String
            let title: String
            let message: String

            enum CodingKeys: String, CodingKey {
                case userId = "user_id"
                case notifType = "notif_type"
                case title
                case message
            }
        }

        try await client
            .from("notifications")
            .insert(NotificationInsert(userId: userId, notifType: type, title: title, message: message))
            .execute()
    }

    func fetchBranches() async throws -> [BranchInfo] {
        return try await client
            .from("branches")
            .select()
            .execute()
            .value
    }
}

private extension String {
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private extension AddressInfo {
    var isBlank: Bool {
        streetAddress.isBlank && city.isBlank && state.isBlank && zipCode.isBlank
    }
}

private extension EmploymentInfo {
    var isBlank: Bool {
        employmentType.isBlank && companyName.isBlank && designation.isBlank && employerAddress.isBlank && workExperienceYears == 0
    }
}

private extension IncomeInfo {
    var isBlank: Bool {
        monthlyIncome == 0 && annualIncome == 0 && existingEMIs == 0 && creditScore == 0 && incomeSource.isBlank
    }
}

private extension BankDetails {
    var isBlank: Bool {
        bankName.isBlank && accountHolderName.isBlank && accountNumber.isBlank && ifscCode.isBlank && upiID?.isBlank != false
    }
}

private extension KYCVerification {
    var isBlank: Bool {
        aadhaarStatus == .pending &&
            panStatus == .pending &&
            addressProofStatus == .pending &&
            selfieStatus == .pending &&
            aadhaarFileName == nil &&
            panFileName == nil &&
            addressProofFileName == nil
    }
}

private extension LoanOverview {
    var isBlank: Bool {
        activeLoans == 0 && loanHistoryCount == 0 && remainingBalance == 0 && currentLoanStatus.isBlank
    }
}

private extension BorrowerProfile {
    var hasPersistedBorrowerDetails: Bool {
        !gender.isBlank ||
            !maritalStatus.isBlank ||
            !nationality.isBlank ||
            !aadhaarNumber.isBlank ||
            !panNumber.isBlank ||
            !currentAddress.isBlank ||
            !employment.isBlank ||
            !income.isBlank ||
            !bankDetails.isBlank ||
            !preferredBranch.isBlank ||
            !nomineeName.isBlank ||
            !emergencyContactName.isBlank
    }

    var isSparsePlaceholderProfile: Bool {
        gender.isBlank &&
            maritalStatus.isBlank &&
            nationality.isBlank &&
            aadhaarNumber.isBlank &&
            panNumber.isBlank &&
            currentAddress.isBlank &&
            employment.isBlank &&
            income.isBlank &&
            bankDetails.isBlank
    }
}
