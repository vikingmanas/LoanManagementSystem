import AppIntents

struct OpenLoanDashboardIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Loan Dashboard"
    static var description = IntentDescription("Opens the Loan Management System dashboard.")

    @MainActor
    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct OpenEMIPaymentsIntent: AppIntent {
    static var title: LocalizedStringResource = "Open EMI Payments"
    static var description = IntentDescription("Opens Loan Management System for EMI payment review.")

    @MainActor
    func perform() async throws -> some IntentResult {
        .result()
    }
}

struct LMSShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenLoanDashboardIntent(),
            phrases: [
                "Open \(.applicationName) dashboard",
                "Show my loans in \(.applicationName)"
            ],
            shortTitle: "Loan Dashboard",
            systemImageName: "indianrupeesign.circle"
        )

        AppShortcut(
            intent: OpenEMIPaymentsIntent(),
            phrases: [
                "Check EMI in \(.applicationName)",
                "Open payments in \(.applicationName)"
            ],
            shortTitle: "EMI Payments",
            systemImageName: "calendar.badge.clock"
        )
    }
}
