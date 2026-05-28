import SwiftUI

// MARK: - Loans Tab (Marketplace)

struct LoansMarketplaceView: View {
    @ObservedObject var viewModel: LoanApplicationViewModel
    let onProductDetail: (BorrowerLoanProduct) -> Void
    let onApply: (BorrowerLoanProduct) -> Void

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: LMSSpacing.xl) {
                VStack(alignment: .leading, spacing: LMSSpacing.xs) {
                    Text("Find the right financing for your needs")
                        .font(LMSFont.subheadline)
                        .foregroundStyle(LMSColors.textSecondary)

                    Text("\(viewModel.filteredProducts.count) products available")
                        .font(LMSFont.caption)
                        .foregroundStyle(LMSColors.textTertiary)
                }
                .padding(.horizontal, LMSSpacing.screenHorizontal)

                LoansSearchBar(text: $viewModel.searchQuery)
                    .padding(.horizontal, LMSSpacing.screenHorizontal)

                LoanCategoryChipRow(selection: $viewModel.selectedProductCategory)
                    .padding(.horizontal, LMSSpacing.screenHorizontal)

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
                            .contentShape(RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
                            .onTapGesture {
                                onProductDetail(product)
                            }
                        }
                    }
                    .padding(.horizontal, LMSSpacing.screenHorizontal)
                }
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

// MARK: - Category Chips

private struct LoanCategoryChipRow: View {
    @Binding var selection: LoanProductCategoryFilter

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: LMSSpacing.sm) {
                ForEach(LoanProductCategoryFilter.allCases) { category in
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selection = category
                        }
                    } label: {
                        Text(category.rawValue)
                            .font(LMSFont.footnote.weight(.semibold))
                            .foregroundStyle(selection == category ? Color.white : LMSColors.textPrimary)
                            .padding(.horizontal, LMSSpacing.lg)
                            .padding(.vertical, LMSSpacing.sm)
                            .background(
                                selection == category ? LMSColors.brandNavy : LMSColors.surface,
                                in: Capsule()
                            )
                            .overlay(
                                Capsule()
                                    .stroke(selection == category ? Color.clear : LMSColors.separatorLight, lineWidth: 0.5)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Product Card

struct PremiumLoanProductCard: View {
    let product: BorrowerLoanProduct
    let onApply: () -> Void
    let onLearnMore: () -> Void

    var body: some View {
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

                Spacer(minLength: 0)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(LMSColors.textTertiary)
                    .frame(width: 28, height: 28)
                    .background(LMSColors.background.opacity(0.7), in: Circle())
            }

            // Metrics
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: LMSSpacing.sm) {
                LoanMetricTile(title: "Maximum Amount", value: product.maximumAmount.formattedAsCompactINR(), icon: "indianrupeesign.circle.fill")
                LoanMetricTile(title: "Interest Range", value: product.interestRateRange, icon: "percent")
                LoanMetricTile(title: "Approval Time", value: product.estimatedProcessingTime, icon: "clock.fill", valueTint: LMSColors.emerald)
                LoanMetricTile(title: "EMI Starting From", value: product.emiStartingFrom.formattedAsINR(), icon: "calendar")
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
        .background(LMSColors.surfaceElevated, in: RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: LMSRadius.card, style: .continuous)
                .stroke(LMSColors.separatorLight, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.055), radius: 18, x: 0, y: 8)
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
        .background(LMSColors.background, in: RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous))
    }
}

private extension BorrowerLoanProductType {
    var marketplaceTint: Color {
        switch self {
        case .personal: return LMSColors.actionBlue
        case .home: return LMSColors.brandNavy
        case .education: return LMSColors.teal
        case .business: return LMSColors.amber
        case .vehicle: return LMSColors.emeraldDark
        case .gold: return LMSColors.amber
        case .loanAgainstProperty: return LMSColors.brandNavyLight
        case .other: return LMSColors.textSecondary
        }
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
