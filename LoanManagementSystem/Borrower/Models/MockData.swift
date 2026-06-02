import SwiftUI

extension Color {
    public static let brandNavy        = LMSColors.brandNavy
    public static let brandNavyDark    = LMSColors.brandNavyLight
    public static let brandEmerald     = LMSColors.emerald
    public static let brandEmeraldDark = LMSColors.emeraldDark
    public static let brandAmber       = LMSColors.amber
    public static let brandCoral       = LMSColors.coral
}

extension Double {
    public func formattedAsINR() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale(identifier: "en_IN")
        formatter.currencyCode = "INR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "₹\(Int(self))"
    }

    public func formattedAsCompactINR() -> String {
        let absoluteValue = abs(self)
        let sign = self < 0 ? "-" : ""

        if absoluteValue >= 100_000 {
            return "\(sign)₹\((absoluteValue / 100_000).formattedCompactNumber()) L"
        }

        return formattedAsINR()
    }

    private func formattedCompactNumber() -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = self >= 10 ? 0 : 1
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Date {
    public func formattedAsDDMMMYYYY() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: self)
    }
}

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
}
