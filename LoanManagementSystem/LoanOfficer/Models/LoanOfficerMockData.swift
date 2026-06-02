import Foundation

struct LoanOfficerMockData {
    typealias LoanApplication = OfficerLoanApplication

    static let branchName = ""
    static let officerName = ""

    static func createApplications() -> [LoanApplication] {
        []
    }

    static func createActivityFeed() -> [ActivityFeedItem] {
        []
    }
}
