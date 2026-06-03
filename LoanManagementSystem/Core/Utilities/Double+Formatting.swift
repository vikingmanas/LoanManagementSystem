import Foundation

extension Double {
    public func formattedAsINR() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.currencySymbol = "₹"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: self)) ?? "₹\(self)"
    }

    public func formattedAsCompactINR() -> String {
        let absoluteValue = abs(self)
        let sign = self < 0 ? "-" : ""

        if absoluteValue >= 100_000 {
            return "\(sign)₹\((absoluteValue / 100_000).formattedCompactNumber()) L"
        }

        return formattedAsINR()
    }

    public func formattedCompactNumber() -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
