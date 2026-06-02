import Foundation
import Combine
import SwiftUI

@MainActor
final class AdminStaffViewModel: ObservableObject {
    @Published var staffMembers: [StaffMember] = []
    @Published var branches: [BranchInfo] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil


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
    
    var filteredBranches: [BranchInfo] {
        if searchText.isEmpty {
            return branches
        }
        return branches.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.code.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func staff(for branchId: UUID) -> [StaffMember] {
        return staffMembers.filter { $0.branchId == branchId }
    }


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


    func createStaff(
        payload: AdminStaffService.CreateStaffPayload
    ) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await service.createStaffMember(payload: payload)

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


    func deleteStaff(id: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await service.deleteStaffMember(userId: id)

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

    func createBranch(name: String, code: String, region: String, address: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        do {
            try await service.createBranch(name: name, code: code, region: region, address: address)
            self.branches = try await service.fetchBranches()
            isLoading = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            isLoading = false
            return false
        }
    }
}

