//
//  MockData.swift
//  LoanManagementSystem
//
//  Created by Antigravity on 19/05/26.
//

import SwiftUI

// MARK: - Color Extensions
extension Color {
    public static let brandNavy = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 26/255, green: 54/255, blue: 93/255, alpha: 1) // #1A365D
            : UIColor(red: 10/255, green: 37/255, blue: 64/255, alpha: 1) // #0A2540
    })
    
    public static let brandNavyDark = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 16/255, green: 34/255, blue: 63/255, alpha: 1) // #10223F
            : UIColor(red: 46/255, green: 59/255, blue: 132/255, alpha: 1) // #2E3B84
    })
    
    public static let brandEmerald = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 5/255, green: 224/255, blue: 165/255, alpha: 1) // #05E0A5
            : UIColor(red: 0/255, green: 196/255, blue: 140/255, alpha: 1) // #00C48C
    })
    
    public static let brandEmeraldDark = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0/255, green: 120/255, blue: 90/255, alpha: 1) // #00785A
            : UIColor(red: 0/255, green: 158/255, blue: 134/255, alpha: 1) // #009E86
    })
    
    public static let brandAmber = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 255/255, green: 196/255, blue: 54/255, alpha: 1) // #FFC436
            : UIColor(red: 255/255, green: 179/255, blue: 0/255, alpha: 1) // #FFB300
    })
    
    public static let brandCoral = Color(UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 255/255, green: 115/255, blue: 117/255, alpha: 1) // #FF7375
            : UIColor(red: 255/255, green: 77/255, blue: 79/255, alpha: 1) // #FF4D4F
    })
}

// MARK: - Formatters
extension Double {
    public func formattedAsINR() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_IN")
        formatter.currencyCode = "INR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "₹\(Int(self))"
    }
}

extension Date {
    public func formattedAsDDMMMYYYY() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: self)
    }
}

