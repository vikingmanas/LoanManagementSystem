import Foundation

extension Date {
    public func formattedAsDDMMMYYYY() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        return formatter.string(from: self)
    }
}
