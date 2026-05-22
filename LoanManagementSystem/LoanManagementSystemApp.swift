//
//  LoanManagementSystemApp.swift
//  LoanManagementSystem
//
//  Created by apple on 14/05/26.
//

import SwiftUI

@main
struct LoanManagementSystemApp: App {
    
    /// Shared authentication manager injected into the environment.
    @StateObject private var authManager = AuthManager()
    
    init() {
        Task {
            print("🚀 RUNNING AUTOMATED DB INSERT DIAGNOSTIC ON LAUNCH...")
            do {
                // Generate a random email to test signup and public.users insertion
                let randomEmail = "test_\(Int.random(in: 10000...99999))@test.com"
                let password = "Password@123"
                let name = "Test Diagnostic"
                
                print("Diagnostic: Signing up \(randomEmail)...")
                let session = try await AuthService.shared.signUp(email: randomEmail, password: password, name: name)
                print("Diagnostic Success! Session: \(String(describing: session))")
                
                let successMsg = "SUCCESS\nSession: \(String(describing: session))"
                try? successMsg.write(toFile: "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/diagnostic_success.txt", atomically: true, encoding: .utf8)
            } catch {
                print("❌ Diagnostic FAILURE: \(error.localizedDescription)")
                print("❌ Diagnostic error debug info: \(String(describing: error))")
                let errorReport = "Error: \(error.localizedDescription)\nFull details: \(String(describing: error))"
                try? errorReport.write(toFile: "/Users/abhinav/Desktop/Amit/LMS/LoanManagementSystem/diagnostic_error.txt", atomically: true, encoding: .utf8)
            }
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
        }
    }
}
