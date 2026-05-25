import SwiftUI

struct HelpSupportDetailView: View {
    var body: some View {
        Form {
            Section(header: Text("Customer Care")) {
                Link(destination: URL(string: "tel:18001234567")!) {
                    HStack {
                        Image(systemName: "phone.fill")
                            .foregroundStyle(Color.AppTheme.success)
                        Text("Toll Free: 1800-123-4567")
                            .foregroundStyle(Color.AppTheme.textPrimary)
                    }
                }

                Link(destination: URL(string: "mailto:support@loanmanagement.com")!) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(Color.AppTheme.primary)
                        Text("Email: support@loanmanagement.com")
                            .foregroundStyle(Color.AppTheme.textPrimary)
                    }
                }
            }

            Section(header: Text("Frequently Asked Questions")) {
                DisclosureGroup("How long does verification take?") {
                    Text("Standard KYC and employment verification are completed within 24-48 business hours.")
                        .font(Font.AppTheme.caption)
                        .foregroundStyle(Color.AppTheme.textSecondary)
                        .padding(.vertical, 4)
                }

                DisclosureGroup("Can I prepayment my active loan?") {
                    Text("Yes, prepayment is allowed after 6 successful EMI payments. Please contact your loan officer for details.")
                        .font(Font.AppTheme.caption)
                        .foregroundStyle(Color.AppTheme.textSecondary)
                        .padding(.vertical, 4)
                }

                DisclosureGroup("How is my personal data secured?") {
                    Text("All documents and bank credentials are encrypted using bank-grade AES-256 standard and transmitted securely over HTTPS.")
                        .font(Font.AppTheme.caption)
                        .foregroundStyle(Color.AppTheme.textSecondary)
                        .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        HelpSupportDetailView()
    }
}

