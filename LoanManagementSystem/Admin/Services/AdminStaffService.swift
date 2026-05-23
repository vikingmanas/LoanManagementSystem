import Foundation
import Supabase

final class AdminStaffService {
    static let shared = AdminStaffService()
    
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    // Internal struct to match the database schemas
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
    
    /// Fetches all available branches.
    func fetchBranches() async throws -> [BranchInfo] {
        let branches: [BranchInfo] = try await client
            .from("branches")
            .select()
            .execute()
            .value
        return branches
    }
    
    /// Fetches all loan officers and bank managers.
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
    
    /// Invokes the create-staff-user Edge Function to register a new user in auth.users and public tables.
    func createStaffMember(payload: CreateStaffPayload) async throws {
        try await client.functions.invoke(
            "create-staff-user",
            options: FunctionInvokeOptions(
                method: .post,
                body: payload
            )
        )
    }
    
    /// Invokes the Edge Function with action 'delete' to remove the user from auth.users and all cascading tables.
    func deleteStaffMember(userId: UUID) async throws {
        let payload = DeleteStaffPayload(userId: userId)
        try await client.functions.invoke(
            "create-staff-user",
            options: FunctionInvokeOptions(
                method: .post,
                body: payload
            )
        )
    }
    
    /// Updates staff member's info in public.users and their role-specific details.
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
        // 1. Update public.users
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
            
        // 2. Update role-specific detail tables
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
}
