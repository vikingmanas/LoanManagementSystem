import SwiftUI

enum ManagerMockData {
    static let managerName = ""
    static let managerInitials = ""
    static let branchName = ""
    static let branchCode = ""
    static let employeeId = ""

    static let officers: [ManagerOfficer] = []
    static let applicants: [ManagerApplicant] = []
    static let notifications: [ManagerNotificationItem] = []
    static let conversations: [ManagerChatConversation] = []
    static let branchOverview = BranchOverview(
        name: "Assigned Branch",
        code: "BR",
        region: "Regional Office",
        staffCount: 0,
        activeLoanCount: 0,
        totalDisbursed: 0,
        totalRecovered: 0,
        nplRate: 0,
        auditRating: "Pending",
        monthlyTarget: 0
    )
}
