import Foundation
import UserNotifications

final class LocalNotificationService {
    static let shared = LocalNotificationService()

    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func scheduleEMIReminder(title: String, amount: Double, dueDate: Date) async {
        let granted = await requestAuthorization()
        guard granted else { return }

        let content = UNMutableNotificationContent()
        content.title = "EMI Reminder"
        content.body = "\(title) EMI of \(CurrencyFormatter.shared.format(amount)) is due soon."
        content.sound = .default
        content.categoryIdentifier = "EMI_REMINDER"

        let reminderDate = Calendar.current.date(byAdding: .day, value: -1, to: dueDate) ?? dueDate
        var components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminderDate)
        components.hour = 9
        components.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "emi-\(title)-\(Int(dueDate.timeIntervalSince1970))",
            content: content,
            trigger: trigger
        )

        try? await UNUserNotificationCenter.current().add(request)
    }
}
