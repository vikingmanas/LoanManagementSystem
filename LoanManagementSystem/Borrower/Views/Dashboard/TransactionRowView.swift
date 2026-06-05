import SwiftUI

public struct TransactionRowView: View {
    let transaction: Transaction

    public init(transaction: Transaction) {
        self.transaction = transaction
    }

    private var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy • h:mm a"
        return formatter.string(from: transaction.date)
    }

    public var body: some View {
        HStack(spacing: LMSSpacing.md) {

            ZStack {
                RoundedRectangle(cornerRadius: LMSRadius.md, style: .continuous)
                    .fill(iconBackgroundColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title)
                    .font(LMSFont.subheadline.weight(.semibold))
                    .foregroundStyle(LMSColors.textPrimary)

                Text(formattedDateTime)
                    .font(LMSFont.caption)
                    .foregroundStyle(LMSColors.textSecondary)

                Text("Ref: \(transaction.referenceNo)")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(LMSColors.textTertiary)
            }

            Spacer()

            Text(amountText)
                .font(LMSFont.subheadline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(amountColor)
        }
        .padding(.horizontal, LMSSpacing.lg)
        .padding(.vertical, LMSSpacing.md)
        .contentShape(Rectangle())
    }

    private var iconName: String {
        switch transaction.type {
        case .emiPayment: return "indianrupeesign.circle"
        case .credit: return "plus.circle"
        case .penalty: return "exclamationmark.circle"
        case .refund: return "arrow.uturn.left.circle"
        case .failedDebit: return "exclamationmark.circle.fill"
        }
    }

    private var iconColor: Color {
        switch transaction.type {
        case .emiPayment: return LMSColors.brandNavy
        case .credit: return LMSColors.emerald
        case .penalty: return LMSColors.coral
        case .refund: return LMSColors.actionBlue
        case .failedDebit: return LMSColors.amber
        }
    }

    private var iconBackgroundColor: Color {
        iconColor
    }

    private var isDebit: Bool {
        switch transaction.type {
        case .emiPayment, .penalty, .failedDebit:
            return true
        case .credit, .refund:
            return false
        }
    }

    private var amountText: String {
        let formatted = transaction.amount.formattedAsINR()
        return isDebit ? "- \(formatted)" : "+ \(formatted)"
    }

    private var amountColor: Color {
        isDebit ? LMSColors.coral : LMSColors.emerald
    }
}

public struct TransactionRowSkeleton: View {
    public init() {}

    public var body: some View {
        HStack(spacing: LMSSpacing.md) {
            Circle()
                .fill(LMSColors.surfaceElevated)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: LMSRadius.sm)
                    .fill(LMSColors.surfaceElevated)
                    .frame(width: 140, height: 14)

                RoundedRectangle(cornerRadius: LMSRadius.sm)
                    .fill(LMSColors.surfaceElevated)
                    .frame(width: 100, height: 10)
            }

            Spacer()

            RoundedRectangle(cornerRadius: LMSRadius.sm)
                .fill(LMSColors.surfaceElevated)
                .frame(width: 60, height: 14)
        }
        .padding(.horizontal, LMSSpacing.screenHorizontal)
        .padding(.vertical, LMSSpacing.sm)
        .shimmer(active: true)
    }
}

#Preview("Transaction Row") {
    EmptyView()
}

#Preview("Transaction Skeleton") {
    TransactionRowSkeleton()
        .padding()
}
