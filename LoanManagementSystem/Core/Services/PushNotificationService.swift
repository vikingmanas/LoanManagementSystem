import Foundation
import Supabase
import UIKit
import UserNotifications

struct PushDeviceTokenRecord: Codable {
    let userId: UUID
    let deviceToken: String
    let platform: String
    let appBundleId: String
    let deviceName: String
    let isActive: Bool
    let updatedAt: Date
}

final class PushNotificationService {
    static let shared = PushNotificationService()

    private let pendingTokenKey = "pendingAPNsDeviceToken"

    private init() {}

    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    @MainActor
    func requestAuthorizationAndRegister() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            guard granted else { return }

            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
        } catch {
            print("[PushNotificationService] Authorization failed: \(error.localizedDescription)")
        }
    }

    func cacheDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        UserDefaults.standard.set(token, forKey: pendingTokenKey)
        Task {
            await registerCurrentDeviceTokenIfPossible()
        }
    }

    func registerCurrentDeviceTokenIfPossible() async {
        guard let token = UserDefaults.standard.string(forKey: pendingTokenKey), !token.isEmpty else {
            return
        }
        guard
            let uid = AuthManager.shared.currentUser?.uid,
            let userId = UUID(uuidString: uid)
        else {
            return
        }

        let record = PushDeviceTokenRecord(
            userId: userId,
            deviceToken: token,
            platform: "ios",
            appBundleId: Bundle.main.bundleIdentifier ?? "unknown",
            deviceName: UIDevice.current.name,
            isActive: true,
            updatedAt: Date()
        )

        do {
            try await client
                .from("push_device_tokens")
                .upsert(record, onConflict: "user_id,device_token")
                .execute()
            print("[PushNotificationService] Registered APNs token for \(userId.uuidString.prefix(8))")
        } catch {
            print("[PushNotificationService] Failed to register APNs token: \(error.localizedDescription)")
        }
    }

    func deactivateCurrentDeviceToken() async {
        guard let token = UserDefaults.standard.string(forKey: pendingTokenKey), !token.isEmpty else {
            return
        }

        struct TokenUpdate: Codable {
            let isActive: Bool
            let updatedAt: Date
        }

        do {
            try await client
                .from("push_device_tokens")
                .update(TokenUpdate(isActive: false, updatedAt: Date()))
                .eq("device_token", value: token)
                .execute()
        } catch {
            print("[PushNotificationService] Failed to deactivate APNs token: \(error.localizedDescription)")
        }
    }
}