// MARK: - Mock Data Struct
public struct MockData {
    public static func makeDate(year: Int, month: Int, day: Int, hour: Int = 10, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
    
    // Unique UUIDs for mock data linking
    public static let uuid1 = UUID(uuidString: "7a83d789-21df-4a69-9528-98e6e58914b1") ?? UUID()
    public static let uuid2 = UUID(uuidString: "f07d2c3e-8c9e-4c8d-8a1a-4a2b3c4d5e6f") ?? UUID()
    public static let uuid3 = UUID(uuidString: "8e9b0a1c-2d3e-4f5a-6b7c-8d9e0f1a2b3c") ?? UUID()
    
    public static let loanId1 = UUID(uuidString: "a3b4c5d6-e7f8-9a0b-1c2d-3e4f5a6b7c8d") ?? UUID()
    public static let loanId2 = UUID(uuidString: "b4c5d6e7-f89a-0b1c-2d3e-4f5a-6b7c8d9e") ?? UUID()
    public static let loanId3 = UUID(uuidString: "c5d6e7f8-9a0b-1c2d-3e4f-5a6b7c8d9e0f") ?? UUID()

    // 3 Bank Accounts
    public static let sbi = BankAccount(
        id: uuid1,
        accountNumber: "XXXXXX7890",
        bankName: "State Bank of India",
        accountType: .savings,
        availableBalance: 42300.0,
        minBalance: 5000.0,
        linkedLoanIds: [loanId1]
    )
    
    public static let hdfc = BankAccount(
        id: uuid2,
        accountNumber: "XXXXXX3421",
        bankName: "HDFC Bank",
        accountType: .overdraft,
        availableBalance: 15000.0,
        odLimit: 50000.0,
        linkedLoanIds: [loanId2]
    )
    
    public static let axis = BankAccount(
        id: uuid3,
        accountNumber: "XXXXXX9910",
        bankName: "Axis Bank",
        accountType: .current,
        availableBalance: 2800.0,
        linkedLoanIds: [loanId3]
    )
    
    // 3 Loans
    public static let home = DashboardLoanAccount(
        id: loanId1,
        accountNumber: "XXXX XXXX 4321",
        loanType: "Home Loan",
        sanctionedAmount: 3000000.0,
        principalOutstanding: 1850000.0,
        totalEMI: 18500.0,
        nextEMIDate: makeDate(year: 2025, month: 6, day: 5),
        tenureRemainingMonths: 84,
        totalTenureMonths: 120,
        repaidPercentage: 0.68,
        linkedBankAccountId: uuid1
    )
    
    public static let business = DashboardLoanAccount(
        id: loanId2,
        accountNumber: "XXXX XXXX 8765",
        loanType: "Business Loan",
        sanctionedAmount: 1000000.0,
        principalOutstanding: 720000.0,
        totalEMI: 12000.0,
        nextEMIDate: makeDate(year: 2025, month: 6, day: 5),
        tenureRemainingMonths: 36,
        totalTenureMonths: 60,
        repaidPercentage: 0.28,
        linkedBankAccountId: uuid2
    )
    
    public static let car = DashboardLoanAccount(
        id: loanId3,
        accountNumber: "XXXX XXXX 9911",
        loanType: "Car Loan",
        sanctionedAmount: 500000.0,
        principalOutstanding: 380000.0,
        totalEMI: 9200.0,
        nextEMIDate: makeDate(year: 2025, month: 6, day: 5),
        tenureRemainingMonths: 48,
        totalTenureMonths: 60,
        repaidPercentage: 0.24,
        linkedBankAccountId: uuid3
    )
    
    // Initial static data
    public static let sampleLoanAccount = home
    
    public static let sampleBankAccount = sbi
    
    public static let sampleOverdraftAccount = hdfc
    
    public static let samplePendingEMIs: [EMIRecord] = [
        EMIRecord(dueDate: makeDate(year: 2025, month: 6, day: 5), amount: 18500.0, loanType: "Home Loan", status: .dueSoon),
        EMIRecord(dueDate: makeDate(year: 2025, month: 5, day: 5), amount: 8500.0, loanType: "Personal Loan", status: .overdue),
        EMIRecord(dueDate: makeDate(year: 2025, month: 7, day: 5), amount: 18500.0, loanType: "Home Loan", status: .upcoming),
        EMIRecord(dueDate: makeDate(year: 2025, month: 8, day: 5), amount: 18500.0, loanType: "Home Loan", status: .upcoming),
        EMIRecord(dueDate: makeDate(year: 2025, month: 9, day: 5), amount: 18500.0, loanType: "Home Loan", status: .upcoming),
        EMIRecord(dueDate: makeDate(year: 2025, month: 10, day: 5), amount: 18500.0, loanType: "Home Loan", status: .upcoming)
    ]
    
    public static let sampleTransactions: [Transaction] = [
        Transaction(title: "EMI - Home Loan", date: makeDate(year: 2025, month: 5, day: 5, hour: 11, minute: 30), amount: 18500.0, type: .emiPayment, referenceNo: "TXN9847291"),
        Transaction(title: "Salary Credited", date: makeDate(year: 2025, month: 5, day: 1, hour: 9, minute: 15), amount: 75000.0, type: .credit, referenceNo: "TXN1028392"),
        Transaction(title: "Auto-debit Penalty", date: makeDate(year: 2025, month: 4, day: 10, hour: 18, minute: 0), amount: 450.0, type: .penalty, referenceNo: "TXN4728193"),
        Transaction(title: "Processing Fee Refund", date: makeDate(year: 2025, month: 4, day: 5, hour: 14, minute: 20), amount: 2500.0, type: .refund, referenceNo: "TXN7783921"),
        Transaction(title: "EMI - Personal Loan", date: makeDate(year: 2025, month: 4, day: 5, hour: 10, minute: 0), amount: 8500.0, type: .emiPayment, referenceNo: "TXN3384918")
    ]
    
    public static let sampleSchemes: [GovernmentScheme] = [
        GovernmentScheme(
            title: "PM Mudra Yojana",
            description: "Get 2% interest relaxation on business loans under PM Mudra Yojana",
            category: .businessLoan,
            validTill: makeDate(year: 2026, month: 3, day: 31),
            benefitSummary: "2% Rate relaxation"
        ),
        GovernmentScheme(
            title: "PMAY Home Subsidy",
            description: "Interest subsidy of up to ₹2.67 Lakhs on housing loans for eligible families",
            category: .homeLoan,
            validTill: makeDate(year: 2026, month: 3, day: 31),
            benefitSummary: "Up to ₹2.67L Subsidy"
        ),
        GovernmentScheme(
            title: "Kisan Credit Card",
            description: "Short-term credit for farmers with zero processing fees and low interest rates",
            category: .agriculture,
            validTill: makeDate(year: 2026, month: 3, day: 31),
            benefitSummary: "Zero Processing Fee"
        ),
        GovernmentScheme(
            title: "Education Loan Scheme",
            description: "1% interest rate concession for girl students pursuing higher education globally",
            category: .education,
            validTill: makeDate(year: 2026, month: 3, day: 31),
            benefitSummary: "1% Girl Concession"
        )
    ]
}
