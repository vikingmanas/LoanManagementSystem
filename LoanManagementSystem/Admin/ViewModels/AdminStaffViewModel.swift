import Foundation
import Combine
import SwiftUI

@MainActor
final class AdminStaffViewModel: ObservableObject {
    @Published var staffMembers: [StaffMember] = []
    @Published var branches: [BranchInfo] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // Search and filtering state
    @Published var searchText: String = ""
    @Published var selectedRoleFilter: StaffRole? = nil
    @Published var selectedStatusFilter: StaffStatus? = nil
    
    private let service = AdminStaffService.shared
    
    var filteredStaffMembers: [StaffMember] {
        staffMembers.filter { member in
            let matchesSearch = searchText.isEmpty ||
                member.fullName.localizedCaseInsensitiveContains(searchText) ||
                member.email.localizedCaseInsensitiveContains(searchText) ||
                member.employeeCode.localizedCaseInsensitiveContains(searchText)
                
            let matchesRole = selectedRoleFilter == nil || member.role == selectedRoleFilter
            let matchesStatus = selectedStatusFilter == nil || member.status == selectedStatusFilter
            
            return matchesSearch && matchesRole && matchesStatus
        }
    }
    
    /// Loads staff members and branch information in parallel.
    func loadData() async {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        
        do {
            async let staffTask = service.fetchStaffMembers()
            async let branchesTask = service.fetchBranches()
            
            let (fetchedStaff, fetchedBranches) = try await (staffTask, branchesTask)
            
            self.staffMembers = fetchedStaff
            self.branches = fetchedBranches
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    /// Creates a new staff member account.
    func createStaff(
        payload: AdminStaffService.CreateStaffPayload
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await service.createStaffMember(payload: payload)
            // Reload list
            async let staffTask = service.fetchStaffMembers()
            self.staffMembers = try await staffTask
            isLoading = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    /// Updates an existing staff member.
    func updateStaff(
        id: UUID,
        role: StaffRole,
        fullName: String,
        phoneNumber: String,
        status: StaffStatus,
        branchId: UUID,
        designation: String?,
        region: String?
    ) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await service.updateStaffMember(
                id: id,
                role: role,
                fullName: fullName,
                phoneNumber: phoneNumber,
                status: status,
                branchId: branchId,
                designation: designation,
                region: region
            )
            // Reload list
            async let staffTask = service.fetchStaffMembers()
            self.staffMembers = try await staffTask
            isLoading = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
    
    /// Deletes a staff member account from auth.users (cascades to all other tables).
    func deleteStaff(id: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await service.deleteStaffMember(userId: id)
            // Reload list
            async let staffTask = service.fetchStaffMembers()
            self.staffMembers = try await staffTask
            isLoading = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}
