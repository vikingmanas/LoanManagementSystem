import SwiftUI
import Foundation

public struct CustomerInsightCardView: View {
    public var profile: BorrowerProfile
    
    public init(profile: BorrowerProfile) {
        self.profile = profile
    }
    
    public var body: some View {
        VStack(spacing: 0) {

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(profile.fullName)
                        .font(LMSFont.headline)
                        .foregroundStyle(.white)

                    Text("Customer ID: \(profile.id)")
                        .font(LMSFont.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .fontDesign(.monospaced)
                }

                Spacer()

                Image(systemName: "checkmark.seal.fill")
                    .font(.title2)
                    .foregroundStyle(LMSColors.emerald)
                    .opacity(profile.isKYCVerified ? 1 : 0)
            }
            .padding(LMSSpacing.xl)

            Divider()
                .background(Color.white.opacity(0.15))

            VStack(spacing: LMSSpacing.lg) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Account Number")
                            .font(LMSFont.caption)
                            .foregroundStyle(.white.opacity(0.65))
                        Text(maskedAccount(profile.bankDetails.accountNumber))
                            .font(.system(.body, design: .monospaced, weight: .medium))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Branch")
                            .font(LMSFont.caption)
                            .foregroundStyle(.white.opacity(0.65))
                        Text(profile.preferredBranch.isEmpty ? "Not Set" : profile.preferredBranch)
                            .font(LMSFont.body.weight(.medium))
                            .foregroundStyle(.white)
                    }
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Relationship Since")
                            .font(LMSFont.caption)
                            .foregroundStyle(.white.opacity(0.65))
                        Text(profile.bankingRelationshipDuration.isEmpty ? "New" : profile.bankingRelationshipDuration)
                            .font(LMSFont.body.weight(.medium))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Account Status")
                            .font(LMSFont.caption)
                            .foregroundStyle(.white.opacity(0.65))
                        Text("Active")
                            .font(LMSFont.body.weight(.bold))
                            .foregroundStyle(LMSColors.emerald)
                    }
                }
            }
            .padding(LMSSpacing.xl)
            .background(Color.white.opacity(0.05))

            Divider()
                .background(Color.white.opacity(0.15))

            HStack(spacing: LMSSpacing.xl) {
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
            .padding(.vertical, LMSSpacing.lg)
        }
        .background(
            LinearGradient(
                colors: [LMSColors.brandNavy, LMSColors.brandNavyLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.3), Color.clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
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

public struct InsightSummaryItem: View {
    public let title: String
    public let value: String
    public let icon: String
    
    public init(title: String, value: String, icon: String) {
        self.title = title
        self.value = value
        self.icon = icon
    }
    
    public var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.9))

            Text(value)
                .font(LMSFont.body.weight(.bold))
                .foregroundStyle(.white)

            Text(title)
                .font(LMSFont.caption2)
                .foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
    }
}
