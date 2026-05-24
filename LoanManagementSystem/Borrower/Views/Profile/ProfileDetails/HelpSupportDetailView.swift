import SwiftUI

struct HelpSupportDetailView: View {
    var body: some View {
        Form {
            Section {
                Link(destination: URL(string: "tel:18001234567")!) {
                    Label("Toll Free: 1800-123-4567", systemImage: "phone")
                }
                
                Link(destination: URL(string: "mailto:support@loanmanagement.com")!) {
                    Label("Email: support@loanmanagement.com", systemImage: "envelope")
                }
            } header: {
                Text("Contact Channels")
            }
            
            Section {
                DisclosureGroup("How long does verification take?") {
                    Text("Standard KYC and employment verification are completed within 24-48 business hours.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                }
                
                DisclosureGroup("Can I prepayment my active loan?") {
                    Text("Yes, prepayment is allowed after 6 successful EMI payments. Please contact your loan officer for details.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                }
                
                DisclosureGroup("How is my personal data secured?") {
                    Text("All documents and bank credentials are encrypted using bank-grade AES-256 standard and transmitted securely over HTTPS.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 4)
                }
            } header: {
                Text("Frequently Asked Questions")
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
