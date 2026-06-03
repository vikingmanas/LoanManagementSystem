import Foundation
import Supabase

final class AdminStaffService {
    static let shared = AdminStaffService()

    private let client = SupabaseManager.shared.client

    private init() {}

    enum AdminStaffServiceError: LocalizedError {
        case missingServiceRoleKey

        var errorDescription: String? {
            switch self {
            case .missingServiceRoleKey:
                return "Admin user management is not configured. Move service-role operations to a secure backend or provide SUPABASE_SERVICE_ROLE_KEY outside the app bundle for local development."
            }
        }
    }


    private struct DBUser: Codable {
        let id: UUID
        let email: String
        let role: String
        let fullName: String
        let mobileNumber: String
        let status: String
        let createdBy: UUID?
        let createdAt: Date
    }

    private struct DBLoanOfficer: Codable {
        let officerId: UUID
        let userId: UUID
        let employeeCode: String
        let branchId: UUID
        let designation: String
        let createdAt: Date
    }

    private struct DBManager: Codable {
        let managerId: UUID
        let userId: UUID
        let employeeCode: String
        let branchId: UUID
        let region: String
        let createdAt: Date
    }

    struct CreateStaffPayload: Encodable {
        let action: String = "create"
        let email: String
        let password: String
        let role: String
        let fullName: String
        let phoneNumber: String
        let branchId: UUID
        let employeeCode: String
        let designation: String?
        let region: String?

        enum CodingKeys: String, CodingKey {
            case action, email, password, role
            case fullName = "fullName"
            case phoneNumber = "phoneNumber"
            case branchId = "branchId"
            case employeeCode = "employeeCode"
            case designation, region
        }
    }

    struct DeleteStaffPayload: Encodable {
        let action: String = "delete"
        let userId: UUID

        enum CodingKeys: String, CodingKey {
            case action
            case userId = "userId"
        }
    }


    func fetchBranches() async throws -> [BranchInfo] {
        let branches: [BranchInfo] = try await client
            .from("branches")
            .select()
            .execute()
            .value
        return branches
    }


    func fetchStaffMembers() async throws -> [StaffMember] {
        async let usersTask: [DBUser] = client
            .from("users")
            .select()
            .or("role.eq.loan_officer,role.eq.manager")
            .execute()
            .value

        async let officersTask: [DBLoanOfficer] = client
            .from("loan_officers")
            .select()
            .execute()
            .value

        async let managersTask: [DBManager] = client
            .from("managers")
            .select()
            .execute()
            .value

        async let branchesTask: [BranchInfo] = fetchBranches()

        let (users, officers, managers, branches) = try await (usersTask, officersTask, managersTask, branchesTask)

        let branchesMap = Dictionary(uniqueKeysWithValues: branches.map { ($0.id, $0.name) })
        let officersMap = Dictionary(uniqueKeysWithValues: officers.map { ($0.userId, $0) })
        let managersMap = Dictionary(uniqueKeysWithValues: managers.map { ($0.userId, $0) })

        var staffMembers: [StaffMember] = []

        for user in users {
            let role = StaffRole(rawValue: user.role)

            if role == .loanOfficer, let officer = officersMap[user.id] {
                let branchName = branchesMap[officer.branchId]
                let member = StaffMember(
                    id: user.id,
                    loanOfficerRecordId: officer.officerId,
                    email: user.email,
                    role: .loanOfficer,
                    fullName: user.fullName,
                    phoneNumber: user.mobileNumber,
                    status: StaffStatus(rawValue: user.status) ?? .active,
                    createdBy: user.createdBy,
                    createdAt: user.createdAt,
                    employeeCode: officer.employeeCode,
                    branchId: officer.branchId,
                    branchName: branchName,
                    designation: officer.designation,
                    region: nil
                )
                staffMembers.append(member)
            } else if role == .bankManager, let manager = managersMap[user.id] {
                let branchName = branchesMap[manager.branchId]
                let member = StaffMember(
                    id: user.id,
                    loanOfficerRecordId: nil,
                    email: user.email,
                    role: .bankManager,
                    fullName: user.fullName,
                    phoneNumber: user.mobileNumber,
                    status: StaffStatus(rawValue: user.status) ?? .active,
                    createdBy: user.createdBy,
                    createdAt: user.createdAt,
                    employeeCode: manager.employeeCode,
                    branchId: manager.branchId,
                    branchName: branchName,
                    designation: nil,
                    region: manager.region
                )
                staffMembers.append(member)
            }
        }

        return staffMembers.sorted { $0.fullName.localizedCaseInsensitiveCompare($1.fullName) == .orderedAscending }
    }

