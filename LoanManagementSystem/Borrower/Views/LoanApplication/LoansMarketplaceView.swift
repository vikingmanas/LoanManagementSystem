import SwiftUI

// MARK: - Loans Tab (Marketplace)

struct LoansMarketplaceView: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let onProductDetail: (BorrowerLoanProduct) -> Void
    let onApply: (BorrowerLoanProduct) -> Void
    let onSchemeDetail: (GovernmentSchemeCardModel) -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: LMSSpacing.lg) {
                LoansSearchBar(text: $viewModel.searchQuery)
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                    .padding(.top, LMSSpacing.sm)

                if viewModel.filteredProducts.isEmpty {
                    LoansEmptySearchState(query: viewModel.searchQuery)
                        .padding(.horizontal, LMSSpacing.screenHorizontal)
                        .padding(.top, LMSSpacing.lg)
                } else {
                    LazyVStack(spacing: LMSSpacing.lg) {
                        ForEach(viewModel.filteredProducts) { product in
                            PremiumLoanProductCard(
                                product: product,
                                onApply: { onApply(product) },
                                onLearnMore: { onProductDetail(product) }
                            )
                        }
                    }
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                }

                GovernmentSchemesBenefitsSection(onSchemeDetail: onSchemeDetail)
            }
            .padding(.bottom, LMSSpacing.xxxl)
        }
    }
}

// MARK: - Search

private struct LoansSearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: LMSSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(LMSColors.textTertiary)

            TextField("Search loan products", text: $text)
                .font(LMSFont.body)
                .foregroundStyle(LMSColors.textPrimary)
                .autocorrectionDisabled()

            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(LMSColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, LMSSpacing.md)
        .padding(.vertical, LMSSpacing.md)
        .background(LMSColors.surfaceElevated, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.025), radius: 8, x: 0, y: 3)
    }
}

// MARK: - Product Card

struct PremiumLoanProductCard: View {
    let product: BorrowerLoanProduct
    let onApply: () -> Void
    let onLearnMore: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
                .fill(product.type.marketplaceGradient)

