import SwiftUI

struct LoanProductDetailView: View {
    let product: BorrowerLoanProduct
    let onApply: () -> Void

    @State private var expandedFAQ: UUID?

    private var sampleEMI: Double {
        calculateEMI(
            amount: product.maximumAmount * 0.5,
            months: min(60, product.maxTenureMonths),
            annualRate: product.baseInterestRate > 0 ? product.baseInterestRate / 100 : 0.105
        )
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: LMSSpacing.xxl) {
                heroSection
                benefitsSection
                eligibilitySection
                documentsSection
                emiPreviewSection
                faqSection
            }
            .padding(.bottom, 100)
        }
        .background(LMSColors.background)
        .navigationTitle(product.type.title)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            Button(action: onApply) {
                Text("Apply for Loan")
                    .font(LMSFont.button)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(LMSColors.brandNavy, in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, LMSSpacing.screenHorizontal)
            .padding(.vertical, LMSSpacing.md)
            .background(.ultraThinMaterial)
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [LMSColors.brandNavy, LMSColors.brandNavyLight, LMSColors.actionBlue.opacity(0.85)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            HStack {
                Spacer()
                VStack(spacing: 10) {
                    Image(systemName: "creditcard.fill")
                        .rotationEffect(.degrees(-8))
                        .offset(x: -18)
                    Image(systemName: product.type.iconName)
                        .font(.system(size: 52, weight: .semibold))
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .rotationEffect(.degrees(8))
                        .offset(x: 22)
                }
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.white.opacity(0.16))
                .padding(.trailing, LMSSpacing.xl)
            }

            VStack(alignment: .leading, spacing: LMSSpacing.lg) {
                HStack {
                    Image(systemName: product.type.iconName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 56, height: 56)
                        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
                    Spacer()
                }

                Text(product.type.title)
                    .font(LMSFont.title)
                    .foregroundStyle(.white)

                Text(product.shortDescription)
                    .font(LMSFont.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: LMSSpacing.lg) {
                    heroMetric(title: "Max Amount", value: product.maximumAmount.formattedAsCompactINR())
                    heroMetric(title: "Interest", value: product.interestRateRange)
                    heroMetric(title: "Approval", value: product.estimatedProcessingTime)
                }
            }
            .padding(LMSSpacing.xl)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
        .clipShape(RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
        .padding(.horizontal, LMSSpacing.screenHorizontal)
        .padding(.top, LMSSpacing.sm)
    }

    private func heroMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(LMSFont.caption2)
                .foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(LMSFont.footnote.weight(.bold))
                .foregroundStyle(.white)
        }
    }

    private var benefitsSection: some View {
        detailSection(title: "Key Benefits", subtitle: "Why borrowers choose this product") {
            ForEach(product.benefits, id: \.self) { benefit in
                Label(benefit, systemImage: "checkmark.circle.fill")
                    .font(LMSFont.subheadline)
                    .foregroundStyle(LMSColors.textPrimary)
                    .symbolRenderingMode(.hierarchical)
                    .tint(LMSColors.emerald)
            }
        }
    }

    private var eligibilitySection: some View {
        detailSection(title: "Eligibility Criteria", subtitle: "Minimum requirements to apply") {
            ForEach(product.eligibilityCriteria, id: \.self) { item in
                HStack(alignment: .top, spacing: LMSSpacing.sm) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .foregroundStyle(LMSColors.brandNavy)
                    Text(item)
                        .font(LMSFont.subheadline)
                        .foregroundStyle(LMSColors.textPrimary)
                }
            }
        }
    }

    private var documentsSection: some View {
        let docs = product.minimumRequirements.isEmpty
            ? ["PAN Card", "Aadhaar", "Income Proof", "Bank Statements"]
            : product.minimumRequirements

        return detailSection(title: "Required Documents", subtitle: "Keep these ready before applying") {
            ForEach(docs, id: \.self) { doc in
                Label(doc, systemImage: "doc.fill")
                    .font(LMSFont.subheadline)
                    .foregroundStyle(LMSColors.textPrimary)
                    .symbolRenderingMode(.hierarchical)
            }
        }
    }

    private var emiPreviewSection: some View {
        detailSection(title: "EMI Calculator Preview", subtitle: "Representative example") {
            VStack(alignment: .leading, spacing: LMSSpacing.sm) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(sampleEMI.formattedAsINR())
                        .font(.system(.title2, design: .rounded).weight(.bold))
                        .foregroundStyle(LMSColors.brandNavy)
                    Text("/ month")
                        .font(LMSFont.subheadline)
                        .foregroundStyle(LMSColors.textSecondary)
                }
                Text("For \(Double(Int(product.maximumAmount * 0.5)).formattedAsINR()) over \(min(60, product.maxTenureMonths)) months at \(product.interestRateRange). Final EMI depends on credit appraisal.")
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var faqSection: some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            Text("FAQ")
                .font(LMSFont.title3)
                .foregroundStyle(LMSColors.textPrimary)
                .padding(.horizontal, LMSSpacing.screenHorizontal)

            if product.faqs.isEmpty {
                Text("Contact support for product-specific questions.")
                    .font(LMSFont.footnote)
                    .foregroundStyle(LMSColors.textSecondary)
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
            } else {
                VStack(spacing: LMSSpacing.sm) {
                    ForEach(product.faqs) { faq in
                        DisclosureGroup(
                            isExpanded: Binding(
                                get: { expandedFAQ == faq.id },
                                set: { expandedFAQ = $0 ? faq.id : nil }
                            )
                        ) {
                            Text(faq.answer)
                                .font(LMSFont.footnote)
                                .foregroundStyle(LMSColors.textSecondary)
                                .padding(.top, LMSSpacing.xs)
                        } label: {
                            Text(faq.question)
                                .font(LMSFont.subheadline.weight(.medium))
                                .foregroundStyle(LMSColors.textPrimary)
                        }
                        .padding(LMSSpacing.lg)
                        .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.lg, style: .continuous))
                    }
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)
            }
        }
    }

    @ViewBuilder
    private func detailSection<Content: View>(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: LMSSpacing.md) {
            VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                Text(title)
                    .font(LMSFont.title3)
                    .foregroundStyle(LMSColors.textPrimary)
                Text(subtitle)
                    .font(LMSFont.footnote)
                    .foregroundStyle(LMSColors.textSecondary)
            }
            .padding(.horizontal, LMSSpacing.screenHorizontal)

            VStack(alignment: .leading, spacing: LMSSpacing.md) {
                content()
            }
            .padding(LMSSpacing.lg)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(LMSColors.surface, in: RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
                    .stroke(LMSColors.separatorLight, lineWidth: 0.5)
            )
            .padding(.horizontal, LMSSpacing.screenHorizontal)
        }
    }

    private func calculateEMI(amount: Double, months: Int, annualRate: Double) -> Double {
        let monthlyRate = annualRate / 12
        let n = Double(months)
        guard monthlyRate > 0 else { return amount / n }
        let factor = pow(1 + monthlyRate, n)
        let emi = (amount * monthlyRate * factor) / (factor - 1)
        return emi.isNaN || emi.isInfinite ? amount / n : emi
    }
}