    private func makeAdminClient() throws -> SupabaseClient {
        guard let serviceRoleKey = AppConfiguration.supabaseServiceRoleKey else {
            throw AdminStaffServiceError.missingServiceRoleKey
        }

        return SupabaseClient(
            supabaseURL: AppConfiguration.supabaseURL,
            supabaseKey: serviceRoleKey
        )
    }


    func createAdmin(name: String, email: String, phone: String, password: String) async throws {
        let adminClient = try makeAdminClient()
        let attributes = AdminUserAttributes(
            email: email,
            emailConfirm: true,
            password: password,
            userMetadata: [
                "full_name": .string(name),
                "role": .string("admin")
            ]
        )

        let newUser = try await adminClient.auth.admin.createUser(attributes: attributes)
        let newUserId = newUser.id

        let userInsert: [String: String] = [
            "id": newUserId.uuidString,
            "email": email,
            "role": "admin",
            "full_name": name,
            "mobile_number": phone,
            "status": "active"
        ]

        do {
            try await adminClient.from("users").upsert(userInsert).execute()

            let adminInsert: [String: String] = [
                "user_id": newUserId.uuidString,
                "admin_level": "1"
            ]
            try await adminClient.from("admins").upsert(adminInsert, onConflict: "user_id").execute()
        } catch {
            try? await deleteStaffMember(userId: newUserId, client: adminClient)
            throw error
        }
    }


    func createStaffMember(payload: CreateStaffPayload) async throws {
        let adminClient = try makeAdminClient()

        let attributes = AdminUserAttributes(
            email: payload.email,
            emailConfirm: true,
            password: payload.password,

            userMetadata: [
                "full_name": .string(payload.fullName),
                "role": .string(payload.role)
            ]
        )

        let newUser = try await adminClient.auth.admin.createUser(attributes: attributes)
        let newUserId = newUser.id


        let userInsert: [String: String] = [
            "id": newUserId.uuidString,
            "email": payload.email,
            "role": payload.role,
            "full_name": payload.fullName,
            "mobile_number": payload.phoneNumber,
            "status": "active"
        ]

        do {
            try await adminClient.from("users").upsert(userInsert).execute()


            if payload.role == "loan_officer" {
                let officerInsert: [String: String] = [
                    "user_id": newUserId.uuidString,
                    "employee_code": payload.employeeCode,
                    "branch_id": payload.branchId.uuidString,
                    "designation": payload.designation ?? "Loan Officer"
                ]
                try await adminClient.from("loan_officers").insert(officerInsert).execute()

            } else if payload.role == "manager" {
                let managerInsert: [String: String] = [
                    "user_id": newUserId.uuidString,
                    "employee_code": payload.employeeCode,
                    "branch_id": payload.branchId.uuidString,
                    "region": payload.region ?? "General"
                ]
                try await adminClient.from("managers").insert(managerInsert).execute()
            }
        } catch {

            try? await deleteStaffMember(userId: newUserId, client: adminClient)
            throw error
        }
    }


    func deleteStaffMember(userId: UUID) async throws {
        let adminClient = try makeAdminClient()
        try await deleteStaffMember(userId: userId, client: adminClient)
    }

    private func deleteStaffMember(userId: UUID, client adminClient: SupabaseClient) async throws {
        try await adminClient.auth.admin.deleteUser(id: userId)
    }


    func updateStaffMember(
        id: UUID,
        role: StaffRole,
        fullName: String,
        phoneNumber: String,
        status: StaffStatus,
        branchId: UUID,
        designation: String?,
        region: String?
    ) async throws {

        let userUpdate: [String: String] = [
            "full_name": fullName,
            "mobile_number": phoneNumber,
            "status": status.rawValue
        ]

        try await client
            .from("users")
            .update(userUpdate)
            .eq("id", value: id)
            .execute()


        if role == .loanOfficer {
            let officerUpdate: [String: String] = [
                "branch_id": branchId.uuidString,
                "designation": designation ?? "Loan Officer"
            ]

            try await client
                .from("loan_officers")
                .update(officerUpdate)
                .eq("user_id", value: id)
                .execute()
        } else if role == .bankManager {
            let managerUpdate: [String: String] = [
                "branch_id": branchId.uuidString,
                "region": region ?? "General"
            ]

            try await client
                .from("managers")
                .update(managerUpdate)
                .eq("user_id", value: id)
                .execute()
        }
    }

    func createBranch(name: String, code: String, region: String, address: String) async throws {
        let branchInsert: [String: String] = [
            "name": name,
            "code": code,
            "region": region,
            "address": address,
            "status": "active"
        ]
        try await client
            .from("branches")
            .insert(branchInsert)
            .execute()
    }
}
