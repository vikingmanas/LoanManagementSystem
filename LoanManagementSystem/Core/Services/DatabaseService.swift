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
}
