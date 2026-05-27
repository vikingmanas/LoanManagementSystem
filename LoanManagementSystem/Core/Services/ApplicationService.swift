//
//  ApplicationService.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 26/05/26.
//

import Foundation
import Supabase
import OSLog

class ApplicationService {
    static let shared = ApplicationService()
    private let client = SupabaseManager.shared.client
    private let logger = Logger(subsystem: "galgotias.in.akash", category: "ApplicationService")
    
    private init() {}
    
    /// Fetches all active and draft applications for a specific borrower from Supabase.
    func fetchApplications(borrowerId: UUID) async throws -> [DBLoanApplication] {
        logger.info("ApplicationService: Fetching applications for borrower ID: \(borrowerId)...")
        do {
            let dbApps: [DBLoanApplication] = try await client
                .from("loan_applications")
                .select()
                .eq("borrower_id", value: borrowerId.uuidString)
                .execute()
                .value
            
            logger.info("ApplicationService: Successfully fetched \(dbApps.count) applications.")
            return dbApps
        } catch {
            logger.error("ApplicationService Fetch Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Fetches all submitted (non-draft) applications from Supabase for loan officer view.
    func fetchAllSubmittedApplications() async throws -> [DBLoanApplication] {
        logger.info("ApplicationService: Fetching all submitted applications for officer dashboard...")
        do {
            let dbApps: [DBLoanApplication] = try await client
                .from("loan_applications")
                .select()
                .neq("status", value: "draft")
                .execute()
                .value
            
            logger.info("ApplicationService: Successfully fetched \(dbApps.count) submitted applications.")
            return dbApps
        } catch {
            logger.error("ApplicationService FetchAll Error: \(error.localizedDescription)")
            throw error
        }
    }
    
    /// Inserts or updates an application record in Supabase.
    func upsertApplication(_ app: DBLoanApplication) async throws {
        logger.info("ApplicationService: Upserting application ID: \(app.applicationId) with borrower_id: \(app.borrowerId), product_id: \(app.productId), status: \(app.status)")
        do {
            try await client
                .from("loan_applications")
                .upsert(app, onConflict: "application_id")
                .execute()
            logger.info("ApplicationService: Successfully upserted application ID: \(app.applicationId).")
        } catch {
            logger.error("ApplicationService Upsert Error for \(app.applicationId): \(String(describing: error))")
            throw error
        }
    }
    
    /// Deletes an application record from Supabase.
    func deleteApplication(id: UUID) async throws {
        logger.info("ApplicationService: Deleting application ID: \(id.uuidString)")
        do {
            try await client
                .from("loan_applications")
                .delete()
                .eq("application_id", value: id.uuidString)
                .execute()
            logger.info("ApplicationService: Successfully deleted application ID: \(id.uuidString).")
        } catch {
            logger.error("ApplicationService Delete Error for \(id.uuidString): \(error.localizedDescription)")
            throw error
        }
    }
}

