import Foundation

enum LoanEscalationNote {
    private static let officerPrefix = "Officer escalation by "

    static func officer(name: String, reason: String) -> String {
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        return "\(officerPrefix)\(name): \(trimmedReason.isEmpty ? "Requires manager review." : trimmedReason)"
    }

    static func manager(name: String) -> String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let actor = trimmedName.isEmpty ? "Branch Manager" : trimmedName
        return "Manager escalation by \(actor) for senior admin review."
    }

    static func isOfficerEscalation(_ note: String) -> Bool {
        note.hasPrefix(officerPrefix)
    }

    static func officerName(from note: String) -> String? {
        guard note.hasPrefix(officerPrefix) else { return nil }
        let remainder = note.dropFirst(officerPrefix.count)
        guard let separator = remainder.firstIndex(of: ":") else { return nil }
        let name = remainder[..<separator].trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? nil : name
    }

    static func reason(from note: String) -> String? {
        guard note.hasPrefix(officerPrefix) else { return nil }
        let remainder = note.dropFirst(officerPrefix.count)
        guard let separator = remainder.firstIndex(of: ":") else { return nil }
        let reason = remainder[remainder.index(after: separator)...].trimmingCharacters(in: .whitespacesAndNewlines)
        return reason.isEmpty ? nil : reason
    }
}

final class ManagerOfficerRatingStorage {
    static let shared = ManagerOfficerRatingStorage()

    private let defaults = UserDefaults.standard

    private init() {}

    func rating(managerId: UUID, officerId: UUID) -> Double? {
        let value = defaults.double(forKey: key(managerId: managerId, officerId: officerId))
        guard defaults.object(forKey: key(managerId: managerId, officerId: officerId)) != nil else {
            return nil
        }
        return min(5, max(1, value))
    }

    func setRating(_ rating: Double, managerId: UUID, officerId: UUID) {
        let clamped = min(5, max(1, rating))
        defaults.set(clamped, forKey: key(managerId: managerId, officerId: officerId))
    }

    func clearRating(managerId: UUID, officerId: UUID) {
        defaults.removeObject(forKey: key(managerId: managerId, officerId: officerId))
    }

    private func key(managerId: UUID, officerId: UUID) -> String {
        "managerOfficerRating.\(managerId.uuidString).\(officerId.uuidString)"
    }
}
