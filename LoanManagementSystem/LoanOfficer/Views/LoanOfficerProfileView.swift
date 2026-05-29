import SwiftUI

struct LoanOfficerProfileView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppStateManager
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationStack {
            List {
                // 1. OFFICER PROFILE HEADER CARD
                Section {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(
                                    colors: [LMSColors.brandNavy, LMSColors.actionBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ))
                                .frame(width: 80, height: 80)
                                .shadow(color: LMSColors.actionBlue.opacity(0.2), radius: 8, x: 0, y: 4)
                            
                            Text(authManager.currentStaffProfile?.initials ?? "AK")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text(authManager.currentStaffProfile?.fullName ?? "Arjun Kashyap")
                                .font(.title3.bold())
                                .foregroundStyle(LMSColors.textPrimary)
                            
                            Text(authManager.currentStaffProfile?.designation ?? "Senior Loan Officer")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(LMSColors.actionBlue)
                            
                            Text(authManager.currentStaffProfile?.branchName ?? "Bengaluru Central Branch (ID: BR-492)")
                                .font(.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                
                // 2. EMPLOYEE DETAILS SECTION
                Section("Employee Information") {
                    LabeledContent("Employee ID", value: authManager.currentStaffProfile?.employeeCode ?? "EMP-2024-9021")
                    LabeledContent("Department", value: "Retail Lending Operations")
                    LabeledContent("Role Level", value: authManager.currentStaffProfile?.designation ?? "L3 Administrator")
                    
                    let dateStr: String = {
                        if let date = authManager.currentStaffProfile?.createdAt {
                            return RelativeDateFormatter.shared.absoluteString(from: date)
                        }
                        return "15 Mar 2021"
                    }()
                    LabeledContent("Date of Joining", value: dateStr)
                }
                
                // 3. CONTACT DETAILS SECTION
                Section("Contact Information") {
                    LabeledContent("Official Email", value: authManager.currentStaffProfile?.email ?? "arjun.kashyap@astrabank.com")
                    LabeledContent("Work Phone", value: authManager.currentStaffProfile?.phoneNumber ?? "+91 80 4991 2099")
                }
                
                // 4. PERFORMANCE STATS SECTION
                Section("Performance & Operations") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Loans Verified")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                            Text("482")
                                .font(.headline.bold())
                                .foregroundStyle(LMSColors.brandNavy)
                            Text("Year to Date")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Accuracy Rate")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                            Text("98.7%")
                                .font(.headline.bold())
                                .foregroundStyle(LMSColors.brandNavy)
                            Text("Audit Score")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Portfolio Cap")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                            Text("₹ 12.8 Cr")
                                .font(.headline.bold())
                                .foregroundStyle(LMSColors.brandNavy)
                            Text("Active Limit")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Avg. Cycle Time")
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                            Text("1.8 Days")
                                .font(.headline.bold())
                                .foregroundStyle(LMSColors.brandNavy)
                            Text("TAT Score")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }


                
                // 6. LOGOUT BUTTON
                Section {
                    Button(role: .destructive) {
                        HapticsManager.triggerImpact(style: .medium)
                        dismiss()
                        appState.logout()
                        authManager.signOut()
                    } label: {
                        Text("Log Out Session")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("My Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