            Image(systemName: product.type.marketplaceDecorativeIcon)
                .font(.system(size: 92, weight: .semibold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(product.type.marketplaceTint.opacity(0.09))
                .rotationEffect(.degrees(-12))
                .offset(x: 22, y: 18)

            VStack(alignment: .leading, spacing: LMSSpacing.lg) {
            // Header
            HStack(alignment: .top, spacing: LMSSpacing.md) {
                Image(systemName: product.type.iconName)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(product.type.marketplaceTint)
                    .frame(width: 52, height: 52)
                    .background(product.type.marketplaceTint.opacity(0.11), in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text(product.type.title)
                        .font(LMSFont.headline)
                        .foregroundStyle(LMSColors.textPrimary)
                    Text(product.shortDescription)
                        .font(LMSFont.footnote)
                        .foregroundStyle(LMSColors.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Metrics
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: LMSSpacing.sm) {
                LoanMetricTile(title: product.type.primaryAmountLabel, value: product.maximumAmount.formattedAsCompactINR(), icon: "indianrupeesign.circle.fill")
                LoanMetricTile(title: product.type.interestMetricLabel, value: product.interestRateRange, icon: product.type.interestMetricIcon)
                LoanMetricTile(title: product.type.approvalMetricLabel, value: product.estimatedProcessingTime, icon: "clock.fill", valueTint: LMSColors.emerald)
                LoanMetricTile(title: "Special Benefit", value: product.type.specialBenefit, icon: product.type.specialBenefitIcon, valueTint: product.type.marketplaceTint)
            }

            // Footer CTAs
            HStack(spacing: LMSSpacing.md) {
                Button(action: onLearnMore) {
                    Text("Learn More")
                        .font(LMSFont.footnote.weight(.semibold))
                        .foregroundStyle(LMSColors.brandNavy)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(LMSColors.brandNavy.opacity(0.08), in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
                }
                .buttonStyle(.plain)

                Button(action: onApply) {
                    Text("Apply Now")
                        .font(LMSFont.footnote.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(LMSColors.brandNavy, in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            }
            .padding(LMSSpacing.lg)
        }
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
                .stroke(product.type.marketplaceTint.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: product.type.marketplaceTint.opacity(0.13), radius: 18, x: 0, y: 8)
    }
}

private struct LoanMetricTile: View {
    let title: String
    let value: String
    let icon: String
    var valueTint: Color = LMSColors.textPrimary

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon)
                .font(LMSFont.caption2.weight(.semibold))
                .foregroundStyle(LMSColors.textSecondary)
                .labelStyle(.titleAndIcon)
                .lineLimit(1)

            Text(value)
                .font(LMSFont.footnote.weight(.bold))
                .foregroundStyle(valueTint)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LMSSpacing.md)
        .background(LMSColors.surfaceElevated.opacity(0.72), in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
        )
    }
}

private extension BorrowerLoanProductType {
    var marketplaceTint: Color {
        switch self {
        case .personal: return LMSColors.actionBlue
        case .home: return LMSColors.brandNavy
        case .education: return LMSColors.teal
        case .business: return Color(hex: "7C3AED")
        case .vehicle: return LMSColors.emeraldDark
        case .agriculture: return Color(hex: "16A34A")
        case .consumer: return Color(hex: "6366F1")
        case .msmeStartup: return Color(hex: "14B8A6")
        case .gold: return LMSColors.amber
        case .loanAgainstProperty: return LMSColors.brandNavyLight
        case .other: return LMSColors.textSecondary
        }
    }

    var marketplaceGradient: LinearGradient {
        LinearGradient(colors: marketplaceGradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var marketplaceGradientColors: [Color] {
        switch self {
        case .personal: return [LMSColors.surfaceElevated, LMSColors.actionBlue.opacity(0.10)]
        case .home: return [LMSColors.surfaceElevated, LMSColors.brandNavy.opacity(0.10)]
        case .education: return [LMSColors.surfaceElevated, LMSColors.teal.opacity(0.10)]
        case .business: return [LMSColors.surfaceElevated, Color(hex: "7C3AED").opacity(0.11)]
        case .vehicle: return [LMSColors.surfaceElevated, LMSColors.emeraldDark.opacity(0.10)]
        case .agriculture: return [LMSColors.surfaceElevated, Color(hex: "16A34A").opacity(0.15)]
        case .consumer: return [LMSColors.surfaceElevated, Color(hex: "6366F1").opacity(0.16)]
        case .msmeStartup: return [LMSColors.surfaceElevated, Color(hex: "111827").opacity(0.10), Color(hex: "14B8A6").opacity(0.12)]
        case .gold: return [LMSColors.surfaceElevated, LMSColors.amber.opacity(0.14)]
        case .loanAgainstProperty: return [LMSColors.surfaceElevated, Color(hex: "111827").opacity(0.12)]
        case .other: return [LMSColors.surfaceElevated, LMSColors.textSecondary.opacity(0.08)]
        }
    }

    var marketplaceDecorativeIcon: String {
        switch self {
        case .personal: return "wallet.pass.fill"
        case .home: return "house.and.flag.fill"
        case .education: return "book.closed.fill"
        case .business: return "briefcase.fill"
        case .vehicle: return "car.2.fill"
        case .agriculture: return "leaf.circle.fill"
        case .consumer: return "creditcard.and.123"
        case .msmeStartup: return "chart.line.uptrend.xyaxis.circle.fill"
        case .gold: return "seal.fill"
        case .loanAgainstProperty: return "building.2.fill"
        case .other: return "sparkles"
        }
    }

    var primaryAmountLabel: String {
        switch self {
        case .consumer: return "Credit Limit"
        case .msmeStartup: return "Maximum Funding"
        default: return "Maximum Amount"
        }
    }

    var interestMetricLabel: String {
        switch self {
        case .loanAgainstProperty: return "Loan-to-Value / Rate"
        default: return "Interest"
        }
    }

    var interestMetricIcon: String {
        switch self {
        case .loanAgainstProperty: return "building.columns.fill"
        default: return "percent"
        }
    }

    var approvalMetricLabel: String {
        switch self {
        case .loanAgainstProperty, .msmeStartup: return "Approval Timeline"
        default: return "Approval Time"
        }
    }

    var specialBenefit: String {
        switch self {
        case .agriculture: return "Subsidy support"
        case .loanAgainstProperty: return "High LTV"
        case .consumer: return "Instant EMI"
        case .msmeStartup: return "Govt schemes"
        case .home: return "Tax benefits"
        case .education: return "Moratorium"
        case .business: return "Working capital"
        case .vehicle: return "Dealer tie-ups"
        case .gold: return "Same-day funds"
        case .personal: return "Fast approval"
        case .other: return "Advisory"
        }
    }

    var specialBenefitIcon: String {
        switch self {
        case .agriculture: return "leaf.fill"
        case .loanAgainstProperty: return "checkmark.shield.fill"
        case .consumer: return "bolt.fill"
        case .msmeStartup: return "arrow.up.right.circle.fill"
        default: return "sparkles"
        }
    }
}

// MARK: - Government Schemes

private struct GovernmentSchemesBenefitsSection: View {
    private let schemes = GovernmentSchemeCardModel.featured
    let onSchemeDetail: (GovernmentSchemeCardModel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                Text("Government Schemes & Benefits")
                    .font(LMSFont.title3)
                    .foregroundStyle(LMSColors.textPrimary)
                Text("Special financial programs and benefits")
                    .font(LMSFont.footnote)
                    .foregroundStyle(LMSColors.textSecondary)
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: LMSSpacing.md) {
                    ForEach(schemes) { scheme in
                        GovernmentSchemeCard(scheme: scheme) {
                            onSchemeDetail(scheme)
                        }
                    }
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

struct GovernmentSchemeCardModel: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let description: String
    let eligibility: String
    let benefit: String
    let eligibilityItems: [String]
    let benefits: [String]
    let requiredDocuments: [String]
    let applicationSteps: [String]
    let websiteURL: URL?
    let branchAvailable: Bool
    let badge: String
    let status: String
    let icon: String
    let theme: Color

    static let featured: [GovernmentSchemeCardModel] = [
        GovernmentSchemeCardModel(
            title: "Farmer Support Schemes",
            description: "Crop subsidy, low-interest agriculture credit, and irrigation support programs.",
            eligibility: "Farmers & cultivators",
            benefit: "Subsidy-linked support",
            eligibilityItems: ["Farmers", "Tenant cultivators", "Agri entrepreneurs", "Kisan Credit Card users"],
            benefits: ["Lower interest support", "Crop-season credit", "Reduced processing friction", "Flexible repayment windows"],
            requiredDocuments: ["Aadhaar", "PAN", "Land/cultivation proof", "Bank statement"],
            applicationSteps: ["Verify farming profile", "Upload identity and land proof", "Loan officer verifies eligibility", "Approval and disbursement"],
            websiteURL: URL(string: "https://www.myscheme.gov.in"),
            branchAvailable: true,
            badge: "Farmer Benefit",
            status: "Active",
            icon: "leaf.fill",
            theme: Color(hex: "16A34A")
        ),
        GovernmentSchemeCardModel(
            title: "Defense / Police Benefits",
            description: "Reduced fees, faster approvals, lower rates, and salary-linked benefits.",
            eligibility: "Army, police & service staff",
            benefit: "Priority processing",
            eligibilityItems: ["Army", "Navy", "Air Force", "Police Personnel", "Retired Service Members"],
            benefits: ["Lower interest rates", "Priority processing", "Reduced documentation", "Dedicated support"],
            requiredDocuments: ["Service ID Card", "Aadhaar", "PAN", "Salary Slip"],
            applicationSteps: ["Verify service identity", "Upload documents", "Loan officer verification", "Approval and disbursement"],
            websiteURL: URL(string: "https://www.myscheme.gov.in"),
            branchAvailable: true,
            badge: "Service Benefit",
            status: "Active",
            icon: "shield.lefthalf.filled",
            theme: LMSColors.brandNavy
        ),
        GovernmentSchemeCardModel(
            title: "Women Entrepreneur Programs",
            description: "Startup support, MSME assistance, and reduced collateral requirements.",
            eligibility: "Women-led businesses",
            benefit: "Collateral relief",
            eligibilityItems: ["Women entrepreneurs", "Women-led MSMEs", "Registered startups", "Self-employed applicants"],
            benefits: ["Collateral relief", "Startup support", "MSME assistance", "Flexible assessment"],
            requiredDocuments: ["Aadhaar", "PAN", "Business registration", "Bank statement"],
            applicationSteps: ["Verify business ownership", "Upload KYC and business proof", "Eligibility assessment", "Approval and funding"],
            websiteURL: URL(string: "https://www.myscheme.gov.in"),
            branchAvailable: true,
            badge: "Women Empowerment",
            status: "Recommended",
            icon: "person.2.fill",
            theme: Color(hex: "8B5CF6")
        ),
        GovernmentSchemeCardModel(
            title: "MSME / Startup Support",
            description: "Mudra-style assistance, working capital, and business expansion schemes.",
            eligibility: "MSME & startups",
            benefit: "Growth funding",
            eligibilityItems: ["MSME owners", "Registered startups", "Small businesses", "Working capital borrowers"],
            benefits: ["Growth funding", "Working capital support", "Expansion finance", "Priority loan review"],
            requiredDocuments: ["Aadhaar", "PAN", "Udyam/GST proof", "Bank statement"],
            applicationSteps: ["Verify business profile", "Upload business documents", "Loan officer assessment", "Sanction and disbursement"],
            websiteURL: URL(string: "https://www.myscheme.gov.in"),
            branchAvailable: true,
            badge: "Business Growth",
            status: "Trending",
            icon: "chart.line.uptrend.xyaxis",
            theme: Color(hex: "14B8A6")
        ),
        GovernmentSchemeCardModel(
            title: "EWS Financial Support",
            description: "Subsidized housing assistance, education support loans, and welfare aid.",
            eligibility: "Eligible EWS profiles",
            benefit: "Welfare assistance",
            eligibilityItems: ["EWS applicants", "Eligible family income group", "First-time borrowers", "Welfare-linked profiles"],
            benefits: ["Subsidized support", "Housing assistance", "Education aid", "Lower processing burden"],
            requiredDocuments: ["Aadhaar", "PAN", "Income certificate", "Address proof"],
            applicationSteps: ["Verify income category", "Upload certificate and KYC", "Officer validates eligibility", "Benefit-linked approval"],
            websiteURL: URL(string: "https://www.myscheme.gov.in"),
            branchAvailable: true,
            badge: "Social Welfare",
            status: "Active",
            icon: "hands.sparkles.fill",
            theme: Color(hex: "F59E0B")
        )
    ]
}

private struct GovernmentSchemeCard: View {
    let scheme: GovernmentSchemeCardModel
    let onLearnMore: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            HStack(alignment: .top) {
                Image(systemName: scheme.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                            .stroke(.white.opacity(0.16), lineWidth: 1)
                    )

                Spacer()

                Text(scheme.status)
                    .font(LMSFont.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(.white.opacity(0.16), in: Capsule())
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(scheme.badge)
                    .font(LMSFont.caption2.weight(.bold))
                    .foregroundStyle(.white.opacity(0.74))
                    .lineLimit(1)
                Text(scheme.title)
                    .font(LMSFont.headline.weight(.bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .frame(height: 52, alignment: .topLeading)
                Text(scheme.description)
                    .font(LMSFont.caption)
                    .foregroundStyle(.white.opacity(0.76))
                    .lineLimit(2)
                    .frame(height: 42, alignment: .topLeading)
            }

            VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                SchemeInfoPill(label: "Eligibility", value: scheme.eligibility)
                SchemeInfoPill(label: "Key Benefit", value: scheme.benefit)
            }
            .frame(height: 108, alignment: .top)

            Spacer(minLength: 0)

            Button {
                onLearnMore()
            } label: {
                Text("Learn More")
                    .font(LMSFont.footnote.weight(.semibold))
                    .foregroundStyle(scheme.theme)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .background(.white, in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(LMSSpacing.lg)
        .frame(width: 280, height: 420, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [scheme.theme, scheme.theme.opacity(0.72), Color(hex: "111827")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
        )
        .overlay(alignment: .bottomTrailing) {
            Image(systemName: scheme.icon)
                .font(.system(size: 96, weight: .semibold))
                .foregroundStyle(.white.opacity(0.08))
                .offset(x: 20, y: 16)
        }
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
                .stroke(.white.opacity(0.13), lineWidth: 1)
        )
        .shadow(color: scheme.theme.opacity(0.18), radius: 18, x: 0, y: 8)
    }
}

private struct SchemeInfoPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(LMSFont.caption2.weight(.bold))
                .foregroundStyle(.white.opacity(0.56))
            Text(value)
                .font(LMSFont.caption.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 50, alignment: .leading)
        .padding(.horizontal, LMSSpacing.sm)
        .padding(.vertical, 7)
        .background(.white.opacity(0.12), in: RoundedRectangle(cornerRadius: LMSRadius.sm, style: .continuous))
    }
}

struct GovernmentSchemeDetailView: View {
    let scheme: GovernmentSchemeCardModel
    @Environment(\.openURL) private var openURL
    @State private var didRequestApply = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: LMSSpacing.lg) {
                detailHero
                detailSection(title: "Description", text: scheme.description)
                bulletSection(title: "Eligibility", items: scheme.eligibilityItems)
                bulletSection(title: "Benefits", items: scheme.benefits)
                bulletSection(title: "Required Documents", items: scheme.requiredDocuments)
                stepsSection
                officialInfoSection
                applyButton
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)
            .padding(.bottom, LMSSpacing.xxxl)
        }
        .background(LMSColors.background)
        .navigationTitle("Scheme Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Application Request Saved", isPresented: $didRequestApply) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("A loan officer will guide you through this scheme's eligibility and document verification.")
        }
    }

    private var detailHero: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Image(systemName: scheme.icon)
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 64, height: 64)
                .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))

            Text(scheme.badge)
                .font(LMSFont.caption.weight(.bold))
                .foregroundStyle(.white.opacity(0.76))

            Text(scheme.title)
                .font(.title2.weight(.bold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(scheme.benefit)
                .font(LMSFont.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(.white.opacity(0.16), in: Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LMSSpacing.lg)
        .background(
            LinearGradient(
                colors: [scheme.theme, scheme.theme.opacity(0.72), Color(hex: "111827")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
        )
        .padding(.top, LMSSpacing.sm)
    }

    private func detailSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
            Text(title)
                .font(LMSFont.headline)
                .foregroundStyle(LMSColors.textPrimary)
            Text(text)
                .font(LMSFont.body)
                .foregroundStyle(LMSColors.textSecondary)
        }
        .schemeDetailCard()
    }

    private func bulletSection(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: LMSSpacing.sm) {
            Text(title)
                .font(LMSFont.headline)
                .foregroundStyle(LMSColors.textPrimary)
            ForEach(items, id: \.self) { item in
                Label(item, systemImage: "checkmark.circle.fill")
                    .font(LMSFont.callout)
                    .foregroundStyle(LMSColors.textSecondary)
            }
        }
        .schemeDetailCard()
    }

    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("Application Process")
                .font(LMSFont.headline)
                .foregroundStyle(LMSColors.textPrimary)
            ForEach(Array(scheme.applicationSteps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: LMSSpacing.md) {
                    Text("Step \(index + 1)")
                        .font(LMSFont.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(scheme.theme, in: Capsule())
                    Text(step)
                        .font(LMSFont.callout)
                        .foregroundStyle(LMSColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .schemeDetailCard()
    }

    private var officialInfoSection: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("How to Avail")
                .font(LMSFont.headline)
                .foregroundStyle(LMSColors.textPrimary)

            if scheme.branchAvailable {
                Label("Visit Branch", systemImage: "building.columns.fill")
                    .font(LMSFont.callout.weight(.semibold))
                    .foregroundStyle(LMSColors.textPrimary)
                Text("Nearest branch assistance available.")
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)
            }

            if let websiteURL = scheme.websiteURL {
                Button {
                    openURL(websiteURL)
                } label: {
                    Label("Open External Website", systemImage: "safari.fill")
                        .font(LMSFont.callout.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                }
                .buttonStyle(.bordered)
                .tint(scheme.theme)
            }
        }
        .schemeDetailCard()
    }

    private var applyButton: some View {
        Button {
            didRequestApply = true
        } label: {
            Text("Apply Now")
                .font(LMSFont.button)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(LMSColors.brandNavy, in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private extension View {
    func schemeDetailCard() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(LMSSpacing.lg)
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
                    .stroke(LMSColors.separatorLight.opacity(0.6), lineWidth: 1)
            )
    }
}

private struct LoansEmptySearchState: View {
    let query: String

    var body: some View {
        VStack(spacing: LMSSpacing.md) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(LMSColors.brandNavy.opacity(0.7))
            Text("No loan products found")
                .font(LMSFont.headline)
                .foregroundStyle(LMSColors.textPrimary)
            Text(query.isEmpty
                 ? "Try a different category filter."
                 : "No results for \"\(query)\". Try Personal, Home, or Education.")
                .font(LMSFont.footnote)
                .foregroundStyle(LMSColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(LMSSpacing.xxl)
        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
    }
}
