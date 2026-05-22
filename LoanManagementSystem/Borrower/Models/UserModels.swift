//
//  UserModels.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 20/05/26.
//

import Foundation

// MARK: - User Enums

enum UserRole: String, Codable {
    case borrower
    case loanOfficer = "loan_officer"
    case manager
    case admin
}

enum UserStatus: String, Codable {
    case active, inactive, suspended, pending
}

enum KYCStatus: String, Codable {
    case pending, inProgress = "in_progress", verified, rejected
}

// MARK: - User Models

struct AppUser: Codable, Identifiable {
    let id: UUID
    let name: String
    let email: String
    let mobile: String
    let passwordHash: String
    let role: UserRole
    let status: UserStatus
    let createdAt: Date
    let lastLogin: Date?
    
    enum CodingKeys: String, CodingKey {
        case id = "user_id"
        case name, email, mobile
        case passwordHash = "password_hash"
        case role, status
        case createdAt = "created_at"
        case lastLogin = "last_login"
    }
}

struct Borrower: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let dateOfBirth: Date
    let panNumber: String
    let aadhaarNumber: String
    let kycStatus: KYCStatus
    let kycVerifiedAt: Date?
    let address: String
    
    enum CodingKeys: String, CodingKey {
        case id = "borrower_id"
        case userId = "user_id"
        case dateOfBirth = "date_of_birth"
        case panNumber = "pan_number"
        case aadhaarNumber = "aadhaar_number"
        case kycStatus = "kyc_status"
        case kycVerifiedAt = "kyc_verified_at"
        case address
    }
}

struct LoanOfficer: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let employeeCode: String
    let branchId: UUID
    let designation: String
    
    enum CodingKeys: String, CodingKey {
        case id = "officer_id"
        case userId = "user_id"
        case employeeCode = "employee_code"
        case branchId = "branch_id"
        case designation
    }
}

struct Manager: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let employeeCode: String
    let branchId: UUID
    let region: String
    
    enum CodingKeys: String, CodingKey {
        case id = "manager_id"
        case userId = "user_id"
        case employeeCode = "employee_code"
        case branchId = "branch_id"
        case region
    }
}

struct Admin: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    let adminLevel: Int
    
    enum CodingKeys: String, CodingKey {
        case id = "admin_id"
        case userId = "user_id"
        case adminLevel = "admin_level"
    }
}
