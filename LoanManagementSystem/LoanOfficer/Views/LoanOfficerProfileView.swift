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
                            
                            Text("AK")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text("Arjun Kashyap")
                                .font(.title3.bold())
                                .foregroundStyle(LMSColors.textPrimary)
                            
                            Text("Senior Loan Officer")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(LMSColors.actionBlue)
                            
                            Text("Bengaluru Central Branch (ID: BR-492)")
                                .font(.caption)
                                .foregroundStyle(LMSColors.textSecondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                }
                
                // 2. EMPLOYEE DETAILS SECTION
                Section("Employee Information") {
                    LabeledContent("Employee ID", value: "EMP-2024-9021")
                    LabeledContent("Department", value: "Retail Lending Operations")
                    LabeledContent("Role Level", value: "L3 Administrator")
                    LabeledContent("Date of Joining", value: "15 Mar 2021")
                }
                
                // 3. CONTACT DETAILS SECTION
                Section("Contact Information") {
                    LabeledContent("Official Email", value: "arjun.kashyap@astrabank.com")
                    LabeledContent("Work Phone", value: "+91 80 4991 2099")
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
                
                // 5. ROLE CONFIGURATION & ACTIONS (SWITCH TO BORROWER)
                Section("System Settings") {
                    Button {
                        HapticsManager.triggerImpact(style: .heavy)
                        NotificationCenter.default.post(name: NSNotification.Name("SwitchRoleToBorrower"), object: nil)
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "arrow.left.arrow.right.circle.fill")
                                .font(.title2)
                                .foregroundStyle(LMSColors.actionBlue)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Switch to Borrower Mode")
                                    .font(.body.weight(.medium))
                                    .foregroundStyle(LMSColors.textPrimary)
                                Text("Access simulation client interface")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
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
