import SwiftUI

struct CustomerInsightCardView: View {
    var profile: BorrowerProfile
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Section: Identity & Branch
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(profile.fullName)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Customer ID: \(profile.id)")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .fontDesign(.monospaced)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundColor(Color(hex: "34C759")) // Success Green
                    .opacity(profile.isKYCVerified ? 1 : 0)
            }
            .padding(20)
            
            Divider()
                .background(Color.white.opacity(0.15))
            
            // Middle Section: Account Info
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Account Number")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text(maskedAccount(profile.bankDetails.accountNumber))
                            .font(.system(.body, design: .monospaced, weight: .medium))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Branch")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text(profile.preferredBranch.isEmpty ? "Not Set" : profile.preferredBranch)
                            .font(.system(.body, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Relationship Since")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text(profile.bankingRelationshipDuration.isEmpty ? "New" : profile.bankingRelationshipDuration)
                            .font(.system(.body, weight: .medium))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Account Status")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                        Text("Active")
                            .font(.system(.body, weight: .bold))
                            .foregroundColor(Color(hex: "34C759"))
                    }
                }
            }
            .padding(20)
            .background(Color.white.opacity(0.05))
            
            Divider()
                .background(Color.white.opacity(0.15))
            
            // Bottom Section: Summary
            HStack(spacing: 20) {
                InsightSummaryItem(
                    title: "Active Loans",
                    value: "\(profile.existingLoansCount)",
                    icon: "dollarsign.arrow.circlepath"
                )
                
                Divider()
                    .background(Color.white.opacity(0.15))
                    .frame(height: 40)
                
                InsightSummaryItem(
                    title: "Credit Cards",
                    value: "\(profile.existingCreditCardsCount)",
                    icon: "creditcard.fill"
                )
                
                Divider()
                    .background(Color.white.opacity(0.15))
                    .frame(height: 40)
                
                InsightSummaryItem(
                    title: "KYC Status",
                    value: profile.isKYCVerified ? "Verified" : "Pending",
                    icon: "person.text.rectangle"
                )
            }
            .padding(.vertical, 16)
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "1A3A8F"), Color(hex: "4B67D6")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(24)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.3), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: 8)
    }
    
    private func maskedAccount(_ account: String) -> String {
        guard account.count > 4 else { return account }
        let suffix = account.suffix(4)
        return "•••• \(suffix)"
    }
}

struct InsightSummaryItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "0A84FF")) // Deep Blue Primary
            
            Text(value)
                .font(.system(.body, weight: .bold))
                .foregroundColor(.white)
            
            Text(title)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }
}
