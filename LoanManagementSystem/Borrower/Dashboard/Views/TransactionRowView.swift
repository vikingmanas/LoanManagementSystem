//
//  TransactionRowView.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 19/05/26.
//

import SwiftUI

public struct TransactionRowView: View {
    let transaction: Transaction
    
    public init(transaction: Transaction) {
        self.transaction = transaction
    }
    
    // Helper to format date with time
    private var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy • h:mm a"
        return formatter.string(from: transaction.date)
    }
    
    public var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconBackgroundColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                
                Image(systemName: iconName)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(iconColor)
            }
            
            // Text Column
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.title)
                    .font(.subheadline.weight(.semibold))
                    .fontWeight(.semibold)
                    .foregroundColor(Color(.label))
                
                Text(formattedDateTime)
                    .font(.caption)
                    .foregroundColor(Color(.secondaryLabel))
                
                Text("Ref: \(transaction.referenceNo)")
                    .font(.caption2.monospaced())
                    .foregroundColor(Color(.tertiaryLabel))
            }
            
            Spacer()
            
            // Amount
            Text(amountText)
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .foregroundColor(amountColor)
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color(.tertiaryLabel))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
    
    // MARK: - Color & Symbol Mapping Helpers
    private var iconName: String {
        switch transaction.type {
        case .emiPayment: return "indianrupeesign.circle"
        case .credit: return "plus.circle"
        case .penalty: return "exclamationmark.circle"
        case .refund: return "arrow.uturn.left.circle"
        }
    }
    
    private var iconColor: Color {
        switch transaction.type {
        case .emiPayment: return .brandNavy
        case .credit: return .brandEmerald
        case .penalty: return .brandCoral
        case .refund: return Color(hex: "#00A2C4") // Teal-blue
        }
    }
    
    private var iconBackgroundColor: Color {
        iconColor
    }
    
    private var isDebit: Bool {
        switch transaction.type {
        case .emiPayment, .penalty:
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
        isDebit ? Color.brandCoral : Color.brandEmerald
    }
}

// MARK: - Row Skeleton
public struct TransactionRowSkeleton: View {
    public init() {}
    
    public var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color(.secondarySystemBackground))
                .frame(width: 44, height: 44)
            
            VStack(alignment: .leading, spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 140, height: 14)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.secondarySystemBackground))
                    .frame(width: 100, height: 10)
            }
            
            Spacer()
            
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.secondarySystemBackground))
                .frame(width: 60, height: 14)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .shimmer(active: true)
    }
}
